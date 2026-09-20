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

  // comprobación puntual de reproducibilidad del error en mixto-esEn (O6), se revierte tras usarla
  func runRepeated(storyID: String, times: Int) async {
    guard let story = Corpus.stories.first(where: { $0.id == storyID }) else {
      logger.notice("SPIKE relato \(storyID, privacy: .public) no encontrado")
      return
    }
    for attempt in 1...times {
      logger.notice(
        "SPIKE repetición \(attempt, privacy: .public)/\(times, privacy: .public) de \(storyID, privacy: .public)"
      )
      await extract(story)
    }
    logger.notice("SPIKE fin de la repetición")
  }

  // contrato 5 de F3: idioma de la interfaz fijo, nombres del usuario nunca traducidos
  private func instructions(interfaceLanguage: String) -> String {
    "Respond in \(interfaceLanguage). Never translate the names of people, places or objects: keep them exactly as the user wrote them."
  }

  private func extract(_ story: Corpus.Story) async {
    let session = LanguageModelSession(
      instructions: instructions(interfaceLanguage: story.interfaceLanguage))
    do {
      let stream = session.streamResponse(to: story.text, generating: ExtractedMemory.self)
      let response = try await stream.collect()
      let memory = response.content
      let yearText = memory.deducedYear.map(String.init) ?? "sin año"
      logger.notice(
        "SPIKE [\(story.id, privacy: .public)] ok elementos=\(memory.elements.count, privacy: .public) fecha=\(memory.dateText != nil, privacy: .public) año=\(yearText, privacy: .public)"
      )
      for element in memory.elements {
        logger.notice(
          "SPIKE [\(story.id, privacy: .public)] elemento tipo=\(String(describing: element.type), privacy: .public)"
        )
      }
    } catch let error as LanguageModelSession.GenerationError {
      logger.notice(
        "SPIKE [\(story.id, privacy: .public)] GenerationError=\(String(describing: error), privacy: .public)"
      )
    } catch {
      logger.notice(
        "SPIKE [\(story.id, privacy: .public)] error=\(String(describing: error), privacy: .public)"
      )
    }
  }
}
