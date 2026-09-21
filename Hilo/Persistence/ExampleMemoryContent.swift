import Foundation

enum ExampleMemoryLanguage {
  case spanish
  case english
}

struct ExampleAppearanceSeed {
  let displayName: String
  let type: ElementType
  let role: String?
}

struct ExampleMemorySeed {
  let narrative: String
  let dateText: String?
  let deducedYear: Int?
  let appearances: [ExampleAppearanceSeed]
}

// docs/content/memoria-de-ejemplo.md, aprobado por Ruben: tal cual, sin reescribir ni anadir nada
// contenido fijo sin estado de actor: nonisolated para poder leerlo desde el actor de persistencia
nonisolated enum ExampleMemoryContent {
  static func seeds(for language: ExampleMemoryLanguage) -> [ExampleMemorySeed] {
    switch language {
    case .spanish: spanishSeeds
    case .english: englishSeeds
    }
  }

  private static let spanishSeeds: [ExampleMemorySeed] = [
    ExampleMemorySeed(
      narrative:
        "Mi abuelo José me regaló su reloj el verano del 87, en la casa del pueblo. Me dijo que había sido de su padre y que ahora me tocaba cuidarlo a mí.",
      dateText: "el verano del 87", deducedYear: 1987,
      appearances: [
        ExampleAppearanceSeed(displayName: "José", type: .person, role: "mi abuelo"),
        ExampleAppearanceSeed(displayName: "el reloj", type: .object, role: "me lo regaló"),
        ExampleAppearanceSeed(displayName: "la casa del pueblo", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "Granada, 1994. La tía Carmen nos llevó a ver la Alhambra y José se perdió en los jardines durante una hora. Lo encontramos sentado en un banco, tan tranquilo, mirando las fuentes.",
      dateText: "1994", deducedYear: 1994,
      appearances: [
        ExampleAppearanceSeed(displayName: "Granada", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "Carmen", type: .person, role: "la tía"),
        ExampleAppearanceSeed(displayName: "la Alhambra", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "José", type: .person, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "La última vez que vi al abuelo José estaba arreglando la máquina de coser de la abuela Pilar en la cocina. Tarareó todo el rato y no quiso que le ayudara.",
      dateText: nil, deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "José", type: .person, role: "el abuelo"),
        ExampleAppearanceSeed(displayName: "la máquina de coser", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "Pilar", type: .person, role: "la abuela"),
      ]),
    ExampleMemorySeed(
      narrative:
        "El día que vaciamos la casa del pueblo encontramos una caja de latón debajo de la cama. Dentro estaban las cartas de José, el reloj sin cuerda y una foto suya de joven.",
      dateText: "no me acuerdo del año, pero fue en otoño", deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "la casa del pueblo", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "la caja de latón", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "José", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "el reloj", type: .object, role: "sin cuerda"),
      ]),
    ExampleMemorySeed(
      narrative:
        "En la boda de Carmen, en Granada, bailé con mi padre por primera y última vez. Llevaba el reloj del abuelo en el bolsillo del chaleco.",
      dateText: "el verano de 2001", deducedYear: 2001,
      appearances: [
        ExampleAppearanceSeed(displayName: "Carmen", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Granada", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "mi padre", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "el reloj", type: .object, role: "del abuelo"),
      ]),
  ]

  private static let englishSeeds: [ExampleMemorySeed] = [
    ExampleMemorySeed(
      narrative:
        "My grandpa José gave me his watch in the summer of '87, at the village house. He said it had belonged to his father and that it was my turn to look after it.",
      dateText: "the summer of '87", deducedYear: 1987,
      appearances: [
        ExampleAppearanceSeed(displayName: "José", type: .person, role: "my grandpa"),
        ExampleAppearanceSeed(displayName: "the watch", type: .object, role: "he gave it to me"),
        ExampleAppearanceSeed(displayName: "the village house", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "Granada, 1994. Aunt Carmen took us to see the Alhambra and José got lost in the gardens for an hour. We found him sitting on a bench, perfectly calm, watching the fountains.",
      dateText: "1994", deducedYear: 1994,
      appearances: [
        ExampleAppearanceSeed(displayName: "Granada", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "Carmen", type: .person, role: "aunt"),
        ExampleAppearanceSeed(displayName: "the Alhambra", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "José", type: .person, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "The last time I saw grandpa José he was fixing grandma Pilar's sewing machine in the kitchen. He hummed the whole time and wouldn't let me help.",
      dateText: nil, deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "José", type: .person, role: "grandpa"),
        ExampleAppearanceSeed(displayName: "the sewing machine", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "Pilar", type: .person, role: "grandma"),
      ]),
    ExampleMemorySeed(
      narrative:
        "The day we emptied the village house we found a tin box under the bed. Inside were José's letters, the watch that no longer wound, and a photo of him as a young man.",
      dateText: "I don't remember the year, but it was autumn", deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "the village house", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "the tin box", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "José", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the watch", type: .object, role: "no longer wound"),
      ]),
    ExampleMemorySeed(
      narrative:
        "At Carmen's wedding, in Granada, I danced with my father for the first and last time. He had grandpa's watch in his waistcoat pocket.",
      dateText: "the summer of 2001", deducedYear: 2001,
      appearances: [
        ExampleAppearanceSeed(displayName: "Carmen", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Granada", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "my father", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the watch", type: .object, role: "grandpa's"),
      ]),
  ]
}
