import Foundation
import SwiftData
import Testing

@testable import Hilo

/// No path that leaves a memory unanalyzed gives it appearances.
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
    // Irene is new and inserted first; Lucía is taken as known but is not in the store.
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
    // Another write on the same actor: without a rollback, the failure's pending changes would be saved here.
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

  /// The oracle reads the store directly, bypassing the code under test.
  private static func expectInvariant(in container: ModelContainer) throws {
    let context = ModelContext(container)
    let unanalyzed = try context.fetch(
      FetchDescriptor<MemoryRecord>(predicate: #Predicate { !$0.isAnalyzed }))
    try #require(!unanalyzed.isEmpty, "the path should leave at least one unanalyzed memory")
    let unanalyzedIDs = Set(unanalyzed.map(\.id))
    let offending = try context.fetch(FetchDescriptor<AppearanceRecord>())
      .compactMap { $0.memory?.id }
      .filter { unanalyzedIDs.contains($0) }
    #expect(offending.isEmpty)
  }
}

/// A bounded wait on an observable condition, without exposing the inner Tasks.
private func waitUntil(
  attempts: Int = 200, sleepEach: Duration = .milliseconds(5), _ condition: () -> Bool
) async {
  var remaining = attempts
  while !condition(), remaining > 0 {
    try? await Task.sleep(for: sleepEach)
    remaining -= 1
  }
}
