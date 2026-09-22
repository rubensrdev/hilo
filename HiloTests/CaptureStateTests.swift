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
    `Saving without analyzing persists the narrative unanalyzed, fixes savedMemoryID and never calls onUnderstood`()
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
    let savedID = try #require(state.savedMemoryID)
    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    #expect(record.isAnalyzed == false)
    #expect(record.narrative == "Un paseo que prefiero guardar tal cual.")
    #expect(MemoryID(value: record.id) == savedID)
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
