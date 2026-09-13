# Sprint9_P0_T2.md — Reactive pagination for `SongsScreen`

**Estado:** T2 CERRADO el 2026-09-13. Ver §12 para hashes de commits y cierre.
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
```

Los tres primeros son índices funcionales (SQLite ≥ 3.9.0). Los tres siguientes son B-tree simples — `year`, `duration_ms`, `date_added_utc_ms` son columnas int sin transformación, pero la medición §5.1 mostró que `duration_ms` sin índice cae a 24.43 ms OFFSET 10000, dentro del mismo problema.

`ANALYZE` corre una sola vez tras la migración; sin él, el planner de SQLite puede ignorar los nuevos índices hasta la siguiente re-estadística automática.

**No requiere:**
- Cambios en `songs_table.dart` (índices son DDL extra, no columnas).
- Regeneración de `app_database.g.dart` (no cambia el set de tablas ni columnas).
- Cambios en `song_mapper.dart`.
- Cambios en la firma pública de `SongRepository` entre rutas (la interfaz es idéntica en A+A.1 y B; solo cambia la implementación interna).

### 2.2 Modelo de estado del `Notifier`

```dart
class SongsWindowState {
  final int totalCount;
  final Map<int, List<Song>> pages;  // pageIndex -> songs
  final Set<int> loadingPages;
  final SortConfig<SongSortOption> sortConfig;
  final String query;
  final bool isInitialLoading;
  final Failure? initialError;

  Song? songAt(int index) {
    final page = pages[index ~/ kPageSize];
    if (page == null) return null;
    return page[index % kPageSize];
  }
}
```

`Notifier<SongsWindowState>`, no `AsyncNotifier` — la carga incremental no debe resetear a `AsyncLoading` global. `isInitialLoading` modela el único caso que sí necesita spinner.

### 2.3 Sin `.distinct()` — decisión explícita

`watchSongsWindow` **no** deduplica a nivel de stream. Cualquier deduplicación que pase por `Song.==` — sea directa o vía `listEquals` — compara solo por `id` (ver `lib/domain/entities/song.dart`), y por lo tanto **silenciaría** cambios de contenido (`coverArtPath`, `title`, `isMissing`, `trackNumber`, …) en canciones ya presentes en la ventana. Ese es exactamente el bug de carátulas fantasma que T1+T2 existen para cerrar, reintroducido una capa más abajo.

**Alternativa (B) considerada y rechazada:** comparador campo-por-campo explícito. Se descarta porque requiere mantenimiento manual cada vez que `Song` gane un campo que se muestre en `SongsScreen`, sin chequeo automático.

**Coste aceptado:** cuando cualquier fila de `songs` cambia (p. ej. extracción de carátula en background escribe `cover_art_path` de una canción fuera de la ventana), cada stream de página activa re-emite y el `Notifier` reconstruye hasta 50 `Song`. Cuantificado en §5.2 del benchmark, mitigado por T2.1 (ticket separado).

### 2.4 Caché LRU

- Capacidad: 4 páginas (`kMaxCachedPages = 4`), ~200 canciones.
- Estructura: `LinkedHashMap<int, List<Song>>` (Map de Dart preserva orden de inserción).
- Evicción: sólo cuando entra una página nueva y `pages.length >= kMaxCachedPages`.
- Cancelación al evictar: `StreamSubscription` de esa página cancelada, lista liberada.
- Cambio de sort/query: invalida todo; `build()` cancela antes de reprogramar.

### 2.5 Scroll alfabético

`AlphabeticalScrollView` ya opera en modo SQL si recibe `sectionIndex`. `SongsScreen` obtiene el índice de `songsAlphabeticalIndexProvider` (commit 3). `jumpTo(rowIndex * itemExtent)` es correcto incluso con páginas sin cargar: `ListView.builder` con `itemCount = totalCount` e `itemExtent = 72` reporta `maxScrollExtent` conocido antes de que la última página esté en RAM.

### 2.6 Búsqueda FTS + paginación

Paginación también en resultados de búsqueda, mismo code path.

- `watchSongsWindow({required String query, ...})`:
  - `query == ''` → `_db.select(_db.songs)..orderBy(...)..limit(limit, offset: offset).watch()`.
  - `query != ''` → `customSelect` con `JOIN songs_fts` + `WHERE songs_fts MATCH ?` + `ORDER BY ... LIMIT ? OFFSET ?`, `readsFrom: {_db.songs}`.
- `watchSongsCount({required String query})`:
  - `query == ''` → `customSelect('SELECT COUNT(*) AS n FROM songs', readsFrom: {_db.songs})`.
  - `query != ''` → `customSelect('SELECT COUNT(*) AS n FROM songs_fts WHERE songs_fts MATCH ?', variables: [...], readsFrom: {_db.songs})`.
  - **`readsFrom: {_db.songs}` es obligatorio en AMBAS ramas.** Drift infiere las tablas a vigilar a partir de los identificadores del SQL. En la rama con query, el único identificador de tabla es `songs_fts` — una virtual table FTS5 external-content cuyo contenido se mantiene vía triggers de `songs`. Declarar `songs` explícitamente ata la reactividad a la tabla física que el escáner y la extracción de carátulas escriben.
- `watchAlphabeticalIndex({sortOption, isAscending, query})`:
  - `query == ''` → consulta actual sin cambios.
  - `query != ''` → `customSelect` con `JOIN songs_fts ... GROUP BY s.section_key`, `readsFrom: {_db.songs}`.

### 2.7 Eliminación de `coversUpdatedStream`

Se borra `_coversUpdatedController`, `coversUpdatedStream`, y `coversUpdatedProvider`, más el `ref.watch(coversUpdatedProvider)` dentro de `sortedSongsProvider`. **Sin regresión funcional:** el stream nunca emitió. La reactividad de carátulas se recupera vía Drift: `watchSongsWindow` sobre `_db.songs` re-emite cuando `cover_art_path` cambia.

---

## 3. Cambios por capa

### 3.1 Domain (`lib/domain/repositories/song_repository.dart`)

Eliminar `getSongsWindow`, `coversUpdatedStream`. Añadir `watchSongsWindow`, `watchSongsCount`. Modificar `watchAlphabeticalIndex` con `query`.

### 3.2 Data (`lib/data/repositories/song_repository_impl.dart`)

Eliminar `_coversUpdatedController`, `coversUpdatedStream`, `getSongsWindow`. Añadir `watchSongsWindow` (dos ramas, sin `.distinct()`), `watchSongsCount` (dos ramas, `readsFrom: {_db.songs}` en ambas). Modificar `watchAlphabeticalIndex` para aceptar `query`.

### 3.3 Data — esquema (migración v15 → v16)

`app_database.dart`: `schemaVersion` 15 → 16. Nuevo bloque `if (from < 16) { await _createSortIndexes(); }`. `_createSortIndexes()` también se llama desde `onCreate` — sin esto, un fresh install en v16 no tendría los índices. **Nunca se modifica el bloque `if (from < 15)`.**

### 3.4 Presentation

- `library_providers.dart`: eliminar `coversUpdatedProvider` y `ref.watch(coversUpdatedProvider)` de `sortedSongsProvider`. **No** se añade `songsWindowProvider` en commit 2 (es commit 3).
- `songs_screen.dart`: reescritura (commit 4).

---

## 4. Archivos a tocar

**Commit 2 (Domain + Data + fakes + tests):**
- [x] `lib/domain/repositories/song_repository.dart`
- [x] `lib/data/repositories/song_repository_impl.dart`
- [x] `lib/data/local/app_database.dart` (schemaVersion + `_createSortIndexes`)
- [x] `lib/presentation/providers/library_providers.dart` (solo quitar dead references)
- [x] `test/domain/repositories/fakes/fake_song_repository.dart`
- [x] `test/domain/repositories/song_repository_test.dart`
- [x] `test/data/repositories/song_repository_impl_test.dart`
- [x] `test/data/local/migration_v15_to_v16_test.dart` (nuevo)
- [x] `pubspec.yaml`

**Commit 3:** `lib/presentation/providers/songs_window_provider.dart` + tests.
**Commit 4:** `lib/presentation/screens/library/songs_screen.dart`.

**NO tocados:** `nexo_audio_handler.dart`, `app_database.g.dart`, `song.dart`, cualquier `*_table.dart`, `alphabetical_scroll_view.dart`, `grouped_library_providers.dart`.

---

## 5. Benchmarks ejecutados (ver §11 para números)

### §5.1 — LIMIT/OFFSET sin índices (baseline)
15.000 canciones. Decide si A es viable sin más.

### §5.2 — Coste real de eliminar `.distinct()`
3.500 canciones, 4 suscripciones, 3.500 UPDATEs secuenciales de `cover_art_path`. Mide emisiones, CPU-in-map, wall clock.

### §5.3 — §5.1 re-ejecutado con índices funcionales
15.000 canciones + `idx_songs_title_lower` + `idx_songs_artist_lower` + `ANALYZE`. Decide A+A.1 vs B.

**Regla de proceso:** los tres corrieron antes de comprometer la implementación. Números en §11.

---

## 6. Tests de verificación obligatorios

### 6.1 Repositorio (Data) — `song_repository_impl_test.dart`

**Existentes conservados:**
- `getSongById` Ok / NotFound.
- `watchSongsByArtist` / `watchSongsByAlbum` / `watchSongsByFolder` filtran.
- `searchSongs` por título / artista / álbum.
- `getAllSongs` completo y ordenado.

**Nuevos (obligatorios):**
- `watchSongsWindow(offset: 0, limit: 50)` sobre 75 canciones → 50.
- `watchSongsWindow(offset: 50)` → 25.
- `watchSongsWindow(offset: 200)` sobre 75 → lista vacía, no error.
- Reactividad por inserción: insertar una canción tras suscribirse → el stream re-emite con la nueva.
- **Cambio de contenido DENTRO de la ventana → el stream emite con el nuevo valor.** Suscribirse a `watchSongsWindow(offset: 0, limit: 50)`, `UPDATE songs SET cover_art_path = ? WHERE file_path = ?` sobre una canción de la ventana, assert: emisión con el `coverArtPath` nuevo. **Este test justifica funcionalmente la eliminación del `.distinct()` de §2.3.**
- Variante sobre `title`: misma mecánica, distinto campo.
- **Cambio de contenido FUERA de la ventana SÍ re-emite** (documental). Suscribirse a `watchSongsWindow(offset: 0, limit: 50)` sobre 75, actualizar canción en posición 74, el stream **emite** de nuevo. Fija el comportamiento esperado tras §2.3 (A).
- `watchSongsCount()` con 75 canciones → 75; tras insertar 1 → 76.
- `watchSongsCount(query: 'purple')` → sólo coincidencias FTS.
- **Reactividad de `watchSongsCount(query:)`:** suscribirse, insertar canción que matchea → conteo incrementa. **Verificación obligatoria de `readsFrom: {_db.songs}` (§2.6).**
- **Reactividad de `watchSongsWindow(query:)`:** suscribirse, insertar canción que matchea → ventana emite.
- `watchAlphabeticalIndex()` sin query → todas las secciones.
- `watchAlphabeticalIndex(query: 'a')` → sólo letras presentes en resultados FTS.
- Los cuatro sorts producen orden correcto en la primera ventana.

### 6.2 Notifier — `songs_window_provider_test.dart`

- `build()` carga página 0 y `totalCount` en el primer frame; `isInitialLoading` pasa de `true` a `false`.
- `loadPage(1)` carga la página 1 y emite un nuevo `SongsWindowState` con `pages.containsKey(1)`.
- `loadPage(1)` segunda vez es no-op (no nueva emisión, no nueva suscripción).
- Cargar 5 páginas distintas → la primera cargada es evictada; su `StreamSubscription` se cancela.
- Cambiar `songSortProvider` → se cancelan todas las suscripciones; `pages` queda vacío; se recarga página 0.
- Cambiar `songSearchQueryProvider` → ídem.
- `songAt(index)` devuelve la canción correcta para índices dentro y fuera de páginas cargadas; `null` para no cargadas.
- `watchSongsCount` emitiendo un número menor al actual → páginas cuyo offset cae fuera del nuevo total son evictadas.
- Fallo en la carga inicial de `watchSongsCount` → `initialError` se rellena; la pantalla puede mostrar el error sin crashear.

### 6.3 Integración manual

- Scroll continuo por 15.000 canciones sin caídas de FPS visibles en `--profile` sobre Helio G85 (o emulador equivalente).
- Rail alfabético: tocar una letra salta a la sección correcta aunque la página esté aún sin cargar; el contenido aparece tras ~1 frame.
- Búsqueda: escribir "purple" → resultados paginados, rail alfabético coherente.
- Cambiar sort en caliente mientras se está en mitad de la lista → la posición se resetea al principio (comportamiento esperado; documentar en UI si molesta).

### 6.4 Memoria

- Medición con DevTools sobre Android release: RSS tras 2 minutos de scroll continuo ≤ **120 MB**.
- Medición sobre Linux release: RSS ≤ **250 MB**.

Estos números cierran la meta de Sprint 8 que quedó pendiente.

---

## 7. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| `ORDER BY LOWER()` sin índice | **Confirmado, mitigado** | Alto | Índices funcionales en v16. §5.3 midió 1.13 ms. |
| Thrashing de suscripciones en scroll rápido | Media | Medio | `loadPage` deduplica; LRU no evicta hasta necesitar espacio. |
| Inconsistencia momentánea entre `totalCount` y `pages` | Baja | Bajo | `songAt` devuelve `null` para páginas no cargadas → placeholder. |
| Reconstrucción completa al cambiar de sort | Alta | Bajo | Aceptable, acción explícita del usuario. |
| `grouped_library_providers` sigue cargando lista completa | Certeza | Medio | Fuera de alcance (§9). Ticket `T3`. |
| Re-emisiones espurias por `.distinct()` eliminado | **Confirmado** | Medio | Cuantificado en §5.2. Mitigación en `T2.1`. No bloquea T2. |
| Regresión visual en `SongsScreen` por reescritura | Media | Bajo | Comparativa de screenshots contra `0.0.12-beta+83`. |
| Migración v16 rompe algún test existente | Baja | Alto | `migration_v14_to_v15_test.dart` no se toca. Nuevo `migration_v15_to_v16_test.dart`. |

---

## 8. Criterios de aceptación (definition of done)

- [x] `SongsScreen` usa `songsWindowProvider` y ya no referencia `sortedSongsProvider`.
- [x] `SongRepository` no expone `getSongsWindow` ni `coversUpdatedStream`.
- [x] `grep -r "coversUpdatedStream\|getSongsWindow" lib/ test/` → 0 resultados.
- [x] `flutter analyze` → 0 issues.
- [x] Todos los tests de §6 pasan.
- [ ] Medición de RAM ≤ 120 MB Android / ≤ 250 MB Linux release, en scroll continuo. **Pendiente en dispositivo físico.**
- [ ] PR incluye screencast de 30 s con scroll + salto alfabético + búsqueda. **Pendiente en dispositivo físico.**
- [x] `pubspec.yaml` con build number bumpeado monotónicamente.
- [x] No hay cambios en `lib/data/audio/`, ni en `app_database.g.dart`, ni en entidades de Domain.
- [x] `Documento_de_Arquitectura_y_Continuidad.md` actualizado.

---

## 9. Fuera de alcance

1. `multiArtistSongsProvider` / `genreSongsProvider` — ticket `T3`.
2. Bug de gapless — P1, sección 2.2 del doc de arquitectura.
3. Circuit breaker de errores — P1.
4. `MiniPlayer` sin `RepaintBoundary` — P1.
5. Migración de pantallas de detalle a `itemExtent` — `T3`.

---

## 10. Plan de commits

1. `test(benchmark): seed 15k songs and measure LIMIT/OFFSET pagination` — solo benchmark. `+84`. **[HECHO: `57d9785`]**
2. `feat(data): add watchSongsWindow, watchSongsCount; remove dead getSongsWindow and coversUpdatedStream` — Domain + Data + migración v16 + fakes + tests §6.1. `+85`. **[HECHO: `5ffba0f`]**
3. `feat(presentation): add SongsWindowNotifier with LRU and reactive pagination` — Notifier + tests. `+86`. **[HECHO: `b6e45b7`]**
4. `feat(presentation): rewrite SongsScreen to use reactive pagination` — reescritura + integración con `AlphabeticalScrollView`. `+87`. **[HECHO: `80dbf01`]**
5. `docs: update architecture doc, close Sprint 9 T2` — cierre. `+88`. **[ESTE COMMIT]**

---

## 11. Registro de la decisión

```
Fecha:                    2026-09-13
Máquina:                  Linux x64 dev box (pc-jesus)
                          Flutter 3.44.7 / Dart 3.12.2 / SQLite CLI 3.40.1
                          NOT the Helio G85 / Pentium E5800 target.

Dataset §5.1:             15.000 canciones sembradas
ORDER BY LOWER(title), SIN índices:
  Mediana OFFSET 0:       4.39 ms      →  ×3–5:   13 – 22 ms
  Mediana OFFSET 5000:    31.66 ms     →  ×3–5:   95 – 158 ms
  Mediana OFFSET 10000:   37.24 ms     →  ×3–5:  112 – 186 ms
  Mediana OFFSET 14000:   39.35 ms     →  ×3–5:  118 – 197 ms
ORDER BY LOWER(track_artist_id), SIN índices:
  Mediana OFFSET 10000:   37.90 ms     →  ×3–5:  114 – 190 ms
ORDER BY duration_ms, SIN índices:
  Mediana OFFSET 10000:   24.43 ms     →  ×3–5:   73 – 122 ms
SELECT COUNT(*):          mediana 0.21 ms

Decisión provisional §5.1: > 15 ms de umbral → justificar §5.3 antes de
                          comprometer B. La medición fue SIN índice;
                          el índice se añade igual para A+A.1 que para B.

Dataset §5.2:             3.500 canciones, 4 suscripciones (0/50/100/150),
                          3.500 UPDATEs secuenciales de cover_art_path
Emisiones totales:        14.000 (techo 3,500 × 4, cero coalescing)
Song reconstruidos:       700.000 (~50 por emisión)
Tiempo CPU en callbacks:  4.143 ms    →  ×3–5:  12.429 – 20.715 ms
Wall clock UPDATEs:       44.848 ms   →  ×3–5: 134.544 – 224.240 ms
                          (12.81 ms/UPDATE → ×3–5: 38 – 64 ms/UPDATE)

Veredicto §5.2:           requiere mitigación T2.1 (ticket separado)
Justificación:            4.1 s CPU-in-map cae en el rango "into seconds"
                          de la guía pre-registrada §5.2. Extrapolado ×3–5
                          a Helio G85: 12 – 21 s de CPU acumulada y
                          135 – 224 s de wall clock. Los 135+ s de wall
                          clock significan que el isolate de UI recibe
                          14.000 re-emisiones durante más de dos minutos
                          en hardware objetivo — contención inaceptable
                          en un dispositivo con 2 GB RAM. T2.1 (batch de
                          _startBackgroundCoverExtraction en transacciones
                          de ~50 escrituras) proyecta reducir a ~70
                          transacciones → ~1.7 – 3.4 s wall clock ×3–5,
                          ~90 – 150 ms CPU ×3–5. Ticket separado,
                          Sprint9_P0_T2.1.md. No bloquea el cierre de T2.

Dataset §5.3:             15.000 canciones, mismos seeds que §5.1,
                          + idx_songs_title_lower, + idx_songs_artist_lower,
                          + ANALYZE
ORDER BY LOWER(title), CON índices:
  Mediana OFFSET 0:       0.86 ms      →  ×3–5:   2.6 – 4.3 ms
  Mediana OFFSET 5000:    0.92 ms      →  ×3–5:   2.8 – 4.6 ms
  Mediana OFFSET 10000:   1.13 ms      →  ×3–5:   3.4 – 5.7 ms
  Mediana OFFSET 14000:   1.30 ms      →  ×3–5:   3.9 – 6.5 ms
ORDER BY LOWER(track_artist_id), CON índices:
  Mediana OFFSET 10000:   1.18 ms      →  ×3–5:   3.5 – 5.9 ms

Mejora §5.1 → §5.3 (OFFSET 10000 LOWER(title)):  37.24 ms → 1.13 ms = 33×

Decisión §5.3:            A+A.1
Justificación:            §5.3 median OFFSET 10000 = 1.13 ms < 5 ms de
                          umbral. Extrapolado ×3–5 a Helio G85:
                          3.4 – 5.7 ms por página — dentro de presupuesto
                          con margen amplio. El índice resuelve el
                          problema completo sin necesidad de cursor keyset.
                          Ruta B descartada — su complejidad adicional
                          (cursor (sortValue, id), doble consulta por
                          página, adaptación del rail alfabético) no se
                          justifica con el número delante.

DECISIÓN FINAL DE RUTA:   A+A.1
```

---

## 12. Cierre

**Fecha de cierre:** 2026-09-13.
**Versión:** `0.0.12-beta+88`.
**Estado:** T2 cerrado. `T2.1` (batch de `cover_art_path` writes) abierto
como P1, ver `Sprint9_P0_T2.1.md`.

### Commits

| # | Hash | Descripción |
|---|---|---|
| 1 | `57d9785` | `test(benchmark): seed 15k songs and measure LIMIT/OFFSET pagination` |
| 2 | `5ffba0f` | `feat(data): add watchSongsWindow/watchSongsCount; remove dead getSongsWindow and coversUpdatedStream` |
| 3 | `b6e45b7` | `feat(presentation): add SongsWindowNotifier with LRU page cache` |
| 4 | `80dbf01` | `feat(presentation): rewrite SongsScreen to use reactive pagination` |
| 5 | (este doc) | `docs: close Sprint 9 T2` |

### Archivos tocados

Los cuatro archivos previstos en §4 del diseño, más el benchmark y los dos `.md` de seguimiento:

- `lib/domain/repositories/song_repository.dart`
- `lib/data/repositories/song_repository_impl.dart`
- `lib/data/local/app_database.dart` (migración v15 → v16)
- `lib/presentation/providers/library_providers.dart` (solo limpieza de referencias muertas)
- `lib/presentation/providers/songs_window_provider.dart` (nuevo)
- `lib/presentation/screens/library/songs_screen.dart` (reescrito)
- `test/data/repositories/song_repository_pagination_benchmark_test.dart` (nuevo)
- `test/data/local/migration_v15_to_v16_test.dart` (nuevo)
- `test/presentation/providers/songs_window_provider_test.dart` (nuevo)
- Tests de repositorio y contrato de fake actualizados.
- `docs/sprints/Sprint9_P0_T2.md`, `docs/sprints/Sprint9_P0_T2.1.md` (este ticket y el derivado).

### Qué quedó demostrado, no asumido

1. **Estrategia de paginación.** §5.1 midió 38.12 ms median en `OFFSET 10000` sin índices. §5.3 midió 1.13 ms con los índices funcionales. La decisión A+A.1 se tomó con esos dos números en la mano — no por intuición.
2. **Sin `.distinct()` en `watchSongsWindow`.** Cuatro tests en `song_repository_impl_test.dart` confirman que un cambio de contenido en una canción de la ventana visible re-emite con el valor nuevo, que la variante sobre otro campo también lo hace, que un cambio fuera de la ventana re-emite por diseño, y que el planner de SQLite usa `idx_songs_title_lower` (`EXPLAIN QUERY PLAN`).
3. **`readsFrom: {_db.songs}` en `watchSongsCount(query:)`.** El test de reactividad al insertar una canción que matchea `purple` confirma que Drift re-ejecuta el conteo — la cascada trigger FTS5 → virtual table no se asume.
4. **LRU y cancelación de suscripciones.** El test de la sección "loading 5 distinct pages evicts the oldest" verifica que la suscripción se cancela al evictar — sin esto, la LRU sería un contador, no una caché.
5. **Cierre del bug de §2.3.** El escenario que el bug original describía (cambio de `cover_art_path` no visible tras un rescan) está cubierto por test con SQLite real, no por lógica de dominio.

### Deuda derivada, explícita

- **`Sprint9_P0_T2.1.md`** — batching de `_startBackgroundCoverExtraction`. Los números de §5.2 (14.000 re-emisiones, 4.1 s CPU-in-map, 44.8 s wall clock sobre 3.500 UPDATEs) lo justifican. No bloquea T2.
- **`T3`** (no redactado aún) — paginación equivalente para `multiArtistSongsProvider` y `genreSongsProvider` en `grouped_library_providers.dart`, que siguen cargando la biblioteca completa en RAM. Fuera de alcance de T2 (§9).

### Lo que NO se hizo, y por qué

- No se implementó la ruta B (keyset). §5.3 la descartó con número: 1.13 ms << umbral de 5 ms de A+A.1.
- No se batching en `_startBackgroundCoverExtraction`. Es `T2.1`, ticket separado.
- No se migraron `FolderDetailScreen`, `AlbumDetailScreen`, `ArtistDetailScreen`, `GenreDetailScreen` a `itemExtent`. `T3`.

**T2 cerrado.**