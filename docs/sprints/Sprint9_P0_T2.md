# Sprint9_P0_T2.md — Reactive pagination for `SongsScreen`

**Estado:** diseño cerrado, §5.1/§5.2/§5.3 ejecutados, decisión de ruta aplicada.
**Sprint:** 9 (Estabilidad y FOSS), P0.
**Bloquea a:** cierre de Sprint 9. **Depende de:** T1 mergeado (`0.0.12-beta+83`, schema v15).
**Ámbito:** `SongRepository` (contrato) → `SongRepositoryImpl` (Drift) → `SongsWindowNotifier` (Riverpod) → `SongsScreen` (UI). No se toca el motor de audio. La migración v16 añade índices, no columnas.

---

## 0. Resumen ejecutivo

T2 reemplaza el `FutureProvider` de lista completa (`sortedSongsProvider`) que hoy alimenta a `SongsScreen` por un `Notifier` con paginación reactiva sobre Drift `.watch()`, caché LRU de 4 páginas de 50 filas (~200 canciones en RAM), y scroll alfabético resuelto por búsqueda binaria sobre offsets acumulados — sin necesidad de tener la lista completa en memoria.

**Estrategia de paginación decidida el 2026-09-13 tras §5.1 y §5.3: Ruta A+A.1 — LIMIT/OFFSET con índices funcionales `LOWER()`.** §5.1 midió el baseline sin índices (38.12 ms median OFFSET 10000 en dev box, > 15 ms de umbral). §5.3 re-midió con los índices añadidos (1.13 ms, < 5 ms de umbral). Números completos en §11. La ruta B (keyset) queda descartada con número delante, no por suposición.

T2 también elimina el código muerto de Sprint 8: `SongRepository.getSongsWindow` (Future sin llamadores) y `SongRepository.coversUpdatedStream` + `coversUpdatedProvider` (nunca emitió).

---

## 1. Auditoría del estado actual (pre-T2)

### 1.1 Lo que ya existe y se reutiliza

| Pieza | Ubicación | Uso en T2 |
|---|---|---|
| `watchAlphabeticalIndex({sortOption, isAscending})` | `song_repository_impl.dart` | Se extiende con parámetro `query` opcional (§2.6). Devuelve `List<(String letter, int firstIndex)>` con offsets acumulados. |
| `AlphabeticalScrollView(sectionIndex: ...)` | `presentation/widgets/alphabetical_scroll_view.dart` | Ya soporta modo SQL puro. **No se modifica.** |
| `SongSortOption` | `domain/entities/song_sort_option.dart` | Eje único de orden. |
| `_db.songs.sectionKey` + `idx_songs_section_key` | schema v14 → v15 | Ya existe. |
| `drift.watch()` sobre `customSelect` con `readsFrom:` | usado por `watchAllAlbums/Artists/Genres/Folders/...` | Patrón confirmado. |

### 1.2 Lo que no debe sobrevivir

- `SongRepository.getSongsWindow(...)` (Future, sin llamadores, sin tests).
- `SongRepository.coversUpdatedStream` + `_coversUpdatedController`.
- `coversUpdatedProvider` (`library_providers.dart`).
- El `ref.watch(coversUpdatedProvider)` dentro de `sortedSongsProvider`.

### 1.3 Lo que existe y no se toca

- `getAllSongs` (lo siguen usando `grouped_library_providers.dart` para `multiArtistSongsProvider` y `genreSongsProvider`; su paginación es deuda separada, §9).
- Los `watch*` de agregados.
- `searchSongs`, `searchArtists`, `searchAlbums` (variantes no reactivas, se mantienen; la reactiva es `watchSongsWindow` con query).

---

## 2. Decisiones de arquitectura

### 2.1 Estrategia de paginación: **Ruta A+A.1 (decidida)**

**DECISIÓN CERRADA el 2026-09-13.** Ruta A+A.1: `LIMIT 50 OFFSET ?` sobre índice funcional `LOWER(col)`.

§5.1 (baseline, sin índices) midió 38.12 ms median OFFSET 10000 para el sort por defecto, por encima del umbral de 15 ms de §2.1.3 — habría decidido B. §5.3 re-midió con el índice `LOWER(title)` añadido: 1.13 ms median, muy por debajo del umbral de 5 ms del criterio §5.3 extendido — decide A+A.1. Los dos números en §11.

**Índices requeridos (migración v15 → v16):**

```sql
CREATE INDEX idx_songs_title_lower     ON songs (LOWER(title));
CREATE INDEX idx_songs_artist_lower    ON songs (LOWER(track_artist_id));
CREATE INDEX idx_songs_album_lower     ON songs (LOWER(album_id));
CREATE INDEX idx_songs_year            ON songs (year);
CREATE INDEX idx_songs_duration        ON songs (duration_ms);
CREATE INDEX idx_songs_date_added      ON songs (date_added_utc_ms);
ANALYZE;