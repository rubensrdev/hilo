# Validación manual — F3 Comprensión

Batería para dispositivo físico real, no simulador: comprueba la comprensión con el
modelo de verdad, que en los tests siempre está sustituido por dobles. Contrastada contra
`docs/specs/F3_Comprension.md` (bloque "En dispositivo").

F3 no tenía interfaz propia: la batería usa la captura y la revisión de F4 para ver lo que
entiende el modelo. Lo que se valida aquí es la comprensión; las pantallas tienen su
batería en `F4-captura-y-revision.md`.

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone (build Debug), con el iPhone en
   **español** y Apple Intelligence activado (`F0.2-spike-foundation-models.md` §2).
2. Memoria → engranaje (Ajustes) → **Borrarlo todo** → Continuar → Borrarlo todo.
3. **Activa el modo avión** y déjalo puesto en §1 y §2. Así esas secciones validan también
   el criterio 3.

## 1. Aparición progresiva (criterio 1)

- [ ] Cuenta, escribiendo:

      > Mi abuelo José me llevó a la Alhambra el verano del 87, y me dejó llevar su reloj de bolsillo todo el día.

      Pulsa **Entender y guardar**. Se ve «Leyendo tu recuerdo…» y los elementos aparecen
      **de uno en uno**, en el orden en que salen en el relato: José, la Alhambra, el reloj
      de bolsillo.
- [ ] Cuando se abre la revisión, **lo que había aparecido es lo que hay**: los mismos
      elementos, ni uno más ni uno menos, con su tipo (persona, lugar, objeto) y su papel
      con tus palabras.
- [ ] **La fecha**: la revisión trae «el verano del 87» **literal**. En ningún sitio se ve
      «1987»: el año deducido nunca se enseña.
- [ ] **El relato no se toca**: en la revisión, «Tus palabras, tal como las escribiste»
      muestra el texto exacto, sin correcciones.
- [ ] Guarda. En Memoria el recuerdo cae en **Años 1980**: el año deducido solo ordena.
- [ ] **Sin fecha**: cuenta «Mi hermana Lucía me enseñó a hacer torrijas.» Aparece Lucía,
      no hay fecha entendida, y la revisión ofrece «Añade una fecha con tus palabras». Que
      no haya fecha no es un error. Guarda.
- [ ] **Fecha sin año**: cuenta «Un otoño, Lucía y yo fuimos a la playa de Salobreña.»
      La fecha entendida es «un otoño», o nada. Al guardar, en Memoria cae en **Sin
      fecha**.
- [ ] **Nada genérico**: cuenta «Hoy ha llovido toda la tarde y me he quedado en casa
      leyendo un libro.» No reconoce «la casa» ni «un libro» como elementos. Ver «Esta
      vez, sin nombres» es lo correcto. Guarda o cancela.
- [ ] **Nombres sin traducir**: con el iPhone en **inglés**, cuenta «My grandfather José
      gave me his watch in Granada.» Los nombres salen tal como los escribiste (José,
      Granada) y los papeles en inglés. Vuelve a español.

## 2. Cancelar a mitad

- [ ] Cuenta un recuerdo largo, pulsa **Entender y guardar** y, **mientras aparecen los
      elementos**, pulsa **Cancelar**. La lectura se para sin ningún error, vuelves a la
      captura con tu texto intacto y en Memoria no hay ningún recuerdo nuevo.
- [ ] Desde ahí, **Entender y guardar** vuelve a leer el relato desde cero.

## 3. Sin Apple Intelligence (criterio 2)

> **Hazlo al final, y a ser posible no en el iPhone de demo.** Al volver a activar Apple
> Intelligence el sistema puede tener que descargar el modelo otra vez.

- [ ] Ajustes del sistema → Apple Intelligence y Siri → desactiva Apple Intelligence.
- [ ] En Hilo, cuenta «Comí con Lucía en Sevilla.» y pulsa **Entender y guardar**. La app
      **no falla**: sale «Tu recuerdo está guardado tal como lo contaste», con «Hilo no ha
      podido leerlo esta vez…» en color de aviso, y los botones **Volver a leerlo** y
      **Dejarlo así**.
- [ ] **Ningún texto habla del dispositivo**, de Apple Intelligence ni de ajustes del
      sistema. Es el mismo aviso que cualquier otro fallo de lectura.
- [ ] Pulsa **Dejarlo así**. En Memoria el recuerdo está **guardado sin analizar**, con el
      texto íntegro, y su detalle ofrece **Deja que Hilo lea este recuerdo**.
- [ ] Vuelve a activar Apple Intelligence y espera a que el modelo esté listo. Desde el
      detalle, **Deja que Hilo lea este recuerdo**: ahora lo lee, y al guardar es el
      mismo recuerdo, ya analizado.

## 4. Sin conexión (criterio 3)

- [ ] §1 y §2 se han hecho en modo avión. Si alguno falló solo con el modo avión puesto,
      anótalo aquí.
- [ ] Repite la prueba de §3 en modo avión: el resultado es el mismo.

## Notas conocidas, sin acción pendiente

- Lo que reconoce el modelo no es determinista: el mismo relato puede dar un papel
  redactado distinto, o no dar la fecha «un otoño». Lo que vale es la regla (lo nombrable
  sí, lo genérico no; la fecha literal; el año nunca a la vista), no la palabra exacta.
- El desbordamiento de contexto se provoca a mano con un relato muy largo, y está en
  `F4-captura-y-revision.md` §2. El resto de errores (guardarraíl, rechazo, idioma no
  soportado, decodificación) no se pueden provocar a voluntad: los cubren los tests.
- No hay precalentamiento de la sesión, aunque la spec lo pedía: el spike midió que no
  acorta la espera hasta el primer elemento y hace menos estable el tiempo total.
