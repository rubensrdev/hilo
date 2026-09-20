import os

// F0.2.3: orquesta M1-M6 y O1-O5 en orden, para que ContentView solo llame a un sitio.
// En el físico, una sola generación deja el resto de la sesión en rate limit más de 40s
// (hallazgo de la primera pasada): SPACING espacia TODAS las llamadas de generación, no solo
// las de una repetición concreta.
struct F023Runner {
  private let logger = Logger(subsystem: "dev.ruben.HiloSpike", category: "f023")
  private let measurement = MeasurementHarness()
  private let extraction = ExtractionHarness()
  private let spacing: Double = 28

  private func pause() async {
    try? await Task.sleep(for: .seconds(spacing))
  }

  func run() async {
    logger.notice("SPIKE F0.2.3 arranque")

    // M1-M3 no consumen el modelo (tokenCount(for:) es aparte de la generación): sin espaciar.
    await measurement.measureContextSize()
    await measurement.measureExtractionCost()
    await measurement.measureWritingCost()

    await measurement.measureLatency(
      storyID: "es-cuatroParrafos", prewarmed: false, spacingSeconds: spacing)
    await pause()
    await measurement.measureLatency(
      storyID: "es-cuatroParrafos", prewarmed: true, spacingSeconds: spacing)
    await pause()

    // M6: estabilidad, un relato por idioma, tres repeticiones.
    await extraction.runRepeated(storyID: "es-cuatroParrafos", times: 3, delaySeconds: spacing)
    await pause()
    await extraction.runRepeated(storyID: "en-cuatroParrafos", times: 3, delaySeconds: spacing)
    await pause()

    // O2: guardarraíles con los tres relatos delicados, tres repeticiones cada uno.
    await extraction.runRepeated(storyID: "intimo-muerte", times: 3, delaySeconds: spacing)
    await pause()
    await extraction.runRepeated(storyID: "intimo-enfermedad", times: 3, delaySeconds: spacing)
    await pause()
    await extraction.runRepeated(storyID: "guerra-posguerra", times: 3, delaySeconds: spacing)
    await pause()

    // O3/O4: relato mezclado y relatos sin fecha/fecha ambigua, con el catch ampliado.
    await extraction.runRepeated(storyID: "mixto-esEn", times: 1)
    await pause()
    await extraction.runRepeated(storyID: "es-sinFecha", times: 1)
    await pause()
    await extraction.runRepeated(storyID: "en-sinFecha", times: 1)
    await pause()
    await extraction.runRepeated(storyID: "es-fechaAmbigua", times: 1)
    await pause()
    await extraction.runRepeated(storyID: "en-fechaAmbigua", times: 1)
    await pause()

    // Pregunta abierta de O6: mismo relato, espaciado, para aislar si el rate limit
    // depende de la frecuencia de peticiones.
    await extraction.runRepeated(storyID: "mixto-esEn", times: 3, delaySeconds: spacing)
    await pause()

    // O5: desbordamiento deliberado.
    if let longStory = Corpus.stories.first(where: { $0.id == "es-cuatroParrafos" }) {
      await extraction.attemptOverflow(
        interfaceLanguage: longStory.interfaceLanguage, repeatingText: longStory.text, times: 70)
    }

    logger.notice("SPIKE F0.2.3 fin")
  }
}
