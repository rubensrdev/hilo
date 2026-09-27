# F7 — Retrato

- **Fase**: F7 · Sesión S4 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §9.6, §10.2 (S5), §13 (reglas 13, 14, 15, 18, 19)
- **Capacidades**: 8
- **Decisiones**: consume `ADR-001` y `ADR-003`
- **Depende de**: F5, F6

## Objetivo

Un párrafo breve sobre quién es alguien **según los propios recuerdos**, con sus fuentes, que desaparece en cuanto deja de ser cierto. Cierra los criterios 4 y 7.

## Alcance

**Dentro**
- Generación del retrato reutilizando la recuperación de F6.
- Umbral de tres recuerdos.
- Vigencia: cuándo deja de valer y cuándo se rehace.
- Los estados del retrato dentro de S5.

**Fuera, explícitamente**
- Cualquier camino de recuperación propio. Si hace falta uno, la fase está mal diseñada.
- Tejido (F9).
- Regenerar en cada visita: se rehace al abrir el detalle, no siempre.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.6 · resume y nunca interpreta | Contrato 2 |
| regla 18 · no juzga ni caracteriza | Contrato 2 |
| regla 19 · pierde vigencia y no se muestra | Contrato 3 |
| reglas 14 y 15 · mismo tope, mismo orden, fuentes reales | Contrato 1 |
| criterio 7 · ninguna fuente lleva a un recuerdo inexistente | Contrato 3 |

## Contratos

### 1. Generación

- Usa **exactamente la misma recuperación, el mismo tope y el mismo orden** que la pregunta (F6): los recuerdos del elemento, ordenados por año descendente y luego por guardado descendente.
- Las fuentes son los recuerdos entregados, y si quedó material fuera se dice cuántos.
- Una sesión por generación, sin historial.
- Se genera **al abrir el detalle** cuando no hay retrato vigente, nunca en cada visita.

### 2. Qué puede decir

- **Resume lo que existe.** Si tres recuerdos hablan de José, el retrato cuenta esos tres recuerdos; no deduce cómo era José.
- Nunca interpreta, juzga ni caracteriza a una persona.
- En el idioma de la interfaz, y sin traducir los nombres del usuario.
- Tipográficamente es texto de Hilo, no del usuario: va en la familia de interfaz, sobre la superficie generada.

### 3. Vigencia

- El retrato **deja de valer** cuando el conjunto de recuerdos que lo sostiene cambia: el elemento gana uno, o alguna de sus fuentes se edita o se borra.
- Mientras no vuelva a generarse, **no se muestra**.
- Un retrato que cita un recuerdo que ya no existe es peor que no tener retrato.

### 4. Umbral

- Aparece **a partir de tres recuerdos**. Con menos, el recuerdo ya es su propio retrato.
- Si el elemento baja de tres, el retrato no se muestra.

### 5. Estados en S5

Con menos de tres recuerdos (sin retrato) · normal · generándose · sin vigencia, que se rehace al abrir · elemento con un solo recuerdo.

## Comportamiento

- **Dado** un elemento con dos recuerdos, **cuando** se abre su detalle, **entonces** no hay retrato ni hueco visible que parezca un error.
- **Dado** un elemento con tres recuerdos y sin retrato, **cuando** se abre su detalle, **entonces** se genera y aparece con sus fuentes.
- **Dado** un retrato vigente, **cuando** se borra uno de sus recuerdos fuente, **entonces** deja de mostrarse y se rehace al volver a abrir.
- **Dado** un retrato vigente, **cuando** el elemento gana un recuerdo nuevo, **entonces** pierde vigencia.
- **Dado** que la generación falla, **cuando** ocurre, **entonces** el detalle sigue siendo útil y no se muestra un retrato a medias.

## Criterios de aceptación

**Por test**
- [ ] La vigencia se calcula fuera de la vista y cubre los cuatro disparadores: gana recuerdo, fuente editada, fuente borrada, elemento baja de tres.
- [ ] El material entregado al retrato es idéntico al que entregaría la pregunta para ese elemento.
- [ ] Las fuentes mostradas son las entregadas, y el aviso de lo que quedó fuera coincide.
- [ ] Con menos de tres recuerdos no se genera nada.
- [ ] Un fallo de generación deja el detalle utilizable y sin retrato parcial.

**En dispositivo**
- [ ] El detalle de una persona con varios recuerdos muestra su retrato con fuentes correctas (criterio 4).
- [ ] Ninguna fuente lleva a un recuerdo que ya no existe (criterio 7).
- [ ] Los cinco estados de S5 se ven correctos.
- [ ] AX5, VoiceOver y modo avión.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F7.1** | Vigencia y umbral como lógica pura, con sus tests |
| **F7.2** | Generación reutilizando la recuperación de F6 |
| **F7.3** | Los estados del retrato en S5, con sus fuentes |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`, `auditor-concurrencia`.
- **Después:** ⛳ **punto de control B**. Se decide por escrito qué pasa con F9 y F10 según el orden de recorte.

## Huecos abiertos, a resolver al abrir la fase

- **B8 · cómo se detecta la pérdida de vigencia.** La propuesta de `05` es guardar una **huella** del conjunto de recuerdos candidatos —identificadores y fecha de modificación— en vez de escuchar eventos: si la huella cambia, no hay vigencia. Resuelve todos los disparadores por construcción y es testeable. Queda decidir si renombrar el elemento invalida, dado que el retrato usa el nombre.
- **B9 · qué ocurre cuando el elemento baja de tres recuerdos.** La propuesta es no mostrarlo y descartarlo.
- **B14 · si el aviso de recuerdos fuera del tope también aparece aquí.** La propuesta es que sí, igual que en preguntar.
- **Qué se muestra mientras se genera**, y si la generación se cancela al salir del detalle. Debe cancelarse, como todo streaming, pero conviene fijarlo aquí.
