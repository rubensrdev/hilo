# Validación manual — F2 Persistencia

Batería para dispositivo físico real, no simulador: comprueba que lo guardado sobrevive a
cerrar la app y que el borrado total la deja como el primer día. Contrastada contra
`docs/specs/F2_Persistencia.md` (bloque "En dispositivo").

F2 no tenía interfaz propia, así que la batería usa las pantallas que llegaron después
(captura, Memoria, detalle y Ajustes) solo como forma de escribir y leer el almacén. Lo
que se valida es el almacén, no esas pantallas.

«Matar la app» significa, en toda la batería, cerrarla desde el selector de apps
deslizándola hacia arriba, no solo volver a la pantalla de inicio.

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone (build Debug).
2. Memoria → engranaje (Ajustes) → **Borrarlo todo** → Continuar → Borrarlo todo.
3. Ten a mano una foto cualquiera en Fotos.

## 1. Lo guardado sigue ahí (criterio 1)

- [ ] Cuenta y guarda con **Entender y guardar** un recuerdo **con foto**:

      > Comí con mi hermana Lucía en el mercado de Triana, en la Semana Santa de 2019.

- [ ] Cuenta y guarda **sin foto** y con **Guardar sin analizar**:

      > Cumpleaños de Lucía, con tarta de chocolate.

- [ ] Carga la memoria de ejemplo (Ajustes → **Cargar la memoria de ejemplo**).
- [ ] **Mata la app y ábrela.** Están los siete recuerdos, en el mismo orden:
  - el del mercado conserva su **foto**, su fecha con tus palabras y sus elementos;
  - el del cumpleaños sigue **guardado sin analizar**;
  - la memoria de ejemplo sigue cargada, y Ajustes ofrece **Borrar la memoria de
    ejemplo**, no cargarla.
- [ ] **Cambios después de guardar**: añade el alias «Lu» a Lucía (Memoria → Personas,
      lugares y objetos → Lucía → Añadir un alias) y edita el relato del cumpleaños.
      Mata la app y ábrela: el alias y el relato editado siguen ahí.
- [ ] **Reinicia el iPhone** y abre la app: todo sigue igual.

## 2. Borrar es real

- [ ] Borra el recuerdo del mercado (el de la foto) desde su detalle. Mata la app y
      ábrela: no vuelve, ni su foto. Lucía sigue existiendo, con el recuerdo del
      cumpleaños.
- [ ] Borra la memoria de ejemplo desde Ajustes. Mata la app y ábrela: tus recuerdos
      siguen, y los del ejemplo no vuelven.

## 3. El borrado total (criterio 2)

- [ ] Vuelve a cargar la memoria de ejemplo y guarda un recuerdo más con foto.
- [ ] Ajustes → **Borrarlo todo** → Continuar → **Borrarlo todo**. Memoria muestra el vacío
      de primera vez.
- [ ] **Mata la app y ábrela**: arranca en el vacío de primera vez. No vuelve ningún
      recuerdo, ninguna persona, lugar u objeto, ninguna foto.
- [ ] Ajustes ofrece **Cargar la memoria de ejemplo**: el borrado total también ha quitado
      la marca de ejemplo cargado.

## 4. Sin conexión

- [ ] Repite §1 y §3 en **modo avión**: todo se comporta igual.

## Notas conocidas, sin acción pendiente

- Que la foto se guarda **sin metadatos de ubicación** está cubierto por test, y en el
  dispositivo no hay forma de verlo sin herramientas externas: la app nunca vuelve a
  exportar la foto.
- No hay migraciones: si el esquema cambia, hay que borrar la app y reinstalarla. En la
  build de la entrega el esquema no cambia.
- El borrado total se valida también, con sus dos confirmaciones, en
  `F8-ajustes-espanol-accesibilidad.md` §1. Aquí interesa lo que queda en el almacén, no
  las alertas.
