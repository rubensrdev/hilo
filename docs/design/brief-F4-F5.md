# Brief de Claude Design — Hilo · patrones de F4 y F5

> `docs/design/brief-F4-F5.md` · Se pega en el proyecto de Claude Design con `tokens.md` adjunto.
> Cubre las superficies de F4 (Captura y Revisión) y F5 (Explorar). Retrato (F7), Preguntar (F6), Ajustes (F8), tejido (F9) y hebras sueltas (F10) se piden más adelante.

---

Este proyecto va a servir de referencia visual para una app **nativa iOS en SwiftUI**, no para desarrollo web. Tipo de proyecto: mobile. Es una app nativa **iOS 26**, **solo iPhone y en vertical**, con Liquid Glass, solo componentes de Apple y siguiendo las Human Interface Guidelines.

# Qué es Hilo, en lo que te afecta

Hilo es una memoria personal privada. El usuario cuenta recuerdos en lenguaje natural. La app reconoce las personas, los lugares y los objetos que aparecen, deja revisarlos y conecta cada recuerdo con los anteriores que comparten alguno. Todo ocurre en el teléfono.

Cinco reglas de producto que el diseño no puede romper:

1. **El relato del usuario es lo protagonista y nunca se recorta en su detalle.** Las tarjetas muestran las primeras líneas del propio relato; los recuerdos no tienen título.
2. **La foto es opcional.** La tarjeta sin foto es la tarjeta principal, no una tarjeta a la que le falta algo. **Nunca pongas texto encima de una foto.**
3. **La fecha es el texto del usuario tal como lo dijo** («the summer of '87», «el verano del 87»). Nunca la conviertas en una fecha formateada, ni muestres un año que el usuario no escribió.
4. **Una conexión siempre enseña su motivo.** «By José and Granada» junto a cada recuerdo conectado.
5. **La interfaz no presume de inteligencia artificial.** Nada de destellos, varitas, cerebros, burbujas de chat ni avatares.

La palabra «element» **no aparece nunca** en la interfaz: el usuario ve personas, lugares y objetos.

# Los tokens son entrada: no los decides tú

Te adjunto `tokens.md` con el color (en sus cuatro apariencias), la tipografía, el espaciado, los radios, la iconografía y el movimiento ya decididos, con nombre semántico. Úsalos tal cual.

No inventes ningún color, tamaño, familia tipográfica, símbolo ni valor de espaciado que no esté ahí. Si te falta un token para dibujar algo, **no lo rellenes**: anótalo en una lista al final y sigue con el resto. Esa lista me sirve; un valor inventado no.

Presta atención a dos reglas del documento:

- **New York solo para las palabras del usuario** (relato y fecha). Todo lo demás en SF.
- **El acento terracota solo para la acción principal y para lo que conecta.** Si lo usas en más sitios, la conexión deja de verse.

# Textos

La interfaz es **en inglés**. Los textos de interfaz que escribas son **provisionales**: se reescriben después en el catálogo de textos, así que no te preocupes por pulirlos. **No inventes funciones a través de los textos**: si una etiqueta sugiere algo que la app no hace, es un cambio de producto.

El contenido del usuario de los ejemplos es una memoria mezclada en español e inglés, porque la app no lo traduce:

- «Mi abuelo José me regaló el reloj el verano del 87, en la casa del pueblo. Me dijo que había sido de su padre y que ahora me tocaba cuidarlo a mí.»
- «Granada, 1994. La tía Carmen nos llevó a ver la Alhambra y se perdió José en los jardines durante una hora.»
- «The last time I saw grandpa José he was fixing the sewing machine in the kitchen. He hummed the whole time.»
- Un relato largo, de cuatro párrafos, para probar el caso extremo.

Nombres de elementos para el caso extremo de longitud: «la máquina de coser de la abuela Carmen», «Colegio Nuestra Señora de la Asunción».

# Qué diseñar

Diseña **patrones, no pantallas**: resuelve cada patrón una vez y después solo las pantallas que se desvían de él.

## Patrones

- **Tarjeta de recuerdo.** Estados:
  - sin foto con fecha;
  - sin foto y sin fecha;
  - con foto;
  - relato largo (extracto);
  - recuerdo guardado sin analizar, con `estado-aviso`, símbolo y texto, nunca solo color.
- **Lista de recuerdos agrupada por época.** Encabezado por década («1980s») y un grupo final «No date». Estados:
  - con contenido;
  - un solo recuerdo, que empuja a contar el segundo porque ahí empieza el valor;
  - buscando, con resultados;
  - buscando, sin resultados. No es el mismo estado que el vacío de primera vez.
- **Lista de elementos filtrable por tipo.** Fila con símbolo, color y texto del tipo, nombre y número de recuerdos. Estados:
  - con contenido;
  - filtro sin resultados.
- **Chip de elemento.** Persona, lugar y objeto. Variantes de revisión:
  - nuevo;
  - ya conocido, con cuántos recuerdos conecta;
  - quitado de este recuerdo, que sigue siendo reversible hasta guardar.
- **Fila de recuerdo conectado.** Extracto del relato y motivo de la conexión («By José and Granada»).
- **Pregunta de identidad.** «Is José García the same José you already know?» con dos respuestas de igual peso.
- **Navegación.** `TabView` con dos destinos: **Memory** y **Ask**. En Memory, un selector superior **Memories ⇄ People, places & objects**, búsqueda, acceso destacado a contar un recuerdo y Ajustes en la barra de herramientas. Ask solo como pestaña; su contenido no se diseña ahora.

## Pantallas singulares

- **Memoria vacía (primer arranque).** Promesa del producto en una frase, afirmación de privacidad (todo se queda en el iPhone, sin cuenta ni conexión) y dos salidas: contar el primer recuerdo o explorar una memoria de ejemplo. Aquí la afirmación de privacidad se hace una sola vez, no como sello repetido.
- **Captura.** Campo de texto libre amplio (el dictado lo pone el teclado del sistema, no lo dibujes), foto opcional antes o después, acción principal «Understand & save» y salida secundaria siempre visible «Save without analyzing». Estados:
  - vacío, con texto de ayuda que enseña un recuerdo de ejemplo real;
  - escribiendo;
  - con foto;
  - comprendiendo: los elementos aparecen uno a uno mientras se lee el relato;
  - error de comprensión: el texto sigue a salvo, se guarda sin analizar y se dice por qué, sin tono de fallo grave.
- **Revisión.** Es, con Preguntar, la pantalla más importante del producto. Una sola superficie con cuatro bloques: lo que ha entendido (agrupado por tipo, con quitar y renombrar), lo que ya conocía (cada reconocimiento rechazable con un toque: «Not the same José»), lo que duda (preguntas de identidad) y la fecha entendida, editable como texto. **El camino feliz es una sola confirmación.** Estados:
  - con conexiones: el caso valioso;
  - sin conexiones: se enmarca como **el comienzo**, nunca como un fallo;
  - con dudas de identidad pendientes;
  - sin nada reconocido: el recuerdo se guarda igual.

  Además, el aviso previo a renombrar un elemento que ya existe («José appears in 4 memories»), porque renombrar afecta a toda la memoria y quitar solo a este recuerdo.
- **El momento de la conexión.** Justo después de guardar: el recuerdo ya guardado y sus conexiones formándose. Dibuja el estado final. La animación descríbela en el README.
- **Detalle de recuerdo.** Foto si la hay, relato íntegro, fecha en palabras del usuario, elementos tocables, recuerdos conectados con motivo, y editar y borrar. Estados:
  - con foto;
  - sin foto;
  - sin conexiones;
  - sin elementos reconocidos.
- **Detalle de elemento**, sin retrato ni tejido, que llegan en fases posteriores (deja el espacio sin dibujarlo). Contenido: nombre, tipo, alias, número de recuerdos, rango temporal en palabras del usuario («from the summer of '87 to the nineties»), sus recuerdos en orden, y renombrar y añadir alias. Estados:
  - normal;
  - con un solo recuerdo.

## Además

- **La lista de recuerdos y la Revisión con conexiones, en el tamaño de texto de accesibilidad más grande (AX5).** Las tarjetas se reorganizan en vertical; no truncan el relato ni solapan contenido.
- **La Revisión con conexiones con la interfaz en español**, para comprobar el crecimiento de etiquetas y botones.
- **Una muestra de cada patrón en las cuatro apariencias** (claro, oscuro y ambas con más contraste). Basta con la tarjeta de recuerdo y el chip de elemento.

# Fuera de alcance

- **Lo que ya diseña el sistema:** teclado y dictado, selector de fotos, alertas y diálogos de confirmación, hoja de compartir.
- **Pantallas de fases posteriores:** Preguntar, retrato, tejido, hebras sueltas y Ajustes.
- **Estados que no existen en Hilo:**
  - sin conexión a internet (la app no usa red);
  - «Apple Intelligence no disponible» (es premisa del producto, no un estado);
  - cuentas, inicio de sesión y permisos de notificaciones.

No propongas cambios de producto. Si algo del flujo te parece mejorable, escríbelo como pregunta al final en lugar de dibujarlo de otra forma.

# Entregables

1. Un PNG por patrón y estado, y uno por pantalla singular y estado, con prefijo numérico según el orden de uso: `01-memoria-vacia.png`, `02-captura-vacia.png`…
2. Un `README.md` con una entrada por patrón y por pantalla: propósito, comportamiento condicional y las microinteracciones que una imagen fija no puede mostrar. Como mínimo:
   - la aparición progresiva de elementos;
   - la formación de la conexión al guardar;
   - su versión con Reducir movimiento.
3. La lista de tokens que te han faltado, si ha faltado alguno.
4. Las preguntas de producto que te hayan surgido, si hay alguna.

**No generes un `tokens.md`.** Los tokens vienen dados.

Organiza la salida con las imágenes en una carpeta y el README en la raíz.

---

## Para Rubén: aceptación del handoff

Criterio de `09 · §4`, aplicado a este lote.

**Se acepta si:**

- Cada patrón trae sus estados, no solo el feliz.
- La lista y la Revisión sobreviven a AX5.
- El README explica la aparición progresiva y la conexión, también con Reducir movimiento.
- En escala de grises se siguen distinguiendo persona, lugar y objeto.

**Se devuelve si:**

- Aparece un valor que no está en `tokens.md`.
- Hay texto sobre una foto.
- La fecha aparece formateada.
- Aparece iconografía de IA.
- Aparece la palabra «element».
- Una conexión se muestra sin motivo.
- La Revisión sin conexiones parece un fallo.
- Añade una función: por ejemplo, unir dos elementos existentes, que está fuera del MVP.
