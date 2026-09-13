# Sprint9_P0_T2.1.md — Batch `cover_art_path` writes in `_startBackgroundCoverExtraction`

**Estado:** Abierto, `P1` (no bloqueante para el cierre de T2).
**Bloquea a:** nada. **Depende de:** T2 mergeado (para no pisarse con la
reescritura de `SongRepository`).
**Origen:** hallazgo cuantitativo de `Sprint9_P0_T2.md` §5.2. Sin este
número no habría ticket; con el número, es P1 automático.

---

## 1. Motivo

El benchmark §5.2 de T2 (`song_repository_pagination_benchmark_test.dart`)
midió el coste real de la decisión §2.3 de T2 (eliminar `.distinct()` de
`watchSongsWindow`) bajo el escenario adverso plausible: biblioteca recién
escaneada, extracción de carátulas corriendo en background, usuario con la
pantalla abierta.

Resultado en dev box Linux x64 (Flutter 3.44.7 / Dart 3.12.2 / SQLite 3.40.1):

| Métrica                       | Valor          | ×3–5 a Helio G85        |
|-------------------------------|---------------:|------------------------:|
| Re-emisiones totales          | 14.000         | 14.000 (no escala)      |
| Songs reconstruidos           | 700.000        | 700.000 (no escala)     |
| CPU dentro de `.map`          | 4.143 ms       | 12.429 – 20.715 ms      |
| Wall-clock de los 3.500 UPDATEs | 44.848 ms    | 134.544 – 224.240 ms    |

Cero coalescing: cada `UPDATE` de `cover_art_path` fan-out a las 4
suscripciones activas. En hardware objetivo, la UI queda expuesta a
14.000 re-emisiones repartidas a lo largo de 135–224 s de wall clock —
el isolate de UI recibe un mensaje por cada re-emisión durante más de
dos minutos. Aunque el CPU-in-map acumulado sea ~10% del wall clock, la
contención durante ese periodo no es aceptable en un dispositivo con 2 GB
de RAM donde el presupuesto total es 120 MB.

Ver `Sprint9_P0_T2.md` §11 para los números completos y §5.2 para el
código del benchmark.

---

## 2. Alcance

**Archivo único a tocar:** `lib/data/repositories/song_repository_impl.dart`,
en `_startBackgroundCoverExtraction`.

**Cambio concreto:** reemplazar el `UPDATE` por canción que hoy se ejecuta
dentro del `receivePort.listen` por un buffer acumulador:

- Acumular actualizaciones pendientes (`Map<String filePath, String? path>`
  o similar) en memoria del isolate principal.
- Disparar un flush en cualquiera de estas dos condiciones, la que ocurra
  primero:
  - **50 escrituras acumuladas**, o
  - **500 ms transcurridos** desde el último flush.
- El flush aplica todas las actualizaciones pendientes en **una sola
  transacción** (`_db.transaction`), vacía el buffer, y reprograma el
  timer de 500 ms.
- Al recibir `'DONE'` del último worker: ejecutar un flush final síncrono
  antes de marcar `_isExtractingCovers = false`.

**No cambia:**
- El esquema (`songs` table, migración — nada).
- La firma pública de `SongRepository`.
- El contrato del `coversUpdatedStream` — que ya no existe (T2 lo eliminó).
- El comportamiento observable desde fuera: la reactividad de
  `watchSongsWindow` sobre `_db.songs` sigue disparándose cuando
  `cover_art_path` cambia. Simplemente cambia en lotes en lugar de una
  fila por vez.
- El worker isolate (`_workerIsolateEntry`). Los mensajes que emite
  (`Map<String, dynamic>` con `filePath`/`path`, y `'DONE'`) son los
  mismos. El batching ocurre en el lado del **consumidor** (main isolate),
  no en el productor.

**Sí cambia:**
- La cantidad de transacciones: de 3.500 a ~70 (3.500 / 50).
- La cantidad de re-emisiones por suscripción en el escenario §5.2:
  de 3.500 a ~70.
- El consumo de CPU del isolate de UI reconstruyendo listas de `Song`:
  proyectado de 4.143 ms a ~90 ms (dev box).

---

## 3. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Un fallo entre el último `'DONE'` y el flush final deja el buffer sin escribir | Baja | Medio | Flush final síncrono en el handler de `'DONE'`, antes de tocar `_isExtractingCovers`. Test dedicado: inyectar un fallo en el penúltimo flush y verificar que el último sigue aplicándose. |
| Buffering retrasa la visibilidad de una carátula en la UI hasta 500 ms | Alta | Bajo | Aceptable. La carátula se sigue mostrando en cuanto el flush aterriza; un retraso máximo de 500 ms en la aparición de una carátula recién extraída es imperceptible frente a los 45 s de bloqueo que el benchmark midió sin el batch. |
| Múltiples flushes concurrentes si dos workers emiten `'DONE'` casi a la vez | Media | Bajo | El flush se serializa con un flag `_flushInProgress` o `await`-chain; el timer de 500 ms se cancela y reprograma. Test: simular dos `'DONE'` casi simultáneos, verificar que solo se ejecuta un flush final. |
| El buffer crece sin límite si los workers emiten más rápido de lo que el flush vacía | Baja | Bajo | El flush por 50 escrituras ya limita el tamaño del buffer por debajo de ~50 entradas en la práctica. No se necesita tope superior explícito, pero se documenta la asunción. |

---

## 4. Tests de verificación obligatorios

**Nuevos, en `test/data/repositories/song_repository_impl_test.dart`:**

- **Batching real:** sembrar 120 canciones sin carátula, dejar correr la
  extracción completa (con un doble del worker que emite mensajes
  sintéticos), verificar que el número de transacciones ejecutadas sobre
  `songs` es ≤ 4 (120 / 50 + 1 de sobrante). Instrumentar con un
  `QueryExecutor` que cuente `transaction` calls.
- **Visibilidad:** tras el batch, las 120 filas tienen el `cover_art_path`
  correcto. Ninguna se pierde.
- **Flush final:** emitir 37 mensajes (por debajo del umbral de 50),
  enviar `'DONE'`, verificar que las 37 filas se escriben **antes** de que
  `_isExtractingCovers` pase a `false`.
- **Coalescing a nivel de suscriptor (regresión de §5.2):** suscribirse a
  `watchSongsWindow(offset: 0, limit: 50)` sobre 200 canciones, dejar
  correr la extracción completa, contar emisiones. Con batching de 50, el
  esperado es ~4 emisiones, no ~200. **Criterio de aceptación: < 10
  emisiones.**

**Re-ejecución obligatoria del benchmark:**

- Volver a correr `test/data/repositories/song_repository_pagination_benchmark_test.dart`
  §5.2 **contra la implementación con batch** (requiere un tercer grupo,
  §5.4, que replique §5.2 pero llamando al repositorio real con batching
  activo en lugar de emitir `UPDATE`s secuenciales crudos — se añade al
  mismo archivo como parte de este ticket, no de T2).

**Criterio de aceptación numérico:**

| Métrica de §5.2        | Baseline (T2) | Objetivo (T2.1) | ×3–5 a Helio G85 (objetivo) |
|------------------------|--------------:|----------------:|----------------------------:|
| Re-emisiones totales   | 14.000        | < 500           | < 500                       |
| Wall-clock UPDATEs     | 44.848 ms     | < 5.000 ms      | < 25.000 ms                 |
| CPU-in-map             | 4.143 ms      | < 500 ms        | < 2.500 ms                  |

Si el benchmark post-T2.1 no alcanza estos umbrales, el ticket se reabre
para revisar el tamaño del lote (50 → 100, 200) o el intervalo del timer
(500 ms → 250 ms) con los números nuevos delante, no por suposición.

---

## 5. Fuera de alcance

- Cambios en `watchSongsWindow`, `SongsWindowNotifier`, o `SongsScreen`.
  Esos son T2 y ya estarán cerrados cuando T2.1 se aborde.
- Batching en `_scanAndPersist` (el escáner de metadatos, no el de
  carátulas). Ese camino ya está batcheado a 100 filas por flush
  (`batchSongs.length >= 100`), verificado en el código actual.
- Batching en la escritura de carátulas a disco (`cacheCoverArt`).
  Es I/O a disco, no BD; fuera de alcance.
- Cualquier cambio al esquema o migración.

---

## 6. Plan de commits

1. `perf(data): batch cover_art_path writes in background extraction` —
   cambio en `song_repository_impl.dart`. `+N`.
2. `test(data): verify batching, visibility, and final flush` — tests de
   §4. `+N`.
3. `test(benchmark): add §5.4 to measure post-T2.1 re-emission cost` —
   benchmark. `+N`.
4. `docs: close Sprint9_P0_T2.1` — cierre. `+N`.

El PR es único, contra `main`, con los cuatro commits.

---

## 7. Criterios de aceptación (definition of done)

- [ ] `_startBackgroundCoverExtraction` acumula y hace flush por lotes de 50
      o cada 500 ms, lo que ocurra primero.
- [ ] Flush final síncrono en `'DONE'`.
- [ ] Tests de §4 pasan.
- [ ] Benchmark §5.4 corre sin excepción y cumple los umbrales de §4.
- [ ] `flutter analyze` → 0 issues.
- [ ] Sin cambios en esquema, migración, entidades, o UI.
- [ ] `Sprint9_P0_T2.md` §11 actualizado con el resultado post-T2.1 como
      línea adicional en el bloque §5.2.