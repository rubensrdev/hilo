# Validación manual — F5 Explorar

Batería para dispositivo físico real, no simulador: verifica VoiceOver, Tipografía
Dinámica y comportamiento nativo que solo se puede juzgar de verdad en un iPhone.
Contrastada contra `docs/specs/F5_Explorar.md` (bloque "En dispositivo") y contra lo
que `verificador-ui` ya comprobó en simulador durante F5.4/F5.5.

## Preparación

1. Compila y ejecuta el esquema `Hilo` en tu iPhone (build Debug).
2. Ve a Memoria → icono de engranaje (Ajustes) → sección **Debug**. Esa sección solo
   existe en compilaciones Debug; en Release no aparece.
3. Pulsa **Wipe all data** para partir de un estado limpio, y confirma.
4. Pulsa **Load validation dataset**. Esto carga los 5 recuerdos de la memoria de
   ejemplo aprobada (José, Granada, la máquina de coser, la caja de latón, la boda de
   Carmen) más 2 recuerdos añadidos solo para esta batería:
   - **Recuerdo A** — persona **Marta** (nunca nombrada en el relato, solo "ella"),
     lugar **el parque**. Fecha "por 1990".
   - **Recuerdo B** — relato largo que menciona a **Martina** (persona) y **la
     bicicleta vieja** (objeto), con "bicicleta" pasada la mitad del texto. Sin fecha.

   Estos dos últimos son contenido sintético de prueba, no una memoria real — sirven
   para probar colisión de nombres, búsqueda que solo encuentra por elemento y
   extracto centrado, casos que la memoria de ejemplo no cubre por sí sola.

Repite el "wipe + load" cada vez que quieras reiniciar la batería desde cero.

## 1. Estados de S1 — Recuerdos (contrato 2)

- [ ] **Vacío** (tras wipe, antes de cargar nada): trae la promesa del producto, el
      aviso de privacidad una sola vez, y dos salidas — contar el primer recuerdo o
      cargar la memoria de ejemplo.
- [ ] **Un solo recuerdo**: guarda una única captura manual (S2) — invita
      explícitamente a contar el segundo.
- [ ] **Normal** (con el set de validación cargado): agrupado por década del año
      deducido; el grupo final "sin año" incluye tanto el recuerdo sin fecha (Martina)
      como el que tiene texto de fecha pero sin año deducido (la caja de latón).
- [ ] **Buscando con resultados**:
  - "reloj" → encuentra por el relato.
  - "Marta" → encuentra *solo* por el elemento (el relato nunca dice "Marta"); la
    tarjeta muestra el elemento Marta para explicar por qué aparece.
  - "bicicleta" → el extracto se centra en la coincidencia, no en las primeras
    líneas del relato.
- [ ] **Buscando sin resultados**: "xyz-inexistente" — mensaje distinto al vacío de
      primera vez.

## 2. Búsqueda — casos concretos (contrato 3, DEC-15, DEC-20)

- [ ] "Carmen" o "Granada": el recuerdo de la boda y el de la Alhambra comparten
      ambos motivos — cada tarjeta aparece una sola vez.
- [ ] Edita el relato de un recuerdo cuyo extracto sostenía una búsqueda activa: la
      lista no se recalcula en caliente, solo al volver a S1.

## 3. S4 — Detalle de recuerdo (contrato 4)

- [ ] **Con foto**: guarda una captura manual con foto adjunta — se ve sin recortar,
      bajo el relato.
- [ ] **Sin foto**: guarda una captura manual sin foto.
- [ ] **Sin conexiones**: una captura manual con elementos que no se repitan en
      ningún otro recuerdo del set.
- [ ] **Sin elementos reconocidos**: si el modelo no reconoce nada en una captura,
      revisa el mensaje "Hilo didn't recognize...".
- [ ] **Guardado sin analizar**: usa "comprender más tarde" (F4) y revisa el aviso
      más el botón "Let Hilo read this memory" desde aquí.
- [ ] **Borrar**: el texto de confirmación acierta qué elementos desaparecen y
      cuáles sobreviven — por ejemplo, borrar el recuerdo A dice que Marta y "el
      parque" desaparecen (si no aparecen en ningún otro recuerdo cargado).

## 4. S5 — Detalle de elemento (contrato 4, DEC-26)

- [ ] **Varios recuerdos**: abre "José" o "el reloj" — nombre, tipo, alias (añade
      uno para comprobarlo), número de recuerdos, rango temporal con las palabras
      del usuario del más antiguo y el más reciente, lista de recuerdos en el mismo
      orden que S1.
- [ ] **Un solo recuerdo**: abre "Marta" o "Martina" — invitación a contar otro
      recuerdo donde aparezca, sin rango temporal.
- [ ] **Renombrar sin colisión**: renombra "Martina" a un nombre no usado — se
      aplica; S1 y S4 reflejan el nombre nuevo al volver.
- [ ] **Renombrar con colisión**: renombra "Martina" a "Marta" — se rechaza con el
      aviso de que "Marta" ya existe, sin aplicar el cambio.
- [ ] **Añadir alias**: añade un alias nuevo; repite el mismo nombre (o un alias ya
      existente) y comprueba que no duplica.

## 5. Navegación (criterio 3)

- [ ] S1 (Elementos) → S5 → uno de sus recuerdos → S4 → uno de los elementos de ese
      recuerdo → S5 de nuevo.
- [ ] S4 → un recuerdo conectado (con motivo visible) → su propio S4 → vuelta.
- [ ] Confirma que desde cualquier recuerdo del set original se llega a cualquier
      otro que comparta un elemento (José conecta los 5 recuerdos de la memoria de
      ejemplo; Carmen/Granada conectan dos de ellos con doble motivo).

## 6. Accesibilidad — AX5 y VoiceOver

- [ ] Ajustes del sistema → Accesibilidad → Texto → Tamaños de texto más grandes →
      AX5 (el tamaño máximo).
  - S1 (vista Elementos): los chips de filtro pasan a columna, no fila horizontal;
    nada se recorta ni se solapa.
  - El selector superior "Recuerdos / Elementos" se convierte en menú.
  - S4 y S5: el relato del usuario nunca se recorta, a ningún tamaño.
- [ ] Activa VoiceOver. Recorre S1 (fila de elemento), S4 (foto, relato, elementos,
      conectados) y S5 (cabecera): **el tipo de un elemento se anuncia una sola vez**
      (nombre, tipo, número de recuerdos) — nunca duplicado por el símbolo SF además
      del texto.
- [ ] Los encabezados de década en S1 y las cabeceras de sección en S4/S5 se
      anuncian como encabezados con el rotor de VoiceOver.
- [ ] Todos los objetivos de toque (elementos, botones, chips) responden sin fallos
      de precisión.

## 7. Modo claro / oscuro

- [ ] Repite las secciones 1, 3 y 4 en modo oscuro: contraste correcto; el tipo de
      un elemento nunca se distingue solo por color — símbolo y texto siempre
      presentes junto al color.

## 8. Modo avión

- [ ] Activa el modo avión y repite cualquiera de las secciones anteriores: la app
      funciona exactamente igual, sin fallos.

## Notas conocidas, sin acción pendiente

- Al volver a S5 desde Ajustes justo tras activar AX5, `verificador-ui` vio una vez
  una pantalla en blanco no reproducible (solo la barra y "Rename"); no volvió a
  pasar en dos intentos más. Si te ocurre, anota los pasos exactos.
- `MemoryDetailScreen.swift:20` usa `800` como tamaño de decodificación de foto sin
  un token de `tokens.md` — es una resolución de decodificación generosa, no un
  valor visual; revisado y aceptado, sin acción pendiente.
- Las cadenas del panel Debug de Ajustes ("Load validation dataset", "Wipe all
  data"...) quedaron sin traducir al español — son Debug-only, nunca se compilan en
  Release. Si abres el proyecto en Xcode.app y compilas allí, deberían extraerse al
  catálogo y se pueden traducir entonces con las herramientas de String Catalog.
