# F5 — Explorar

- **Fase**: F5 · Sesión S3 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §9.3, §10.1, §10.2 (S1, S4, S5), §13 (reglas 12, 17)
- **Capacidades**: 5 (motivo visible), 6, 7
- **Decisiones**: DEC-12, DEC-13, DEC-14, DEC-15, DEC-16, DEC-20, DEC-21, DEC-24, DEC-57, DEC-59
- **Depende de**: F1, F2, F4

## Objetivo

Que la memoria se pueda recorrer: por recuerdos, por elementos y por vecindad, sin callejones sin salida. Al terminar se cumple el criterio 3: desde cualquier recuerdo se llega a cualquier otro con el que comparta un elemento.

## Alcance

**Dentro**
- Navegación: dos destinos, selector superior, ajustes en la barra de herramientas.
- S1 Memoria, en sus dos vistas y con sus cuatro estados.
- Búsqueda por texto.
- S4 Detalle de recuerdo, con sus cuatro estados, editar y borrar.
- S5 Detalle de elemento **sin retrato ni tejido**, con renombrar y añadir alias.
- Carga de la memoria de ejemplo desde el estado vacío.

**Fuera, explícitamente**
- Retrato (F7) y tejido (F9): su sitio queda reservado, sin dibujar.
- Preguntar (F6): la pestaña existe, su contenido no.
- Hebras sueltas intercaladas en S1 (F10).
- Ajustes como hoja (F8); aquí solo el acceso.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.3 · tres formas de recorrer | Contratos 2, 3 y 4 |
| §9.3 · una conexión siempre enseña su motivo | Contrato 4 |
| regla 17 · la fecha con las palabras del usuario | Contratos 2 y 4 |
| regla 12 · borrar un recuerdo no borra sus elementos | Contrato 4 |
| DEC-14 · época por década, «sin año» al final | Contrato 2 |
| DEC-15 y DEC-20 · alcance de la búsqueda y extracto centrado | Contrato 3 |
| DEC-16 · comprender más tarde desde el detalle | Contrato 4 |
| DEC-24 · el texto del borrado se calcula | Contrato 4 |
| DEC-57 · huecos de apertura de F5 | Contratos 2, 3 y 4 |
| DEC-59 · botón de Ajustes en F5 | Contrato 1 |

## Contratos

### 1. Navegación

- Dos destinos: Memoria y Preguntar. Ajustes en la barra de herramientas.
- En Memoria, un selector superior entre recuerdos y elementos: son **dos vistas del mismo material**, no dos sitios distintos.
- El acceso a contar un recuerdo vive en la barra de herramientas, en todos los tamaños de texto (DEC-12). Solo los estados vacío y de un recuerdo añaden además un botón dentro del contenido.
- El acceso a Ajustes se construye como el de Preguntar (DEC-59): el botón existe y es tocable, abre un estado vacío/mínimo, nunca un crash ni un no-op silencioso. Su contenido real es de F8 y puede no existir aún al entregar.

### 2. Recuerdos (S1)

- Cronológicos, **agrupados por década del año deducido**; los que no tienen año van en un grupo final «sin año», nunca dentro de otro (DEC-14, DEC-21).
- El encabezado de década es texto de interfaz, no una fecha del usuario, así que no choca con la regla 17.
- Sin tope de década.
- Cada tarjeta muestra las primeras líneas del propio relato y, si la hay, el texto de la fecha. Los recuerdos no tienen título.
- Estados: vacío, un solo recuerdo, normal y buscando con y sin resultados.
- **Vacío** trae la promesa del producto, la afirmación de privacidad una sola vez, y dos salidas: contar el primer recuerdo o cargar la memoria de ejemplo.
- **Un solo recuerdo** empuja explícitamente al segundo, porque ahí empieza la conexión.

### 3. Búsqueda

- Cubre el relato y **los nombres y alias de los elementos del recuerdo** (DEC-15).
- El término encontrado se marca con peso, sin color ni fondo. Si la coincidencia cae fuera de las primeras líneas, **el extracto se centra en ella** (DEC-20).
- Si el recuerdo aparece por un elemento y no por el relato, la tarjeta muestra ese elemento, para que se entienda por qué está en los resultados. Si coincide por varios elementos, se muestran todos, sin tope (DEC-57).
- «Buscando sin resultados» no es el estado vacío de primera vez: aquí ya hay memoria.
- Si se edita el texto de un recuerdo cuyo extracto sostenía una búsqueda activa, la lista se recalcula al volver a S1, nunca en caliente mientras el recuerdo se edita (DEC-57).

### 4. Elementos y detalles

**Lista de elementos**: filtrable por tipo con chips (DEC-13); cada fila lleva símbolo, color y **texto del tipo**, el nombre y su número de recuerdos. La palabra «elemento» no aparece nunca.

**S4 · Detalle de recuerdo**: foto si la hay, relato íntegro **sin recortar**, fecha con las palabras del usuario, elementos tocables, y los recuerdos conectados **con su motivo**. Editar y borrar.
- Editar el texto no reanaliza (DEC-19).
- Un recuerdo guardado sin analizar ofrece aquí comprenderlo (DEC-16).
- El texto de la confirmación de borrado **se calcula**: un elemento que se quede sin recuerdos desaparece (DEC-24, regla 11).
- Estados: con foto, sin foto, sin conexiones, sin elementos reconocidos.

**S5 · Detalle de elemento**: nombre, tipo, alias, número de recuerdos, el rango temporal y sus recuerdos en orden. Renombrar y añadir alias, con las validaciones de F1. El espacio del retrato y del tejido queda reservado, sin dibujarse.
- El rango temporal muestra las palabras del usuario del recuerdo más antiguo y del más reciente, por el mismo orden de DEC-35 (año deducido descendente, `savedAt` descendente, sin año al final, desempate por identificador). Si el extremo elegido no tiene texto de fecha del usuario, ese extremo no se muestra. Con un solo recuerdo no hay rango que mostrar (DEC-57).
- «Sus recuerdos en orden» usa ese mismo orden de DEC-35, no uno nuevo (DEC-57).
- Estados: normal y con un solo recuerdo.

## Comportamiento

- **Dado** un recuerdo sin año, **cuando** se lista, **entonces** aparece en el grupo final «sin año».
- **Dado** que se busca «reloj» y un recuerdo lo menciona en la cuarta línea, **cuando** se muestran resultados, **entonces** el extracto se centra en esa coincidencia.
- **Dado** un recuerdo que comparte José y Granada con otro, **cuando** se abre su detalle, **entonces** el otro aparece una vez, con ambos motivos.
- **Dado** un elemento que solo aparece en el recuerdo que se va a borrar, **cuando** se pide confirmación, **entonces** el texto dice que ese elemento desaparecerá.
- **Dado** un elemento con un solo recuerdo, **cuando** se abre su detalle, **entonces** se invita a contar otro donde aparezca.

## Criterios de aceptación

**Por test**
- [ ] La agrupación por década y el grupo «sin año» se calculan fuera de la vista, con los casos límite: sin año, año en el límite de década, memoria vacía.
- [ ] La búsqueda encuentra por relato y por nombre o alias de elemento, y produce el extracto centrado cuando corresponde.
- [ ] Los vecinos de un recuerdo, con motivo, en orden estable y sin duplicados.
- [ ] El texto de la confirmación de borrado enumera correctamente qué elementos desaparecen y cuáles se quedan.
- [ ] Los textos anunciables de listas, filas y motivos, en los dos idiomas.

**En dispositivo**
- [ ] Desde cualquier recuerdo se llega a cualquier otro con el que comparta un elemento (criterio 3).
- [ ] Los cuatro estados de S1 y los cuatro de S4 se ven correctos, en claro y oscuro.
- [ ] AX5 y VoiceOver en las tres pantallas.
- [ ] En modo avión, todo igual.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F5.1** | Agrupación, orden y búsqueda como lógica pura, con sus tests |
| **F5.2** | Navegación y S1 en sus dos vistas y cuatro estados |
| **F5.3** | S4 con sus estados, editar y borrar |
| **F5.4** | S5 sin retrato ni tejido, renombrar y alias |
| **F5.5** | Accesibilidad, textos y AX5 |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** no, más allá de mostrarlos.
- **Concurrencia nueva:** no.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`.

## Huecos abiertos, a resolver al abrir la fase

- **A1 · el rango temporal en S5 — resuelto (DEC-57).** Palabras del usuario del recuerdo más antiguo y del más reciente, por el orden de DEC-35; el extremo sin texto de fecha no se muestra; con un solo recuerdo no hay rango.
- **Cuántos chips mostrar — resuelto (DEC-57).** Todos, sin tope, cuando un resultado de búsqueda coincide por varios elementos.
- **Qué ocurre al editar el texto de un recuerdo cuyo extracto sostenía una búsqueda activa — resuelto (DEC-57).** La lista se recalcula al volver a S1, nunca en caliente mientras se edita.
- **Orden de los recuerdos dentro de S5 — resuelto (DEC-57).** El mismo criterio de DEC-35 que ya usa la lista general, no uno nuevo.
