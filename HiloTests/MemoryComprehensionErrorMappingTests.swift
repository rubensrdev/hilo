import Foundation
import FoundationModels
import Testing

@testable import Hilo

// contrato 4: contextOverflow, guardrailViolation, refusal, unsupportedLanguage, assetsUnavailable,
// decodingFailure y noResponse son estados de producto; concurrentRequests, unsupportedGuide y
// unsupportedGenerationGuide son defectos nuestros (preconditionFailure), no se prueban aqui
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

  // MARK: - LanguageModelError (iOS 27+, excepcion acotada de CLAUDE.md: el simulador activo es 27.0)

  @Test func `Model guardrail violation maps to guardrailViolation`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.guardrailViolation(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .guardrailViolation)
  }

  @Test func `Model context size exceeded maps to contextOverflow`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.contextSizeExceeded(
      .init(contextSize: 4096, tokenCount: 5000, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .contextOverflow)
  }

  @Test func `Model unsupported language or locale maps to unsupportedLanguage`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.unsupportedLanguageOrLocale(
      .init(languageCode: "xx", debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .unsupportedLanguage)
  }

  @Test func `Model refusal maps to refusal`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.refusal(
      .init(explanation: "test", debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .refusal)
  }

  @Test func `Model rate limited maps to noResponse`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @Test func `Model timeout maps to noResponse`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.timeout(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @Test func `Model unsupported capability maps to noResponse`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.unsupportedCapability(
      .init(capability: .vision, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @Test func `Model unsupported transcript content maps to noResponse`() {
    guard #available(iOS 27, *) else {
      Issue.record("este test requiere iOS 27, el simulador activo del proyecto ya lo es")
      return
    }
    let error = LanguageModelError.unsupportedTranscriptContent(
      .init(unsupportedContent: [], debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  // MARK: - Cualquier otro error

  @Test func `An unrecognized error maps to noResponse`() {
    let error = UnrecognizedTestError()

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }
}
