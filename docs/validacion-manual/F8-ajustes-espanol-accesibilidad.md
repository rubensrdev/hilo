# Validación manual — F8 Ajustes, español, accesibilidad y diseño

Batería para dispositivo físico real, no simulador: verifica VoiceOver, Tipografía
Dinámica, las cuatro apariencias y el comportamiento nativo que solo se juzga en un
iPhone. Contrastada contra `docs/specs/F8_Ajustes_Espanol_Accesibilidad.md` (bloque
"En dispositivo"), contra los hallazgos de `docs/validacion-manual/F8-accesibilidad-y-diseno.md`
y contra lo que `verificador-ui` ya comprobó en simulador en F8.1, F8.4 y F8.5 (siempre
en español, oscuro y tamaño de accesibilidad: la variante por defecto del selector y el
modo claro solo se han visto en render).

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone (build Debug).
2. Pon el iPhone en **español** (Ajustes del sistema → General → Idioma y región).
3. Ve a Memoria → engranaje (Ajustes) → **Borrarlo todo** → Continuar → Borrarlo todo.
   Ya no existe el botón Debug «Wipe all data» de F5: el borrado total es producto.
4. En Ajustes → sección **Debug** (solo en compilaciones Debug) pulsa **Load validation
   dataset**: carga los 5 recuerdos de la memoria de ejemplo aprobada más los 2 de la
   batería de F5 (Marta / el parque; Martina / la bicicleta vieja). Es el mismo set de
   `docs/validacion-manual/F5-explorar.md`; F8 no necesita datos nuevos.
5. Guarda además **un recuerdo real** desde Contar un recuerdo (por ejemplo «Comimos con
   José el domingo pasado», con «Entender y guardar»): sirve para comprobar que borrar el
   ejemplo respeta lo tuyo y que José sobrevive con ese recuerdo.

Repite «Borrarlo todo + Load validation dataset + un recuerdo real» cada vez que quieras
reiniciar la batería desde cero.

## 1. S7 Ajustes (contrato 1, regla 25)

- [ ] **Es una hoja**: se abre desde el engranaje, se cierra con «Cerrar» y deslizando;
      reabrirla dos veces seguidas funciona siempre.
- [ ] **Privacidad**: la tarjeta amplía la frase del estado vacío («Tus recuerdos, las
      personas, lugares y objetos que hay en ellos, y tus fotos viven solo en este
      iPhone…»), no la repite. Es el segundo y último sitio donde se afirma.
- [ ] **Borrar la memoria de ejemplo** (con el set cargado y el recuerdo real guardado):
      alerta → «Borrar el ejemplo». El botón pasa a «Cargar la memoria de ejemplo» sin
      cerrarse la hoja. Cierra: en Memoria solo queda tu recuerdo real; **José sigue
      existiendo** (S1 → Personas) con ese único recuerdo; el resto de elementos del
      ejemplo han desaparecido.
- [ ] **Cargar la memoria de ejemplo** desde Ajustes: el ejemplo vuelve **en español**
      (el idioma de la interfaz al cargarlo) y José recupera sus 5 recuerdos + el tuyo.
      Cargarlo dos veces no duplica nada.
- [ ] **Borrado total, doble confirmación**: «Borrarlo todo» → alerta «¿Borrarlo todo?»
      cuyo texto dice exactamente qué desaparece (recuerdos, personas/lugares/objetos,
      fotos) → «Continuar» → segunda alerta «¿Borrarlo todo para siempre?» («No se puede
      deshacer…»). **Cancela en la segunda**: nada se borra. Repite y confirma: la hoja
      se cierra sola y Memoria muestra el vacío de primera vez, con el selector en
      «Recuerdos», sin búsqueda ni filtro activos.
- [ ] **Tras el borrado, mata la app y vuelve a abrirla**: arranca en el vacío de primera
      vez. Si habías guardado un recuerdo con foto antes de borrar, la foto tampoco
      vuelve.
- [ ] **Acerca de**: «Hilo» y «Versión 1.0». Sin enlaces.
- [ ] Tocar fuera de una alerta o deslizar la hoja a mitad del borrado lo cancela; al
      reabrir Ajustes no queda ninguna alerta colgada.

## 2. Español (contrato 2, criterio 9)

- [ ] Recorre **toda** la app en español: S1 (vacío, un recuerdo, normal, buscando con y
      sin resultados, vista de personas/lugares/objetos con sus filtros «Todos /
      Personas / Lugares / Objetos»), S2, S3 (los cuatro bloques), momento de la
      conexión, S4, S5, S7 y todas las alertas. **Ningún texto en inglés** salvo el
      contenido del usuario y la sección Debug de Ajustes (nunca en Release).
- [ ] Compuestos montados con 1 y con varios: «en 1 recuerdo» / «en 3 recuerdos» en
      S1 y S5; «Conectado con 1 recuerdo» / «Conectado con 3 recuerdos» en S4 y en el
      momento; «Por José» / «Por Carmen y Granada» como motivo; «Cambiar el nombre en
      N recuerdos» al renombrar desde S5.
- [ ] El contenido del usuario no se traduce ni se reformatea: el recuerdo real que
      guardaste, los nombres y «el domingo pasado» salen tal cual.
- [ ] Rango temporal en S5 (José): la etiqueta de VoiceOver dice «Desde … hasta …»
      con las palabras del usuario, sin «a el».
- [ ] Cambia el iPhone a **inglés** y repite S7 y una captura: todo en inglés, y el
      ejemplo cargado en inglés si lo cargas ahora.

## 3. Accesibilidad — matriz (contrato 3, criterio 8)

Ajustes del sistema → Accesibilidad → Pantalla y tamaño del texto.

- [ ] **Tamaño más pequeño** (xSmall): S1, S4, S5 y S7 legibles; el selector de Memoria
      cabe entero en el segmentado; nada se recorta.
- [ ] **Tamaño por defecto**: el selector «Recuerdos / Personas, lugares y objetos»
      está **bajo la barra, a ancho completo**, y el texto largo se lee entero sin
      puntos suspensivos.
- [ ] **AX5** (Tamaños de texto más grandes al máximo):
  - El selector pasa a menú y muestra el texto entero del seleccionado.
  - S1 (personas/lugares/objetos): los chips de filtro en columna; en cada fila el
    recuento baja bajo el tipo, no comparte línea.
  - S5: el símbolo y el nombre se apilan; «Añadir un alias» y «Cambiar nombre»
    responden.
  - S4: los chips de elemento son tocables sin fallos de precisión (objetivo ≥ 44 pt).
  - S3 Revisión: filas, respuestas de duda y chips apilados; el relato nunca trunca.
  - S7: las tarjetas crecen, ningún texto trunca; las alertas del borrado total se
    leen enteras desplazando el mensaje.
  - Alertas con campo de texto (renombrar, alias) usables.
- [ ] **VoiceOver**, de principio a fin:
  - S1: cada fila de persona/lugar/objeto es un solo elemento: «nombre, Persona, en N
    recuerdos», sin anunciar el símbolo aparte.
  - S1: los encabezados de década y, en S4/S5/S7, las cabeceras de sección aparecen
    en el rotor «Encabezados» (en S5 la cabecera con el nombre, en S7 «Privacidad»,
    «Memoria de ejemplo», «Acerca de»).
  - S2: al tocar «Entender y guardar» se oye «Leyendo tu recuerdo…», después cada
    elemento que aparece y, si falla, el aviso.
  - S4 de un recuerdo guardado sin analizar: «Deja que Hilo lea este recuerdo» anuncia
    «Leyendo tu recuerdo…» y, si falla, el aviso; «Guardado sin analizar» es encabezado.
  - S3 Revisión: quitar un chip anuncia «nombre, tipo, fuera de este recuerdo» y el
    foco aterriza en «Deshacer»; deshacer devuelve el foco a la X; «No es José» deja
    el foco sobre José en «Lo que Hilo ha entendido»; responder una duda deja el foco
    sobre el nombre en su bloque nuevo. El foco nunca salta al principio de la hoja.
  - Momento de la conexión: se oye «Recuerdo guardado. Conectado con N recuerdos» al
    abrirse; si se corta con el anuncio de pantalla, anótalo (hallazgo 13).
  - S7: el borrado total con VoiceOver: las dos alertas se leen y confirman; tras
    borrar, VoiceOver aterriza en Memoria vacía.
- [ ] **Reducir movimiento**: la aparición de elementos al comprender y el trazo del
      momento de la conexión funden en vez de animarse; el anuncio es el mismo.
- [ ] **Control por botones / toque asistido** (si lo usas): «Añadir un alias», los
      chips de S4 y el botón Debug reciben el toque en toda su fila.

## 4. Diseño — cuatro apariencias (contrato 4, DEC-58)

Repite S1 (normal), S2, S3, momento de la conexión, S4, S5 y S7 en cada apariencia:
**claro**, **oscuro**, **claro + Aumentar contraste**, **oscuro + Aumentar contraste**
(Accesibilidad → Pantalla y tamaño del texto → Aumentar contraste).

- [ ] **Acciones secundarias en color de texto primario**, nunca azul del sistema:
      «Cerrar», «Cancelar», «Añadir una foto», «Guardar sin analizar», «Deshacer»,
      «No es José», «Hecho» del momento, «Cambiar nombre», botones no destructivos de
      las alertas. El acento terracota queda solo para la acción principal, el
      selector, contar, lo que conecta y «Cargar la memoria de ejemplo» / «Añadir un
      alias». Juzga tú si «No es José» y «Deshacer» se reconocen como pulsables
      (MINOR-4 del cierre); si no, se les pone estilo con borde.
- [ ] **Alto contraste**: las tarjetas de S1, S4, momento de la conexión y S7 llevan
      contorno (`borde-tarjeta`); los chips de elemento llevan contorno
      (`borde-chip-nuevo`); en claro con más contraste las tarjetas de Ajustes se
      distinguen del fondo solo por ese contorno. En claro y oscuro normales no hay
      contorno.
- [ ] El tipo de un elemento nunca se distingue solo por color: símbolo + texto
      siempre presentes; en escala de grises (Accesibilidad → Filtros de color) se
      siguen distinguiendo.
- [ ] Ningún texto sobre una foto; el fondo `fondo` bajo todas las barras; sin
      iconografía de IA.

## 5. Modo avión (criterio de la spec)

- [ ] Activa el modo avión y repite las secciones 1 y 3 (al menos una captura con
      «Entender y guardar», el borrado total y la carga del ejemplo): la app funciona
      exactamente igual.

## Notas conocidas, sin acción pendiente

- `docs/validacion-manual/F5-explorar.md` sigue nombrando el botón Debug «Wipe all
  data»; desde F8 el borrado es el producto («Borrarlo todo» con doble confirmación).
- Las claves «Debug» y «Load validation dataset» siguen sin extraerse al catálogo:
  bajo `#if DEBUG`, nunca en Release.
- Textos pendientes de decisión de Rubén, no bloqueantes (hallazgos 15, 16 y 3 de
  F8.3; MINOR-5 del cierre): recuento de resultados de búsqueda para VoiceOver, hint
  del chip de filtro activo, anuncio al responder una duda, hint «Toca dos veces para
  cambiar el nombre» → «Cambia el nombre».
- Fuera de F8: al reabrir Captura tras guardar sin analizar, el banner «Recuerdo
  guardado» sigue ahí hasta escribir; en S4 de un recuerdo sin analizar conviven «Hilo
  no ha reconocido…» y «Guardado sin analizar».
- `tokens.md` 1.6 propuesto (AccentColor = texto-primario; grosor de
  `borde-chip-nuevo`), pendiente de escribirse en `main`.
