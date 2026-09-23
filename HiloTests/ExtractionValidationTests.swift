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

  // MARK: DEC-51 — un texto de fecha que solapa con el relato o con un elemento no es una fecha

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
    // el relato llega con espacios en los extremos: el modelo devuelve su contenido, sin ellos
    let narrative = "\nCarmen cosía con la Singer en Cádiz. "
    let raw = ExtractedMemory(
      elements: [], dateText: "Carmen cosía con la Singer en Cádiz.", deducedYear: 1990)

    let validated = ExtractionValidation.validate(raw, against: narrative)

    #expect(validated.dateText == nil)
    #expect(validated.deducedYear == nil)
  }

  // el que evita pasarse de frenada: una fecha de verdad junto a elementos que no la tocan
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
