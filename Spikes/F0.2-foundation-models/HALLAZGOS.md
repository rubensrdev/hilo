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

## F0.2.3 — M1, M2, M3 confirmados en dispositivo físico; M5-O5 bloqueados por rate limit

Arnés ampliado: `catch` con rama explícita para `LanguageModelError`, `ExtractionHarness.runRepeated` con `delaySeconds`, `MeasurementHarness` nuevo para M1/M2/M3/M5, `attemptOverflow` para O5. Primera pasada completa en el simulador (iPhone 18 Pro) sin un solo error, para verificar que el arnés corre de principio a fin. Pasada que cuenta, en el iPhone físico de Rubén:

### M1 — medido, distinto por dispositivo

| Dispositivo | `contextSize` |
|---|---|
| Simulador iPhone 18 Pro (gen 27) | 8192 |
| iPhone físico de Rubén (gen 27) | **4096** |

El simulador y el físico, ambos generación 27, dan un `contextSize` distinto. Confirma lo que el spec ya advertía sobre el tope adaptativo entre dispositivos, un nivel más abajo de lo esperado: ni dentro de la misma generación el número es fijo. El valor que manda para el suelo del tope sigue siendo el documentado de iOS 26 (4096), no ninguno de estos dos — ambos son solo referencia.

### M2, M3 — medidos, idénticos entre simulador y físico

Los tokens de instrucciones/esquema/prompt (M2) y del material de redacción (M3) salieron exactamente iguales en ambos dispositivos, como cabía esperar: dependen del tokenizador, no del tamaño de la ventana. La tabla completa no se transcribió en la pasada física original (solo se anotó la conclusión cualitativa); como `tokenCount(for:)` no genera, no tiene rate limit ni necesita espaciado, se repitió en el simulador para tener los números exactos, sin volver a gastar tiempo de físico.

**M2 — coste en tokens de la extracción, por relato**

| Relato | Instrucciones | Esquema | Prompt | Total |
|---|---|---|---|---|
| es-corto | 71 | 326 | 48 | 445 |
| es-cuatroParrafos | 71 | 326 | 176 | 573 |
| es-sinFecha | 71 | 326 | 53 | 450 |
| es-fechaAmbigua | 71 | 326 | 43 | 440 |
| en-corto | 71 | 326 | 31 | 428 |
| en-cuatroParrafos | 71 | 326 | 154 | 551 |
| en-sinFecha | 71 | 326 | 38 | 435 |
| en-fechaAmbigua | 71 | 326 | 39 | 436 |
| intimo-muerte | 71 | 326 | 69 | 466 |
| intimo-enfermedad | 71 | 326 | 60 | 457 |
| guerra-posguerra | 71 | 326 | 77 | 474 |
| mixto-esEn | 71 | 326 | 75 | 472 |

Instrucciones (71) y esquema (326) son constantes: no varían por relato ni por idioma, solo el prompt. El relato más caro es `es-cuatroParrafos` (573 total, el más largo del corpus); el más barato, `en-corto` (428).

**M3 — coste en tokens de un prompt de redacción, por N de recuerdos**

| Recuerdos (N) | Tokens |
|---|---|
| 4 | 169 |
| 6 | 245 |
| 8 | 317 |
| 10 | 392 |
| 12 | 473 |

Crecimiento aproximadamente lineal: ~38 tokens por recuerdo añadido (169→245 son 6 recuerdos más por 76 tokens, ≈12.7/recuerdo con resúmenes truncados a 120 caracteres; la pendiente real con recuerdos completos sería mayor — este número es una cota inferior, no el coste típico de un recuerdo real).

### El hallazgo que bloqueó el resto de la pasada física

En el físico, tras la **primera** llamada de M5 (completó con normalidad, 9s), la segunda llamada — 4 segundos después, con la app en primer plano, recién terminada la anterior — devolvió rate limit. A partir de ahí, **todas** las llamadas de generación restantes de esa sesión de app (9 repeticiones más de M5, las 18 de M6+O2, las 5 de O3/O4, las 3 de la repetición espaciada con `delaySeconds: 10`, y el intento de desbordamiento de O5) devolvieron el mismo rate limit, sin excepción, durante más de 40 segundos seguidos — incluidos los dos huecos de 10s insertados a propósito para esta comprobación.

Esto contradice lo observado en el simulador en la misma sesión (34 llamadas de generación sin un solo rate limit) y también lo insinuado en F0.2.2 sobre que 10s de espaciado bastaban para evitarlo: en el físico, ni 20s acumulados fueron suficientes para que se recuperara.

**Confirmado, no solo sospechado:**
- **O6 tiene ya una respuesta empírica clara.** El rate limit en el físico llegó como `FoundationModels.LanguageModelError`, capturado correctamente por la rama nueva del `catch`. No hizo falta un caso ambiguo: en esta pasada, la superficie vigente en la práctica fue `LanguageModelError`, no `GenerationError`.
- **El supuesto de F3 de que `rateLimited` "solo pasa en segundo plano" no se sostiene en este dispositivo.** Ocurrió con la app en primer plano, recién lanzada, tras un único uso normal del modelo.
- Coste para F0.2.3: no hay todavía datos limpios de M6, O2, O3, O4 ni O5 tomados en el físico — el rate limit los tapó a todos. Los datos de esas medidas que sí existen, de la pasada del simulador, no cuentan para las tablas del informe: el criterio de aceptación exige dispositivo físico.

**Pendiente de decidir con Rubén antes de seguir gastando tiempo de dispositivo:** la próxima pasada en el físico necesita espaciar *todas* las llamadas de generación, no solo la de la repetición de `mixto-esEn`, con un hueco bastante mayor que los 10-20s que ya se comprobó que no bastan — tantear cuánto es en sí mismo parte de responder O5/O6. Con las ~34 llamadas de generación del arnés actual, espaciarlas todas a 25-30s serían 15-20 minutos de sesión en el dispositivo.

### Desviación del criterio de aceptación — decidida con Rubén

Con el arnés ya espaciado a 28s entre cada llamada, se reintentó dos veces en el físico: la primera terminó con `RunProject` colgado más de 120s sin llegar a lanzar la app (tarea en segundo plano `khh8mjssi`, resultado final "the app failed to launch after building successfully"); la segunda, tras parar el proceso anterior que había quedado vivo en el dispositivo desde el primer intento, volvió a fallar igual (tarea `krw588ls4`, mismo resultado). El log de compilación de ambos intentos termina en `BUILD SUCCEEDED` sin más detalle: el fallo está en la instalación/lanzamiento en el dispositivo, no en el código del spike.

Rubén decidió explícitamente no seguir insistiendo con el físico y cerrar M5, M6, O2, O3, O4 y O5 con los datos del simulador, que sí corrió limpio de principio a fin. **Esto es una desviación deliberada del criterio de aceptación del spec** ("todas las mediciones hechas en el dispositivo de demo... nunca solo en el simulador", `F0.2_Spike_Foundation_Models.md:106`): las tablas siguientes están etiquetadas explícitamente como simulador, no como físico, para que F0.2.4 no las confunda al escribir el informe o `ADR-001`. M1, M2 y M3 sí quedan confirmados en el físico (arriba). Esta desviación tiene que quedar visible al cerrar F0.2 completa.

### M5 — latencia (simulador, no físico), 5 repeticiones con y sin precalentamiento

Relato `es-cuatroParrafos`.

| Precalentado | Repetición | Primer fragmento | Total |
|---|---|---|---|
| no | 1 | 0.83s | 6.24s |
| no | 2 | 1.07s | 7.55s |
| no | 3 | 0.96s | 6.03s |
| no | 4 | 0.97s | 5.83s |
| no | 5 | 1.00s | 7.23s |
| sí | 1 | 0.83s | 13.38s |
| sí | 2 | 0.82s | 4.90s |
| sí | 3 | 0.80s | 34.90s (atípico) |
| sí | 4 | 0.84s | 4.03s |
| sí | 5 | 0.79s | 10.11s |

`prewarm(promptPrefix:)` no reduce el tiempo hasta el primer fragmento de forma apreciable (~0.8-1.0s con y sin precalentar) y el tiempo total con precalentamiento es más inestable que sin él, con un pico de 34.9s en la repetición 3 sin causa visible en el log. Con esta única pasada no se puede concluir que precalentar ayude — más bien lo contrario, aunque la muestra es pequeña (5 repeticiones) para afirmarlo con fuerza.

### M6 — estabilidad (simulador, no físico), 3 repeticiones por idioma

| Relato | Elementos | Fecha | Año deducido |
|---|---|---|---|
| es-cuatroParrafos rep 1 | 10 | sí | 2019 |
| es-cuatroParrafos rep 2 | 10 | sí | 2019 |
| es-cuatroParrafos rep 3 | 10 | sí | 2019 |
| en-cuatroParrafos rep 1 | 7 | sí | 2021 |
| en-cuatroParrafos rep 2 | 7 | sí | 2021 |
| en-cuatroParrafos rep 3 | 7 | sí | 2021 |

Estables en esta pasada, a diferencia de lo observado en la primera pasada de F0.2.3 en simulador (donde `es-cuatroParrafos` varió 10→10→12). `en-cuatroParrafos` deduce año 2021 en las tres repeticiones, mientras que en F0.2.2 no había deducido ningún año para ese mismo relato — instabilidad entre pasadas, no solo entre repeticiones de la misma pasada.

### O2 — guardarraíles (simulador, no físico), 3 repeticiones por relato delicado

| Relato | Elementos | Fecha | Año deducido |
|---|---|---|---|
| intimo-muerte rep 1 | 3 | sí | sin año |
| intimo-muerte rep 2 | 4 | sí | **2023 (alucinado)** |
| intimo-muerte rep 3 | 3 | sí | sin año |
| intimo-enfermedad rep 1 | 3 | no | sin año |
| intimo-enfermedad rep 2 | 3 | no | sin año |
| intimo-enfermedad rep 3 | 3 | sí | sin año |
| guerra-posguerra rep 1 | 4 | sí | sin año |
| guerra-posguerra rep 2 | **25** | sí | **1945 (alucinado)** |
| guerra-posguerra rep 3 | 4 | sí | sin año |

Ningún guardarraíl saltó en esta pasada (cero errores en los tres relatos delicados) — coincide con F0.2.2. Dos hallazgos nuevos relevantes para O1/O4:
- **`guerra-posguerra` repetición 2 disparó una extracción anómala**: de 4 elementos (lo normal en las otras dos repeticiones) a 25, con un año (1945) que el relato no menciona explícitamente. No es un guardarraíl ni un error — es una extracción "válida" para el tipo, pero claramente fuera de lo esperado.
- `intimo-enfermedad` varía en el booleano `fecha` (no/no/sí) entre repeticiones idénticas, sin que cambie el número de elementos.

### O3/O4 — relato mezclado y fechas ausentes/ambiguas (simulador, no físico)

| Relato | Elementos | Fecha | Año deducido |
|---|---|---|---|
| mixto-esEn (pasada única) | 7 | sí | 2023 |
| es-sinFecha | 4 | **sí (sin fecha en el relato)** | sin año |
| en-sinFecha | 2 | **sí (sin fecha en el relato)** | **2020 (alucinado)** |
| es-fechaAmbigua | 7 | sí | 1987 |
| en-fechaAmbigua | 8 | sí | 1992 |
| mixto-esEn repetición espaciada 1/3 | 7 | sí | 2023 |
| mixto-esEn repetición espaciada 2/3 | — (dato no capturado, sesión expiró antes de leerlo) | — | — |
| mixto-esEn repetición espaciada 3/3 | 6 | sí | 2023 |

`es-fechaAmbigua` y `en-fechaAmbigua` coinciden esta vez con los años de F0.2.2 (1987 y 1992), resolviendo la inconsistencia anotada en la primera pasada de F0.2.3. `es-sinFecha` extrajo `dateText` no nulo por primera vez (en F0.2.2 había dado "no") — el mismo patrón de alucinación que ya se veía solo en `en-sinFecha` ahora aparece también en español, y en `en-sinFecha` esta vez fue más allá: alucinó un año concreto (2020), no solo el texto de fecha. `mixto-esEn` no dio ningún error en ninguna de sus cuatro repeticiones en esta pasada — contrasta con el error real que sí dio en F0.2.2.

### O5 — desbordamiento deliberado (simulador, no físico): resuelto con error literal limpio

70 repeticiones de `es-cuatroParrafos` (176 tokens cada una) fabricaron un prompt de 12.716 tokens, por encima del `contextSize` de 8192 del simulador. El resultado fue un `LanguageModelError` con mensaje literal y preciso:

> `Content contains 12716 tokens, which exceeds the maximum allowed context size of 8192.`

Es la primera vez que el spike consigue provocar y capturar un desbordamiento real: el error cita la cifra exacta de tokens del contenido y el límite contra el que choca, información directamente utilizable para el tope de retrieval que define `ADR-001`. Queda pendiente confirmar en el físico (cuando se retome el dispositivo, fuera de esta tarea) si el mensaje tiene la misma forma contra su `contextSize` de 4096 — no bloquea el cierre de F0.2.3 porque el formato del error ya está verificado, solo faltaría el número exacto en ese dispositivo.

### Intento fallido de relanzar en el físico tras el checkpoint

Antes de aceptar la desviación anterior, se intentó relanzar la pasada espaciada en el iPhone físico dos veces más (ver arriba): ambas veces `RunProject` se colgó más de 120s y terminó devolviendo "the app failed to launch after building successfully", con el build en sí correcto. La app había quedado instalada en el dispositivo (confirmado visualmente por Rubén) pero no arrancaba desde la MCP. No se investigó más a fondo (posible causa: el proceso de la primera pasada sin espaciar, con PID 26865, seguía registrado como vivo en Xcode y bloqueaba el nuevo lanzamiento aunque `StopProject` lo diera por parado) — queda fuera de esta tarea atómica.
