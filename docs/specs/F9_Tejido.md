# F9 — Tejido

- **Fase**: F9 · Sesión S6 · **Con UI** · **Recortable**
- **Estado**: Draft
- **Origen**: Idea v2.3 §9.4, §10.2 (S5), §11.1
- **Capacidades**: 9
- **Decisiones**: DEC-14 (no aplica), `tokens.md` §3.4 (`trazo-vinculo`)
- **Depende de**: F5, F7

## Objetivo

Dar a la memoria una forma visible: un diagrama estático dentro del detalle de elemento, que nunca es el único camino a ningún sitio.

**Esta fase es recortable.** Es la segunda que cae en el orden 12 → 9 → 4, y el punto de control B decide si se construye.

## Alcance

**Dentro**
- Diagrama estático en S5: el elemento en el centro, sus vecinos alrededor, el grosor del vínculo según cuántos recuerdos comparten.
- Navegación al tocar un nodo.
- Lista equivalente que lo sustituye en tamaños de accesibilidad.

**Fuera, explícitamente**
- Interactividad: sin desplazamiento, sin zoom, sin recentrado, sin animación.
- Vecindad de segundo grado: vecino es **comparte un elemento**, no «alcanzable dando saltos».
- Cualquier camino que no exista ya en las listas contiguas.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.4 · estático y estable | Contrato 1 |
| §9.4 · nunca es el único camino | Contrato 3 |
| §9.4 · se sustituye en tamaños de accesibilidad | Contrato 4 |
| `tokens.md` §3.4 · grosor del vínculo | Contrato 2 |

## Contratos

### 1. Qué se dibuja, y que sea estable

- El elemento en el centro; alrededor, los elementos con los que comparte al menos un recuerdo.
- **El mismo elemento produce siempre la misma imagen**: la disposición es determinista, calculada a partir de un orden estable de los vecinos, nunca de un algoritmo con azar ni de simulación física.
- Es una función pura de los datos a posiciones: se puede probar sin dibujar nada.

### 2. El vínculo

- El grosor sale de `trazo-vinculo`: 1 recuerdo compartido 1,5 pt · 2 → 2,5 · 3 → 3,5 · 4 o más → 4,5.
- El tope de grosor existe para que un elemento con muchos recuerdos no tape el diagrama.
- **El número exacto de recuerdos compartidos se da siempre en la lista contigua**, nunca solo en el grosor.

### 3. Navegación

- Tocar un nodo navega a ese elemento. Nada más.
- Todo lo alcanzable aquí es alcanzable en las listas de S5. Si algo solo se alcanza por el tejido, el tejido dejó de ser un adorno y pasó a ser un camino, que es justo lo que no puede ser.

### 4. Accesibilidad

- **En tamaños de accesibilidad se sustituye por su lista equivalente**, sin aviso y sin pérdida de información. Un diagrama con nombres a AX5 no es accesible: es un diagrama roto.
- Para VoiceOver, el diagrama se representa como su lista: cada vecino con su nombre, su tipo y cuántos recuerdos comparten.
- Sin animación, y por tanto sin rama de Reducir movimiento: ya es estático.

## Comportamiento

- **Dado** un elemento con tres vecinos, **cuando** se abre su detalle, **entonces** el diagrama muestra los tres, con grosores según los recuerdos compartidos.
- **Dado** el mismo elemento, **cuando** se abre dos veces, **entonces** la imagen es idéntica.
- **Dado** AX5, **cuando** se abre el detalle, **entonces** en lugar del diagrama aparece la lista equivalente.
- **Dado** un elemento sin vecinos, **cuando** se abre, **entonces** no hay diagrama vacío ni hueco que parezca un error.

## Criterios de aceptación

**Por test**
- [ ] La disposición es determinista: los mismos datos producen las mismas posiciones.
- [ ] El orden de los vecinos es estable y reproducible.
- [ ] El grosor se asigna según la escala de `tokens.md`, con su tope.
- [ ] La lista equivalente contiene exactamente los mismos vecinos que el diagrama.

**En dispositivo**
- [ ] El diagrama se ve correcto en claro y oscuro, y con un elemento de muchos vecinos.
- [ ] En AX5 aparece la lista y no el diagrama.
- [ ] VoiceOver recorre los vecinos con su nombre, tipo y número de recuerdos compartidos.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F9.1** | Disposición determinista como función pura, con tests |
| **F9.2** | Dibujo en S5 y navegación al tocar |
| **F9.3** | Sustitución por lista en tamaños de accesibilidad |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** no.
- **Concurrencia nueva:** no.
- **Antes de implementar:** `ingeniero-tests` para la disposición.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`.

## Huecos abiertos, a resolver al abrir la fase

- **B12 · qué hacer con muchos vecinos.** Sin límite, una persona con cuarenta conexiones rompe el diagrama. La propuesta de `05` es un máximo de N vecinos por peso, con orden estable por nombre, y «y N más» que remite a la lista contigua. Falta fijar N.
- **La disposición concreta**: radial con los vecinos repartidos por ángulo es lo más simple y estable, pero hay que decidir cómo se ordenan y dónde se corta el texto de un nombre largo sin truncar información.
- **Si el tejido aparece antes o después del retrato en S5.**
- **A partir de qué tamaño de texto se sustituye por la lista**: la primera talla de accesibilidad, o antes si el diagrama ya no se lee.
