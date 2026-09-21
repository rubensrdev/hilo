# ADR-002 — Esquema de persistencia

- **Fase**: F2
- **Estado**: Proposed
- **Opened**: 2026-09-21
- **Closed**: —
- **Reason**: —

---

## Contexto

`F2_Persistencia.md` deja abierto dónde vive la marca de «analizado» que necesita DEC-16 (comprender más tarde desde el detalle): una bandera explícita en `Recuerdo`, o derivarla de la ausencia de apariciones propuestas por la comprensión.

La propia spec de F2 exige que un recuerdo pueda guardarse "sin foto, sin fecha y sin elementos" — y ese estado es alcanzable tanto por un recuerdo nunca analizado como por uno que sí se analizó y la comprensión no encontró ningún elemento real (un recuerdo abstracto, sin personas, lugares u objetos reconocibles). Derivar la marca de la ausencia de apariciones confunde esos dos estados: el segundo volvería a ofrecer «comprender más tarde» (DEC-16) sobre algo ya resuelto, y el guardarraíl de comprensión (DEC-18, F3) que guarda "sin analizar" quedaría indistinguible de una comprensión exitosa sin hallazgos.

---

## Decisión

### 1. Bandera explícita `isAnalyzed`

`Recuerdo` guarda `isAnalyzed: Bool`. Nombre en ASCII, coherente con el resto del esquema.

**Solo dos estados persistidos.** "Comprendiendo" nunca se guarda — no se persiste nada desde un resultado parcial de la comprensión. El motivo de un fallo de comprensión no se guarda: se comunica al usuario en el momento de guardar (F3) y no se vuelve a usar después.

**Transiciones:**

| Momento | Valor |
|---|---|
| Se guarda sin analizar, o cualquier error de comprensión (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta) | `false` |
| La comprensión termina, con o sin elementos encontrados | `true` |
| Se edita el texto del recuerdo (DEC-19: editar no reanaliza) | Sin cambio |
| Recuerdos de la memoria de ejemplo (F2, contrato 5) | Nacen en `true` |

### 2. Por qué no la alternativa derivada

Derivar "analizado" de "sin apariciones propuestas" ata dos preguntas distintas — *¿se intentó comprender?* y *¿qué encontró la comprensión?* — a una sola señal, y las apariciones no bastan para separarlas: un recuerdo con cero apariciones puede no haberse analizado nunca, o haberse analizado y no encontrar nada. Solo la bandera explícita mantiene los dos estados observables por separado sin lógica adicional en ningún sitio.

---

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| Derivar de la ausencia de apariciones propuestas | Confunde "nunca analizado" con "analizado sin hallazgos" — ver Decisión §2 |
| Guardar el motivo del último fallo de comprensión | No tiene consumidor después del momento de guardar (F3 lo comunica una vez); guardarlo sería estado sin uso |
| Un tercer estado persistido para "comprendiendo" | Ninguna vista lee un recuerdo a mitad de una comprensión en curso — la comprensión vive en memoria de la sesión, no en el esquema |

---

## Consecuencias

- F2.1 declara `isAnalyzed: Bool` en el esquema de `Recuerdo`.
- F2.5 (memoria de ejemplo) inicializa cada recuerdo cargado con `isAnalyzed = true`.
- F3 escribe `false` en el camino de guardar-sin-analizar y en cada caso de su contrato 4 (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta), y `true` al terminar una comprensión con éxito, tenga o no elementos.
- F4/F5 leen la bandera para decidir si ofrecer «comprender más tarde» (DEC-16); no necesitan mirar las apariciones para eso.
- Tests de F2: un recuerdo analizado sin elementos es distinguible de uno no analizado; editar el texto no altera la bandera; cargar el ejemplo deja todo en `true`.

---

## Coste de reversión

**Bajo.** Es una columna booleana más en el esquema, sin migración que perder porque el MVP no tiene historia de migraciones (reinstalar). Revertir a la derivación exigiría además auditar F3/F4/F5 para separar de otra forma los dos estados que hoy distingue la bandera.
