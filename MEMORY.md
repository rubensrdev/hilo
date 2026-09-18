# MEMORY.md — Hilo

Memoria entre sesiones. Se lee al empezar y se actualiza al cerrar cada fase.

## Decisiones tomadas

Las fases cerradas se archivan enteras en `docs/decisions/memory-archive/F<n>.md` y aquí queda una línea por fase. Así crece el archivo, no la memoria activa.

<!-- Aún no hay fases cerradas. Ejemplo del formato:
- [F1](docs/decisions/memory-archive/F1.md) — Núcleo de dominio: canónico, resolución y recuperación puros (`ADR-002-esquema-persistencia.md`)
-->

Decisiones vivas, todavía sin archivar:

- **Aislamiento**: `MainActor` por defecto en el target único. `Domain` es una carpeta con cada tipo y función `nonisolated`. El compilador no protege esa frontera: la protegen los tests, el hook de importaciones y `revisor-constitucion` (`ADR-000-stack`).
- **Toolchain**: Xcode 27 con SDK de iOS 27, mínimo **iOS 26.4** (`ADR-000`, D4 y D5 revisados). El SDK va por delante del objetivo, así que el compilador ya no es la única barrera: **nunca una comprobación de disponibilidad para usar algo posterior a 26.4**.
- **ADRs**: solo para decisiones caras de revertir. Previstos: `ADR-001` (contratos del modelo y tope), `ADR-002` (esquema de persistencia), `ADR-003` (cascada y vigencia del retrato).
- **Tope de recuperación**: se deriva de `contextSize` con una función pura, con suelo y techo. Sus parámetros salen de F0.2 y quedan en `ADR-001`. Ningún literal en código ni en tests: los tests inyectan la ventana.
- **Comprender el contrato del modelo**: `tokenCount(for:)` solo existe desde 26.4 y es instrumental del spike, nunca código de producción.
- **Diseño**: `docs/design/tokens.md` es el contrato. `docs/design/reference/` tiene seis desviaciones conocidas, listadas en `docs/design/README.md`, que no se implementan.
- **Sin `seguridad-apple`**: la privacidad local se protege con el principio VIII de la constitución, no con una Skill.
- **Ramas**: una por fase (`fase/F<n>-<slug>`), un commit por tarea atómica, merge a `main` con `--no-ff` al cerrar. El spike de F0.2 no se fusiona nunca.
- **Reglas nuevas**: se proponen aquí, en «Patrones aprendidos», nunca editando `CLAUDE.md`.

## Errores conocidos y su solución

<!-- Una entrada por error que costó tiempo: error concreto, causa real y solución aplicada.
     Esta sección es la que evita repetirlo dentro de tres semanas. -->

Todavía vacía.

## Patrones aprendidos en este proyecto

<!-- Patrones que han emergido y ya son convención. Cuando uno se repite en tres fases,
     es candidato a Skill propia. -->

Todavía vacía.

## Última sesión

### F0.1 — Proyecto y cimientos (abierta, sin empezar)

- **Estado**: proyecto Xcode creado con los ajustes de `ADR-000` §1 y §2, repositorio git local con la documentación ya dentro. Falta todo lo demás de la fase.
- **Próxima tarea**: F0.1.2 — zonas `Domain`, `Persistence`, `Intelligence`, `Features` y `DesignSystem`, pantalla provisional y andamiaje de tests. Leer antes `docs/specs/F0.1_Proyecto_y_Cimientos.md`.
- **Riesgos o bloqueos**: ninguno para F0.1, F0.2, F1 ni F2: B1, B2 y D3 están ratificados (DEC-25, DEC-26, DEC-27). Siguen abiertos, y van con su fase: A1 (F5), B3–B7 y B15 (F6), B8, B9 y B14 (F7), B12 (F9), A2 (F10), y la superficie de error del modelo (F3), que decide el spike.
- **Contenido pendiente de Rubén**: los recuerdos de la memoria de ejemplo (F2), y los textos de producto del error de comprensión, la revisión sin conexiones, el reconocimiento honesto y el borrado total.
