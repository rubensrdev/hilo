import FoundationModels
import os

// F0.2.3: M1, M2, M3 y M5. M4 no mide nada nuevo — se calcula a partir de estas en el informe.
struct MeasurementHarness {
  private let logger = Logger(subsystem: "dev.ruben.HiloSpike", category: "measurement")

  private func instructions(interfaceLanguage: String) -> String {
    "Respond in \(interfaceLanguage). Never translate the names of people, places or objects: keep them exactly as the user wrote them."
  }

  // M1: ventana de contexto de la generación 27, de referencia frente a los 4096 documentados de iOS 26.
  func measureContextSize() async {
    let contextSize = SystemLanguageModel.default.contextSize
    logger.notice(
      "SPIKE [M1] contextSize=\(contextSize, privacy: .public) (referencia gen27, no el tope)")
  }

  // M2: coste en tokens de la extracción, por relato y por idioma, separando instrucciones/esquema/prompt.
  func measureExtractionCost() async {
    let model = SystemLanguageModel.default
    let schema = ExtractedMemory.generationSchema
    for story in Corpus.stories {
      do {
        let instructionsTokens = try await model.tokenCount(
          for: Instructions(instructions(interfaceLanguage: story.interfaceLanguage)))
        let schemaTokens = try await model.tokenCount(for: schema)
        let promptTokens = try await model.tokenCount(for: story.text)
        let total = instructionsTokens + schemaTokens + promptTokens
        logger.notice(
          "SPIKE [M2][\(story.id, privacy: .public)] instrucciones=\(instructionsTokens, privacy: .public) esquema=\(schemaTokens, privacy: .public) prompt=\(promptTokens, privacy: .public) total=\(total, privacy: .public)"
        )
      } catch {
        logger.notice(
          "SPIKE [M2][\(story.id, privacy: .public)] error=\(String(describing: error), privacy: .public)"
        )
      }
    }
  }

  // M3: coste en tokens de un prompt de redacción con N recuerdos típicos como material.
  // No genera un retrato real: el contrato de redacción es de F6/F7, fuera de alcance aquí.
  func measureWritingCost() async {
    let model = SystemLanguageModel.default
    let summaries = Corpus.stories.map { "- \($0.id): \($0.text.prefix(120))..." }
    for count in [4, 6, 8, 10, 12] {
      let material = summaries.prefix(count).joined(separator: "\n")
      let prompt = "Write a short portrait using only these memories:\n\(material)"
      do {
        let tokens = try await model.tokenCount(for: prompt)
        logger.notice(
          "SPIKE [M3] recuerdos=\(count, privacy: .public) tokens=\(tokens, privacy: .public)")
      } catch {
        logger.notice(
          "SPIKE [M3] recuerdos=\(count, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
      }
    }
  }

  // M5: latencia hasta el primer fragmento y hasta el final, con y sin precalentamiento, 5 repeticiones.
  // spacingSeconds espacia las llamadas: en el físico, una sola generación ya deja el resto
  // de la sesión en rate limit durante más de 40s (hallazgo de la primera pasada de F0.2.3).
  func measureLatency(
    storyID: String, prewarmed: Bool, repetitions: Int = 5, spacingSeconds: Double = 0
  ) async {
    guard let story = Corpus.stories.first(where: { $0.id == storyID }) else {
      logger.notice("SPIKE [M5] relato \(storyID, privacy: .public) no encontrado")
      return
    }
    for attempt in 1...repetitions {
      let session = LanguageModelSession(
        instructions: instructions(interfaceLanguage: story.interfaceLanguage))
      if prewarmed {
        session.prewarm()
      }
      let clock = ContinuousClock()
      let start = clock.now
      do {
        let stream = session.streamResponse(to: story.text, generating: ExtractedMemory.self)
        var firstFragment: Duration?
        for try await _ in stream {
          if firstFragment == nil {
            firstFragment = clock.now - start
          }
        }
        let total = clock.now - start
        logger.notice(
          "SPIKE [M5] precalentado=\(prewarmed, privacy: .public) repetición=\(attempt, privacy: .public) primerFragmento=\(firstFragment.map(String.init(describing:)) ?? "n/d", privacy: .public) total=\(String(describing: total), privacy: .public)"
        )
      } catch {
        logger.notice(
          "SPIKE [M5] precalentado=\(prewarmed, privacy: .public) repetición=\(attempt, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
      }
      if spacingSeconds > 0, attempt < repetitions {
        try? await Task.sleep(for: .seconds(spacingSeconds))
      }
    }
  }
}
