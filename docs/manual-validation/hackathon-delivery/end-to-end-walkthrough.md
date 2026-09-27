# Validación manual — Entrega del hackathon, de principio a fin

Recorrido completo de la app tal como se entrega: **F0.1 a F5 más F8** (sin F6, F7, F9 ni F10).
Se sigue de una sentada, pantalla a pantalla, en un iPhone real, y cada paso deja la memoria
en el estado que necesita el siguiente. Si un paso falla, anota el número y sigue: casi nada
depende de que el anterior haya salido perfecto, y donde sí depende se dice.

No repite la matriz de accesibilidad ni la de apariencias: están en
`docs/manual-validation/F5-explore.md` (§6 AX5 y VoiceOver, §7 claro/oscuro) y en
`docs/manual-validation/F8-settings-spanish-accessibility.md` (§3 accesibilidad, §4 las cuatro
apariencias). Pásalas aparte, o por encima del estado en que queda la memoria tras el paso 9.

Duración aproximada: 30–40 minutos.

## Qué datos se usan

- **Tus recuerdos de prueba**, que cuentas tú durante el recorrido. Los textos van escritos
  abajo y son inventados. Salvo el relato del paso 5, que nombra a propósito a Nines y Marcos
  para provocar la duda y los reconocimientos, **no comparten ningún nombre con la memoria de
  ejemplo**, así los recuentos salen exactos. «El mercado de Triana» es un lugar distinto de
  «Triana».
- **El set de validación**, que se carga desde Ajustes → **Debug** → **Load validation
  dataset**. Es la memoria de ejemplo (`docs/content/example-memory.md`, once recuerdos) más
  los dos recuerdos sintéticos de F5 (`DebugValidationContent.swift`), trece en total:
  - **A**: Marta y el parque, «por 1990». Marta nunca se nombra en el relato.
  - **B**: un relato largo con Martina y la bicicleta vieja, sin fecha.
- **La memoria de ejemplo del producto**, que se carga desde el vacío o desde Ajustes →
  **Cargar la memoria de ejemplo**. Son los mismos once recuerdos, sin A ni B.

Cómo se cubre cada capacidad:

| Capacidad | La cubre |
|---|---|
| Conexión por persona, lugar y objeto; décadas; «sin fecha»; hebras sueltas | La memoria de ejemplo |
| Búsqueda que solo encuentra por el elemento; extracto centrado; colisión al renombrar | Los recuerdos A y B del set de validación |
| Dudas de identidad; rechazar y confirmar reconocimientos | Tus recuerdos de prueba contra el set cargado. El ejemplo, a propósito, no trae dudas |
| Foto, dictado, guardar sin analizar, comprender más tarde | Tus recuerdos de prueba |

No hacía falta ampliar ningún dato: lo que no cubre la memoria de ejemplo lo cubren A y B, o
sale solo al contar un recuerdo nuevo sobre el set.

> **Ojo con el orden:** «Load validation dataset» no hace nada si ya hay una memoria de ejemplo
> cargada (usa la misma guarda que no deja duplicarla). Por eso el paso 1 borra el ejemplo antes
> de que el paso 4 cargue el set.

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone, **en Debug**. La sección Debug de
   Ajustes solo existe en esa configuración.
2. Pon el iPhone en **español** (General → Idioma y región). Comprueba que Apple Intelligence
   está activado.
3. **Activa el modo avión y no lo quites en todo el recorrido.** Así el recorrido entero valida
   también que la app funciona sin conexión.
4. Si la app ya tiene datos: Memoria → engranaje (Ajustes) → **Borrarlo todo** → Continuar →
   Borrarlo todo. El borrado total se valida en detalle en el paso 12; aquí solo sirve para
   partir de cero.
5. Ten a mano una foto cualquiera en Fotos, **mejor un objeto o un paisaje, sin personas**.

---

## 1. Primera vez: la memoria vacía y el ejemplo

- [ ] **Vacío de primera vez**: se ve la promesa («Hilo recuerda las personas, los lugares y
      los objetos de tus recuerdos, y los conecta por ti.»), el aviso de privacidad **una sola
      vez** («Todo se queda en tu iPhone. Sin cuenta ni conexión.») y dos salidas: **Cuenta tu
      primer recuerdo** y **Cargar una memoria de ejemplo**.
- [ ] La pestaña **Preguntar** muestra «Preguntar llega pronto». Es lo esperado en esta entrega.
- [ ] Pulsa **Cargar una memoria de ejemplo**. Aparecen once recuerdos agrupados en «Años
      2010», «Años 2000», «Años 1990», «Años 1980», «Años 1970» y «Sin fecha». El grupo «Sin
      fecha» lleva los dos recuerdos de la abuela Mercedes: el del jersey verde (sin fecha) y
      el de la tarta de manzana («el verano que cumplí quince años»).
- [ ] Ajustes → **Borrar la memoria de ejemplo** → «¿Borrar la memoria de ejemplo?» → **Borrar
      el ejemplo**. El botón pasa a «Cargar la memoria de ejemplo» sin cerrarse la hoja. Pulsa
      **Cerrar**: Memoria vuelve al vacío de primera vez.

## 2. Contar escribiendo: el primer recuerdo es el comienzo

Pulsa **Cuenta tu primer recuerdo** (en adelante, el botón de contar de la barra de Memoria).

- [ ] **Vacío**: el texto de ayuda es un recuerdo de verdad («Triana, verano de 1979. Nines
      y yo…»), no una instrucción. **Entender y guardar** está desactivado y **Guardar sin
      analizar** está visible.
- [ ] **Escribiendo**: escribe

      > Comí con mi hermana Ana en el mercado de Triana, en la Semana Santa de 2019.

      Entender y guardar se activa.
- [ ] **Comprendiendo**: pulsa **Entender y guardar**. Se ve «Leyendo tu recuerdo…» y los
      elementos aparecen de uno en uno (Ana, el mercado de Triana), cada uno con su color,
      símbolo y tipo.
- [ ] **Revisión como comienzo**: se abre la hoja de revisión con «Tus palabras, tal como las
      escribiste», el relato intacto y «Aquí empiezan los hilos», además de «Es la primera vez
      que aparecen…». **Nunca** se presenta como un fallo. No hay bloque «Ya estaba en tu
      memoria» ni «Hilo no está seguro».
- [ ] **La fecha entendida**: «la Semana Santa de 2019», editable. No la toques.
- [ ] **Quitar y deshacer**: quita «el mercado de Triana» con su X. Queda «Fuera de este
      recuerdo» con **Deshacer**; pulsa Deshacer y vuelve con su papel.
- [ ] **Renombrar un elemento nuevo**: toca Ana → «¿Cambiar el nombre de Ana?» **sin**
      mensaje de alcance, porque es nueva y no afecta a nada más. Cancela.
- [ ] Pulsa **Guardar recuerdo**. Como no hay conexiones no hay momento de la conexión: la
      revisión se cierra y la captura queda vacía, lista para otro. Ciérrala con **Cancelar**.
- [ ] **Un solo recuerdo** en Memoria: su tarjeta, «Aquí empiezan las conexiones.» y el botón
      **Cuenta un segundo recuerdo**.

## 3. Contar dictando y con foto: la primera conexión

Pulsa **Cuenta un segundo recuerdo**.

- [ ] **Con foto**: pulsa **Añadir una foto**, elige la foto preparada y comprueba que se ve la
      miniatura con **Quitar la foto**. Añadir la foto antes de escribir también vale.
- [ ] **Dictando**: con el micrófono del teclado del sistema, dicta

      > Ana me enseñó a hacer torrijas en su cocina de Sevilla.

      Hilo no graba audio: el texto lo pone el dictado del sistema.
- [ ] **Cerrar la revisión sin guardar**: Entender y guardar → cuando se abra la revisión,
      desliza la hoja hacia abajo. Vuelves a la captura con **el relato y la foto intactos** y
      con Entender y guardar disponible.
- [ ] Vuelve a pulsar **Entender y guardar**. La revisión trae **Ya estaba en tu memoria**:
      «Ana · en 1 recuerdo», sin contar el que estás guardando. Sevilla aparece en «Lo que
      Hilo ha entendido» como nueva.
- [ ] Guarda. **Momento de la conexión**: «Recuerdo guardado», tu relato, «Conectado con 1
      recuerdo», el recuerdo del mercado con el motivo **«Por Ana»** y el trazo que los une.
      Pulsa **Hecho**.
- [ ] Todo el paso 2 más este paso lleva **menos de un minuto** por recuerdo cuando no te paras
      a comprobar (criterio 1 de F4).

## 4. Cargar el set de validación

- [ ] Ajustes → sección **Debug** → **Load validation dataset** → Cerrar. Memoria muestra tus
      dos recuerdos más los trece del set, agrupados por década. Tus recuerdos siguen intactos.
- [ ] El botón «Cargar la memoria de ejemplo» de Ajustes pasa a «Borrar la memoria de
      ejemplo»: el set cuenta como ejemplo.

## 5. Resolver identidades ambiguas

Este paso es el único donde el orden importa: primero se prueba todo y se cancela; después se
guarda de verdad.

Pulsa el botón de contar y escribe

> Merendamos con Nines García y Marcos en el parque, y luego fuimos a la heladería Los Italianos.

Entender y guardar. **Plan B**: si Hilo solo reconoce «Nines» en vez de «Nines García»,
cancela y escribe «mi amiga Nines García».

**Primera pasada: probar y cancelar**

- [ ] Están los **cuatro bloques**, cada uno solo con contenido:
  - **Lo que Hilo ha entendido**: la heladería Los Italianos, nueva.
  - **Ya estaba en tu memoria**: Marcos «en 2 recuerdos» (la Vespa amarilla y la boda) y el
    parque «en 1 recuerdo» (el recuerdo A).
  - **Hilo no está seguro**: «¿Nines García es Nines, que ya estaba en tu memoria?», con **Sí,
    es Nines** y **Otra persona** del mismo peso y ninguna preseleccionada, más «Puedes
    guardar sin responder. Hilo los mantendrá separados.». Es una duda y no una coincidencia:
    «nines garcia» y «nines» no son el mismo canónico, pero «nines» está contenido como palabra
    completa en el otro, y los dos son personas.
  - **La fecha**: sin fecha entendida, con «Añade una fecha con tus palabras».
- [ ] **Renombrar un existente hacia un nombre ocupado**: toca Marcos → el aviso de alcance
      («Marcos aparece en otros 2 recuerdos. El nombre nuevo también se verá allí.») → escribe
      «Lucía» → se bloquea con «Lucía ya existe» y «Elige otro nombre, o cambia antes el nombre
      de Lucía.». Lucía existe como persona por el recuerdo del informe del ejemplo (2018). Al
      cerrarlo vuelves al campo con «Lucía» tal como estaba. Cancela.
- [ ] **Renombrar un existente sin colisión**: toca el parque → escribe «el parque del Retiro» →
      acepta. Queda pendiente: solo se aplicaría al guardar.
- [ ] **Renombrar un nuevo hacia un nombre existente**: toca la heladería Los Italianos →
      escribe «Triana» → pasa a **Ya estaba en tu memoria** como reconocimiento de Triana
      (recuerdos 1 y 9), y se puede rechazar. «El mercado de Triana» también es un lugar y se
      parece, pero la coincidencia exacta va antes que la duda: se reconoce Triana, sin duda con
      el mercado.
- [ ] **Rechazar un reconocimiento**: en Marcos pulsa **No es Marcos**. Pasa a «Lo que Hilo ha
      entendido» como nuevo. Con VoiceOver, el foco se queda sobre Marcos.
- [ ] **Cancela la revisión** deslizando la hoja. Vuelves a la captura con el relato intacto.

**Segunda pasada: guardar de verdad**

- [ ] Pulsa otra vez **Entender y guardar**. La revisión vuelve a estar **limpia**: el parque se
      llama «el parque», Marcos está en «Ya estaba en tu memoria», la heladería es nueva y la
      duda está sin responder. Nada de la primera pasada ha quedado.
- [ ] Responde **Sí, es Nines**: Nines García pasa a «Ya estaba en tu memoria» como Nines, y se
      ve «Hilo reconocerá este nombre para Nines en futuros recuerdos.».
- [ ] Guarda. **Momento de la conexión**: «Conectado con 7 recuerdos», cada uno una sola vez.
      Los motivos: «Por Nines» en la bici en Triana (1), la máquina de escribir (2), Bolonia (4)
      y el reencuentro en Triana (9); «Por Nines y Marcos» en la boda (5); «Por Marcos» en la
      Vespa amarilla (3); «Por el parque» en el recuerdo de Marta (A). Hecho.

**Editar la fecha**

- [ ] Cuenta otro:

      > José Antonio me enseñó a nadar en la playa de Salobreña el verano de 1999.

      Guardar sin responder una duda de nombre repetido queda fuera de esta entrega: el ejemplo
      nuevo no tiene un caso equivalente, y no se inventa un nombre para forzarlo. José Antonio
      llega como persona nueva, sin duda.
- [ ] **Regla de la fecha**: edita «el verano de 1999» a «el verano del 99».
- [ ] Guarda. Como no hay conexiones no hay momento: José Antonio queda separado. Cierra la
      captura.
- [ ] En Memoria, ese recuerdo está en **«Sin fecha»**, aunque su tarjeta muestra «el verano del
      99»: de un texto editado nunca se deduce un año.

## 6. Guardar sin analizar y comprender más tarde

- [ ] Cuenta:

      > Cumpleaños de Ana, con tarta de chocolate.

      Pulsa **Guardar sin analizar**. Aparece «Recuerdo guardado». Cierra la captura.
- [ ] Abre ese recuerdo (S4): se ven «Guardado sin analizar», **Deja que Hilo lea este
      recuerdo** y ningún elemento.
- [ ] **Editar no reanaliza**: pulsa **Editar**, cambia el relato a «Cumpleaños de Ana en
      Sevilla, con tarta de chocolate.» y guarda. Sigue sin elementos.
- [ ] Pulsa **Deja que Hilo lea este recuerdo**: «Leyendo tu recuerdo…» y la revisión del relato
      **actual**, con Ana «en 2 recuerdos» y Sevilla «en 1 recuerdo» en Ya estaba en tu
      memoria. Guarda.
- [ ] Es **el mismo recuerdo**, no uno nuevo: ya no dice «Guardado sin analizar», tiene sus
      elementos y conexiones, y en Memoria no se ha movido de sitio.
- [ ] **Editar un recuerdo analizado**: abre el del mercado de Triana, Editar, quita «de Triana»
      y guarda. «El mercado de Triana» sigue siendo su elemento: editar no toca lo confirmado.

## 7. Errores de comprensión (opcional)

Solo uno se puede provocar a mano con garantía. El resto está cubierto por tests.

- [ ] **Recuerdo demasiado largo**: pega en la captura un texto muy largo (un párrafo copiado
      muchas veces, unas 3.000 palabras) y pulsa Entender y guardar. Sale el aviso «Este recuerdo
      es demasiado largo para que Hilo lo lea de una vez…» en color de aviso, nunca de error, y
      **un único botón**, sin volver a leerlo. El texto queda guardado sin analizar. Bórralo
      después desde su detalle.
- [ ] Si algún recuerdo falla por otra razón (un error genérico), comprueba que el aviso ofrece
      **Volver a leerlo** y **Dejarlo así**, y que el texto está a salvo.

## 8. Recorrer la memoria

**Por orden cronológico** (Memoria → Recuerdos)

- [ ] Décadas de la más reciente a la más antigua: «Años 2010» (tu mercado de Triana, el
      informe con Lucía, la vuelta a Bolonia y el reencuentro en Triana), «Años 2000» (el vecino
      Rafa y la boda de Nines), «Años 1990» (Bolonia con Nines, Marcos en la Vespa y Marta,
      «por 1990»), «Años 1980» (la máquina de escribir) y «Años 1970» (la bici en Triana). Al
      final va **«Sin fecha»**, con los dos recuerdos de la abuela Mercedes, Martina, José
      Antonio y los recuerdos sin fecha que contaste. Los recuerdos de Sevilla caen en el grupo
      que corresponda según lo que Hilo entendiera de su fecha. Ningún encabezado muestra una
      fecha que no escribiste.

**Por elemento** (Memoria → Personas, lugares y objetos)

- [ ] Filtros **Todos / Personas / Lugares / Objetos**. Personas incluye a Nines (en 6
      recuerdos), Marcos (en 3), la abuela Mercedes (en 2), Ana, Lucía, tío Paco, el vecino
      Rafa, José Antonio (en 1), Marta y Martina. Objetos incluye la Vespa (en 3). Cada fila lleva
      símbolo, tipo en texto y recuento.
- [ ] **S5 de Nines**: nombre, tipo, «También conocido como: Nines García», «Nines aparece en 6
      recuerdos», el rango temporal con las palabras del usuario y la lista en el mismo orden
      que Memoria.
- [ ] **S5 de una hebra suelta** (tío Paco, el vecino Rafa, Salobreña o la heladería): un solo
      recuerdo, invitación a contar otro, sin rango.
- [ ] **Renombrar desde S5, con colisión**: Martina → «Marta» → se bloquea. **Sin colisión**:
      Martina → «Martina Ruiz» → se aplica, y Memoria y S4 lo reflejan al volver.
- [ ] **Añadir un alias** a Ana («Anita»). Repetirlo no lo duplica.

**Navegación y conexiones**

- [ ] Personas → Nines → el recuerdo de la boda (S4) → Marcos (S5) → Marcos en la Vespa (S4)
      → la Vespa (S5) → uno de sus recuerdos → vuelta atrás hasta Memoria sin perderse.
- [ ] **S4 con foto** (torrijas): la foto se ve entera, sin recortar, bajo el relato y **sin
      texto encima**. Los conectados muestran su motivo («Por Ana»).
- [ ] **S4 sin conexiones** (José Antonio): «Todavía sin conectar».

## 9. Buscar

En Memoria → Recuerdos, en «Busca en tus recuerdos»:

- [ ] «Vespa»: encuentra por el relato, con la coincidencia resaltada en el extracto.
- [ ] «Marta»: encuentra el recuerdo A **solo por el elemento** (el relato dice «ella»), y la
      tarjeta enseña a Marta para explicar por qué aparece.
- [ ] «bicicleta»: el extracto de Martina se centra en la coincidencia, no en el principio.
- [ ] «Nines García»: encuentra el recuerdo de la merienda por el relato y por el alias.
- [ ] «Marcos»: el recuerdo de la Vespa amarilla y el de la boda salen **una vez cada uno**,
      aunque coincidan por el relato y por el elemento.
- [ ] «xyz»: «Nada coincide todavía», distinto del vacío de primera vez.

## 10. Borrar un recuerdo

- [ ] Abre el de José Antonio → **Borrar recuerdo** → el texto de «¿Borrar este recuerdo?» dice
      que **José Antonio y la playa de Salobreña desaparecen**, porque no tienen más recuerdos.
      Confirma. En Personas ya no está José Antonio.
- [ ] Abre el de las torrijas (con foto) → Borrar → el texto dice que **Ana se queda, con sus
      otros recuerdos**, y que tus palabras y tu foto se borran. Confirma. Ana sigue en
      Personas con un recuerdo menos.

## 11. La memoria de ejemplo desde Ajustes

- [ ] Ajustes → **Borrar la memoria de ejemplo** → Borrar el ejemplo. Cierra: solo quedan **tus**
      recuerdos. **Nines sigue existiendo**, con su alias Nines García y un único recuerdo (la
      merienda). Marcos y el parque también siguen, con un recuerdo cada uno. Lucía, Marta,
      Martina, la abuela Mercedes, la Vespa, Triana y el resto del ejemplo han desaparecido.
- [ ] Ajustes → **Cargar la memoria de ejemplo**: vuelven los once recuerdos **en español**,
      sin A ni B, y Nines recupera sus conexiones con tu merienda (en 6 recuerdos); Marcos
      vuelve a estar en 3. Cargarlo otra vez no duplica nada.

## 12. Borrado total

- [ ] Ajustes → **Borrarlo todo** → «¿Borrarlo todo?», con el texto de todo lo que desaparece
      (recuerdos, personas, lugares y objetos, fotos) → **Continuar** → «¿Borrarlo todo para
      siempre?» («No se puede deshacer. No hay copia en ningún otro sitio.») → **Cancelar**. No
      se ha borrado nada.
- [ ] Repite y confirma **Borrarlo todo**. La hoja se cierra sola y Memoria muestra el vacío de
      primera vez, con el selector en «Recuerdos» y sin búsqueda ni filtro.
- [ ] **Mata la app y ábrela otra vez**: arranca en el vacío de primera vez. No vuelve nada, ni
      las fotos.

## 13. Accesibilidad y apariencia

No se repite aquí. Pasa `F5-explore.md` §6–§7 y `F8-settings-spanish-accessibility.md` §3–§4
(AX5, VoiceOver, Reducir movimiento y las cuatro apariencias) sobre la memoria del paso 9, o
vuelve a cargar el set de validación después del paso 12. Si quieres una comprobación rápida
dentro de este recorrido, en el paso 5 con VoiceOver: quitar un chip anuncia «…, fuera de este
recuerdo» y el foco nunca salta al principio de la hoja.

---

## Notas conocidas, sin acción pendiente

- Todo el recorrido se ha hecho en modo avión: si ha salido bien, también está validado el
  criterio de funcionar sin conexión.
- Las dudas de identidad, el reconocimiento de una variante de nombre y los recuentos del
  momento de la conexión dependen de lo que entienda el modelo. Si Hilo extrae un nombre distinto, lo que
  vale es la regla (mismo tipo, nombre contenido en el otro → duda), no la cifra exacta.
- La sección Debug de Ajustes («Debug», «Load validation dataset») está en inglés: nunca se
  compila en Release.
- `F5-explore.md` sigue nombrando el botón Debug «Wipe all data». Desde F8, el borrado es el
  producto («Borrarlo todo»).
- Ya anotado en F8, fuera de alcance: al reabrir Captura tras guardar sin analizar, el banner
  «Recuerdo guardado» sigue ahí hasta que escribes. En S4 de un recuerdo sin analizar conviven
  «Hilo no ha reconocido…» y «Guardado sin analizar».
