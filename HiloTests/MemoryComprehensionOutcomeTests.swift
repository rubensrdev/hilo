import Testing

@testable import Hilo

// contrato 4 + DEC-16/DEC-18: el desenlace completo de un intento de comprension, no solo el error
nonisolated struct MemoryComprehensionOutcomeTests {
  private static let errorsAndReasons: [(MemoryComprehensionError, MemoryComprehensionReason)] = [
    (.guardrailViolation, .guardrail),
    (.refusal, .guardrail),
    (.contextOverflow, .contextOverflow),
    (.unsupportedLanguage, .unsupportedLanguage),
    (.assetsUnavailable, .generic),
    (.decodingFailure, .generic),
    (.noResponse, .generic),
  ]

  @Test(arguments: errorsAndReasons)
  func `Each comprehension error maps to its outcome category`(
    pair: (MemoryComprehensionError, MemoryComprehensionReason)
  ) {
    #expect(MemoryComprehensionReason(mapping: pair.0) == pair.1)
  }

  @Test(arguments: errorsAndReasons)
  func `A failed result becomes notAnalyzed, keeping the narrative and the mapped reason`(
    pair: (MemoryComprehensionError, MemoryComprehensionReason)
  ) {
    let outcome = MemoryComprehensionOutcome(
      Result<ExtractedMemory, MemoryComprehensionError>.failure(pair.0),
      narrative: "un relato cualquiera")

    guard case .notAnalyzed(let narrative, let reason) = outcome else {
      Issue.record("expected .notAnalyzed for \(pair.0)")
      return
    }
    #expect(narrative == "un relato cualquiera")
    #expect(reason == pair.1)
  }

  @Test func `A successful result becomes understood with the same memory, compared by field`() {
    let extracted = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Elena", type: .person, role: "mi vecina"),
        ExtractedElement(name: "el parque", type: .place, role: "donde nos vimos"),
      ],
      dateText: "un domingo por la mañana", deducedYear: nil)

    let outcome = MemoryComprehensionOutcome(
      Result<ExtractedMemory, MemoryComprehensionError>.success(extracted),
      narrative: "no importa para el caso de exito")

    guard case .understood(let memory) = outcome else {
      Issue.record("expected .understood")
      return
    }
    #expect(memory.elements.map(\.name) == ["Elena", "el parque"])
    #expect(memory.elements.map(\.role) == ["mi vecina", "donde nos vimos"])
    #expect(memory.dateText == "un domingo por la mañana")
    #expect(memory.deducedYear == nil)
  }

  @Test func `No result at all, as when the attempt is cancelled, becomes cancelled`() {
    let outcome = MemoryComprehensionOutcome(nil, narrative: "no importa")

    guard case .cancelled = outcome else {
      Issue.record("expected .cancelled")
      return
    }
  }

  @Test func `Comprehending later from the same scripted result yields the same outcome twice`() {
    // DEC-16/DEC-18: reintentar reconstruye el desenlace desde el mismo guion, sin estado compartido
    let result = Result<ExtractedMemory, MemoryComprehensionError>.failure(.contextOverflow)

    let first = MemoryComprehensionOutcome(result, narrative: "un relato cualquiera")
    let second = MemoryComprehensionOutcome(result, narrative: "un relato cualquiera")

    guard case .notAnalyzed(let firstNarrative, let firstReason) = first,
      case .notAnalyzed(let secondNarrative, let secondReason) = second
    else {
      Issue.record("expected both outcomes to be .notAnalyzed")
      return
    }
    #expect(firstNarrative == secondNarrative)
    #expect(firstReason == secondReason)
  }
}
