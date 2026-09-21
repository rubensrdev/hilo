# Memoria de ejemplo — Hilo

> `docs/content/memoria-de-ejemplo.md` · Contenido de producto de la F2.5, aprobado por Rubén.
> Todo es inventado. Ningún recuerdo es de una persona real.

## Qué tiene que demostrar

Cinco recuerdos que, cargados juntos, enseñan el producto entero sin que el usuario tenga que contar nada:

| Qué se ve | Dónde |
|---|---|
| Conexión por **persona** | José aparece en cuatro recuerdos |
| Conexión por **lugar** | Granada (2 y 5) y la casa del pueblo (1 y 4) |
| Conexión por **objeto** | El reloj aparece en tres recuerdos |
| **Retrato** de una persona | José: cuatro recuerdos, supera el umbral de tres |
| **Retrato** de un objeto | El reloj: tres recuerdos, justo en el umbral |
| Agrupación por **década** | 1980s, 1990s, 2000s |
| Grupo **«sin año»** | Recuerdos 3 y 4 |
| Fecha **en palabras sin año deducible** | Recuerdo 4 |
| Recuerdo **sin ninguna fecha** | Recuerdo 3 |
| Elemento con **un solo recuerdo** (hebra suelta) | Pilar, la máquina de coser, la caja de latón, la Alhambra, el padre |
| **Tejido** con varios vecinos | José conecta con casi todo |

Sin fotos: no hay imágenes que se puedan incluir en la app sin que sean de alguien.

Todos los recuerdos nacen **analizados** (`isAnalyzed = true`) y con sus apariciones **confirmadas**. No hay dudas de identidad en el ejemplo.

---

## Español

### 1

> Mi abuelo José me regaló su reloj el verano del 87, en la casa del pueblo. Me dijo que había sido de su padre y que ahora me tocaba cuidarlo a mí.

- **Fecha**: «el verano del 87» · año 1987
- **Elementos**: José (persona, «mi abuelo») · el reloj (objeto, «me lo regaló») · la casa del pueblo (lugar)

### 2

> Granada, 1994. La tía Carmen nos llevó a ver la Alhambra y José se perdió en los jardines durante una hora. Lo encontramos sentado en un banco, tan tranquilo, mirando las fuentes.

- **Fecha**: «1994» · año 1994
- **Elementos**: Granada (lugar) · Carmen (persona, «la tía») · la Alhambra (lugar) · José (persona)

### 3

> La última vez que vi al abuelo José estaba arreglando la máquina de coser de la abuela Pilar en la cocina. Tarareó todo el rato y no quiso que le ayudara.

- **Fecha**: ninguna
- **Elementos**: José (persona, «el abuelo») · la máquina de coser (objeto) · Pilar (persona, «la abuela»)

### 4

> El día que vaciamos la casa del pueblo encontramos una caja de latón debajo de la cama. Dentro estaban las cartas de José, el reloj sin cuerda y una foto suya de joven.

- **Fecha**: «no me acuerdo del año, pero fue en otoño» · sin año
- **Elementos**: la casa del pueblo (lugar) · la caja de latón (objeto) · José (persona) · el reloj (objeto, «sin cuerda»)

### 5

> En la boda de Carmen, en Granada, bailé con mi padre por primera y última vez. Llevaba el reloj del abuelo en el bolsillo del chaleco.

- **Fecha**: «el verano de 2001» · año 2001
- **Elementos**: Carmen (persona) · Granada (lugar) · mi padre (persona) · el reloj (objeto, «del abuelo»)

---

## English

The names of people and places are the same in both languages: they are the user's own and are never translated.

### 1

> My grandpa José gave me his watch in the summer of '87, at the village house. He said it had belonged to his father and that it was my turn to look after it.

- **Date**: "the summer of '87" · year 1987
- **Elements**: José (person, "my grandpa") · the watch (object, "he gave it to me") · the village house (place)

### 2

> Granada, 1994. Aunt Carmen took us to see the Alhambra and José got lost in the gardens for an hour. We found him sitting on a bench, perfectly calm, watching the fountains.

- **Date**: "1994" · year 1994
- **Elements**: Granada (place) · Carmen (person, "aunt") · the Alhambra (place) · José (person)

### 3

> The last time I saw grandpa José he was fixing grandma Pilar's sewing machine in the kitchen. He hummed the whole time and wouldn't let me help.

- **Date**: none
- **Elements**: José (person, "grandpa") · the sewing machine (object) · Pilar (person, "grandma")

### 4

> The day we emptied the village house we found a tin box under the bed. Inside were José's letters, the watch that no longer wound, and a photo of him as a young man.

- **Date**: "I don't remember the year, but it was autumn" · no year
- **Elements**: the village house (place) · the tin box (object) · José (person) · the watch (object, "no longer wound")

### 5

> At Carmen's wedding, in Granada, I danced with my father for the first and last time. He had grandpa's watch in his waistcoat pocket.

- **Date**: "the summer of 2001" · year 2001
- **Elements**: Carmen (person) · Granada (place) · my father (person) · the watch (object, "grandpa's")

---

## Notas para la implementación

- **El canónico hace el trabajo**: «el reloj», «su reloj» y «el reloj del abuelo» son el mismo objeto, y «the watch» en inglés. «Mi padre» y «my father» se guardan con su nombre mostrado; el canónico les quita el posesivo (DEC-25).
- **«La tía Carmen» y «Carmen» son el mismo elemento**: el nombre es Carmen y «la tía» es su papel. Igual con «el abuelo José» y «la abuela Pilar».
- **La cocina, los jardines, la cama y las cartas no son elementos**: son genéricos, no nombrables y singulares (§7.3).
- **Los dos idiomas son dos conjuntos separados.** Se carga el del idioma de la interfaz en el momento de cargar, y no cambia después (F2, contrato 5).
