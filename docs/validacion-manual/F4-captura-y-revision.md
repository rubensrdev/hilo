# Validación manual — F4 Captura y revisión

Batería para dispositivo físico real, no simulador: comprueba las dos pantallas donde
ocurre el producto, contar y revisar, con el modelo de verdad, VoiceOver, Tipografía
Dinámica y dictado. Contrastada contra `docs/specs/F4_Captura_y_Revision.md` (bloque
"En dispositivo"), que fue también el punto de control A: si los criterios 1 y 2 no
pasan, el resto de la app no tiene sentido.

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone (build Debug), con el iPhone en
   **español** y Apple Intelligence activado.
2. Memoria → engranaje (Ajustes) → **Borrarlo todo** → Continuar → Borrarlo todo.
   **No cargues todavía** ni el ejemplo ni el set de validación: §1 necesita una memoria
   vacía para ver el comienzo y la primera conexión.
3. **Activa el modo avión y déjalo puesto en toda la batería.** Así la batería entera
   valida también el criterio 5.
4. Ten a mano una foto cualquiera en Fotos, mejor sin personas.

## 1. Los criterios 1 y 2: contar en menos de un minuto y ver la conexión

- [ ] **Criterio 1, escribiendo**: pon un cronómetro. Pulsa **Cuenta tu primer
      recuerdo**, escribe

      > Comí con mi hermana Lucía en el mercado de Triana, en la Semana Santa de 2019.

      pulsa **Entender y guardar**, revisa sin tocar nada y pulsa **Guardar recuerdo**.
      Lleva **menos de un minuto**.
- [ ] **Criterio 1, dictando**: pulsa **Cuenta un segundo recuerdo** y, con el micrófono
      del teclado, dicta

      > Lucía me enseñó a hacer torrijas en su cocina de Sevilla.

      Entender y guardar → Guardar recuerdo. También **menos de un minuto**, dictado
      incluido.
- [ ] **Criterio 2**: al guardar el segundo, **sin hacer nada más**, aparece el momento de
      la conexión: «Recuerdo guardado», «Conectado con 1 recuerdo», el recuerdo del
      mercado con el motivo **«Por Lucía»** y el trazo que los une. Se ve **por qué** se
      conectan sin abrir nada. Pulsa **Hecho**.

## 2. Los cinco estados de la captura (criterio 3)

Abre la captura desde el botón de contar de Memoria.

- [ ] **Vacío**: el texto de ayuda es un recuerdo de verdad («Mi abuelo José me regaló su
      reloj…»), no una instrucción. **Entender y guardar** está desactivado y **Guardar
      sin analizar** está visible.
- [ ] **Escribiendo**: al escribir una letra, Entender y guardar se activa. Guardar sin
      analizar sigue visible.
- [ ] **Con foto**: **Añadir una foto** abre el selector del sistema. Elegida la foto, se ve
      su miniatura con **Quitar la foto**. Sirve igual antes o después de escribir. Quitarla
      deja el texto intacto.
- [ ] **Comprendiendo**: con texto, pulsa Entender y guardar. Se ve «Leyendo tu
      recuerdo…», los elementos van apareciendo de uno en uno con color, símbolo y tipo,
      y arriba hay **Cancelar**, que para la lectura y deja el texto y la foto.
- [ ] **Error de comprensión**: pega un texto muy largo (un párrafo copiado muchas veces,
      unas 3.000 palabras) y pulsa Entender y guardar. Sale «Tu recuerdo está guardado
      tal como lo contaste» con «Este recuerdo es demasiado largo para que Hilo lo lea de
      una vez…», en **color de aviso, nunca de error**, y un único botón, **Hecho**, sin
      volver a leerlo. El texto queda guardado sin analizar: bórralo después desde su
      detalle.
- [ ] Si en algún momento sale el aviso genérico («Hilo no ha podido leerlo esta vez…»),
      comprueba que ofrece **Volver a leerlo** y **Dejarlo así**. Solo este aviso ofrece
      reintentar.
- [ ] **Guardar sin analizar**: cuenta «Cumpleaños de Lucía, con tarta de chocolate.» y
      pulsa Guardar sin analizar. Sale «Recuerdo guardado» y la captura queda lista para
      otro.

## 3. Los cuatro estados de la revisión (criterio 3)

**El comienzo** ya se vio en §1 con el primer recuerdo. Si quieres volver a verlo, cuenta
algo cuyos nombres no estén en tu memoria:

- [ ] **Comienzo**: «Aquí empiezan los hilos» con «Es la primera vez que aparece…» o «…que
      aparecen…», según sean uno o varios. **Nunca** se presenta como un fallo. Sin
      bloques «Ya estaba en tu memoria» ni «Hilo no está seguro».

Ahora carga el set: Ajustes → **Debug** → **Load validation dataset** → Cerrar.

- [ ] **Con conexiones**: cuenta «Volví a Granada con Carmen el año pasado.» La
      revisión trae **Ya estaba en tu memoria** con Carmen y Granada, cada una con
      «en N recuerdos» **sin contar el que estás guardando**. Cada reconocimiento lleva su
      **No es Carmen** / **No es Granada**. Rechaza Granada: pasa a «Lo que Hilo ha
      entendido» como nueva. Rechaza también Carmen: la pantalla **pasa en vivo** a ser el
      comienzo. Cancela deslizando la hoja: vuelves a la captura con el relato intacto.
- [ ] **Con dudas**: cuenta «Merendamos con José Luis en el parque.» La revisión trae
      **Hilo no está seguro**: «¿José Luis es José, que ya estaba en tu memoria?», con
      **Sí, es José** y **Otra persona** del mismo peso y **ninguna preseleccionada**, y
      «Puedes guardar sin responder. Hilo los mantendrá separados.». **Guardar recuerdo**
      está disponible sin responder. Responde **Sí, es José**: se ve «Hilo reconocerá este
      nombre para José en futuros recuerdos.». Cancela.
- [ ] **Sin nada reconocido**: cuenta «Hoy ha llovido toda la tarde y me he quedado en
      casa leyendo.» La revisión dice «Esta vez, sin nombres» y que se guardará con tus
      palabras. **No dice que ya esté guardado** antes de pulsar Guardar recuerdo. Guarda.

**Acciones de la revisión**, sobre «Merendamos con José Luis y la tía Carmen en el parque,
y luego fuimos a la heladería Los Italianos.»:

- [ ] **Quitar y deshacer**: quita la heladería con su X. Queda «Fuera de este recuerdo»
      con **Deshacer**, que la devuelve con su papel.
- [ ] **Renombrar un nuevo**: toca la heladería → «¿Cambiar el nombre de…?» **sin** mensaje
      de alcance.
- [ ] **Renombrar un existente**: toca Carmen → el aviso dice en cuántos **otros**
      recuerdos aparece y que el nombre nuevo también se verá allí. Escribe «Pilar»: se
      **bloquea** con «Pilar ya existe». Al cerrar vuelves al campo con «Pilar» tal como
      estaba. Cancela.
- [ ] **Renombrar un nuevo hacia un existente**: renombra la heladería a «Granada»: pasa a
      **Ya estaba en tu memoria** como reconocimiento de Granada, rechazable.
- [ ] **El renombrado es pendiente**: renombra el parque a «el parque del Retiro» y
      **cancela** la revisión. Vuelve a pulsar Entender y guardar: el parque se sigue
      llamando «el parque», y en Memoria → Personas, lugares y objetos también.
- [ ] **La fecha**: sin fecha entendida, la revisión ofrece «Añade una fecha con tus
      palabras». Escribe «el verano pasado» y guarda: la tarjeta muestra tus palabras y el
      recuerdo cae en **Sin fecha**, porque de un texto escrito a mano nunca se deduce un
      año.

## 4. Comprender más tarde

- [ ] Abre el recuerdo del cumpleaños (§2): «Guardado sin analizar» y **Deja que Hilo lea
      este recuerdo**.
- [ ] Púlsalo: «Leyendo tu recuerdo…» y la misma revisión, con Lucía en «Ya estaba en tu
      memoria». Guarda: es **el mismo recuerdo**, en el mismo sitio de Memoria, ya con sus
      elementos.
- [ ] Cancelar esa revisión deja el recuerdo intacto y sin analizar.

## 5. Claro y oscuro (criterio 3)

- [ ] Repite los cinco estados de §2 y los cuatro de §3 en **modo oscuro**: contraste
      correcto; el aviso de error en color de aviso; persona, lugar y objeto siempre con
      símbolo y texto, nunca solo color; ningún texto sobre la foto.

## 6. AX5 y VoiceOver (criterio 4)

- [ ] **AX5** (Accesibilidad → Pantalla y tamaño del texto → Tamaños más grandes, al
      máximo):
  - Captura: el campo, la miniatura de la foto y los dos botones caben y responden; el
    texto de ayuda y el aviso de error se leen enteros.
  - Revisión: las filas, los chips y las dos respuestas de la duda se apilan; el relato
    **nunca se trunca**.
  - Momento de la conexión: las tarjetas se reorganizan y el motivo se lee entero.
  - Las alertas de renombrar son usables.
- [ ] **VoiceOver** en la captura:
  - Todos los botones tienen nombre: Añadir una foto, Quitar la foto, Entender y guardar,
    Guardar sin analizar, Cancelar.
  - Al pulsar Entender y guardar se oye «Leyendo tu recuerdo…» y después cada elemento
    que aparece, con su tipo («Lucía, Persona»). Si falla, se lee el aviso.
- [ ] **VoiceOver** en la revisión:
  - Un elemento conocido anuncia nombre, tipo y recuerdos («Carmen, Persona, en 2
    recuerdos»); uno nuevo, «…, primera vez». El tipo se anuncia una sola vez.
  - Quitar un chip anuncia «…, fuera de este recuerdo» y el foco va a **Deshacer**; el
    foco nunca salta al principio de la hoja.
  - En el momento de la conexión se oye «Recuerdo guardado. Conectado con N recuerdos», y
    cada conexión anuncia su motivo.
- [ ] **Reducir movimiento**: los elementos que aparecen y el trazo del momento de la
      conexión funden en vez de moverse; el anuncio es el mismo.

## 7. Modo avión (criterio 5)

- [ ] Toda la batería se ha hecho en modo avión. Si algo falló solo por eso, anótalo aquí.

## Notas conocidas, sin acción pendiente

- Los recuentos («en 2 recuerdos»), la duda de «José Luis» y el estado sin nada reconocido
  dependen de lo que entienda el modelo. Si extrae otro nombre, lo que vale es la regla,
  no la cifra ni la palabra exacta.
- «Load validation dataset» no hace nada si ya hay una memoria de ejemplo cargada: si
  repites la batería, empieza siempre por Borrarlo todo.
- El único error de comprensión que se provoca a voluntad es el desbordamiento. El resto
  lo cubren los tests, con el texto y el botón que corresponden a cada uno.
- Ya anotado en F8: al reabrir la captura tras guardar sin analizar, el banner «Recuerdo
  guardado» sigue ahí hasta que escribes.
- El recorrido completo de la entrega (`entrega-hackathon/recorrido-de-principio-a-fin.md`,
  pasos 2 a 7) pasa por estas mismas pantallas en otro orden. Si ya lo has hecho, esta
  batería solo añade la matriz de estados, AX5 y VoiceOver.
