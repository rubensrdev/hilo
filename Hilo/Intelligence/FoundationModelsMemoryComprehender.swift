import FoundationModels

// implementacion real de contrato 1 sobre Foundation Models; el patron de sesion/streaming
// viene validado por el spike F0.2 (ExtractionHarness.swift, nunca mergeado)
nonisolated struct FoundationModelsMemoryComprehender: MemoryComprehending {
  func comprehend(
    narrative: String,
    interfaceLanguage: String
  ) -> AsyncThrowingStream<ExtractedMemory, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          // una sesion por generacion, sin historial
          // precalentamiento descartado: M5 (spike F0.2, HALLAZGOS.md) midio que prewarm(promptPrefix:)
          // no baja la latencia al primer fragmento y hace el total mas inestable
          let session = LanguageModelSession(
            instructions: Self.instructions(interfaceLanguage: interfaceLanguage))
          let stream = session.streamResponse(to: narrative, generating: ExtractedMemory.self)
          for try await snapshot in stream {
            let candidate = ExtractedMemory(partial: snapshot.content)
            continuation.yield(ExtractionValidation.validate(candidate, against: narrative))
          }
          continuation.finish()
        } catch {
          // mapeo caso a caso a MemoryComprehensionError llega en F3.4; aqui se reenvia tal cual
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  // contrato 5: idioma de la interfaz fijo, nombres del usuario nunca traducidos
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
