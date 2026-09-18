# MEMORY.md — Hilo

Memoria entre sesiones. Se lee al empezar y se actualiza al cerrar cada fase.

## Decisiones tomadas

Las fases cerradas se archivan enteras en `docs/decisions/memory-archive/F<n>.md` y aquí queda una línea por fase. Así crece el archivo, no la memoria activa.

<!-- Aún no hay fases cerradas. Ejemplo del formato:
- [F1](docs/decisions/memory-archive/F1.md) — Núcleo de dominio: canónico, resolución y recuperación puros (`ADR-002-esquema-persistencia.md`)
-->

Decisiones vivas, todavía sin archivar:

- **Aislamiento**: `MainActor` por defecto en el target único. `Domain` es una carpeta con cada tipo y función `nonisolated`. El compilador no protege esa frontera: la protegen los tests, el hook de importaciones y `revisor-constitucion` (`ADR-000-stack`).
- **Toolchain**: Xcode 26 con SDK de iOS 26, mínimo iOS 26.0. Una API de iOS 27 no compila, y así debe seguir.
- **ADRs**: solo para decisiones caras de revertir. Previstos: `ADR-001` (contratos del modelo y tope), `ADR-002` (esquema de persistencia), `ADR-003` (cascada y vigencia del retrato).
- **Tope de recuperación**: pendiente de medir en F0.2. Hasta entonces, constante con valor provisional 6. Ningún test repite ese número.
- **Diseño**: `docs/design/tokens.md` es el contrato. `docs/design/reference/` tiene seis desviaciones conocidas, listadas en `docs/design/README.md`, que no se implementan.
- **Sin `seguridad-apple`**: la privacidad local se protege con el principio VIII de la constitución, no con una Skill.

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
- **Riesgos o bloqueos**: los huecos B1 y B2 (`05`) siguen sin ratificar y bloquean F1. D3, los metadatos de la foto, bloquea F2.
