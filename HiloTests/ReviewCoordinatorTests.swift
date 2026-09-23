import Foundation
import SwiftData
import Testing

@testable import Hilo

// contrato 5 + DEC-49: tras guardar, la misma hoja pasa al momento de la conexion solo si hay conexiones
struct ReviewCoordinatorTests {
  @Test func `Saving a memory that shares Lucía with an earlier one shows the connection moment`()
    async throws
  {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let earlier = try #require(
      Memory(narrative: "Lucía aprendió a montar en bici.", savedAt: Date()))
    _ = try await actor.save(earlier, photoData: nil, isAnalyzed: true, isExample: false)
    let lucia = try #require(Element(displayName: "Lucía", type: .person))
    _ = try await actor.save(lucia)
    try await actor.save(
      Appearance(memoryID: earlier.id, elementID: lucia.id, role: nil, status: .confirmedByUser))
    let (capture, coordinator) = Self.wired(actor: actor)
    capture.narrative = "Lucía y el primer diente."

    try await Self.understandAndConfirm(capture, coordinator)
    await waitUntil { Self.moment(in: coordinator) != nil }

    let moment = try #require(Self.moment(in: coordinator))
    #expect(moment.narrative == "Lucía y el primer diente.")
    #expect(
      moment.rows == [
        ConnectionMoment.Row(
          memoryID: earlier.id, narrative: "Lucía aprendió a montar en bici.",
          motiveNames: ["Lucía"])
      ])
    #expect(capture.phase == .capturing)
    #expect(capture.narrative == "")
  }

  @Test func `Saving a memory with no connections closes the sheet and leaves the capture empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let (capture, coordinator) = Self.wired(actor: actor)
    capture.narrative = "Lucía y el primer diente."

    try await Self.understandAndConfirm(capture, coordinator)
    await waitUntil { coordinator.presentation == nil }

    #expect(coordinator.presentation == nil)
    #expect(capture.phase == .capturing)
    #expect(capture.narrative == "")
    #expect(try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>()).count == 1)
  }

  // DEC-47: deslizar la hoja con el guardado en vuelo la cierra; el final del guardado no la reabre
  @Test func `A sheet swiped away while saving is not reopened when the save finishes`()
    async throws
  {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let earlier = try #require(Memory(narrative: "Lucía en Laredo.", savedAt: Date()))
    _ = try await actor.save(earlier, photoData: nil, isAnalyzed: true, isExample: false)
    let lucia = try #require(Element(displayName: "Lucía", type: .person))
    _ = try await actor.save(lucia)
    try await actor.save(
      Appearance(memoryID: earlier.id, elementID: lucia.id, role: nil, status: .confirmedByUser))
    let (capture, coordinator) = Self.wired(actor: actor)
    var connectionsTask: Task<Void, Never>?
    capture.onReviewSaved = { connectionsTask = coordinator.showConnections(savedMemoryID: $0) }
    capture.narrative = "Lucía y el primer diente."

    try await Self.understandAndConfirm(capture, coordinator)
    coordinator.presentation = nil
    capture.reviewDismissed()
    await waitUntil { connectionsTask != nil }
    await try #require(connectionsTask).value

    #expect(coordinator.presentation == nil)
    #expect(capture.narrative == "")
  }

  // DEC-47: solo la hoja de ese guardado pasa al momento; una hoja abierta despues no se toca
  @Test func `The connection moment never lands on a different sheet opened meanwhile`()
    async throws
  {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
    let earlier = try #require(Memory(narrative: "Lucía en Laredo.", savedAt: Date()))
    _ = try await actor.save(earlier, photoData: nil, isAnalyzed: true, isExample: false)
    let lucia = try #require(Element(displayName: "Lucía", type: .person))
    _ = try await actor.save(lucia)
    try await actor.save(
      Appearance(memoryID: earlier.id, elementID: lucia.id, role: nil, status: .confirmedByUser))
    let coordinator = ReviewCoordinator(persistenceActor: actor)
    let other = ReviewState(extracted: Self.luciaExtraction, knownElements: [], appearances: [])
    coordinator.presentation = .init(stage: .review(other, narrative: "Otro relato."))
    let staleSheetID = try #require(coordinator.presentation?.id)
    let saved = try #require(Memory(narrative: "Lucía y el diente.", savedAt: Date()))
    _ = try await actor.save(saved, photoData: nil, isAnalyzed: true, isExample: false)
    try await actor.save(
      Appearance(memoryID: saved.id, elementID: lucia.id, role: nil, status: .confirmedByUser))

    let task = coordinator.showConnections(savedMemoryID: saved.id)
    coordinator.presentation = .init(stage: .review(other, narrative: "Otro relato."))
    await task.value

    #expect(coordinator.presentation?.id != staleSheetID)
    guard case .review(_, let narrative) = coordinator.presentation?.stage else {
      Issue.record("la hoja nueva deberia seguir en la revision")
      return
    }
    #expect(narrative == "Otro relato.")
  }

  // MARK: fixtures

  private static let luciaExtraction = ExtractedMemory(
    elements: [ExtractedElement(name: "Lucía", type: .person, role: "mi hija")],
    dateText: nil, deducedYear: nil)

  // el mismo cableado que HiloApp.init
  private static func wired(actor: PersistenceActor) -> (CaptureState, ReviewCoordinator) {
    let coordinator = ReviewCoordinator(persistenceActor: actor)
    let capture = CaptureState(
      comprehender: FakeMemoryComprehender(
        script: .succeeds(partials: [], final: luciaExtraction)),
      persistenceActor: actor, interfaceLanguage: "es"
    ) { extracted, narrative, _, savedMemoryID in
      coordinator.present(extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
    }
    coordinator.onPreparationFailed = { capture.reviewDismissed() }
    capture.onReviewSaved = { coordinator.showConnections(savedMemoryID: $0) }
    capture.onReviewSaveFailed = { coordinator.closeAfterFailedSave() }
    return (capture, coordinator)
  }

  // lo que hace el usuario: comprender y pulsar «Save memory» en la revision que abre el coordinador
  private static func understandAndConfirm(
    _ capture: CaptureState, _ coordinator: ReviewCoordinator
  ) async throws {
    capture.understandAndSave()
    await waitUntil { coordinator.presentation != nil }
    let presentation = try #require(coordinator.presentation)
    guard case .review(let reviewState, _) = presentation.stage else {
      Issue.record("la hoja deberia abrir en la revision")
      return
    }
    capture.reviewConfirmed(reviewState, dateTextAtSave: "")
  }

  private static func moment(in coordinator: ReviewCoordinator) -> ConnectionMoment? {
    guard case .connected(let moment) = coordinator.presentation?.stage else { return nil }
    return moment
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
