import Testing

@testable import Hilo

nonisolated struct FoundationModelsMemoryComprehenderTests {
  /// The spec doesn't fix the wording: the language's name is accepted in Spanish or English.
  private let spanishMarkers = ["español", "espanol", "spanish"]
  private let englishMarkers = ["inglés", "ingles", "english"]

  private func mentions(_ text: String, anyOf markers: [String]) -> Bool {
    let lowered = text.lowercased()
    return markers.contains { lowered.contains($0) }
  }

  @Test func `Instructions for Spanish mention Spanish and not English`() {
    let instructions = FoundationModelsMemoryComprehender.instructions(interfaceLanguage: "es")

    #expect(mentions(instructions, anyOf: spanishMarkers))
    #expect(!mentions(instructions, anyOf: englishMarkers))
  }

  @Test func `Instructions for English mention English and not Spanish`() {
    let instructions = FoundationModelsMemoryComprehender.instructions(interfaceLanguage: "en")

    #expect(mentions(instructions, anyOf: englishMarkers))
    #expect(!mentions(instructions, anyOf: spanishMarkers))
  }

  @Test func `Instructions differ between interface languages`() {
    let spanish = FoundationModelsMemoryComprehender.instructions(interfaceLanguage: "es")
    let english = FoundationModelsMemoryComprehender.instructions(interfaceLanguage: "en")

    #expect(spanish != english)
  }

  @Test(arguments: ["es", "en"])
  func `Instructions always forbid translating the user's names`(interfaceLanguage: String) {
    let instructions = FoundationModelsMemoryComprehender.instructions(
      interfaceLanguage: interfaceLanguage)
    let lowered = instructions.lowercased()

    let mentionsNotTranslating =
      (lowered.contains("translat") || lowered.contains("traduc"))
      && (lowered.contains("name") || lowered.contains("nombr"))

    #expect(mentionsNotTranslating)
  }
}
