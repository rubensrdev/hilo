# Hallazgos en curso — F0.2

Notas de trabajo del spike, no el informe final (ese es F0.2.4). Se van apuntando aquí a medida que aparecen, para no perderlos entre sesiones.

## F0.2.2 — Primera pasada del corpus (12/12 relatos, dispositivo físico)

| Relato | Elementos | Texto de fecha | Año deducido |
|---|---|---|---|
| es-corto | 7 | sí | — |
| es-cuatroParrafos | 9 | sí | 2019 |
| es-sinFecha | 4 | no | — |
| es-fechaAmbigua | 5 | sí | 1987 |
| en-corto | 4 | sí | — |
| en-cuatroParrafos | 7 | sí | — |
| en-sinFecha | 4 | **sí (sin fecha en el relato)** | — |
| en-fechaAmbigua | 6 | sí | 1992 |
| intimo-muerte | 3 | sí | — |
| intimo-enfermedad | 3 | sí | — |
| guerra-posguerra | 5 | sí | — |
| mixto-esEn | — | — | error, ver abajo |

- `en-sinFecha` extrajo `dateText` no nulo aunque el relato no menciona ninguna fecha — relevante para O4: la validación posterior del contrato 2 de F3 tiene que descartar esto.
- Ninguno de los tres relatos delicados (`intimo-muerte`, `intimo-enfermedad`, `guerra-posguerra`) disparó guardarraíl en esta pasada — una sola repetición, no las tres que pide M6.

## O6 — abierto, contradice lo verificado en F0.2.1

En F0.2.1 se verificó contra el `.swiftinterface` instalado que `LanguageModelSession.GenerationError` es la superficie disponible en el deployment target (26.4), frente a `LanguageModelError` que exige iOS 27.0+. Esa verificación fue de **disponibilidad de símbolos**, no de comportamiento en ejecución.

En la práctica, sobre el dispositivo físico (iPhone, iOS 27), se provocaron cuatro fallos con el relato `mixto-esEn` (uno en la pasada de los doce, tres repitiéndolo aparte) y **ninguno fue capturado por `catch let error as LanguageModelSession.GenerationError`** — los cuatro cayeron en el `catch` genérico:

1. Error envuelto: `FoundationModels.LanguageModelError` Code -1, con causas internas de `SensitiveContentAnalysisML` / `ModelManagerError` (Code 1043).
2. Repetición inmediata del mismo relato: sin error, extracción normal (6 elementos).
3. Repetición siguiente: `"Request has been rate limited. Please try again later..."`.
4. Repetición inmediata tras la anterior: mismo rate limit.

Implicaciones a resolver en F0.2.3/F0.2.4, no decididas aquí:

- **O6 sigue abierto.** La disponibilidad del símbolo en el SDK no garantiza que sea eso lo que se lanza en tiempo de ejecución. Falta comprobar cuántos de los caminos de error de la tabla de F3 se lanzan realmente como `GenerationError` capturable, y cuántos como algo distinto (`LanguageModelError` u otro).
- **El supuesto de `rateLimited`** en la tabla de F3 ("Solo en segundo plano; Hilo genera en primer plano") no se sostuvo aquí: el rate limit salió con la app en primer plano, recién lanzada, tras crear una sesión nueva justo después de que la petición anterior terminara. Puede ser un efecto de la frecuencia de peticiones más que del estado de la app — pendiente de más repeticiones con más espacio entre ellas para aislar la causa.
- Si F3 solo captura `GenerationError`, estos fallos reales se escaparían al camino de "guardar sin analizar" y quedarían sin tratar. Antes de cerrar F0.2 hay que decidir con Rubén si el `catch` de F3 necesita cubrir ambas superficies, o si hay una causa más simple (p. ej. algo específico de este dispositivo o de esta versión beta) que lo explique.
