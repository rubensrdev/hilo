import FoundationModels

/// The session and streaming pattern is the one the F0.2 spike validated.
nonisolated struct FoundationModelsMemoryComprehender: MemoryComprehending {
  func comprehend(
    narrative: String,
    interfaceLanguage: String
  ) -> AsyncThrowingStream<ExtractedMemory, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          // One session per generation, no history. No prewarm: the F0.2 spike measured that it doesn't
          // cut the time to the first chunk and makes the total latency less stable.
          let session = LanguageModelSession(
            instructions: Self.instructions(interfaceLanguage: interfaceLanguage))
          let stream = session.streamResponse(to: narrative, generating: ExtractedMemory.self)
          for try await snapshot in stream {
            let candidate = ExtractedMemory(partial: snapshot.content)
            continuation.yield(ExtractionValidation.validate(candidate, against: narrative))
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: MemoryComprehensionError(mapping: error))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// Fixed interface language; the user's names are never translated.
  static func instructions(interfaceLanguage: String) -> String {
    let language = languageName(for: interfaceLanguage)
    return """
      Respond in \(language). Never translate the names of people, places or objects the user \
      mentions in their story: keep them exactly as they wrote them.
      """
  }

  private static func languageName(for interfaceLanguage: String) -> String {
    switch interfaceLanguage {
    case "es": "Spanish"
    case "en": "English"
    default: interfaceLanguage
    }
  }
}
