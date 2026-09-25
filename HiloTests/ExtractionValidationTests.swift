import Testing

@testable import Hilo

nonisolated struct ExtractionValidationTests {
  @Test func `Discards an element whose name never appears literally in the narrative`() {
    let narrative = "Cenamos con mi hermano Pablo en el patio de la abuela."
    let raw = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Pablo", type: .person, role: "mi hermano"),
        ExtractedElement(name: "Manolo", type: .person, role: "un amigo"),
      ],
      dateText: nil, deducedYear: nil)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.elements.map(\.name) == ["Pablo"])
  }

  @Test
  func
    `Discards a dateText that never appears literally in the narrative, and its deduced year with it`()
  {
    let narrative = "Fuimos al mercado un sábado cualquiera."
    let raw = ExtractedMemory(elements: [], dateText: "el verano del 87", deducedYear: 1987)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
  }

  @Test func `A narrative with no date at all keeps both dateText and deducedYear absent`() {
    let narrative = "Aprendimos a hacer pan en la cocina de mi tía."
    let raw = ExtractedMemory(
      elements: [ExtractedElement(name: "mi tía", type: .person, role: "quien enseñó")],
      dateText: nil, deducedYear: nil)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
    #expect(validated.elements.map(\.name) == ["mi tía"])
  }

  @Test func `A narrative with a literal date but no deducible year keeps the text and no year`() {
    let narrative = "Aquel otoño perdimos las llaves en la playa."
    let raw = ExtractedMemory(elements: [], dateText: "Aquel otoño", deducedYear: nil)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == "Aquel otoño")
    #expect(validated.deducedYear == nil)
  }

  @Test func `A narrative with a literal date and a deducible year keeps both untouched`() {
    let narrative = "El verano del 87 aprendimos a bucear en la cala."
    let raw = ExtractedMemory(elements: [], dateText: "El verano del 87", deducedYear: 1987)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == "El verano del 87")
    #expect(validated.deducedYear == 1987)
  }

  // MARK: a date text overlapping the narrative or an element is not a date

  @Test func `Discards a dateText that wraps the mention of an extracted place, and its year with it`() {
    let narrative = "Mi tía Carmen me enseñó a coser en su casa de Cádiz, junto a la ventana."
    let raw = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Carmen", type: .person, role: "mi tía"),
        ExtractedElement(name: "Cádiz", type: .place, role: "donde vivía"),
      ],
      dateText: "en su casa de Cádiz", deducedYear: 1990)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
    #expect(validated.elements.map(\.name) == ["Carmen", "Cádiz"])
  }

  @Test func `Discards a dateText that is the whole narrative`() {
    // The narrative arrives with surrounding whitespace; the model returns its content without it.
    let narrative = "\nCarmen cosía con la Singer en Cádiz. "
    let raw = ExtractedMemory(
      elements: [], dateText: "Carmen cosía con la Singer en Cádiz.", deducedYear: 1990)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
  }

  /// The guard against overcorrecting: a real date next to elements that don't touch it.
  @Test func `Keeps a real dateText that overlaps with no extracted element`() {
    let narrative = "El verano del 87 la abuela nos llevó a Cádiz con la Singer en el coche."
    let raw = ExtractedMemory(
      elements: [
        ExtractedElement(name: "la abuela", type: .person, role: "quien nos llevó"),
        ExtractedElement(name: "Cádiz", type: .place, role: "el destino"),
        ExtractedElement(name: "la Singer", type: .object, role: "lo que llevamos"),
      ],
      dateText: "El verano del 87", deducedYear: 1987)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == "El verano del 87")
    #expect(validated.deducedYear == 1987)
  }

  @Test func `A narrative with no date and no elements stays without date or year`() {
    let narrative = "Llovió toda la tarde y nadie salió."
    let raw = ExtractedMemory(elements: [], dateText: nil, deducedYear: nil)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
    #expect(validated.elements.isEmpty)
  }
}
