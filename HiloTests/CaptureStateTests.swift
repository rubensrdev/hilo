import Foundation
import SwiftData
import Synchronization
import Testing

@testable import Hilo

// contrato 1 (S2 Captura): CaptureState gobierna narrativa, comprension en vivo y guardado sin analizar
struct CaptureStateTests {
  // nonisolated: el macro de @Test(arguments:) la lee fuera de todo contexto de actor
  private nonisolated static let errorsAndReasons:
    [(
      MemoryComprehensionError, MemoryComprehensionReason
    )] = [
      (.guardrailViolation, .guardrail),
      (.refusal, .guardrail),
      (.contextOverflow, .contextOverflow),
      (.unsupportedLanguage, .unsupportedLanguage),
      (.assetsUnavailable, .generic),
      (.decodingFailure, .generic),
      (.noResponse, .generic),
    ]

  // MARK: canUnderstand / canSaveWithoutAnalyzing

  @Test(arguments: ["", "   ", "\n\t"])
  func `canUnderstand and canSaveWithoutAnalyzing are false for an empty or blank narrative`(
    narrative: String
  ) throws {
    let state = try Self.makeState(script: .fails(.noResponse))
    state.narrative = narrative

    #expect(state.canUnderstand == false)
    #expect(state.canSaveWithoutAnalyzing == false)
  }

  @Test func `canUnderstand and canSaveWithoutAnalyzing are true once the narrative has content`()
    throws
  {
    let state = try Self.makeState(script: .fails(.noResponse))
    state.narrative = "Un domingo cualquiera en el pueblo."

    #expect(state.canUnderstand)
    #expect(state.canSaveWithoutAnalyzing)
  }

  @Test
  func `canUnderstand and canSaveWithoutAnalyzing turn false the moment comprehension starts`()
    async throws
  {
    let state = try Self.makeState(
      script: .succeeds(
        partials: [], final: Self.emptyExtraction, delayBetweenPartials: .milliseconds(50)))
    state.narrative = "Un relato cualquiera."

    state.understandAndSave()

    // transicion sincrona (paso 1 del contrato): ya vale antes de que la Task interna progrese
    #expect(state.phase == .comprehending)
    #expect(state.canUnderstand == false)
    #expect(state.canSaveWithoutAnalyzing == false)

    state.cancel()
    await waitUntil { state.phase == .capturing }
  }

  // MARK: canRetry — DEC-42, solo el generico ofrece reintentar

  @Test func `canRetry is false before any comprehension has run`() throws {
    let state = try Self.makeState(script: .fails(.noResponse))

    #expect(state.canRetry == false)
  }

  @Test func `canRetry is false while comprehension is in progress`() async throws {
    let state = try Self.makeState(
      script: .succeeds(
        partials: [], final: Self.emptyExtraction, delayBetweenPartials: .milliseconds(50)))
    state.narrative = "Un relato cualquiera."

    state.understandAndSave()

    #expect(state.canRetry == false)

    state.cancel()
    await waitUntil { state.phase == .capturing }
  }

  // MARK: comprension exitosa

  @Test
  func
    `Understanding streams extractedSoFar through every scripted partial in order before calling onUnderstood once`()
    async throws
  {
    let firstPartial = ExtractedMemory(
      elements: [ExtractedElement(name: "Marta", type: .person, role: "mi tía")],
      dateText: nil, deducedYear: nil)
    let secondPartial = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Marta", type: .person, role: "mi tía"),
        ExtractedElement(name: "la cocina", type: .place, role: "donde hablamos"),
      ], dateText: nil, deducedYear: nil)
    let final = ExtractedMemory(
      elements: secondPartial.elements, dateText: "una tarde de invierno", deducedYear: nil)
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCalls: [(ExtractedMemory, String, Data?, MemoryID?)] = []
    let fake = FakeMemoryComprehender(
      script: .succeeds(
        partials: [firstPartial, secondPartial], final: final,
        delayBetweenPartials: .milliseconds(30)))
    let state = CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, narrative, photo, id in
      understoodCalls.append((extracted, narrative, photo, id))
    }
    let photo = Data([0xAB, 0xCD])
    state.narrative = "Marta y yo hablamos en la cocina."
    state.photoData = photo

    state.understandAndSave()

    var observedElementCounts: [Int] = []
    for _ in 0..<200 {
      if let snapshot = state.extractedSoFar, observedElementCounts.last != snapshot.elements.count
      {
        observedElementCounts.append(snapshot.elements.count)
      }
      if !understoodCalls.isEmpty { break }
      try? await Task.sleep(for: .milliseconds(5))
    }

    #expect(observedElementCounts == [1, 2])
    #expect(understoodCalls.count == 1)
    let call = try #require(understoodCalls.first)
    #expect(call.0.elements.map(\.name) == ["Marta", "la cocina"])
    #expect(call.0.dateText == "una tarde de invierno")
    #expect(call.1 == "Marta y yo hablamos en la cocina.")
    #expect(call.2 == photo)
    #expect(call.3 == nil)
  }

  // MARK: los 7 caminos de fallo — contrato 4, guardado automatico sin analizar

  @Test(arguments: errorsAndReasons)
  func
    `A failed comprehension saves the narrative unanalyzed, lands on notAnalyzed with the mapped reason, and offers retry only for the generic one`(
      pair: (MemoryComprehensionError, MemoryComprehensionReason)
    ) async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let fake = FakeMemoryComprehender(script: .fails(pair.0))
    let state = CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      understoodCallCount += 1
    }
    state.narrative = "Un relato que el modelo no pudo analizar."

    state.understandAndSave()
    await waitUntil { state.phase != .comprehending }

    #expect(state.phase == .notAnalyzed(pair.1))
    // anexo DEC-46: guardarraiz y rechazo comparten texto y botones con el generico,
    // reintentar incluido; solo desbordamiento e idioma cierran con un unico boton
    #expect(state.canRetry == (pair.1 == .generic || pair.1 == .guardrail))
    #expect(understoodCallCount == 0)
    let savedID = try #require(state.savedMemoryID)
    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    #expect(record.isAnalyzed == false)
    #expect(record.narrative == "Un relato que el modelo no pudo analizar.")
    #expect(MemoryID(value: record.id) == savedID)
  }

  // MARK: reintento — DEC-45, actualiza el mismo recuerdo en vez de insertar otro

  @Test
  func
    `Retrying after a generic failure calls onUnderstood with the id already saved by the first attempt`()
    async throws
  {
    let final = ExtractedMemory(
      elements: [ExtractedElement(name: "Diego", type: .person, role: "mi primo")],
      dateText: "el año pasado", deducedYear: nil)
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCalls: [(ExtractedMemory, String, Data?, MemoryID?)] = []
    // el mismo comprehender debe fallar la primera vez y acertar en el reintento (DEC-45)
    let comprehender = SequencedComprehender(
      scripts: [.fails(.noResponse), .succeeds(partials: [], final: final)])
    let state = CaptureState(
      comprehender: comprehender, persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, narrative, photo, id in
      understoodCalls.append((extracted, narrative, photo, id))
    }
    state.narrative = "Comí con Diego el año pasado."

    state.understandAndSave()
    await waitUntil { state.phase != .comprehending }
    #expect(state.phase == .notAnalyzed(.generic))
    let firstSavedID = try #require(state.savedMemoryID)

    state.retry()
    await waitUntil { !understoodCalls.isEmpty }

    #expect(understoodCalls.count == 1)
    let call = try #require(understoodCalls.first)
    #expect(call.3 == firstSavedID)
    #expect(try await actor.fetchMemories().count == 1)
  }

  // MARK: saveWithoutAnalyzing

  @Test
  func
    `Saving without analyzing persists the narrative unanalyzed and never calls onUnderstood`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let fake = FakeMemoryComprehender(script: .fails(.noResponse))
    let state = CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      understoodCallCount += 1
    }
    state.narrative = "Un paseo que prefiero guardar tal cual."

    await state.saveWithoutAnalyzing()

    #expect(understoodCallCount == 0)
    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    #expect(record.isAnalyzed == false)
    #expect(record.narrative == "Un paseo que prefiero guardar tal cual.")
  }

  @Test func `Saving without analyzing does nothing for a blank narrative`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let fake = FakeMemoryComprehender(script: .fails(.noResponse))
    let state = CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      Issue.record("onUnderstood should never be called")
    }
    state.narrative = "   "

    await state.saveWithoutAnalyzing()

    #expect(state.savedMemoryID == nil)
    #expect(try await actor.fetchMemories().isEmpty)
  }

  @Test
  func `Saving without analyzing empties the capture so saving again cannot duplicate the memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      Issue.record("onUnderstood should never be called")
    }
    state.narrative = "La tarde que llovió en la verbena."
    state.photoData = try PhotoStripperTests.jpegWithGPS()

    await state.saveWithoutAnalyzing()

    #expect(state.narrative == "")
    #expect(state.photoData == nil)
    #expect(state.savedMemoryID == nil)
    #expect(state.phase == .capturing)
    #expect(state.canSaveWithoutAnalyzing == false)

    await state.saveWithoutAnalyzing()

    let context = ModelContext(container)
    let records = try context.fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let record = try #require(records.first)
    #expect(record.narrative == "La tarde que llovió en la verbena.")
    // la foto se guarda sin metadatos, asi que basta con que no se haya perdido al vaciar
    #expect(record.photoData != nil)
    #expect(record.isAnalyzed == false)
  }

  @Test
  func
    `A second tap on save without analyzing while the first is still saving cannot duplicate the memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      Issue.record("onUnderstood should never be called")
    }
    state.narrative = "El verano que aprendimos a nadar en el río."

    async let firstTap: Void = state.saveWithoutAnalyzing()
    async let secondTap: Void = state.saveWithoutAnalyzing()
    _ = await (firstTap, secondTap)

    let memories = try await actor.fetchMemories()
    #expect(memories.count == 1)
    #expect(memories.first?.narrative == "El verano que aprendimos a nadar en el río.")
    #expect(state.narrative == "")
  }

  // MARK: cancelacion — hueco de auditoria de concurrencia que F3 dejo sin cubrir

  @Test
  func
    `Cancelling mid-comprehension returns to capturing, persists nothing and never calls onUnderstood`()
    async throws
  {
    let firstPartial = ExtractedMemory(
      elements: [ExtractedElement(name: "Nuria", type: .person, role: "mi hermana")],
      dateText: nil, deducedYear: nil)
    let secondPartial = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Nuria", type: .person, role: "mi hermana"),
        ExtractedElement(name: "el jardín", type: .place, role: "donde jugábamos"),
      ], dateText: nil, deducedYear: nil)
    let final = ExtractedMemory(
      elements: secondPartial.elements, dateText: "un verano de la infancia", deducedYear: nil)
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let fake = FakeMemoryComprehender(
      script: .succeeds(
        partials: [firstPartial, secondPartial], final: final,
        delayBetweenPartials: .milliseconds(50)))
    let state = CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in
      understoodCallCount += 1
    }
    state.narrative = "Jugábamos con Nuria en el jardín."

    state.understandAndSave()
    try await Task.sleep(for: .milliseconds(10))
    state.cancel()
    await waitUntil { state.phase == .capturing }

    #expect(state.phase == .capturing)
    #expect(understoodCallCount == 0)
    #expect(state.savedMemoryID == nil)
    #expect(try await actor.fetchMemories().isEmpty)
  }

  // MARK: salir de la revision — DEC-47, contrato 2

  @Test func `A successful comprehension leaves the capture reviewing instead of comprehending`()
    async throws
  {
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.emptyExtraction)),
      persistenceActor: PersistenceActor(
        modelContainer: try PersistenceContainer.make(inMemory: true)),
      interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }
    state.narrative = "Una tarde en el río con mi hermano."

    state.understandAndSave()
    await waitUntil { understoodCallCount == 1 }

    #expect(understoodCallCount == 1)
    #expect(state.phase == .reviewing)
  }

  @Test
  func
    `Dismissing the review returns to capturing with narrative and photo intact, persists nothing and can understand again`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.emptyExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }
    let photo = Data([0x01, 0x02, 0x03])
    state.narrative = "La feria de agosto con los primos."
    state.photoData = photo

    state.understandAndSave()
    await waitUntil { understoodCallCount == 1 }
    state.reviewDismissed()

    #expect(state.phase == .capturing)
    #expect(state.narrative == "La feria de agosto con los primos.")
    #expect(state.photoData == photo)
    #expect(state.canUnderstand)
    #expect(state.savedMemoryID == nil)
    #expect(try await actor.fetchMemories().isEmpty)

    state.understandAndSave()
    await waitUntil { understoodCallCount == 2 }

    #expect(understoodCallCount == 2)
  }

  @Test
  func
    `Dismissing a review opened by retry returns to the generic error with the same unanalyzed memory and no new one`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: SequencedComprehender(
        scripts: [.fails(.noResponse), .succeeds(partials: [], final: Self.emptyExtraction)]),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }
    state.narrative = "El primer día de colegio de Lucía."

    state.understandAndSave()
    await waitUntil { state.phase == .notAnalyzed(.generic) }
    let firstSavedID = try #require(state.savedMemoryID)
    state.retry()
    await waitUntil { understoodCallCount == 1 }
    state.reviewDismissed()

    #expect(state.phase == .notAnalyzed(.generic))
    #expect(state.canRetry)
    #expect(state.savedMemoryID == firstSavedID)
    #expect(state.narrative == "El primer día de colegio de Lucía.")
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    #expect(records.first?.isAnalyzed == false)
  }

  @Test
  func `Saving the review empties the capture for a new memory without persisting anything itself`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(
          partials: [],
          final: ExtractedMemory(
            elements: [ExtractedElement(name: "Lucía", type: .person, role: "mi hija")],
            dateText: nil, deducedYear: nil))),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }
    state.narrative = "Lucía aprendió a montar en bici."
    state.photoData = Data([0x0A])

    state.understandAndSave()
    await waitUntil { understoodCallCount == 1 }
    state.reviewSaved()

    #expect(state.narrative == "")
    #expect(state.photoData == nil)
    #expect(state.extractedSoFar == nil)
    #expect(state.savedMemoryID == nil)
    #expect(state.phase == .capturing)
    #expect(state.canUnderstand == false)
    #expect(try await actor.fetchMemories().isEmpty)
  }

  @Test
  func `Saving a review opened by retry releases the saved id so the next memory is not an update`()
    async throws
  {
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: SequencedComprehender(
        scripts: [.fails(.noResponse), .succeeds(partials: [], final: Self.emptyExtraction)]),
      persistenceActor: PersistenceActor(
        modelContainer: try PersistenceContainer.make(inMemory: true)),
      interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }
    state.narrative = "La mudanza al piso de la calle Mayor."

    state.understandAndSave()
    await waitUntil { state.phase == .notAnalyzed(.generic) }
    _ = try #require(state.savedMemoryID)
    state.retry()
    await waitUntil { understoodCallCount == 1 }
    state.reviewSaved()

    #expect(state.savedMemoryID == nil)
    #expect(state.phase == .capturing)
  }

  @Test func `Dismissing when no review is open changes nothing`() async throws {
    var understoodCallCount = 0
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.emptyExtraction)),
      persistenceActor: PersistenceActor(
        modelContainer: try PersistenceContainer.make(inMemory: true)),
      interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCallCount += 1 }

    state.narrative = "Un relato a medio escribir."
    state.reviewDismissed()

    #expect(state.narrative == "Un relato a medio escribir.")
    #expect(state.phase == .capturing)

    state.understandAndSave()
    await waitUntil { understoodCallCount == 1 }
    state.reviewSaved()
    // onDismiss llega tambien despues de guardar: no debe devolver nada a la captura vacia
    state.reviewDismissed()

    #expect(state.narrative == "")
    #expect(state.phase == .capturing)
  }

  // MARK: fixtures

  private static let emptyExtraction = ExtractedMemory(
    elements: [], dateText: nil, deducedYear: nil)

  private static func makeState(script: FakeMemoryComprehender.Script) throws -> CaptureState {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let fake = FakeMemoryComprehender(script: script)
    return CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in }
  }
}

// necesario para DEC-45: el mismo comprehender debe fallar la primera vez y acertar en el reintento;
// Mutex en vez de nonisolated(unsafe) (prohibido sin excepcion en este proyecto), aunque las
// llamadas del test son estrictamente secuenciales, nunca concurrentes
private nonisolated final class SequencedComprehender: MemoryComprehending, Sendable {
  private let scripts: [FakeMemoryComprehender.Script]
  private let callIndex = Mutex(0)

  init(scripts: [FakeMemoryComprehender.Script]) {
    self.scripts = scripts
  }

  func comprehend(narrative: String, interfaceLanguage: String) -> AsyncThrowingStream<
    ExtractedMemory, Error
  > {
    let index = callIndex.withLock { value -> Int in
      let current = value
      value += 1
      return current
    }
    let script = scripts[min(index, scripts.count - 1)]
    return FakeMemoryComprehender(script: script).comprehend(
      narrative: narrative, interfaceLanguage: interfaceLanguage)
  }
}

// espera acotada a una condicion observable, sin exponer la Task interna de CaptureState
private func waitUntil(
  attempts: Int = 200, sleepEach: Duration = .milliseconds(5), _ condition: () -> Bool
) async {
  var remaining = attempts
  while !condition(), remaining > 0 {
    try? await Task.sleep(for: sleepEach)
    remaining -= 1
  }
}
