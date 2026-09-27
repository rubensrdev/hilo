import Foundation

nonisolated enum ExampleMemoryLanguage: Equatable {
  case spanish
  case english

  /// The interface language at load time, already resolved by InterfaceLocale.
  init(interfaceLocale: Locale) {
    self = interfaceLocale.language.languageCode?.identifier == "es" ? .spanish : .english
  }
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

/// A word-for-word copy of docs/content/example-memory.md. nonisolated so the persistence
/// actor can read it.
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
        "Triana, verano de 1979. Nines y yo aprendimos a montar en bici en la misma tarde, ella en la mía porque la suya tenía el sillín roto. Nos caímos tantas veces que mi madre tuvo que sacar el mercromina antes de cenar.",
      dateText: "verano de 1979", deducedYear: 1979,
      appearances: [
        ExampleAppearanceSeed(displayName: "Triana", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "la bicicleta roja", type: .object, role: "la mía"),
      ]),
    ExampleMemorySeed(
      narrative:
        "En 1985, tío Paco me prestó su máquina de escribir para el trabajo de clase sobre los Reyes Católicos. Nines vino a casa a ayudarme y acabamos escribiendo un cuento sobre un dragón en vez del trabajo.",
      dateText: "en 1985", deducedYear: 1985,
      appearances: [
        ExampleAppearanceSeed(displayName: "tío Paco", type: .person, role: "tío"),
        ExampleAppearanceSeed(displayName: "la máquina de escribir", type: .object, role: "su"),
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "Marcos apareció en mi vida encima de una Vespa amarilla, en 1993, ofreciéndose a llevarme a casa un día de lluvia. Tardé tres semanas en aceptar y otras tres en darme cuenta de que ya no quería bajarme.",
      dateText: "en 1993", deducedYear: 1993,
      appearances: [
        ExampleAppearanceSeed(displayName: "Marcos", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "la Vespa", type: .object, role: "amarilla"),
      ]),
    ExampleMemorySeed(
      narrative:
        "El verano de 1999, Nines y yo cogimos un autobús hasta la playa de Bolonia sin decírselo a nadie. Dormimos en una tienda de campaña prestada y volvimos con la piel quemada y sin ni un duro.",
      dateText: "el verano de 1999", deducedYear: 1999,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "la playa de Bolonia", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "El día que Nines se casó, en 2003, Marcos llegó tarde a la ceremonia porque la Vespa se quedó sin gasolina a dos kilómetros de la iglesia. Entró empapado en sudor justo antes del «sí quiero» y todo el mundo se rió.",
      dateText: "en 2003", deducedYear: 2003,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Marcos", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "la Vespa", type: .object, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "La abuela Mercedes murió una madrugada, sin avisar a nadie, con el jersey verde que llevaba tejiendo para mí todavía a medias sobre la mesa camilla. No hemos vuelto a tocar esa lana.",
      dateText: nil, deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "abuela Mercedes", type: .person, role: "la abuela"),
        ExampleAppearanceSeed(
          displayName: "el jersey verde", type: .object, role: "que llevaba tejiendo"),
      ]),
    ExampleMemorySeed(
      narrative:
        "No me acuerdo del año, pero recuerdo que fue el verano que cumplí quince años: la abuela Mercedes me hizo una tarta de manzana en el patio de su casa y me dejó fumarme un cigarro a escondidas de mi madre.",
      dateText: "el verano que cumplí quince años", deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "abuela Mercedes", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "el patio de la abuela", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "En 2005, un domingo cualquiera, la Vespa se paró en mitad de la cuesta y el vecino Rafa bajó en pijama a empujarla conmigo hasta el taller. No cruzamos ni diez palabras, pero desde entonces siempre me saluda por mi nombre.",
      dateText: "en 2005", deducedYear: 2005,
      appearances: [
        ExampleAppearanceSeed(displayName: "la Vespa", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "el vecino Rafa", type: .person, role: "vecino"),
      ]),
    ExampleMemorySeed(
      narrative:
        "Nines y yo no nos hablamos durante casi dos años, hasta que en 2013 nos encontramos de casualidad en la puerta de la iglesia de Triana, las dos con el mismo paraguas roto por el viento. Nos reímos antes de poder evitarlo.",
      dateText: "en 2013", deducedYear: 2013,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Triana", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "En 2018, mi compañera Lucía se quedó conmigo hasta las diez de la noche revisando el informe que había que entregar al día siguiente, aunque a ella no le tocaba. Al final ni lo leyeron entero.",
      dateText: "en 2018", deducedYear: 2018,
      appearances: [
        ExampleAppearanceSeed(displayName: "Lucía", type: .person, role: "mi compañera")
      ]),
    ExampleMemorySeed(
      narrative:
        "Volví a la playa de Bolonia en 2016, sola, y me senté donde nos habíamos puesto aquel verano, con la piel ya sin ganas de quemarse. El viento seguía siendo igual de bestia. Me quedé una hora sin hacer nada más que mirar.",
      dateText: "en 2016", deducedYear: 2016,
      appearances: [
        ExampleAppearanceSeed(displayName: "la playa de Bolonia", type: .place, role: nil)
      ]),
  ]

  private static let englishSeeds: [ExampleMemorySeed] = [
    ExampleMemorySeed(
      narrative:
        "Triana, summer of 1979. Nines and I learned to ride a bike the same afternoon, her on mine because hers had a broken seat. We fell so many times my mother had to get out the iodine before dinner.",
      dateText: "summer of 1979", deducedYear: 1979,
      appearances: [
        ExampleAppearanceSeed(displayName: "Triana", type: .place, role: nil),
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the red bicycle", type: .object, role: "mine"),
      ]),
    ExampleMemorySeed(
      narrative:
        "In 1985, uncle Paco lent me his typewriter for the school project on the Catholic Monarchs. Nines came over to help and we ended up writing a story about a dragon instead of the assignment.",
      dateText: "in 1985", deducedYear: 1985,
      appearances: [
        ExampleAppearanceSeed(displayName: "uncle Paco", type: .person, role: "uncle"),
        ExampleAppearanceSeed(displayName: "the typewriter", type: .object, role: "his"),
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "Marcos showed up in my life on a yellow Vespa, in 1993, offering to give me a ride home on a rainy day. It took me three weeks to say yes and another three to realize I didn't want to get off.",
      dateText: "in 1993", deducedYear: 1993,
      appearances: [
        ExampleAppearanceSeed(displayName: "Marcos", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the Vespa", type: .object, role: "yellow"),
      ]),
    ExampleMemorySeed(
      narrative:
        "In the summer of 1999, Nines and I took a bus to the beach at Bolonia without telling anyone. We slept in a borrowed tent and came back sunburnt and completely broke.",
      dateText: "the summer of 1999", deducedYear: 1999,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the beach at Bolonia", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "The day Nines got married, in 2003, Marcos arrived late to the ceremony because the Vespa ran out of petrol two kilometres from the church. He walked in drenched in sweat right before the vows and everyone laughed.",
      dateText: "in 2003", deducedYear: 2003,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Marcos", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "the Vespa", type: .object, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "Grandma Mercedes died one early morning, without warning anyone, with the green jumper she'd been knitting for me still half-finished on the side table. We haven't touched that wool since.",
      dateText: nil, deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "grandma Mercedes", type: .person, role: "grandma"),
        ExampleAppearanceSeed(
          displayName: "the green jumper", type: .object, role: "she'd been knitting"),
      ]),
    ExampleMemorySeed(
      narrative:
        "I don't remember the year, but I remember it was the summer I turned fifteen: grandma Mercedes made me an apple cake in her courtyard and let me sneak a cigarette behind my mother's back.",
      dateText: "the summer I turned fifteen", deducedYear: nil,
      appearances: [
        ExampleAppearanceSeed(displayName: "grandma Mercedes", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "grandma's courtyard", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "In 2005, on an ordinary Sunday, the Vespa stalled halfway up the hill and neighbour Rafa came down in his pyjamas to help me push it to the workshop. We barely said ten words, but he's greeted me by name ever since.",
      dateText: "in 2005", deducedYear: 2005,
      appearances: [
        ExampleAppearanceSeed(displayName: "the Vespa", type: .object, role: nil),
        ExampleAppearanceSeed(displayName: "neighbour Rafa", type: .person, role: "neighbour"),
      ]),
    ExampleMemorySeed(
      narrative:
        "Nines and I didn't speak for almost two years, until in 2013 we ran into each other by chance outside the church in Triana, both of us with the same umbrella broken by the wind. We started laughing before we could help it.",
      dateText: "in 2013", deducedYear: 2013,
      appearances: [
        ExampleAppearanceSeed(displayName: "Nines", type: .person, role: nil),
        ExampleAppearanceSeed(displayName: "Triana", type: .place, role: nil),
      ]),
    ExampleMemorySeed(
      narrative:
        "In 2018, my colleague Lucía stayed with me until ten at night going over the report that was due the next day, even though it wasn't her job. In the end nobody even read it in full.",
      dateText: "in 2018", deducedYear: 2018,
      appearances: [
        ExampleAppearanceSeed(displayName: "Lucía", type: .person, role: "my colleague")
      ]),
    ExampleMemorySeed(
      narrative:
        "I went back to the beach at Bolonia in 2016, alone, and sat where we used to sit that summer, my skin no longer keen to burn. The wind was still just as fierce. I stayed an hour doing nothing but watch.",
      dateText: "in 2016", deducedYear: 2016,
      appearances: [
        ExampleAppearanceSeed(displayName: "the beach at Bolonia", type: .place, role: nil)
      ]),
  ]
}
