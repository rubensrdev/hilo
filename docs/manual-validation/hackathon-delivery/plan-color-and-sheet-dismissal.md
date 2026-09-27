# Plan — color y cierre de hojas (entrega del hackathon)

Rama `mantenimiento/color-y-cierre-de-hojas`. Tres cambios de UI; la única lógica nueva es el descarte de Captura, en `CaptureState` y con tests.

## Decisiones de Rubén (2026-09-25)

- La X de Captura (antes chevron) **sustituye** al «Cancelar» de texto que solo aparecía mientras comprende: un solo control que para la lectura, descarta texto y foto y cierra la hoja. `cancel()` y sus tests no cambian (sigue usándose en `onDisappear`).
- En el estado de error (guardado sin analizar) **no hay X**: el recuerdo ya está guardado y ese estado tiene su propia salida.

## Decisiones tomadas en la implementación (para revisar)

- Durante un **reintento** (comprendiendo con un recuerdo ya guardado) la X sí aparece: es la única forma de parar la lectura. Descarta la captura y cierra; el recuerdo sin analizar sigue guardado, igual que con «Dejarlo así». Nunca borra.
- Mientras se guarda el texto tras un error de comprensión la X se oculta (`canDiscard` incluye ese guardado; MINOR 1 y 2 del `revisor-constitucion`, corregidos el 2026-09-27). En los estados de guardado, descartar no hace nada.
- El tinte del `TabView` se propaga al contenido de las pestañas; para no cambiar ningún otro control, cada pestaña vuelve a `Color.accentColor` (= `texto-primario`).

## Pasos

1. Tests de `CaptureState.discard()` / `canDiscard` (rojo) → implementación (verde).
2. `CaptureScreen`: `xmark` en `.cancellationAction`, label «Cancel», visible si `canDiscard`.
3. `ReviewScreen` («Cancel») y `SettingsScreen` («Close»): texto → `xmark` con label explícito (Rubén, 2026-09-27: `xmark` en vez de `chevron.left`).
4. `MemoryScreen`: `gearshape` con `.tint(acentoHilo)`. `RootScreen`: `TabView` con `.tint(acentoHilo)`.
5. Documentación: `tokens.md` §4, D1 en `F8-accessibility-and-design.md`, línea de «Cerrar» en `F8-settings-spanish-accessibility.md`, punto nuevo en `F4-capture-and-review.md`.
6. Build limpio 0/0, todos los tests, previews en claro/oscuro/AC, `verificador-ui` con VoiceOver, `revisor-constitucion`.

## Fuera de esta rama — defecto detectado en el paso 6 (2026-09-27)

- `PersistenceActorReviewTests` «A failed final write of an unanalyzed memory leaves nothing pending in the actor» falla siempre en el simulador de iOS 26.5 y pasa en iOS 27. En 26.x, si falla la escritura final de un recuerdo sin analizar, el recuerdo se queda pendiente en el contexto del actor y el siguiente guardado que salga bien lo escribe: la app diría «no se ha guardado» y el recuerdo acabaría guardado igualmente. Afecta a usuarios reales (el mínimo es iOS 26.4). Queda para una tarea propia; hasta entonces, la suite completa se corre también en un simulador 26.x.
