import FoundationModels
import Testing

@testable import Hilo

// contrato 4: contextOverflow, guardrailViolation, refusal, unsupportedLanguage, assetsUnavailable,
// decodingFailure y noResponse son estados de producto; concurrentRequests, unsupportedGuide y
// unsupportedGenerationGuide son defectos nuestros (preconditionFailure), no se prueban aqui
// LanguageModelError exige iOS 27.0 (SDK real, ver FoundationModels.swiftinterface): con deployment
// target 26.4 no se puede construir sin un @available prohibido por CLAUDE.md, asi que solo se
// prueba la superficie GenerationError (26.0), que ya cubre los 7 casos
nonisolated struct MemoryComprehensionErrorMappingTests {
  private struct UnrecognizedTestError: Error, Sendable {}

  // MARK: - LanguageModelSession.GenerationError

  @Test func `Generation guardrail violation maps to guardrailViolation`() {
    let error = LanguageModelSession.GenerationError.guardrailViolation(
      .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .guardrailViolation)
  }

  @Test func `Generation exceeded context window maps to contextOverflow`() {
    let error = LanguageModelSession.GenerationError.exceededContextWindowSize(
      .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .contextOverflow)
  }

  @Test func `Generation unsupported language or locale maps to unsupportedLanguage`() {
    let error = LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(
      .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .unsupportedLanguage)
  }

  @Test func `Generation refusal maps to refusal`() {
    let error = LanguageModelSession.GenerationError.refusal(
      .init(transcriptEntries: []), .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .refusal)
  }

  @Test func `Generation assets unavailable maps to assetsUnavailable`() {
    let error = LanguageModelSession.GenerationError.assetsUnavailable(
      .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .assetsUnavailable)
  }

  @Test func `Generation decoding failure maps to decodingFailure`() {
    let error = LanguageModelSession.GenerationError.decodingFailure(
      .init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .decodingFailure)
  }

  @Test func `Generation rate limited maps to noResponse`() {
    let error = LanguageModelSession.GenerationError.rateLimited(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  // MARK: - Cualquier otro error

  @Test func `An unrecognized error maps to noResponse`() {
    let error = UnrecognizedTestError()

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }
}
