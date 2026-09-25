import Foundation
import OSLog

@Observable
final class ElementDetailState {
  enum EditOutcome: Equatable {
    case applied
    case blocked(conflictName: String)
    case failed
  }

  let elementID: ElementID
  private(set) var element: Element?
  private(set) var ownMemories: [Memory] = []
  private(set) var notFound = false

  private let persistenceActor: PersistenceActor
  private let onMaterialChanged: () async -> Void
  private var allElements: [Element] = []
  private let logger = Logger(subsystem: "com.hilo.app", category: "explore")

  init(
    elementID: ElementID, persistenceActor: PersistenceActor,
    onMaterialChanged: @escaping () async -> Void
  ) {
    self.elementID = elementID
    self.persistenceActor = persistenceActor
    self.onMaterialChanged = onMaterialChanged
  }

  /// The user's words for the oldest and newest memories. ownMemories is newest first, so the ends
  /// are last and first; with fewer than two there is no range.
  var dateRangeDisplay: String? {
    guard ownMemories.count > 1 else { return nil }
    let newestText = ownMemories.first?.date?.text
    let oldestText = ownMemories.last?.date?.text
    switch (oldestText, newestText) {
    case (let oldest?, let newest?): return "\(oldest) – \(newest)"
    case (let oldest?, nil): return oldest
    case (nil, let newest?): return newest
    case (nil, nil): return nil
    }
  }

  /// Only when both ends exist: the composed VoiceOver label doesn't apply with a single side.
  var dateRangeEndpoints: (oldest: String, newest: String)? {
    guard ownMemories.count > 1, let oldest = ownMemories.last?.date?.text,
      let newest = ownMemories.first?.date?.text
    else { return nil }
    return (oldest, newest)
  }

  func load() async {
    await refresh()
  }

  /// The domain rejects a collision before writing. Rule 1: an element without a name doesn't
  /// exist, so an empty name is never persisted.
  func rename(to newName: String) async -> EditOutcome {
    guard let element else { return .failed }
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .failed }
    switch NameCollision.checking(
      trimmed, type: element.type, excluding: element.id, against: allElements)
    {
    case .collidesWith(let conflictID):
      return .blocked(conflictName: conflictName(for: conflictID))
    case .none:
      do {
        try await persistenceActor.renameElement(id: element.id, newName: trimmed)
        await refresh()
        await onMaterialChanged()
        return .applied
      } catch {
        logger.error(
          "Could not rename the element: \(String(describing: type(of: error)), privacy: .public)"
        )
        return .failed
      }
    }
  }

  /// Same collision path as renaming. An alias matching the name or an existing alias isn't
  /// duplicated, and that is not an error.
  func addAlias(_ alias: String) async -> EditOutcome {
    guard let element else { return .failed }
    let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .failed }
    if element.matches(canonical: CanonicalName.of(trimmed)) { return .applied }
    switch NameCollision.checking(
      trimmed, type: element.type, excluding: element.id, against: allElements)
    {
    case .collidesWith(let conflictID):
      return .blocked(conflictName: conflictName(for: conflictID))
    case .none:
      do {
        try await persistenceActor.addAlias(id: element.id, alias: trimmed)
        await refresh()
        await onMaterialChanged()
        return .applied
      } catch {
        logger.error(
          "Could not add the alias: \(String(describing: type(of: error)), privacy: .public)")
        return .failed
      }
    }
  }

  private func conflictName(for id: ElementID) -> String {
    allElements.first(where: { $0.id == id })?.displayName ?? ""
  }

  private func refresh() async {
    do {
      async let fetchedElements = persistenceActor.fetchElements()
      async let fetchedMemories = persistenceActor.fetchMemories()
      async let fetchedAppearances = persistenceActor.fetchAppearances()
      let elements = try await fetchedElements
      let memories = try await fetchedMemories
      let appearances = try await fetchedAppearances
      allElements = elements
      guard let found = elements.first(where: { $0.id == elementID }) else {
        element = nil
        notFound = true
        ownMemories = []
        return
      }
      element = found
      notFound = false
      let memoryIDs = ElementMemories.memoryIDs(for: elementID, in: appearances)
      ownMemories = memoryIDs.compactMap { id in memories.first(where: { $0.id == id }) }
        .sorted(by: Memory.isOrderedBefore)
    } catch {
      logger.error(
        "Could not load the element detail: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
  }
}
