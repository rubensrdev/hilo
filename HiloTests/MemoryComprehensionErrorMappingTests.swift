import Foundation
import FoundationModels
import Testing

@testable import Hilo

/// Our own defects (concurrentRequests, unsupportedGuide, unsupportedGenerationGuide) are
/// preconditionFailures, so they are not tested here.
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

  // MARK: - LanguageModelError (iOS 27+, the one availability exception; the active simulator runs 27.0)

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model guardrail violation maps to guardrailViolation`() {
    let error = LanguageModelError.guardrailViolation(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .guardrailViolation)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model context size exceeded maps to contextOverflow`() {
    let error = LanguageModelError.contextSizeExceeded(
      .init(contextSize: 4096, tokenCount: 5000, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .contextOverflow)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model unsupported language or locale maps to unsupportedLanguage`() {
    let error = LanguageModelError.unsupportedLanguageOrLocale(
      .init(languageCode: "xx", debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .unsupportedLanguage)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model refusal maps to refusal`() {
    let error = LanguageModelError.refusal(
      .init(explanation: "test", debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .refusal)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model rate limited maps to noResponse`() {
    let error = LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model timeout maps to noResponse`() {
    let error = LanguageModelError.timeout(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model unsupported capability maps to noResponse`() {
    let error = LanguageModelError.unsupportedCapability(
      .init(capability: .vision, debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model unsupported transcript content maps to noResponse`() {
    let error = LanguageModelError.unsupportedTranscriptContent(
      .init(unsupportedContent: [], debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }

  // MARK: - SystemLanguageModel.Error, GeneratedContent.ParsingError (iOS 27+)

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `System model assets unavailable maps to assetsUnavailable`() {
    let error = SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: "test"))

    #expect(MemoryComprehensionError(mapping: error) == .assetsUnavailable)
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Generated content parsing error maps to decodingFailure`() {
    let error = GeneratedContent.ParsingError(rawContent: "test", debugDescription: "test")

    #expect(MemoryComprehensionError(mapping: error) == .decodingFailure)
  }

  // MARK: - MemoryComprehensionClassification, our own defects (not product states)

  @Test func `Generation concurrent requests classifies as an own defect`() {
    let error = LanguageModelSession.GenerationError.concurrentRequests(
      .init(debugDescription: "test"))

    guard case .ownDefect = MemoryComprehensionClassification(classifying: error) else {
      Issue.record("expected .ownDefect for concurrentRequests")
      return
    }
  }

  @Test func `Generation unsupported guide classifies as an own defect`() {
    let error = LanguageModelSession.GenerationError.unsupportedGuide(
      .init(debugDescription: "test"))

    guard case .ownDefect = MemoryComprehensionClassification(classifying: error) else {
      Issue.record("expected .ownDefect for unsupportedGuide")
      return
    }
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Model unsupported generation guide classifies as an own defect`() {
    let error = LanguageModelError.unsupportedGenerationGuide(
      .init(schemaName: nil, debugDescription: "test"))

    guard case .ownDefect = MemoryComprehensionClassification(classifying: error) else {
      Issue.record("expected .ownDefect for unsupportedGenerationGuide")
      return
    }
  }

  @available(iOS, introduced: 27, message: "requires iOS 27: this error type does not exist on 26.x")
  @Test func `Session concurrent requests classifies as an own defect`() {
    let error = LanguageModelSession.Error.concurrentRequests

    guard case .ownDefect = MemoryComprehensionClassification(classifying: error) else {
      Issue.record("expected .ownDefect for concurrentRequests")
      return
    }
  }

  // MARK: - Any other error

  @Test func `An unrecognized error maps to noResponse`() {
    let error = UnrecognizedTestError()

    #expect(MemoryComprehensionError(mapping: error) == .noResponse)
  }
}
