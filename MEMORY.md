# MEMORY.md — Hilo

Memoria entre sesiones. Se lee al empezar y se actualiza al cerrar cada fase.

## Decisiones tomadas

Las fases cerradas se archivan enteras en `docs/decisions/memory-archive/F<n>.md` y aquí queda una línea por fase. Así crece el archivo, no la memoria activa.

- [F0.1](docs/decisions/memory-archive/F0.1.md) — Proyecto y cimientos: zonas, catálogo de colores, tipografía/espaciado, String Catalog y prueba de aislamiento
- [F0.2](docs/decisions/memory-archive/F0.2.md) — Spike de Foundation Models: parámetros del tope, contrato de extracción validado, superficie de error de O6 resuelta. Nunca fusionada — entrega `ADR-001` y `INFORME.md` directamente en `main`
- [F1](docs/decisions/memory-archive/F1.md) — Núcleo de dominio: nombre canónico, duda de identidad, resolución, conexión deducida, renombrar/alias con colisión y huérfanos. Todo puro, `nonisolated`, sin estado
- [F2](docs/decisions/memory-archive/F2.md) — Persistencia: esquema de cuatro entidades (DEC-37 `isAnalyzed` explícito, DEC-38 sufijo `Record`), actor de modelo único, foto externa sin metadatos, memoria de ejemplo idempotente, borrado total. `ADR-002` cerrado en `main`

Decisiones vivas, todavía sin archivar:

- **Aislamiento**: `MainActor` por defecto en el target único. `Domain` es una carpeta con cada tipo y función `nonisolated`. El compilador no protege esa frontera: la protegen los tests, el hook de importaciones y `revisor-constitucion` (`ADR-000-stack`).
- **Toolchain**: Xcode 27 con SDK de iOS 27, mínimo **iOS 26.4** (`ADR-000`, D4 y D5 revisados). El SDK va por delante del objetivo, así que el compilador ya no es la única barrera: **nunca una comprobación de disponibilidad para usar algo posterior a 26.4**.
- **ADRs**: solo para decisiones caras de revertir. `ADR-001` (contratos del modelo y tope, F0.2) y `ADR-002` (esquema de persistencia, F2) cerrados. Previsto: `ADR-003` (cascada y vigencia del retrato).
- **Tope de recuperación** (`ADR-001`, F0.2): `tope(contextSize) = clamp(floor((contextSize − 71 − 300) / 176), 21, 30)`. Ningún literal en código ni en tests: los tests inyectan la ventana. El techo (30) es presupuesto de ingeniería, no hallazgo de calidad — se revisa cuando F6/F7 generen retratos reales.
- **Contrato de extracción y superficie de error** (`ADR-001`, F0.2): contrato de F3 validado tal cual, con dos matices de validación posterior (`dateText` y `deducedYear` pueden llegar alucinados). El `catch` de F3 cubre `LanguageModelSession.GenerationError` y `FoundationModels.LanguageModelError`, no solo la primera. `tokenCount(for:)` solo existe desde 26.4 y es instrumental del spike, nunca código de producción.
- **Diseño**: `docs/design/tokens.md` es el contrato. `docs/design/reference/` tiene seis desviaciones conocidas, listadas en `docs/design/README.md`, que no se implementan.
- **Sin `seguridad-apple`**: la privacidad local se protege con el principio VIII de la constitución, no con una Skill.
- **Ramas**: una por fase (`fase/F<n>-<slug>`), un commit por tarea atómica, merge a `main` con `--no-ff` al cerrar. El spike de F0.2 no se fusiona nunca.
- **Gobernanza y ramas** (revisado en F0.1): los hooks y los agentes viajan con la rama de fase, se comprometen ahí. Solo `CLAUDE.md`, las specs y los ADR los escribe Rubén directamente en `main`.
- **Reglas nuevas**: se proponen aquí, en «Patrones aprendidos», nunca editando `CLAUDE.md`.

## Errores conocidos y su solución

<!-- Una entrada por error que costó tiempo: error concreto, causa real y solución aplicada.
     Esta sección es la que evita repetirlo dentro de tres semanas. -->

- **F0.1.5**: `protect-files.sh` bloqueaba `StringCatalogEdit` (la herramienta pensada para traducir sin tocar el `.xcstrings` a mano) porque el matcher de `settings.json` engancha el hook a cualquier tool de Xcode con "Write"/"Edit" en el nombre. Solución: el propio hook exime cualquier `tool_name` que empiece por `mcp__xcode__` de su regla sobre `.xcstrings`, en vez de tocar el matcher.
- **Cierre de F0.1**: `revisor-constitucion` encontró un `import UIKit` en `ColorCatalogTests.swift` (de F0.1.3) que había sobrevivido hasta el cierre de fase sin detectarse, porque el auditor solo se había lanzado al final, no tras cada tarea atómica.
- **F0.2.3, pasada espaciada en el físico**: `RunProject` se quedó colgado más de 120s dos veces seguidas, con "the app failed to launch after building successfully" pese a `BUILD SUCCEEDED`. Causa no confirmada (hipótesis sin cerrar en `HALLAZGOS.md`). Solución aplicada: M5, M6 y O2-O5 se cerraron en el simulador (misma generación 27), documentando la desviación del criterio de aceptación en el informe en vez de insistir sin diagnóstico.
- **F0.2.4**: `GetConsoleOutput` no deja fichero de log recuperable en una sesión posterior, a diferencia de `RunProject`/`RunAllTests`. Los números de M2/M3 de una pasada anterior se perdieron tras un `/compact` y hubo que remedirlos. Solución: cualquier número leído por `GetConsoleOutput` se transcribe al fichero de notas en el momento, nunca se deja para "más tarde en la misma sesión".
- **Cierre de F0.2**: `revisor-constitucion` dio un BLOCKER falso al auditar `INFORME.md` y `ADR-001` con la rama del spike pagada — esos dos ficheros solo existen en `main` (la fase nunca se fusiona). Solución: auditar los entregables de cierre de F0.2 con `main` pagado, no con la rama de fase.
- **Cierre de F1**: `ElementResolution.resolving` (F1.3) y `NameCollision.checking` (F1.5) duplicaban el mismo predicado de coincidencia de canónico contra `displayName`/`aliases`, con código casi idéntico. Ninguna de las dos auditorías por tarea lo detectó porque cada una solo veía su propio fichero nuevo. Solución: extraído a `Element.matches(canonical:)`, usado por ambas.
- **F2.6**: verificar que el borrado total libera el almacenamiento externo midiendo el tamaño total del directorio del store da una falsa alarma — el fichero SQLite no se encoge al borrar filas (las páginas libres se reutilizan, no se truncan), así que el tamaño total puede crecer aunque el dato externo sí se haya liberado. Solución: excluir explícitamente los ficheros del propio store (`<nombre>.store`, `-wal`, `-shm`) del cómputo y medir solo el resto del directorio, que es donde vive el dato externo.
- **Cierre de F2**: al redactar `ADR-002` a petición de Rubén se escribió un borrador nuevo desde cero sin comprobar antes si ya había contenido en `main` — sí lo había, `Proposed` desde F2.1, invisible desde el árbol de trabajo de la rama de fase por el mismo motivo ya conocido de F0.2 (ver «Patrones aprendidos»). `git checkout main` se negó a sobrescribir un fichero no rastreado y evitó perderlo, pero casi se pisan. Solución: antes de crear cualquier documento en `docs/decisions/` o `docs/`, comprobar con `git show main:<ruta>` si ya existe contenido, no solo mirar el árbol de trabajo de la rama de fase actual.

## Patrones aprendidos en este proyecto

<!-- Patrones que han emergido y ya son convención. Cuando uno se repite en tres fases,
     es candidato a Skill propia. -->

- Un hook comprueba la ruta de destino del fichero, nunca el contenido de lo que se escribe. Inspeccionar el contenido no impide escribir un fichero protegido: impide hablar de él (citar su nombre en un test o en un comentario). `protect-files.sh` aprendió esto por las malas en F0.1.5 y en el cierre de F0.1.
- Una regla de hook demasiado ancha bloquea trabajo legítimo antes de proteger nada real. `protect-files.sh` pasó de 15 reglas (cualquier string del `tool_input`) a 4 reglas que miran solo la ruta de destino — lo que no está en la lista se escribe libre, y el diff se revisa antes de cada merge.
- Un token de `tokens.md` cuyo valor cambia según la apariencia (p. ej. "ninguno" en contraste normal, "= otro token" solo en alto contraste) no se resuelve con un alias plano de Swift en `DesignSystem` — necesita su propio colorset con las 4 variantes, para que el dato del catálogo decida y no haga falta lógica en ningún sitio.
- Un tipo o carpeta que debe existir por alcance de la fase pero sin contenido real todavía (una zona vacía, el primer tipo de `Domain`) se marca con un placeholder mínimo sin lógica de producto, y se borra en la fase que trae el contenido real.
- `revisor-constitucion` conviene lanzarlo tras cada tarea atómica con impacto en las reglas no negociables (imports, APIs prohibidas), no solo al cerrar la fase — así no sobrevive una violación varias tareas sin detectarse.
- Las cabeceras de fichero que autogenera Xcode en cada `.swift` nuevo ("Created by...") se limpian sistemáticamente al cerrar la fase, no al crearlas — interrumpir la tarea atómica en curso por un comentario de plantilla no compensa (visto en F0.1 y en F0.2).
- Una fase excepcional que entrega documentación directamente a `main` sin fusionar (F0.2) deja esos ficheros invisibles en el `checkout` de su propia rama de fase — cualquier auditoría o lectura de esos entregables tiene que hacerse con `main` pagado, nunca con la rama de la fase. Esto aplica igual al *escribir* un documento nuevo en `docs/`, no solo al auditar uno ya entregado: comprobar `git show main:<ruta>` antes de asumir que no existe (F2).
- Un tipo nuevo en `Persistence/` que se llama de forma síncrona desde `PersistenceActor` necesita `nonisolated` explícito — sin él, el aislamiento `MainActor` por defecto del proyecto lo atrapa y la compilación falla solo al intentar llamarlo desde el actor. Visto dos veces en F2: `PhotoStripper.stripMetadata` (F2.3) y `ExampleMemoryContent` (F2.5).
- La auditoría de cierre de fase sobre el conjunto completo encuentra cosas que las auditorías por tarea, una a una, no pueden ver por diseño: duplicación de lógica entre tipos escritos en tareas distintas (F1: `ElementResolution` y `NameCollision`). Auditar tarea a tarea sigue siendo necesario para no arrastrar una violación varias tareas, pero no sustituye la pasada de cierre sobre todos los ficheros juntos.
- Un tipo del dominio inmutable cuyo inicializador regenera siempre su propio `ID` no puede "mutar" dentro del dominio — solo puede validar una operación (renombrar, añadir alias) y devolver el veredicto; construir el valor actualizado le corresponde a la capa que sí tiene identidad persistente (F1.5, `Element`/`ElementID`).
- Cuando una regla de plegado de texto (mayúsculas, acentos) puede variar con el idioma del dispositivo, fijar el locale explícitamente (`en_US_POSIX`) en vez de dejarlo `nil` — si no, el mismo nombre canonicaliza distinto en un iPhone en español que en uno en inglés (F1.2, `CanonicalName.of`).

## Última sesión

### F2 — Persistencia (cerrada 2026-09-21)

- **Estado**: fase cerrada y fusionada a `main` con `--no-ff` (rama `fase/F2-persistencia`). Seis contratos, seis tareas atómicas (F2.1-F2.6) más las auditorías de cierre: `revisor-constitucion` 0 BLOCKER (1 MENOR, ver pendiente), `auditor-concurrencia` 0 hallazgos. 119/119 tests en verde, 0 warnings. `ADR-002-esquema-persistencia` cerrado (`Accepted`) directamente en `main`. Detalle completo en [docs/decisions/memory-archive/F2.md](decisions/memory-archive/F2.md).
- **Próxima tarea**: F3 — Comprensión. Leer `docs/specs/F3_Comprension.md` antes de abrirla; consume `ADR-001` (tope de recuperación, contrato de extracción, superficie de error) y usa `PersistenceActor` de F2 (`save(_:Memory, isAnalyzed:...)`) para el camino de guardar-sin-analizar y comprender más tarde (DEC-16/DEC-18).
- **Pendiente, no bloqueante**: `PersistenceActor.fetchMemories()`/`fetchElements()`/`fetchAppearances()` no declaran `fetchLimit`, aunque el contrato 2 de F2 pide límite en las consultas que puedan crecer. Decisión de Rubén (2026-09-21): no tocarlo ahora, resolverlo cuando F5/F6 definan su paginación real.
- **Riesgos o bloqueos**: ninguno para F3. Riesgo ya aceptado por Rubén (`ADR-002` §7): sin migraciones en el MVP, un cambio de esquema no aditivo obliga a reinstalar el dispositivo de demo hasta el ensayo final de la semana.
- **Contenido pendiente de Rubén**: la memoria de ejemplo ya está resuelta (F2.5, `docs/content/memoria-de-ejemplo.md`). Sigue pendiente: los textos de producto del error de comprensión, la revisión sin conexiones, el reconocimiento honesto y la confirmación de borrado total en interfaz (F8). `IPHONEOS_DEPLOYMENT_TARGET` a nivel de proyecto sigue en 27.0 (inocuo); `docs/specs/F0.1_Proyecto_y_Cimientos.md` contrato 1 sigue diciendo "iOS 26.0".
