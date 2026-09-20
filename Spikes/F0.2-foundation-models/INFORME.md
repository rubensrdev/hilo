# Informe — F0.2 Spike de Foundation Models

- **Fase**: F0.2 · Sesión S0
- **Fecha**: 2026-09-20
- **Dispositivos**: iPhone de Rubén (iPhone 16, generación 27, iOS 27) para M1-M3; simulador iPhone 18 Pro (generación 27, iOS 27) para M5-O5, por la desviación explicada más abajo
- **Corpus**: doce relatos inventados, adjuntos al final de este informe (`Corpus.swift`, también citado aquí para que el informe se baste a sí mismo)
- **Notas de trabajo completas**: `HALLAZGOS.md`, en esta misma carpeta — este informe resume y cierra lo que allí queda documentado paso a paso

Cada número lleva su etiqueta: **medido** (leído directamente del dispositivo), **calculado** (aritmética sobre un número medido) o **estimado** (una suposición razonada porque el dato que haría falta no existe todavía — el contrato de redacción es de F6/F7). Mezclar estas tres categorías sería el peor resultado posible de esta fase, así que nunca aparecen sin su etiqueta.

## Resumen ejecutivo

El contrato de extracción (§7.5) funciona con relatos reales en español e inglés: los doce relatos del corpus, más las repeticiones de M6/O2/O3/O4, produjeron siempre la forma esperada (elementos, tipo, papel, texto de fecha, año deducido). El riesgo de §15 — que el modelo se niegue con contenido íntimo legítimo — **no se materializó**: ningún guardarraíl saltó en los tres relatos delicados, ni en F0.2.2 ni en las tres repeticiones de F0.2.3. El desbordamiento sí se provocó y se capturó con un mensaje literal y preciso. La superficie de error vigente en la práctica es `LanguageModelError`, no `GenerationError` (O6), algo que la verificación de símbolos de F0.2.1 no podía predecir. Y la estabilidad de la extracción es más frágil de lo que el spec anticipaba: el mismo relato, en la misma pasada, puede dar 4 elementos una vez y 25 la siguiente, con un año inventado.

## M1 — Ventana de contexto

| Dispositivo | `contextSize` | Etiqueta |
|---|---|---|
| iOS 26 documentado (el que manda) | 4096 | dato de documentación, no medido |
| iPhone físico de Rubén (gen 27) | 4096 | **medido** |
| Simulador iPhone 18 Pro (gen 27) | 8192 | **medido** |

**Hallazgo no anticipado por el spec.** El spec llama a la ventana de la generación 27 "la referencia alta" (`F0.2_Spike_Foundation_Models.md:59`), dando por hecho que superaría el suelo de 4096. En el dispositivo físico de demo no lo hace: coincide exactamente con el suelo documentado. Solo el simulador da 8192. Consecuencia para `ADR-001`: la "referencia alta" que de verdad importa para la demo es 4096, no 8192 — el número del simulador es una curiosidad de la generación 27 virtualizada, no algo que vaya a ver el dispositivo real. Ni siquiera dentro de la misma generación de silicio el número es fijo entre dispositivos, un nivel más abajo de lo que el spec advertía.

## M2 — Coste en tokens de la extracción

**Medido**, simulador (repetido ahí porque `tokenCount(for:)` no genera, no tiene rate limit y no depende del tamaño de ventana — confirmado idéntico a la pasada física original).

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

Instrucciones (71) y esquema (326) son constantes — 397 tokens fijos por generación de extracción, sea cual sea el relato o el idioma. Solo el prompt varía: de 31 (en-corto) a 176 (es-cuatroParrafos).

## M3 — Coste en tokens de una generación de redacción

**Medido**, simulador. Material sintético: N resúmenes de relato truncados a 120 caracteres, no relatos completos — el contrato real de redacción es de F6/F7, fuera de alcance aquí (explícito en el spec).

| Recuerdos (N) | Tokens |
|---|---|
| 4 | 169 |
| 6 | 245 |
| 8 | 317 |
| 10 | 392 |
| 12 | 473 |

**Calculado**: pendiente ≈ 38 tokens por recuerdo añadido ((473−169)/(12−4)). Como el material está truncado a 120 caracteres, esta pendiente es una **cota inferior**: un recuerdo real, sin truncar, costaría más. No sirve para fijar el coste típico de M4 sin corrección — M4 usa en su lugar el coste de relato completo que ya da M2.

## M4 — Parámetros del tope de recuperación

**Calculado**, a partir de M1 y M2, con dos estimaciones señaladas donde el dato no existe todavía (el contrato de redacción de F6/F7 no está escrito).

| Parámetro | Valor | Etiqueta | Origen |
|---|---|---|---|
| Coste típico de un recuerdo, ES | 75 tokens | **calculado** | Media del `prompt` de M2 sobre los 8 relatos en español: (48+176+53+43+69+60+77+75)/8 = 75.1 |
| Coste típico de un recuerdo, EN | 66 tokens | **calculado** | Media del `prompt` de M2 sobre los 4 relatos en inglés: (31+154+38+39)/4 = 65.5, redondeado al alza |
| Peor coste de un recuerdo (ambos idiomas) | 176 tokens | **medido** | `es-cuatroParrafos`, el relato más largo del corpus (M2) |
| Tokens de instrucciones (redacción) | 71 tokens | **estimado** | No existe el prompt real de F6/F7. Se usa como orden de magnitud el coste de las instrucciones de extracción (M2), que son de longitud comparable |
| Espacio reservado para la respuesta | 300 tokens | **estimado** | Ningún relato generó un retrato real en este spike (fuera de alcance). 300 tokens (~200-250 palabras) es un margen razonable para un retrato breve, a revisar en cuanto F6/F7 generen de verdad |

**La función pura** (`ADR-000` §1): `tope(contextSize) = clamp(floor((contextSize − instrucciones − respuesta) / costePeorRecuerdo), suelo, techo)`. Se divide por el **peor** coste, no el típico, porque el tope nunca debe desbordar aunque los N recuerdos recuperados sean justo los más largos — "el suelo importa más que el techo" (`F0.2_Spike_Foundation_Models.md:137`).

| Ventana | Cuenta | Tope resultante | Etiqueta |
|---|---|---|---|
| 4096 (suelo, iOS 26 documentado — y el valor real del físico de demo) | floor((4096−71−300)/176) = floor(3725/176) | **21** | **calculado** |
| 8192 (simulador, gen 27 virtualizada — no representativa del físico) | floor((8192−71−300)/176) = floor(7821/176) | **44** | **calculado** |

**Techo propuesto: 30.** El criterio de aceptación pide "a partir de cuántos recuerdos la respuesta no mejora y solo tarda más" — esta pregunta **no se puede responder con los datos de este spike**: M3 nunca generó un retrato real, solo midió coste de entrada con resúmenes truncados, así que no hay ninguna señal de calidad que se estanque. El 30 propuesto aquí es un **techo de presupuesto de tokens**, no un hallazgo de calidad: por encima de eso, una respuesta tarda más sin que el spike tenga evidencia de que mejore. Debe revisarse en cuanto F6/F7 generen retratos reales y se pueda observar la calidad de verdad, no solo el coste.

**Suelo propuesto: 21** — el resultado de la función para 4096, el mismo valor que ya sale directamente de la fórmula para el dispositivo físico real. El suelo declarado como cláusula de seguridad de la función solo entraría en juego si algún dispositivo futuro tuviera una ventana por debajo de 4096, algo que el mínimo de iOS 26.4 no permite hoy.

## M5 — Latencia (simulador, no físico — ver desviación más abajo)

Relato `es-cuatroParrafos`, 5 repeticiones con y sin precalentamiento. **Medido.**

| Precalentado | Rep. | Primer fragmento | Total |
|---|---|---|---|
| no | 1-5 | 0.83s / 1.07s / 0.96s / 0.97s / 1.00s | 6.24s / 7.55s / 6.03s / 5.83s / 7.23s |
| sí | 1-5 | 0.83s / 0.82s / 0.80s / 0.84s / 0.79s | 13.38s / 4.90s / 34.90s (atípico) / 4.03s / 10.11s |

`prewarm(promptPrefix:)` no reduce el tiempo hasta el primer fragmento de forma apreciable, y el tiempo total con precalentamiento fue más inestable, no menos (pico de 34.9s sin causa visible). Con esta muestra (5 repeticiones), precalentar no demostró ningún beneficio.

## M6 — Estabilidad (simulador, no físico)

`es-cuatroParrafos` ×3: 10/10/10 elementos, año 2019 las tres veces. `en-cuatroParrafos` ×3: 7/7/7 elementos, año 2021 las tres veces. **Medido**, estable dentro de esta pasada — pero una pasada anterior de F0.2.3 en el mismo simulador había dado 10→10→12 para el mismo relato, y F0.2.2 no había deducido ningún año para `en-cuatroParrafos`. La estabilidad varía entre pasadas, no solo dentro de una misma pasada: tres repeticiones seguidas no bastan para garantizar el mismo resultado la semana que viene.

## Desviación del criterio de aceptación (dispositivo)

El spec exige "todas las mediciones hechas en el dispositivo de demo... nunca solo en el simulador" (`F0.2_Spike_Foundation_Models.md:106`). **M1, M2 y M3 se confirmaron en el físico.** M5, M6, O2, O3, O4 y O5 se cerraron solo en el simulador, por decisión explícita de Rubén, tras dos intentos fallidos de relanzar la pasada espaciada en el físico (`RunProject` colgado más de 120s ambas veces, resultado "the app failed to launch after building successfully" pese a `BUILD SUCCEEDED"). El detalle completo, incluida la hipótesis no confirmada de la causa, está en `HALLAZGOS.md`. Esta es una desviación deliberada y documentada, no un olvido.

## O1 — Calidad de la extracción

El contrato (elementos, tipo, papel, texto de fecha, año deducido) se produjo con la forma correcta en las doce historias y en todas las repeticiones. Dos patrones de alucinación aparecen con relatos sin fecha o delicados: `dateText` no nulo sin ninguna fecha en el texto (`en-sinFecha`, `es-sinFecha`), y años deducidos inventados (`en-sinFecha` → 2020, `intimo-muerte` rep. 2 → 2023, `guerra-posguerra` rep. 2 → 1945). Ejemplo: `en-sinFecha` extrajo `dateText` no nulo y `deducedYear=2020` aunque el relato no menciona ninguna fecha.

## O2 — Guardarraíles

Ningún guardarraíl se disparó en los tres relatos delicados, ni en la pasada única de F0.2.2 ni en las tres repeticiones de F0.2.3 (9 intentos en total) — el riesgo de §15 no se materializó con este corpus. Sí apareció una inestabilidad seria sin relación con guardarraíles: `guerra-posguerra` repetición 2 extrajo 25 elementos (frente a 4 en las otras dos) con un año inventado (1945) que el relato no menciona.

## O3 — Idioma de la salida, relato mezclado

`mixto-esEn` mantuvo los nombres y frases en inglés sin traducir ("the best deep dish in town", "this is amazing") en las cuatro repeticiones limpias de F0.2.3, consistente con las instrucciones de §11.2. F0.2.2 había capturado un error real con este mismo relato (resuelto ahora: era `LanguageModelError`, ver O6, no un fallo de idioma).

## O4 — Fechas ausentes y ambiguas

`es-sinFecha` y `en-sinFecha` alucinan `dateText` no nulo pese a no tener fecha en el texto — el campo no queda vacío de forma fiable cuando debería. `es-fechaAmbigua` y `en-fechaAmbigua` sí resolvieron bien la fecha ambigua ("el verano del 87" → 1987, "the summer of '92" → 1992) en las dos pasadas del spike.

## O5 — Errores concretos

El desbordamiento se provocó y capturó limpio: 70 repeticiones de `es-cuatroParrafos` (12.716 tokens) contra un `contextSize` de 8192 dieron `LanguageModelError`: *"Content contains 12716 tokens, which exceeds the maximum allowed context size of 8192."* Pendiente, no bloqueante: confirmar el mismo formato contra el `contextSize` de 4096 del físico. Guardarraíl y rechazo nunca se dispararon con este corpus — quedan sin observar, no descartados.

## O6 — Superficie de error vigente

Resuelto empíricamente. El rate limit real, en el físico, llegó como `FoundationModels.LanguageModelError`, capturado por la rama nueva del `catch`, y **no** como `LanguageModelSession.GenerationError` — pese a que F0.2.1 había verificado que `GenerationError` es la superficie disponible en el deployment target. Disponibilidad de símbolo en el SDK no predice qué se lanza en ejecución. `F3` debe cubrir ambas superficies.

## Caminos de error de F3 — estado tras el spike

| Caso | Estado |
|---|---|
| `guardrailViolation` | No se disparó en 9 intentos con contenido delicado — no confirmado, no descartado |
| Desbordamiento (`LanguageModelError`, no `exceededContextWindowSize`) | **Confirmado**, mensaje literal capturado (O5) |
| `assetsUnavailable` | No observado |
| `unsupportedLanguageOrLocale` | No observado (corpus solo usa ES/EN, ambos soportados) |
| `refusal` | No observado |
| `decodingFailure` | No observado |
| `unsupportedGuide` | No observado (nuestro esquema es válido) |
| `concurrentRequests` | No observado (el arnés nunca lanza dos peticiones a la vez) |
| `rateLimited` | **Confirmado, pero contradice la premisa de la tabla** ("solo en segundo plano"): ocurrió en primer plano, recién lanzada la app, vía `LanguageModelError` |

## Checklist de criterios de aceptación

**Por medición**
- [x] M1 a M6 tomadas y anotadas, con las tres repeticiones visibles donde aplica
- [x] Parámetros del tope con la cuenta completa a la vista, y el tope para 4096 y para la referencia de gen 27
- [x] Techo propuesto (30) — con la salvedad explícita de que no es un hallazgo de calidad, es un presupuesto de tokens
- [x] Cada número marcado medido/calculado/estimado
- [x] O1 a O5 descritas en una o dos frases con ejemplo

**En dispositivo**
- [~] M1-M3 en el físico. M5, M6, O2-O5 solo en simulador — **desviación deliberada, documentada arriba**
- [~] Apple Intelligence activo, modelo descargado y ES/EN disponibles: confirmado de forma transitiva (F0.2.2/F0.2.3 generaron con éxito en ambos idiomas en el físico). El dictado del sistema no se ejerció en ningún momento del spike — el checklist de F0.2.1 no dejó registro en fichero. Pendiente de confirmar aparte, fuera de esta tarea.

**De cierre**
- [x] `ADR-001` escrito (documento separado, `docs/decisions/ADR-001-...md`)
- [x] El código del spike vive fuera del target de la app (`Spikes/F0.2-foundation-models/`, proyecto Xcode propio)
- [x] Ningún relato real de nadie entró en el corpus — los doce son inventados

## Apéndice — Corpus completo

Los doce relatos, tal como se usaron (código fuente: `HiloSpike/HiloSpike/Corpus.swift`):

**es-corto** — El sábado pasado fui con mi amigo Pablo al Retiro. Nos sentamos junto al estanque y comimos unos bocadillos que había preparado mi madre. Pablo llevaba su cámara vieja y sacó varias fotos de los patos.

**es-cuatroParrafos** — El 12 de julio de 2019 mi hermana Elena y yo cogimos el tren de madrugada hacia San Sebastián. Casi no dormimos en todo el trayecto, pero llegamos con ganas de todo. Nos alojamos en un hostal pequeño cerca de la parte vieja, y a media tarde se unió a nosotros mi tío Andrés, que llevaba viviendo allí desde hacía años y conocía la ciudad de memoria. Al día siguiente bajamos a la playa de la Concha. Apareció mi prima Nuria con su perro Toby, y nos pasamos la mañana entera tirándole un palo al agua mientras Elena leía bajo la sombrilla. Por la noche cenamos los cuatro en Casa Alcalde. Pedimos de todo, y recuerdo que Andrés brindó por que volviéramos a hacer el viaje juntos al año siguiente.

**es-sinFecha** — Cada domingo por la mañana, mi abuela Carmen prepara torrijas en su cocina de siempre. Me siento en el taburete azul mientras el aroma a canela llena toda la casa. Ella nunca sigue una receta escrita: lo hace todo de memoria.

**es-fechaAmbigua** — El verano del 87 mi padre compró la casa de la sierra. Recuerdo el olor a pino y el ruido de las cigarras las primeras noches que dormimos allí con mi tío Rafael.

**en-corto** — Last Friday I met my neighbor Sam at the corner bakery on Elm Street. We shared a loaf of sourdough bread and talked about his trip to Portugal.

**en-cuatroParrafos** — On March 3rd, 2021 my sister Laura and I drove down to Big Sur before sunrise. Neither of us had slept much, but we were too excited to care. We checked into a small cabin near the coast, and by afternoon our uncle Mark showed up, since he'd been living nearby for years and knew every trail around there. The next morning we hiked out to McWay Falls. My cousin Grace turned up with her dog Biscuit, and we spent the whole morning throwing a stick into the stream while Laura read on a rock nearby. That night the four of us had dinner at The Fernwood Tavern. Mark raised a toast to doing the trip again the following year, and we all agreed on the spot.

**en-sinFecha** — Every Sunday morning, my grandmother Ruth bakes cinnamon rolls in her old kitchen. I sit on the green stool while the smell fills the whole house. She never uses a written recipe.

**en-fechaAmbigua** — The summer of '92 my father bought the cabin by the lake. I remember the smell of pine and the sound of crickets the first nights we slept there with my uncle Dave.

**intimo-muerte** — Mi abuela Pilar murió una mañana de noviembre, tranquila, en su propia cama. Estuve con ella las últimas horas, cogiéndole la mano mientras mi madre preparaba café en la cocina de al lado. No fue un momento triste del todo: hablamos de cuando era joven y bailaba en las verbenas del pueblo.

**intimo-enfermedad** — Mi padre estuvo enfermo casi tres años antes de que pudiéramos por fin volver a llevarlo de paseo al parque de siempre. Recuerdo las tardes en el hospital, el sillón verde junto a la ventana, y cómo poco a poco fue recuperando las fuerzas para caminar solo otra vez.

**guerra-posguerra** — Mi abuelo Ezequiel contaba que, después de la guerra, pasaron dos inviernos enteros con muy poco pan en casa. Él y su hermano Tomás iban a buscar leña al monte de madrugada para no perder las pocas horas de escuela que quedaban. Nunca hablaba de aquello con amargura, solo decía que aprendió a no desperdiciar nada.

**mixto-esEn** — Fui a visitar a mi prima Sofía a Chicago el pasado octubre. Su marido, John, nos llevó a un sitio que él llamaba "the best deep dish in town", cerca de Wrigley Field. Sofía no paraba de decir "this is amazing" mientras probábamos la pizza, y al final brindamos con un "cheers" improvisado.
