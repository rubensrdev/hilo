import Foundation
import SwiftData
import Testing

@testable import Hilo

// DEC-45: ningun camino que deja un recuerdo sin analizar le da apariciones; la ampliacion 7 lo rompera
struct UnanalyzedMemoryInvariantTests {
  @Test func `Saving without analyzing leaves no appearances on the memory`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let capture = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in }
    capture.narrative = "Lucía y el primer diente."

    await capture.saveWithoutAnalyzing()

    try Self.expectInvariant(in: container)
  }

  @Test func `A generic comprehension error leaves no appearances on the saved memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let capture = CaptureState(
      comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in }
    capture.narrative = "Lucía y el primer diente."

    capture.understandAndSave()
    await waitUntil { capture.phase == .notAnalyzed(.generic) }

    try Self.expectInvariant(in: container)
  }

  @Test func `A failed completeAnalysis leaves no appearances on the memory`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(Memory(narrative: "Irene y Lucía en el pantano.", savedAt: Date()))
    let memoryID = try await actor.save(memory, isAnalyzed: false, isExample: false)
    // Irene es nueva y se inserta antes; Lucía se da por conocida pero no esta en el almacen
    let ghost = try #require(Element(displayName: "Lucía", type: .person))
    let extracted = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Irene", type: .person, role: "mi amiga"),
        ExtractedElement(name: "Lucía", type: .person, role: "mi hija"),
      ], dateText: nil, deducedYear: nil)
    let outcome = ReviewState(extracted: extracted, knownElements: [ghost], appearances: [])
      .outcome(memoryID: memoryID, dateTextAtSave: "")

    await #expect(throws: PersistenceActor.WriteError.elementNotFound) {
      try await actor.completeAnalysis(of: memoryID, outcome: outcome)
    }
    // otra escritura en el mismo actor: sin rollback, lo pendiente del fallo se guardaria aqui
    _ = try await actor.save(try #require(Element(displayName: "el pantano", type: .place)))

    try Self.expectInvariant(in: container)
  }

  @Test func `A retry whose review is dismissed leaves no appearances on the memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    var understoodCount = 0
    let capture = CaptureState(
      comprehender: SequencedComprehender(
        scripts: [.fails(.noResponse), .succeeds(partials: [], final: Self.luciaExtraction)]),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCount += 1 }
    capture.narrative = "Lucía y el primer diente."

    capture.understandAndSave()
    await waitUntil { capture.phase == .notAnalyzed(.generic) }
    capture.retry()
    await waitUntil { understoodCount == 1 }
    try #require(understoodCount == 1)
    capture.reviewDismissed()

    try Self.expectInvariant(in: container)
  }

  @Test func `Understanding later with the review dismissed leaves no appearances on the memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(Memory(narrative: "Lucía y el primer diente.", savedAt: Date()))
    let memoryID = try await actor.save(memory, isAnalyzed: false, isExample: false)
    var understoodCount = 0
    let state = UnderstandLaterState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCount += 1 }

    await state.start(memoryID: memoryID)
    try #require(understoodCount == 1)
    state.reviewDismissed()

    try Self.expectInvariant(in: container)
  }

  // MARK: fixtures

  private static let luciaExtraction = ExtractedMemory(
    elements: [ExtractedElement(name: "Lucía", type: .person, role: "mi hija")],
    dateText: nil, deducedYear: nil)

  // el oraculo lee el almacen directamente, sin pasar por el codigo que se prueba
  private static func expectInvariant(in container: ModelContainer) throws {
    let context = ModelContext(container)
    let unanalyzed = try context.fetch(
      FetchDescriptor<MemoryRecord>(predicate: #Predicate { !$0.isAnalyzed }))
    try #require(!unanalyzed.isEmpty, "el camino deberia dejar al menos un recuerdo sin analizar")
    let unanalyzedIDs = Set(unanalyzed.map(\.id))
    let offending = try context.fetch(FetchDescriptor<AppearanceRecord>())
      .compactMap { $0.memory?.id }
      .filter { unanalyzedIDs.contains($0) }
    #expect(offending.isEmpty)
  }
}

// espera acotada a una condicion observable, sin exponer las Task internas
private func waitUntil(
  attempts: Int = 200, sleepEach: Duration = .milliseconds(5), _ condition: () -> Bool
) async {
  var remaining = attempts
  while !condition(), remaining > 0 {
    try? await Task.sleep(for: sleepEach)
    remaining -= 1
  }
}
