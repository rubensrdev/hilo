# MEMORY.md — Hilo

Memoria entre sesiones. Se lee al empezar y se actualiza al cerrar cada fase.

## Decisiones tomadas

Las fases cerradas se archivan enteras en `docs/decisions/memory-archive/F<n>.md` y aquí queda una línea por fase. Así crece el archivo, no la memoria activa.

- [F0.1](docs/decisions/memory-archive/F0.1.md) — Proyecto y cimientos: zonas, catálogo de colores, tipografía/espaciado, String Catalog y prueba de aislamiento

Decisiones vivas, todavía sin archivar:

- **Aislamiento**: `MainActor` por defecto en el target único. `Domain` es una carpeta con cada tipo y función `nonisolated`. El compilador no protege esa frontera: la protegen los tests, el hook de importaciones y `revisor-constitucion` (`ADR-000-stack`).
- **Toolchain**: Xcode 27 con SDK de iOS 27, mínimo **iOS 26.4** (`ADR-000`, D4 y D5 revisados). El SDK va por delante del objetivo, así que el compilador ya no es la única barrera: **nunca una comprobación de disponibilidad para usar algo posterior a 26.4**.
- **ADRs**: solo para decisiones caras de revertir. Previstos: `ADR-001` (contratos del modelo y tope), `ADR-002` (esquema de persistencia), `ADR-003` (cascada y vigencia del retrato).
- **Tope de recuperación**: se deriva de `contextSize` con una función pura, con suelo y techo. Sus parámetros salen de F0.2 y quedan en `ADR-001`. Ningún literal en código ni en tests: los tests inyectan la ventana.
- **Comprender el contrato del modelo**: `tokenCount(for:)` solo existe desde 26.4 y es instrumental del spike, nunca código de producción.
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

## Patrones aprendidos en este proyecto

<!-- Patrones que han emergido y ya son convención. Cuando uno se repite en tres fases,
     es candidato a Skill propia. -->

- Un hook comprueba la ruta de destino del fichero, nunca el contenido de lo que se escribe. Inspeccionar el contenido no impide escribir un fichero protegido: impide hablar de él (citar su nombre en un test o en un comentario). `protect-files.sh` aprendió esto por las malas en F0.1.5 y en el cierre de F0.1.
- Una regla de hook demasiado ancha bloquea trabajo legítimo antes de proteger nada real. `protect-files.sh` pasó de 15 reglas (cualquier string del `tool_input`) a 4 reglas que miran solo la ruta de destino — lo que no está en la lista se escribe libre, y el diff se revisa antes de cada merge.
- Un token de `tokens.md` cuyo valor cambia según la apariencia (p. ej. "ninguno" en contraste normal, "= otro token" solo en alto contraste) no se resuelve con un alias plano de Swift en `DesignSystem` — necesita su propio colorset con las 4 variantes, para que el dato del catálogo decida y no haga falta lógica en ningún sitio.
- Un tipo o carpeta que debe existir por alcance de la fase pero sin contenido real todavía (una zona vacía, el primer tipo de `Domain`) se marca con un placeholder mínimo sin lógica de producto, y se borra en la fase que trae el contenido real.
- `revisor-constitucion` conviene lanzarlo tras cada tarea atómica con impacto en las reglas no negociables (imports, APIs prohibidas), no solo al cerrar la fase — así no sobrevive una violación varias tareas sin detectarse.

## Última sesión

### F0.1 — Proyecto y cimientos (cerrada 2026-09-20)

- **Estado**: fase cerrada y mergeada a `main`. Detalle completo en [docs/decisions/memory-archive/F0.1.md](decisions/memory-archive/F0.1.md).
- **Próxima tarea**: F0.2 — spike de Foundation Models. Es la fase excepcional que no se fusiona nunca (código fuera del target de la app); entrega un informe y `ADR-001`. Leer `docs/specs/F0.2_Spike_Foundation_Models.md` antes de abrirla.
- **Pendiente de Rubén, sin bloquear F0.2**: `IPHONEOS_DEPLOYMENT_TARGET` a nivel de proyecto sigue en 27.0 (el override de target en 26.4 gana, inocuo hoy); `docs/specs/F0.1_Proyecto_y_Cimientos.md` contrato 1 sigue diciendo "iOS 26.0".
- **Riesgos o bloqueos**: ninguno para F0.2, F1 ni F2: B1, B2 y D3 están ratificados (DEC-25, DEC-26, DEC-27). Siguen abiertos, y van con su fase: A1 (F5), B3–B7 y B15 (F6), B8, B9 y B14 (F7), B12 (F9), A2 (F10), y la superficie de error del modelo (F3), que decide el spike.
- **Contenido pendiente de Rubén**: los recuerdos de la memoria de ejemplo (F2), y los textos de producto del error de comprensión, la revisión sin conexiones, el reconocimiento honesto y el borrado total.
