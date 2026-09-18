# reference/ — Patrones y pantallas de F4 y F5

Referencia visual para la app nativa iOS en SwiftUI. Si una imagen contradice `tokens.md` o la spec de fase, ganan `tokens.md` y la spec.

Al día con `tokens.md` **1.2** y con las decisiones de producto de este lote.

Fuente de las imágenes: `Hilo - Patrones.dc.html` (lienzo navegable, un grupo por sección). Cada PNG es un grupo completo con sus estados etiquetados dentro (`01a`, `01b`…).

## Mapa de imágenes

| PNG | Grupo | Estados |
|---|---|---|
| `01-tarjeta-de-recuerdo.png` | Tarjeta de recuerdo | sin foto con fecha · sin foto sin fecha · con foto · relato largo · guardado sin analizar |
| `02-lista-de-recuerdos.png` | Lista agrupada por década | con contenido (1990s · 1980s · No date) · un solo recuerdo · buscando con resultados · buscando sin resultados |
| `03-lista-de-elementos.png` | Personas, lugares y objetos | con contenido · filtro sin resultados |
| `04-chip-de-elemento.png` | Chip de elemento | nuevo · ya conocido · quitado · nombre largo en AX5 |
| `05-fila-conectada.png` | Fila de recuerdo conectado | dos motivos · motivo largo en AX5 |
| `06-pregunta-de-identidad.png` | Pregunta de identidad | inglés · español en AX5 |
| `07-navegacion.png` | Navegación | TabView · selector superior · barra de herramientas con el acceso a contar |
| `08-memoria-vacia.png` | Memoria vacía | vacío de primera vez |
| `09-captura.png` | Captura | vacío · escribiendo · con foto · comprendiendo · error de comprensión |
| `10-revision.png` | Revisión | con conexiones · sin conexiones · con dudas de identidad · sin nada reconocido · aviso previo a renombrar |
| `11-momento-de-la-conexion.png` | Momento de la conexión | justo después de guardar |
| `12-detalle-de-recuerdo.png` | Detalle de recuerdo | completo · sin foto sin conexiones · guardado sin analizar · confirmación de borrado |
| `13-detalle-de-elemento.png` | Detalle de persona, lugar u objeto | persona con varios recuerdos · objeto con un solo recuerdo |
| `14-ax5-y-espanol.png` | AX5 y español | lista en AX5 · revisión en AX5 · revisión en español |
| `15-cuatro-apariencias.png` | Las cuatro apariencias | claro · oscuro · claro AC · oscuro AC |

## Decisiones aplicadas en este lote

- **Contar un recuerdo** vive en la barra de herramientas de Memoria, en todos los tamaños de texto (`02a`, `02b`, `07c`, `14a`). Nunca flotante ni a ancho completo. Sólo `08a` (memoria vacía) y `02b` (un solo recuerdo) añaden además un botón principal dentro del contenido.
- **Épocas** por década del año deducido: `1990s`, `1980s`. Los recuerdos sin año van en un grupo final `No date`, nunca dentro de otro grupo (`02a`).
- **Filtro por tipo**: chips de filtro (`03a`, `03b`).
- **Búsqueda** sobre el relato y sobre los nombres y alias de los elementos del recuerdo. El término encontrado va en **semibold**, sin color ni fondo. Cuando el recuerdo aparece por un elemento y no por el relato, la tarjeta muestra ese elemento como chip (`02c`, tercer resultado).
- **Guardado sin analizar**: se comprende más tarde sólo desde el detalle (`12c`). La tarjeta (`01e`) informa, no ofrece la acción.
- **Chip ya conocido**: el número cuenta los recuerdos en los que aparece el elemento («in 4 memories»).
- **Foto**: 3:2 recortada en tarjeta; proporción original sin recorte en el detalle (`12a`, una 4:3). En `02a` la tarjeta de ejemplo va sin foto para que los tres grupos, incluido `No date`, entren en pantalla; la variante con foto es `01c`.
- **Conexión**: en el momento de la conexión (`11`), `trazo-conexion` a 2,5 pt fijos. En el detalle (`12a`) no hay trazo: cada fila declara la conexión con el símbolo `link` y su motivo. `trazo-vinculo` es sólo del tejido.
- **Chips**: nuevo · ya conocido con borde de acento a 1,5 pt · quitado en `texto-secundario` con tachado.

## Notas de lectura

- **El lienzo `#E4DFD6` y los marcos de iPhone son andamio de la entrega.** No son tokens y no aparecen en ninguna vista.
- **Los símbolos son sustitutos geométricos de SF Symbols.** En la app va el símbolo real compatible con iOS 26 (`person.fill`, `mappin.and.ellipse`, `cube.fill`, `link`, `exclamationmark.triangle.fill`, `checkmark.circle.fill`, `exclamationmark.octagon.fill`), escala *medium* y el peso del texto contiguo.
- **Liquid Glass sólo en barras del sistema** (pestañas, herramientas, pie de acción). Debajo queda `fondo`. Nunca vidrio sobre tarjetas, relato ni fotos. Los valores de translucidez y desenfoque los pone el sistema: aquí están aproximados.
- **Teclado, dictado, `PhotosPicker`, alertas y diálogos** se dibujan como zona rayada o como bloque: son superficies del sistema.
- **La apariencia por defecto de todos los grupos es la clara.** El intercambio por rol está en `15`.

## Movimiento (no se puede dibujar)

| Momento | Qué pasa | Token |
|---|---|---|
| Comprender el relato | Los elementos reconocidos aparecen uno a uno, en orden de lectura | `mov-aparicion-elemento` |
| Guardar | El relato sube a su sitio y el aviso de guardado entra sin rebote | movimiento del sistema |
| Momento de la conexión | El trazo de `trazo-conexion` se dibuja de arriba abajo y luego entran las filas conectadas | `mov-conexion` |
| Quitar un elemento | El chip se tacha en el sitio; «Undo» queda disponible | movimiento del sistema |

En `09d` el tercer chip está a media aparición para que se vea el orden; no es un estado real.

## Preguntas abiertas

Al final del lienzo, en dos listas: **tokens: resuelto y pendiente** y **preguntas de producto**. Las que siguen abiertas:

1. Si el chip de filtro inactivo lleva símbolo, y el relleno exacto del botón de acento en la barra (círculo de acento frente a vidrio teñido `prominent` de iOS 26).
2. Si la foto de la tarjeta es a sangre o dentro de `relleno-tarjeta`.
3. Si «in N memories» incluye el recuerdo que se está guardando (en `10a` no lo incluye).
4. En `02c`, cuántos chips mostrar cuando coinciden dos elementos.
5. Si hay tope de década («Before 1950»).

## Fuera de alcance

Rango temporal en el detalle de persona, lugar u objeto (pendiente de decisión, no dibujado), contenido de la pestaña Ask, retrato, tejido y widgets.
