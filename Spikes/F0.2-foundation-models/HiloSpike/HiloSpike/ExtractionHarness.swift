import FoundationModels
import os

// F0.2.2: pasa los doce relatos del corpus por el modelo y anota el resultado.
// Nunca registra el texto del relato, solo su identificador y el resultado estructurado.
struct ExtractionHarness {
  private let logger = Logger(subsystem: "dev.ruben.HiloSpike", category: "extraction")

  func run() async {
    logger.notice("SPIKE arranque, \(Corpus.stories.count, privacy: .public) relatos")
    for story in Corpus.stories {
      await extract(story)
    }
    logger.notice("SPIKE fin del banco de pruebas")
  }

  // M6/O2: repite un relato para comprobar estabilidad; delaySeconds > 0 aísla si el rate limit
  // de O6 depende de la frecuencia de peticiones (hallazgo abierto en F0.2.2).
  func runRepeated(storyID: String, times: Int, delaySeconds: Double = 0) async {
    guard let story = Corpus.stories.first(where: { $0.id == storyID }) else {
      logger.notice("SPIKE relato \(storyID, privacy: .public) no encontrado")
      return
    }
    for attempt in 1...times {
      logger.notice(
        "SPIKE repetición \(attempt, privacy: .public)/\(times, privacy: .public) de \(storyID, privacy: .public)"
      )
      await extract(story)
      if delaySeconds > 0, attempt < times {
        try? await Task.sleep(for: .seconds(delaySeconds))
      }
    }
    logger.notice("SPIKE fin de la repetición")
  }

  // O5: fabrica un prompt por encima del contextSize medido en M1, repitiendo un relato,
  // y anota el error literal del desbordamiento.
  func attemptOverflow(interfaceLanguage: String, repeatingText text: String, times: Int) async {
    let oversized = Array(repeating: text, count: times).joined(separator: "\n\n")
    logger.notice("SPIKE [overflow] intento con \(times, privacy: .public) repeticiones")
    await extract(id: "overflow", interfaceLanguage: interfaceLanguage, text: oversized)
  }

  // contrato 5 de F3: idioma de la interfaz fijo, nombres del usuario nunca traducidos
  private func instructions(interfaceLanguage: String) -> String {
    "Respond in \(interfaceLanguage). Never translate the names of people, places or objects: keep them exactly as the user wrote them."
  }

  private func extract(_ story: Corpus.Story) async {
    await extract(id: story.id, interfaceLanguage: story.interfaceLanguage, text: story.text)
  }

  private func extract(id: String, interfaceLanguage: String, text: String) async {
    let session = LanguageModelSession(
      instructions: instructions(interfaceLanguage: interfaceLanguage))
    do {
      let stream = session.streamResponse(to: text, generating: ExtractedMemory.self)
      let response = try await stream.collect()
      let memory = response.content
      let yearText = memory.deducedYear.map(String.init) ?? "sin año"
      logger.notice(
        "SPIKE [\(id, privacy: .public)] ok elementos=\(memory.elements.count, privacy: .public) fecha=\(memory.dateText != nil, privacy: .public) año=\(yearText, privacy: .public)"
      )
      for element in memory.elements {
        logger.notice(
          "SPIKE [\(id, privacy: .public)] elemento tipo=\(String(describing: element.type), privacy: .public)"
        )
      }
    } catch let error as LanguageModelSession.GenerationError {
      logger.notice(
        "SPIKE [\(id, privacy: .public)] GenerationError=\(String(describing: error), privacy: .public)"
      )
    } catch let error as LanguageModelError {
      // O6: esta superficie no la capturaba el catch de F0.2.2 y sí se lanzó en el dispositivo.
      logger.notice(
        "SPIKE [\(id, privacy: .public)] LanguageModelError=\(String(describing: error), privacy: .public)"
      )
    } catch {
      logger.notice(
        "SPIKE [\(id, privacy: .public)] error=\(String(describing: error), privacy: .public)"
      )
    }
  }
}
