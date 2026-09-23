import Foundation
import SwiftData
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

  @Test func `Dismissing when no review is open changes nothing`() async throws {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.emptyExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }

    state.narrative = "Un relato a medio escribir."
    state.reviewDismissed()

    #expect(state.narrative == "Un relato a medio escribir.")
    #expect(state.phase == .capturing)

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    state.reviewConfirmed(
      try await Self.reviewState(for: try #require(understood.first), actor: actor),
      dateTextAtSave: "")
    await waitUntil { state.phase == .capturing }
    // onDismiss llega tambien despues de guardar: no debe devolver nada a la captura vacia
    state.reviewDismissed()

    #expect(state.narrative == "")
    #expect(state.phase == .capturing)
  }

  // MARK: guardar desde la revision — F4.5.2, contrato 2 + DEC-40 + DEC-45

  @Test
  func `Saving the review persists one analyzed memory with its elements and empties the capture`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    state.narrative = "Lucía aprendió a montar en bici."
    state.photoData = try PhotoStripperTests.jpegWithGPS()

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    state.reviewConfirmed(
      try await Self.reviewState(for: try #require(understood.first), actor: actor),
      dateTextAtSave: "")
    await waitUntil { state.phase == .capturing }

    let context = ModelContext(container)
    let records = try context.fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let record = try #require(records.first)
    #expect(record.isAnalyzed)
    #expect(record.narrative == "Lucía aprendió a montar en bici.")
    #expect(record.photoData != nil)
    #expect(try context.fetch(FetchDescriptor<ElementRecord>()).map(\.displayName) == ["Lucía"])
    #expect(try await actor.fetchAppearances().count == 1)
    #expect(state.narrative == "")
    #expect(state.photoData == nil)
    #expect(state.extractedSoFar == nil)
    #expect(state.savedMemoryID == nil)
    #expect(state.canUnderstand == false)
  }

  @Test
  func
    `Saving a review opened by retry analyzes the memory already saved instead of inserting another`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: SequencedComprehender(
        scripts: [.fails(.noResponse), .succeeds(partials: [], final: Self.luciaExtraction)]),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    state.narrative = "La mudanza al piso de la calle Mayor con Lucía."

    state.understandAndSave()
    await waitUntil { state.phase == .notAnalyzed(.generic) }
    let firstSavedID = try #require(state.savedMemoryID)
    state.retry()
    await waitUntil { understood.count == 1 }
    state.reviewConfirmed(
      try await Self.reviewState(
        for: try #require(understood.first), actor: actor, excluding: firstSavedID),
      dateTextAtSave: "")
    await waitUntil { state.phase == .capturing }

    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    #expect(records.first?.id == firstSavedID.value)
    #expect(records.first?.isAnalyzed == true)
    #expect(try await actor.fetchAppearances().map(\.memoryID) == [firstSavedID])
    #expect(state.savedMemoryID == nil)
    #expect(state.narrative == "")
  }

  // DEC-47: deslizar con el guardado en vuelo dispara onDismiss
  @Test
  func
    `Dismissing right after confirming the save does not bring the narrative back or duplicate the memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    state.narrative = "Lucía y el primer diente."

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    let reviewState = try await Self.reviewState(for: try #require(understood.first), actor: actor)
    state.reviewConfirmed(reviewState, dateTextAtSave: "")
    state.reviewDismissed()

    #expect(state.phase == .savingReview)
    #expect(state.canUnderstand == false)
    await waitUntil { state.phase == .capturing }

    #expect(state.narrative == "")
    #expect(try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>()).count == 1)
  }

  @Test
  func `A failed save returns to the capture with narrative and photo intact and nothing stored`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    let photo = try PhotoStripperTests.jpegWithGPS()
    state.narrative = "Lucía en la playa de Laredo."
    state.photoData = photo

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    // un elemento conocido que no esta en el almacen: la aparicion confirmada no encuentra su elemento
    let ghost = try #require(Element(displayName: "Lucía", type: .person))
    state.reviewConfirmed(
      ReviewState(
        extracted: try #require(understood.first), knownElements: [ghost], appearances: []),
      dateTextAtSave: "")
    await waitUntil { state.phase != .savingReview }

    #expect(state.phase == .capturing)
    #expect(state.narrative == "Lucía en la playa de Laredo.")
    #expect(state.photoData == photo)
    #expect(state.extractedSoFar == nil)
    #expect(state.canUnderstand)

    // el mismo relato se puede volver a comprender y guardar, sin arrastrar nada del intento fallido
    state.understandAndSave()
    await waitUntil { understood.count == 2 }
    state.reviewConfirmed(
      try await Self.reviewState(for: try #require(understood.last), actor: actor),
      dateTextAtSave: "")
    await waitUntil { state.phase == .capturing }

    let context = ModelContext(container)
    #expect(try context.fetch(FetchDescriptor<MemoryRecord>()).count == 1)
    #expect(try context.fetch(FetchDescriptor<ElementRecord>()).map(\.displayName) == ["Lucía"])
    #expect(try await actor.fetchAppearances().count == 1)
  }

  // DEC-40: el renombrado pendiente de la revision se aplica al guardar
  @Test func `A pending rename is applied to the stored element when the review is saved`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let abuelo = try #require(Element(displayName: "el abuelo", type: .person))
    _ = try await actor.save(abuelo)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(
          partials: [],
          final: ExtractedMemory(
            elements: [ExtractedElement(name: "el abuelo", type: .person, role: "")],
            dateText: nil, deducedYear: nil))),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    state.narrative = "El abuelo nos llevó al río."

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    var saved = try await Self.reviewState(for: try #require(understood.first), actor: actor)
    saved.rename(try #require(saved.items.first?.id), to: "abuelo Ramón")
    state.reviewConfirmed(saved, dateTextAtSave: "")
    await waitUntil { state.phase == .capturing }

    #expect(try await actor.fetchElements().map(\.displayName) == ["abuelo Ramón"])
  }

  // MARK: aviso del guardado — F4.5.3, el coordinador decide si hay momento de la conexion

  @Test
  func `A saved review reports the stored memory's id once the capture is already empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    var reported: [MemoryID] = []
    var narrativeWhenReported: String?
    state.onReviewSaved = { id in
      reported.append(id)
      narrativeWhenReported = state.narrative
    }
    state.narrative = "Lucía y el primer diente."

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    state.reviewConfirmed(
      try await Self.reviewState(for: try #require(understood.first), actor: actor),
      dateTextAtSave: "")
    await waitUntil { reported.count == 1 }

    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(reported.map(\.value) == records.map(\.id))
    #expect(narrativeWhenReported == "")
  }

  @Test func `A failed save reports the failure and never a saved memory`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understood: [ExtractedMemory] = []
    let state = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, _, _, _ in understood.append(extracted) }
    var savedReports = 0
    var failedReports = 0
    state.onReviewSaved = { _ in savedReports += 1 }
    state.onReviewSaveFailed = { failedReports += 1 }
    state.narrative = "Lucía en la playa de Laredo."

    state.understandAndSave()
    await waitUntil { understood.count == 1 }
    // un elemento conocido que no esta en el almacen: la aparicion confirmada no encuentra su elemento
    let ghost = try #require(Element(displayName: "Lucía", type: .person))
    state.reviewConfirmed(
      ReviewState(
        extracted: try #require(understood.first), knownElements: [ghost], appearances: []),
      dateTextAtSave: "")
    await waitUntil { failedReports == 1 }

    #expect(failedReports == 1)
    #expect(savedReports == 0)
  }

  // MARK: fixtures

  private static let emptyExtraction = ExtractedMemory(
    elements: [], dateText: nil, deducedYear: nil)

  private static let luciaExtraction = ExtractedMemory(
    elements: [ExtractedElement(name: "Lucía", type: .person, role: "mi hija")],
    dateText: nil, deducedYear: nil)

  // lo mismo que ReviewCoordinator.present lee del almacen antes de abrir la hoja
  private static func reviewState(
    for extracted: ExtractedMemory, actor: PersistenceActor, excluding: MemoryID? = nil
  ) async throws -> ReviewState {
    ReviewState(
      extracted: extracted, knownElements: try await actor.fetchElements(),
      appearances: try await actor.fetchAppearances(), excludingMemoryID: excluding)
  }

  private static func makeState(script: FakeMemoryComprehender.Script) throws -> CaptureState {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let fake = FakeMemoryComprehender(script: script)
    return CaptureState(
      comprehender: fake, persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in }
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
