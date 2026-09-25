import Foundation
import SwiftData
import Testing

@testable import Hilo

struct UnderstandLaterStateTests {
  @Test
  func
    `Understanding later reviews the narrative as it is stored now, starting from no appearances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    // What editing in the detail does: the stored narrative changes after it was saved.
    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    record.narrative = "Lucía y el primer diente, en casa de los abuelos."
    try context.save()
    let (state, coordinator) = Self.wired(actor: actor)

    await state.start(memoryID: memoryID)
    await waitUntil { coordinator.presentation != nil }

    let (reviewState, narrative) = try #require(Self.review(in: coordinator))
    #expect(narrative == "Lucía y el primer diente, en casa de los abuelos.")
    #expect(state.phase == .reviewing)
    #expect(reviewState.blocks.known.isEmpty)
    #expect(reviewState.blocks.understood.map(\.name) == ["Lucía"])
    #expect(try await actor.fetchAppearances().isEmpty)
  }

  @Test
  func `Dismissing the review leaves the memory unanalyzed with the same savedAt and photo`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed(
      "Lucía en la playa de Laredo.", photo: try PhotoStripperTests.jpegWithGPS(), actor: actor)
    let before = try #require(
      try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>()).first)
    let (savedAtBefore, photoBefore) = (before.savedAt, before.photoData)
    let (state, coordinator) = Self.wired(actor: actor)

    await state.start(memoryID: memoryID)
    await waitUntil { coordinator.presentation != nil }
    try #require(coordinator.presentation != nil)
    coordinator.presentation = nil
    state.reviewDismissed()

    #expect(state.phase == .idle)
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let after = try #require(records.first)
    #expect(after.isAnalyzed == false)
    #expect(after.savedAt == savedAtBefore)
    #expect(after.photoData == photoBefore)
    #expect(try await actor.fetchAppearances().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
  }

  /// «in N memories» doesn't count the memory being understood.
  @Test func `The review counts José's other memories without this one`() async throws {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let earlier = try #require(Memory(narrative: "José trajo naranjas.", savedAt: Date()))
    _ = try await actor.save(earlier, isAnalyzed: true, isExample: false)
    let jose = try #require(Element(displayName: "José", type: .person))
    _ = try await actor.save(jose)
    try await actor.save(
      Appearance(memoryID: earlier.id, elementID: jose.id, role: nil, status: .confirmedByUser))
    let memoryID = try await Self.saveUnanalyzed("Una tarde de dominó con José.", actor: actor)
    let (state, coordinator) = Self.wired(actor: actor, extraction: Self.joseExtraction)

    await state.start(memoryID: memoryID)
    await waitUntil { coordinator.presentation != nil }

    let (reviewState, _) = try #require(Self.review(in: coordinator))
    #expect(reviewState.excludingMemoryID == memoryID)
    #expect(reviewState.blocks.known.map(\.otherMemoriesCount) == [1])
  }

  @Test
  func `Saving the review analyzes the same memory, keeps savedAt and photo, and reports its id`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed(
      "Lucía en la playa de Laredo.", photo: try PhotoStripperTests.jpegWithGPS(), actor: actor)
    let before = try #require(
      try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>()).first)
    let (savedAtBefore, photoBefore) = (before.savedAt, before.photoData)
    let (state, coordinator) = Self.wired(actor: actor)
    var reportedIDs: [MemoryID] = []
    state.onReviewSaved = { reportedIDs.append($0) }

    await state.start(memoryID: memoryID)
    await waitUntil { coordinator.presentation != nil }
    let (reviewState, _) = try #require(Self.review(in: coordinator))
    state.reviewConfirmed(reviewState, dateTextAtSave: "")
    await waitUntil { !reportedIDs.isEmpty }

    #expect(reportedIDs == [memoryID])
    #expect(state.phase == .idle)
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let after = try #require(records.first)
    #expect(MemoryID(value: after.id) == memoryID)
    #expect(after.isAnalyzed)
    #expect(after.savedAt == savedAtBefore)
    #expect(after.photoData == photoBefore)
    let appearances = try await actor.fetchAppearances()
    #expect(appearances.map(\.memoryID) == [memoryID])
    #expect(try await actor.fetchElements().map(\.displayName) == ["Lucía"])
  }

  @Test
  func
    `A failed comprehension on this path tells why, inserts nothing and leaves the memory as it was`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    var understoodCount = 0
    let state = UnderstandLaterState(
      comprehender: FakeMemoryComprehender(script: .fails(.noResponse)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCount += 1 }

    await state.start(memoryID: memoryID)

    #expect(understoodCount == 0)
    #expect(state.phase == .notAnalyzed(.generic))
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.map { MemoryID(value: $0.id) } == [memoryID])
    #expect(records.first?.isAnalyzed == false)
    #expect(records.first?.narrative == "Lucía y el primer diente.")
  }

  @Test
  func
    `Cancelling while the model is comprehending returns to idle and leaves the memory untouched`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    let savedAtBefore = try #require(
      try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>()).first
    ).savedAt
    var understoodCount = 0
    // A real gap between partials, to cancel in.
    let state = UnderstandLaterState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(
          partials: [Self.luciaExtraction], final: Self.luciaExtraction,
          delayBetweenPartials: .milliseconds(300))),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCount += 1 }

    let starting = Task { await state.start(memoryID: memoryID) }
    await waitUntil { state.phase == .comprehending }
    try #require(state.phase == .comprehending)
    starting.cancel()
    await starting.value

    #expect(state.phase == .idle)
    #expect(understoodCount == 0)
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.map { MemoryID(value: $0.id) } == [memoryID])
    #expect(records.first?.isAnalyzed == false)
    #expect(records.first?.savedAt == savedAtBefore)
    #expect(try await actor.fetchAppearances().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
  }

  @Test func `After a failed comprehension, starting again comprehends the memory again`()
    async throws
  {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    var understoodIDs: [MemoryID?] = []
    let state = UnderstandLaterState(
      comprehender: SequencedComprehender(
        scripts: [.fails(.noResponse), .succeeds(partials: [], final: Self.luciaExtraction)]),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, id in understoodIDs.append(id) }

    await state.start(memoryID: memoryID)
    try #require(state.phase == .notAnalyzed(.generic))
    await state.start(memoryID: memoryID)

    #expect(understoodIDs == [memoryID])
    #expect(state.phase == .reviewing)
  }

  @Test func `An analyzed memory or an unknown id never opens the review`() async throws {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let analyzed = try #require(Memory(narrative: "Lucía en Laredo.", savedAt: Date()))
    _ = try await actor.save(analyzed, isAnalyzed: true, isExample: false)
    var understoodCount = 0
    let state = UnderstandLaterState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: Self.luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { _, _, _, _ in understoodCount += 1 }

    await state.start(memoryID: analyzed.id)
    await state.start(memoryID: MemoryID())

    #expect(understoodCount == 0)
    #expect(state.phase == .idle)
  }

  // MARK: notices — the same rule as in capture

  @Test func `A review that cannot be prepared returns to idle with a notice`() async throws {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    let (state, _) = Self.wired(actor: actor)

    await state.start(memoryID: memoryID)
    state.reviewPreparationFailed()

    #expect(state.phase == .idle)
    #expect(state.notice == .reviewUnavailable)
  }

  @Test func `Starting again clears the notice`() async throws {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let memoryID = try await Self.saveUnanalyzed("Lucía y el primer diente.", actor: actor)
    let (state, _) = Self.wired(actor: actor)
    await state.start(memoryID: memoryID)
    state.reviewPreparationFailed()

    await state.start(memoryID: memoryID)

    #expect(state.notice == nil)
    #expect(state.phase == .reviewing)
  }

  @Test func `A failed review save returns to idle with a notice and the memory unanalyzed`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memoryID = try await Self.saveUnanalyzed("Lucía en la playa de Laredo.", actor: actor)
    let (state, _) = Self.wired(actor: actor)
    var failedReports = 0
    state.onReviewSaveFailed = { failedReports += 1 }

    await state.start(memoryID: memoryID)
    // A known element missing from the store: the confirmed appearance can't find its element.
    let ghost = try #require(Element(displayName: "Lucía", type: .person))
    state.reviewConfirmed(
      ReviewState(extracted: Self.luciaExtraction, knownElements: [ghost], appearances: []),
      dateTextAtSave: "")
    await waitUntil { failedReports == 1 }

    #expect(state.phase == .idle)
    #expect(state.notice == .reviewNotSaved)
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.first?.isAnalyzed == false)
  }

  // MARK: fixtures

  private static let luciaExtraction = ExtractedMemory(
    elements: [ExtractedElement(name: "Lucía", type: .person, role: "mi hija")],
    dateText: nil, deducedYear: nil)

  private static let joseExtraction = ExtractedMemory(
    elements: [ExtractedElement(name: "José", type: .person, role: "mi abuelo")],
    dateText: nil, deducedYear: nil)

  private static func saveUnanalyzed(
    _ narrative: String, photo: Data? = nil, actor: PersistenceActor
  ) async throws -> MemoryID {
    let memory = try #require(Memory(narrative: narrative, savedAt: Date()))
    return try await actor.save(memory, photoData: photo, isAnalyzed: false, isExample: false)
  }

  /// The same wiring HiloApp.init uses for capture.
  private static func wired(
    actor: PersistenceActor, extraction: ExtractedMemory = luciaExtraction
  ) -> (UnderstandLaterState, ReviewCoordinator) {
    let coordinator = ReviewCoordinator(persistenceActor: actor)
    let state = UnderstandLaterState(
      comprehender: FakeMemoryComprehender(script: .succeeds(partials: [], final: extraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, narrative, _, savedMemoryID in
      coordinator.present(extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
    }
    // weak: the state and the coordinator point at each other.
    coordinator.onPreparationFailed = { [weak state] in state?.reviewPreparationFailed() }
    state.onReviewSaved = { coordinator.showConnections(savedMemoryID: $0) }
    state.onReviewSaveFailed = { coordinator.closeAfterFailedSave() }
    return (state, coordinator)
  }

  private static func review(in coordinator: ReviewCoordinator) -> (ReviewState, String)? {
    guard case .review(let reviewState, let narrative) = coordinator.presentation?.stage else {
      return nil
    }
    return (reviewState, narrative)
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
