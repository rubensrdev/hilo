# F10 — Hebras sueltas

- **Fase**: F10 · Sesión S6 · **Con UI** · **Recortable**
- **Estado**: Draft
- **Origen**: Idea v2.3 §9.8, §10.2 (S1, S5), §12 (descarte), §13 (reglas 20, 21)
- **Capacidades**: 12
- **Depende de**: F1, F2, F5

## Objetivo

Que Hilo detecte huecos y haga preguntas que solo el usuario puede responder, sin convertirse nunca en una lista de tareas sobre la propia memoria.

**Esta fase es la primera que se recorta** en el orden 12 → 9 → 4. El punto de control B decide si se construye.

## Alcance

**Dentro**
- Detección de huecos, como lógica pura.
- Catálogo de huecos del MVP.
- Formulación por plantilla, no por modelo.
- Presentación intercalada donde el usuario ya está mirando.
- Descarte, y su persistencia.

**Fuera, explícitamente**
- Pantalla propia, notificaciones o insignias.
- Más de una hebra a la vez.
- Formulación generada por el modelo.
- Responder rellenando un campo: responder es contar un recuerdo, por el camino normal.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.8 · una a la vez | Contrato 3 |
| §9.8 · siempre descartable | Contrato 4 |
| §9.8 · la detección es nuestra, la formulación es plantilla | Contratos 1 y 2 |
| §9.8 · responder es contar un recuerdo | Contrato 3 |
| regla 20 · una hebra descartada no vuelve para ese elemento | Contrato 4 |
| regla 21 · solo una a la vez | Contrato 3 |
| §12 · el descarte es (tipo de hueco, elemento) | Contrato 4 |

## Contratos

### 1. Detección

- Es **lógica pura** sobre recuerdos, elementos y apariciones: mismos datos, mismas hebras, en el mismo orden.
- No interviene el modelo en ningún momento.
- El catálogo del MVP se cierra a **huecos de elemento** (hueco A2 de `05`): por ejemplo, un elemento con un solo recuerdo, o una persona sin ningún lugar compartido.
- Los huecos sobre un recuerdo concreto —«¿de qué año es este recuerdo?»— quedan fuera del MVP, porque el descarte se guarda por elemento y porque responderlos sería editar un dato, no contar un recuerdo.

### 2. Formulación

- Plantillas localizadas por tipo de hueco, con el nombre real del elemento.
- Lo interesante es **qué** se pregunta, no cómo se redacta.
- El tono es de invitación, nunca de reproche ni de tarea pendiente.

### 3. Presentación

- **Una a la vez**, nunca una lista.
- Aparece **donde el usuario ya está mirando**: intercalada arriba en S1, y en el detalle de elemento cuando le corresponde.
- Nunca es pantalla propia, notificación ni insignia.
- **Responderla es contar un recuerdo**: abre la captura normal, con el mismo camino de comprensión y revisión.
- Un usuario debe poder ignorarlas para siempre y que Hilo siga siendo Hilo.

### 4. Descarte

- Al descartar se guarda el par **(tipo de hueco, elemento)**, y esa pregunta no vuelve para ese elemento (regla 20).
- No se descarta un tipo de pregunta para siempre, ni solo esa aparición concreta.
- El descarte sobrevive al cierre de la app y desaparece con el borrado total.

## Comportamiento

- **Dado** un elemento con un solo recuerdo, **cuando** se abre S1, **entonces** aparece una hebra que invita a contar otro donde aparezca.
- **Dado** que hay tres huecos detectados, **cuando** se muestra, **entonces** solo aparece uno.
- **Dado** que se descarta una hebra, **cuando** se vuelve a entrar, **entonces** esa pregunta no vuelve para ese elemento, pero sí puede aparecer la misma pregunta para otro.
- **Dado** que se responde contando un recuerdo, **cuando** se guarda, **entonces** el hueco deja de existir por sí solo, sin marcarlo.
- **Dado** un borrado total, **cuando** termina, **entonces** no queda ningún descarte.

## Criterios de aceptación

**Por test**
- [ ] La detección devuelve las mismas hebras, en el mismo orden, para los mismos datos.
- [ ] Cada tipo de hueco del catálogo se detecta y deja de detectarse cuando se cubre.
- [ ] Un descarte impide esa hebra para ese elemento y no para otros.
- [ ] Solo se ofrece una hebra a la vez, y el criterio de cuál es reproducible.
- [ ] Las plantillas se generan en los dos idiomas, con el nombre real del elemento.

**En dispositivo**
- [ ] La hebra aparece intercalada en S1 sin romper el recorrido de la lista.
- [ ] Descartar funciona con un toque y no vuelve.
- [ ] Responder abre la captura normal.
- [ ] AX5, VoiceOver y modo avión.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F10.1** | Detección y catálogo como lógica pura, con tests |
| **F10.2** | Plantillas localizadas |
| **F10.3** | Presentación intercalada y descarte persistente |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** no.
- **Concurrencia nueva:** no.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`.

## Huecos abiertos, a resolver al abrir la fase

- **A2 · el catálogo exacto de huecos del MVP.** La propuesta de `05` es cerrarlo a huecos de elemento y dejar fuera los de recuerdo. Hay que fijar la lista concreta: cuáles entran y con qué condición se detecta cada uno.
- **Qué hebra se elige cuando hay varias.** El criterio tiene que ser reproducible y explicable; no vale «la primera que salga».
- **Cada cuánto vuelve a aparecer una hebra no descartada**, si el usuario simplemente la ignora sin descartarla.
- **Dónde aparece exactamente en S1** y qué pasa cuando la lista está vacía o tiene un solo recuerdo, que ya tienen su propio mensaje.
