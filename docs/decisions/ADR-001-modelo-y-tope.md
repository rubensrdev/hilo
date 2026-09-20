# ADR-001 — Contrato del modelo y tope de recuperación

- **Fase**: F0.2
- **Estado**: Accepted
- **Opened**: 2026-09-20
- **Closed**: 2026-09-20
- **Reason**: Parámetros del tope fijados (71 / 300 / 176 / 21 / 30); contrato de extracción validado con dos matices de validación posterior para F3; superficie de error decidida — ambas, `GenerationError` y `LanguageModelError`

---

## Contexto

`ADR-000` (D5) fijó el mínimo en iOS 26.4 precisamente para que el tope de recuperación se derivara de `contextSize` con una función pura en vez de ser un número fijo escrito a mano. Lo que faltaba eran los parámetros de esa función: cuánto ocupa un recuerdo típico y el peor caso, cuánto hay que reservar para instrucciones y respuesta, y si el contrato de extracción (§7.5) y la superficie de error (O6, dudosa desde la documentación) se sostienen con relatos reales. F0.2 midió eso. El detalle completo — cada medición, cada repetición, los hallazgos que no encajaban con lo esperado — está en `Spikes/F0.2-foundation-models/INFORME.md` y en `HALLAZGOS.md` de la misma carpeta; este ADR solo fija lo que de ahí se decide y queda caro de revertir.

---

## Decisión

### 1. Parámetros del tope de recuperación

| Parámetro | Valor | Origen |
|---|---|---|
| Coste típico de un recuerdo, español | 75 tokens | Media medida sobre 8 relatos ES (M2) |
| Coste típico de un recuerdo, inglés | 66 tokens | Media medida sobre 4 relatos EN (M2) |
| Peor coste de un recuerdo (divisor de la función) | 176 tokens | Máximo medido en el corpus (M2, `es-cuatroParrafos`) |
| Tokens de instrucciones de redacción | 71 tokens | Estimado por analogía con las instrucciones de extracción — el contrato real de F6/F7 no existe todavía |
| Espacio reservado para la respuesta | 300 tokens | Estimado — ningún retrato real se generó en el spike (fuera de su alcance) |
| Suelo del tope | **21** | Calculado: `floor((4096 − 71 − 300) / 176)` |
| Techo del tope | **30** | Presupuesto de tokens, no hallazgo de calidad — ver más abajo |

**La función**: `tope(contextSize) = clamp(floor((contextSize − 71 − 300) / 176), 21, 30)`.

Se divide por el **peor** coste de un recuerdo (176), no por el típico, para que el tope nunca desborde aunque los recuerdos recuperados sean justo los más largos del material real del usuario. Con el suelo de iOS 26.4 (4096), la función da 21 — el mismo valor tanto por la cláusula de seguridad como por el cálculo directo, porque el iPhone físico de demo mide exactamente 4096, no más. El techo (30) es una decisión de ingeniería, no un hallazgo: el spike no generó retratos reales, así que no hay señal de que la calidad de la respuesta se estanque a partir de cierto N — solo el coste en tokens crece. **Este techo se revisa en cuanto F6/F7 generen retratos de verdad** y se pueda observar si la calidad mejora o no más allá de cierto punto.

**Ningún literal de este ADR se escribe en un test.** Los tests inyectan `contextSize` y verifican la función contra 4096, contra los valores medidos de generación 27, y contra los casos límite (`ADR-000` §1).

### 2. Contrato de extracción — validado, con dos matices

El contrato (elementos, tipo, papel, texto de fecha, año deducido) produjo la forma correcta en los doce relatos del corpus y en todas sus repeticiones, en español e inglés, incluido contenido íntimo (muerte, enfermedad, guerra) y mezclado (ES/EN). **No hace falta cambiar el contrato de la F3.** Dos comportamientos del modelo, no del contrato, quedan documentados para que la validación posterior (fuera de este spike) los cubra:

- **`dateText` no nulo sin fecha en el texto**: ocurrió en español e inglés (`es-sinFecha`, `en-sinFecha`). La validación del contrato 2 de F3 tiene que descartar un `dateText` que no aparece literalmente en el relato, no confiar en que el modelo lo deje vacío.
- **`deducedYear` alucinado**: ocurrió sin patrón claro (`en-sinFecha` → 2020, dos relatos delicados en repeticiones sueltas). El año deducido nunca se muestra como fecha al usuario (regla de producto ya existente), pero si se usa para ordenar u agrupar, un año inventado agrupa mal. No se propone aquí ninguna mitigación nueva — queda anotado para cuando F3 lo implemente.

### 3. Superficie de error — `LanguageModelError`, no solo `GenerationError` (O6)

F0.2.1 verificó, contra el `.swiftinterface` instalado, que `LanguageModelSession.GenerationError` es la superficie disponible en el deployment target (26.4). Esa verificación era de disponibilidad de símbolo, no de comportamiento en ejecución. En la práctica, en el físico, el rate limit real llegó como `FoundationModels.LanguageModelError`, y un `catch let error as LanguageModelSession.GenerationError` no lo habría capturado nunca — habría caído en el `catch` genérico, sin distintivo, y el "guardar sin analizar y decir por qué" (`ADR-000` §4) no habría sabido decir por qué.

**Decisión: el `catch` de F3 cubre ambas superficies**, con una rama explícita para cada una, tal como quedó implementado en el arnés desechable del spike (`ExtractionHarness.swift`, F0.2.3). No es una preferencia por una sobre otra — es que ninguna de las dos basta sola.

### 4. Caminos de error — confirmados y pendientes

| Caso | Estado tras el spike |
|---|---|
| Desbordamiento | **Confirmado**: `LanguageModelError` con mensaje literal (*"Content contains N tokens, which exceeds the maximum allowed context size of M"*), no `GenerationError.exceededContextWindowSize` |
| `rateLimited` | **Confirmado, y la premisa de la tabla original no se sostiene**: ocurrió en primer plano, recién lanzada la app, tras un único uso normal del modelo — no "solo en segundo plano" |
| `guardrailViolation` | No se disparó en 9 intentos con contenido delicado real. No confirmado ni descartado — F3 lo cubre igualmente, por precaución, tal como pedía §15 |
| `assetsUnavailable`, `unsupportedLanguageOrLocale`, `refusal`, `decodingFailure`, `unsupportedGuide`, `concurrentRequests` | No observados en el spike. F3 los cubre según la tabla original de la spec, sin cambios |

Todos, confirmados o no, siguen acabando en "guardar sin analizar y decir por qué" (`ADR-000` §4) — este ADR no cambia esa regla, solo la superficie de la que hay que capturarlos.

---

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| **Tope fijo, un solo número para todos los dispositivos** | Es justo lo que D5 de `ADR-000` decidió evitar: desperdicia ventana en un dispositivo con más margen, o arriesga desbordar en el mínimo. El spike confirma que hace falta la función, no solo lo plantea: dos dispositivos de la misma generación ya dan `contextSize` distintos |
| **Dividir por el coste típico en vez del peor caso** | Da un tope más generoso, pero puede desbordar si los recuerdos recuperados resultan ser justo los más largos del usuario real. "El suelo importa más que el techo" (spec F0.2, riesgos) |
| **Esperar a F6/F7 para fijar el techo con datos de calidad reales** | Se consideró, pero dejaría el tope sin límite superior mientras tanto, contradiciendo el propio `ADR-000`. Se fija un techo conservador ahora (presupuesto de tokens) y se revisa explícitamente cuando existan datos de calidad |
| **Capturar solo `GenerationError`, ignorando lo visto con `LanguageModelError`** | Habría dejado el rate limit real, confirmado en el físico, sin capturar — exactamente el riesgo que O6 pedía descartar antes de escribir F3 |

---

## Consecuencias

- **F3** implementa la función del tope tal como está aquí, inyectando `contextSize` en los tests, nunca leyéndolo dentro de un test. El `catch` cubre `GenerationError` y `LanguageModelError` con ramas explícitas.
- **F3** confirma, antes de reutilizar el patrón de logging del spike (`String(describing: error)` con `privacy: .public`), que la descripción de ningún caso de error incluye un fragmento del texto del relato — el spike no lo comprobó exhaustivamente, solo observó que los mensajes capturados hasta ahora citan cifras y categorías, nunca texto de usuario.
- **F3** añade validación posterior al contrato de extracción para descartar `dateText` sin fecha real en el texto — no cambia el contrato, añade una comprobación después de recibirlo.
- **F6/F7**, cuando generen retratos y respuestas reales, revisan el techo de 30: si la calidad no mejora bastante antes de llegar ahí, se puede bajar; si mejora hasta el límite, se documenta por qué se mantiene.
- **El techo y el suelo son constantes con nombre, en un solo sitio** (spec F0.2, riesgos abiertos) — cambiarlos no debe tocar ningún test salvo los que verifican la función misma.
- Confirmar el mensaje de desbordamiento contra el `contextSize` de 4096 del físico (no solo el de 8192 del simulador) queda pendiente, no bloqueante — se retoma la próxima vez que haya sesión de dispositivo físico disponible.

---

## Coste de reversión

| Decisión | Coste |
|---|---|
| Parámetros del tope (71 / 300 / 176 / 21 / 30) | **Bajo mientras F3 no exista.** Son constantes con nombre; cambiar un número no toca la forma de la función ni sus tests, que inyectan `contextSize` |
| Cubrir ambas superficies de error en el `catch` | **Bajo.** Añadir o quitar una rama de `catch` no cambia el contrato hacia el resto de la app: los dos caminos ya acaban en el mismo estado de producto |
| Contrato de extracción sin cambios | **N/A** — no se tocó, se validó tal cual |
