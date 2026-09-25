import Foundation
import OSLog

/// Builds its own understandLater and reviewCoordinator, the way HiloApp does for capture.
@Observable
final class MemoryDetailState {
  let memoryID: MemoryID
  private(set) var memory: Memory?
  private(set) var photoData: Data?
  private(set) var ownElements: [Element] = []
  private(set) var connectedRows: [ConnectionMoment.Row] = []
  private(set) var isAnalyzed = false
  private(set) var notFound = false

  let understandLater: UnderstandLaterState
  let reviewCoordinator: ReviewCoordinator

  private let persistenceActor: PersistenceActor
  private let onMaterialChanged: () async -> Void
  private var allAppearances: [Appearance] = []
  private let logger = Logger(subsystem: "com.hilo.app", category: "explore")

  init(
    memoryID: MemoryID, persistenceActor: PersistenceActor, comprehender: MemoryComprehending,
    interfaceLanguage: String, onMaterialChanged: @escaping () async -> Void
  ) {
    self.memoryID = memoryID
    self.persistenceActor = persistenceActor
    self.onMaterialChanged = onMaterialChanged
    let coordinator = ReviewCoordinator(persistenceActor: persistenceActor)
    let later = UnderstandLaterState(
      comprehender: comprehender, persistenceActor: persistenceActor,
      interfaceLanguage: interfaceLanguage
    ) { extracted, narrative, _, savedMemoryID in
      coordinator.present(extracted: extracted, narrative: narrative, savedMemoryID: savedMemoryID)
    }
    coordinator.onPreparationFailed = { [weak later] in later?.reviewPreparationFailed() }
    self.reviewCoordinator = coordinator
    self.understandLater = later
    later.onReviewSaved = { [weak self, weak coordinator] savedID in
      coordinator?.showConnections(savedMemoryID: savedID)
      Task { await self?.refresh() }
    }
    later.onReviewSaveFailed = { [weak coordinator] in coordinator?.closeAfterFailedSave() }
  }

  /// Rule 11: own elements that survive in another memory, versus those left with none if this
  /// one is deleted.
  var deleteImpact: (surviving: [Element], disappearing: [Element]) {
    guard !ownElements.isEmpty else { return ([], []) }
    let remaining = allAppearances.filter { $0.memoryID != memoryID }
    let orphanIDs = Set(OrphanElements.among(ownElements, appearances: remaining))
    return (
      surviving: ownElements.filter { !orphanIDs.contains($0.id) },
      disappearing: ownElements.filter { orphanIDs.contains($0.id) }
    )
  }

  func load() async {
    await refresh()
  }

  /// The element's total count, not just this memory's, so the chip can announce it.
  func memoryCount(for element: Element) -> Int {
    ElementMemories.count(for: element.id, in: allAppearances)
  }

  func editNarrative(_ narrative: String) async -> Bool {
    do {
      try await persistenceActor.editNarrative(id: memoryID, narrative: narrative)
      await refresh()
      await onMaterialChanged()
      return true
    } catch {
      logger.error(
        "Could not edit the narrative: \(String(describing: type(of: error)), privacy: .public)")
      return false
    }
  }

  func delete() async -> Bool {
    do {
      try await persistenceActor.deleteMemory(id: memoryID)
      await onMaterialChanged()
      return true
    } catch {
      logger.error(
        "Could not delete the memory: \(String(describing: type(of: error)), privacy: .public)")
      return false
    }
  }

  private func refresh() async {
    do {
      async let fetchedMemories = persistenceActor.fetchMemories()
      async let fetchedElements = persistenceActor.fetchElements()
      async let fetchedAppearances = persistenceActor.fetchAppearances()
      async let unanalyzedCheck = persistenceActor.unanalyzedMemory(id: memoryID)
      let memories = try await fetchedMemories
      let elements = try await fetchedElements
      allAppearances = try await fetchedAppearances
      let unanalyzedMemory = try await unanalyzedCheck
      guard let found = memories.first(where: { $0.id == memoryID }) else {
        memory = nil
        notFound = true
        return
      }
      memory = found
      notFound = false
      isAnalyzed = unanalyzedMemory == nil
      photoData = try await persistenceActor.photoData(for: memoryID)
      let elementIDs = MemoryElements.elementIDs(for: memoryID, in: allAppearances)
      ownElements = elementIDs.compactMap { id in elements.first(where: { $0.id == id }) }
      connectedRows =
        ConnectionMoment(
          savedMemoryID: memoryID, memories: memories, elements: elements,
          appearances: allAppearances)?.rows ?? []
    } catch {
      logger.error(
        "Could not load the detail: \(String(describing: type(of: error)), privacy: .public)")
    }
  }
}
