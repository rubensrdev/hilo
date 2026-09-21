import Foundation

// contrato 2 + ADR-001 §2: una estructura bien formada puede traer nombres o fechas que el relato no dice
nonisolated enum ExtractionValidation {
  static func validate(_ extracted: ExtractedMemory, against narrative: String) -> ExtractedMemory {
    let validElements = extracted.elements.filter { narrative.contains($0.name) }
    let validDateText = extracted.dateText.flatMap { narrative.contains($0) ? $0 : nil }
    // el año se deduce del texto de la fecha: sin texto valido no hay de donde deducirlo (ADR-001 §2)
    let validYear = validDateText != nil ? extracted.deducedYear : nil

    return ExtractedMemory(
      elements: validElements, dateText: validDateText, deducedYear: validYear)
  }
}
