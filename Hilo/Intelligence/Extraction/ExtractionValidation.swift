import Foundation

/// A well-formed structure can still carry names or dates the narrative never says (ADR-001 §2).
nonisolated enum ExtractionValidation {
  static func validate(_ extracted: ExtractedMemory, against narrative: String) -> ExtractedMemory {
    let validElements = extracted.elements.filter { narrative.contains($0.name) }
    let validDateText = extracted.dateText.flatMap {
      isDate($0, in: narrative, elements: validElements) ? $0 : nil
    }
    // The year is deduced from the date text: with no valid text there is nothing to deduce it from.
    let validYear = validDateText != nil ? extracted.deducedYear : nil

    return ExtractedMemory(
      elements: validElements, dateText: validDateText, deducedYear: validYear)
  }

  /// Neither the whole narrative nor an element's mention is a date.
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
