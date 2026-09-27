# F6 — Recuperación y preguntar

- **Fase**: F6 · Sesión S4 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §9.5, §9.7, §10.2 (S6), §13 (reglas 13, 14, 15, 16, 22)
- **Capacidades**: 10, 11
- **Decisiones**: DEC-30, DEC-33 · consume `ADR-001` · produce `ADR-003`
- **Depende de**: F1, F2, F3, F5 y **el resultado de la F0.2**

## Objetivo

Preguntar a la propia memoria y recibir una respuesta con fuentes exactas, o un «no lo sé» que llega rápido y no se disculpa. Es, con la revisión, la pantalla más importante del producto, y cierra los criterios 5, 6 y 7.

## Alcance

**Dentro**
- La cascada de tres pasos.
- Tope derivado, orden y aviso de lo que quedó fuera.
- Redacción de la respuesta, en streaming.
- Fuentes tocables.
- Reconocimiento honesto como texto de interfaz.
- S6 con sus seis estados y las sugerencias construidas con elementos reales.

**Fuera, explícitamente**
- Retrato (F7), aunque reutilice esta misma recuperación.
- Historial de preguntas: no existe (regla 22).
- Segundo intento tras el paso 3: no lo hay.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.5 paso 1 · reconocer nombres guardados | Contrato 1 |
| §9.5 paso 2 · interpretar con el modelo | Contrato 2 |
| §9.5 paso 3 · no generar sin material | Contrato 3 |
| regla 14 · tope, orden | Contrato 4 |
| regla 15 · las fuentes son lo entregado | Contrato 5 |
| regla 16 · sin material no hay generación | Contrato 3 |
| regla 22 · las preguntas no se conservan | Contrato 6 |

## Contratos

### 1. Paso 1 — reconocimiento directo

- La pregunta se normaliza igual que un nombre canónico y se buscan en ella los nombres **completos** de elementos y alias, como secuencia de palabras.
- Los papeles del usuario también cuentan.
- Es puro, síncrono y no depende del modelo.
- «¿Qué pasó en la casa del pueblo?» encuentra *la casa del pueblo*; «¿de quién es esta casa?» no encuentra nada, y hace bien.

### 2. Paso 2 — interpretación

- Solo se ejecuta **si el paso 1 no encontró nada**.
- Devuelve una estructura cerrada: nombres, tipo opcional e intervalo de años opcional. Nunca texto libre.
- Con esa estructura se busca **exactamente igual que en el paso 1**, sin coincidencia difusa.
- El intervalo se cruza con el año deducido.

### 3. Paso 3 — reconocimiento honesto

- Si sigue sin haber material, **no se genera respuesta**.
- El texto es de la interfaz, localizado y siempre idéntico: no lo redacta el modelo, no se disculpa y no propone alternativas forzadas. Ofrece una salida útil: contar ese recuerdo ahora.
- No hay segundo intento.

### 4. Tope y orden

- El tope **se deriva de la ventana del dispositivo** con la función pura de `ADR-001`, con suelo y techo (DEC-33). Ningún literal, ni en código ni en tests: los tests inyectan la ventana.
- Orden: **año descendente** y, a igualdad, **guardado descendente**.
- Si quedó material fuera, se dice **cuántos**.

### 5. Fuentes

- Las fuentes mostradas son **exactamente los recuerdos entregados al modelo**, nunca los que el modelo diga haber usado ni todos los encontrados.
- Son tocables y llevan al recuerdo.
- Ninguna fuente puede conducir a un recuerdo que ya no existe (criterio 7).

### 6. S6 · Preguntar

- **No es un chat**: sin burbujas, sin avatar, sin historial entre sesiones.
- Campo de pregunta, sugerencias construidas con los elementos reales del usuario, respuesta progresiva en el idioma de la interfaz, fuentes debajo y aviso de lo que quedó fuera.
- Estados: inicial con sugerencias, buscando, respondiendo, respondida con fuentes, sin resultados —estado de primera clase— y memoria vacía.
- Una sesión por generación, sin historial.

## Comportamiento

- **Dado** que la pregunta nombra un elemento existente, **cuando** se pregunta, **entonces** el paso 2 no se ejecuta.
- **Dado** que el paso 1 no encuentra nada y el paso 2 devuelve nombres que no existen, **entonces** se llega al paso 3 sin generar respuesta.
- **Dado** que la búsqueda encuentra más recuerdos que el tope, **cuando** se responde, **entonces** se entregan los del tope en su orden y se dice cuántos quedaron fuera.
- **Dado** que no hay ningún recuerdo relevante, **cuando** se pregunta, **entonces** el reconocimiento honesto aparece de inmediato, sin llamar al modelo.
- **Dado** que una fuente se borra mientras se lee la respuesta, **cuando** se vuelve, **entonces** ninguna fuente lleva a un recuerdo inexistente.

## Criterios de aceptación

**Por test**
- [ ] El paso 1 reconoce nombres completos y alias, y rechaza coincidencias parciales dentro de una palabra.
- [ ] El paso 2 no se ejecuta si el paso 1 encontró material.
- [ ] El tope se calcula con la función de `ADR-001` para varias ventanas inyectadas, respetando suelo y techo.
- [ ] El orden es año descendente y luego guardado descendente, con los recuerdos sin año al final.
- [ ] Las fuentes devueltas son exactamente las entregadas, y el conteo de lo que quedó fuera es correcto.
- [ ] Sin material no se llama al modelo.
- [ ] Los textos anunciables del aviso y del reconocimiento honesto, en los dos idiomas.

**En dispositivo**
- [ ] Una pregunta en lenguaje natural devuelve respuesta con fuentes correctas (criterio 5).
- [ ] Una pregunta sin material devuelve la respuesta honesta sin generar texto (criterio 6).
- [ ] Ninguna fuente lleva a un recuerdo que ya no existe (criterio 7).
- [ ] AX5, VoiceOver y modo avión.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F6.1** | Pasos 1 y 3, orden y tope, como lógica pura con tests |
| **F6.2** | Paso 2: contrato de interpretación y su doble |
| **F6.3** | Redacción en streaming con material acotado |
| **F6.4** | S6 con sus seis estados |
| **F6.5** | Fuentes, aviso de lo que quedó fuera y accesibilidad |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`, `auditor-concurrencia`.

## Huecos abiertos, a resolver al abrir la fase

Los cuatro primeros son huecos de `05` sin ratificar, y bloquean la fase:

- **B3 · semántica del paso 1 con varios nombres y papeles.** ¿AND u OR entre elementos? ¿Un papel solo recupera algo? La propuesta de `05` es AND cuando hay varios y no está vacío, si no OR, y el papel filtra dentro pero por sí solo no recupera.
- **B4 · un alias que coincide con dos elementos distintos.** La propuesta es recuperar la unión de ambos y no preguntar.
- **B5 · dónde van los recuerdos sin año en el orden**, y **B6 · si un recuerdo sin año satisface un intervalo**. Las propuestas son: al final, y no.
- **B7 · paso 2 con estructura vacía o nombres desconocidos.**
- **B15 · criterio de las sugerencias de S6.** La propuesta es plantillas por tipo con los elementos de más recuerdos, máximo tres.
- **C2 · los parámetros del tope**, que llegan de `ADR-001`.
- **Texto exacto del reconocimiento honesto y del aviso de lo que quedó fuera.** Son de producto: los aprueba Rubén, y §9.7 pide que no sea un texto gris pequeño.
