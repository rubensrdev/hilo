import Foundation

// contrato 2 + ADR-001 §2: una estructura bien formada puede traer nombres o fechas que el relato no dice
nonisolated enum ExtractionValidation {
  static func validate(_ extracted: ExtractedMemory, against narrative: String) -> ExtractedMemory {
    let validElements = extracted.elements.filter { narrative.contains($0.name) }
    let validDateText = extracted.dateText.flatMap {
      isDate($0, in: narrative, elements: validElements) ? $0 : nil
    }
    // el año se deduce del texto de la fecha: sin texto valido no hay de donde deducirlo (ADR-001 §2)
    let validYear = validDateText != nil ? extracted.deducedYear : nil

    return ExtractedMemory(
      elements: validElements, dateText: validDateText, deducedYear: validYear)
  }

  // DEC-51: ni el relato entero ni la mencion de un elemento son una fecha
  private static func isDate(
    _ dateText: String, in narrative: String, elements: [ExtractedElement]
  ) -> Bool {
    guard narrative.contains(dateText) else { return false }
    let isWholeNarrative =
      dateText.trimmingCharacters(in: .whitespacesAndNewlines)
      == narrative.trimmingCharacters(in: .whitespacesAndNewlines)
    let overlapsAnElement = elements.contains {
      dateText.contains($0.name) || $0.name.contains(dateText)
    }
    return !isWholeNarrative && !overlapsAnElement
  }
}
