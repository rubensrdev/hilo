import Testing

@testable import Hilo

// contrato 2 + ADR-001 §2: lo bien formado no siempre es lo que el relato dice
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
}
