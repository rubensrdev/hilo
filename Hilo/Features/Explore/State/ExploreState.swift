import Foundation
import OSLog

@Observable
final class ExploreState {
  enum SelectedView: Equatable {
    case memories
    case elements
  }

  enum MemoriesDisplay: Equatable {
    case empty
    case single(Memory)
    case normal([MemoryGroup])
    case searching(results: [MemorySearchResult])
  }

  private(set) var memories: [Memory] = []
  private(set) var elements: [Element] = []
  private(set) var appearances: [Appearance] = []

  var selectedView: SelectedView = .memories
  var searchQuery: String = ""
  var selectedElementTypeFilter: ElementType?

  private let persistenceActor: PersistenceActor
  private let comprehender: MemoryComprehending
  private let interfaceLanguage: String
  /// The extract width depends on the type style and the card, not on Domain, so it is injected.
  private let defaultExtractLength: Int
  private let logger = Logger(subsystem: "com.hilo.app", category: "explore")

  init(
    persistenceActor: PersistenceActor, comprehender: MemoryComprehending,
    interfaceLanguage: String, defaultExtractLength: Int = 160
  ) {
    self.persistenceActor = persistenceActor
    self.comprehender = comprehender
    self.interfaceLanguage = interfaceLanguage
    self.defaultExtractLength = defaultExtractLength
  }

  var isSearching: Bool {
    !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Searching always wins over the count, even with zero or one memory.
  var memoriesDisplay: MemoriesDisplay {
    if isSearching {
      return .searching(
        results: MemorySearch.results(
          for: searchQuery, in: memories, elements: elements, appearances: appearances,
          defaultExtractLength: defaultExtractLength))
    }
    if memories.isEmpty { return .empty }
    if memories.count == 1, let only = memories.first { return .single(only) }
    return .normal(MemoryGrouping.grouped(memories))
  }

  /// Single-selection type filter; the spec sets no order, so alphabetical.
  var filteredElements: [Element] {
    let base =
      selectedElementTypeFilter.map { type in elements.filter { $0.type == type } } ?? elements
    return base.sorted {
      $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
    }
  }

  func memoryCount(for element: Element) -> Int {
    ElementMemories.count(for: element.id, in: appearances)
  }

  /// Each detail builds its own understandLater and reviewCoordinator. The list reloads as soon as
  /// the detail edits, deletes or finishes an analysis.
  func makeDetailState(for memoryID: MemoryID) -> MemoryDetailState {
    MemoryDetailState(
      memoryID: memoryID, persistenceActor: persistenceActor, comprehender: comprehender,
      interfaceLanguage: interfaceLanguage
    ) { [weak self] in await self?.load() }
  }

  /// No review coordinator: renaming never re-analyses.
  func makeElementDetailState(for elementID: ElementID) -> ElementDetailState {
    ElementDetailState(
      elementID: elementID, persistenceActor: persistenceActor
    ) { [weak self] in await self?.load() }
  }

  /// Loading the example reloads the list; a full wipe takes it back to the first-time empty state.
  func makeSettingsState() -> SettingsState {
    SettingsState(
      persistenceActor: persistenceActor, version: ProductVersion.read(),
      onMemoryChanged: { [weak self] in await self?.load() },
      onWiped: { [weak self] in await self?.resetToFirstTime() })
  }

  func resetToFirstTime() async {
    searchQuery = ""
    selectedElementTypeFilter = nil
    selectedView = .memories
    await load()
  }

  func load() async {
    do {
      async let fetchedMemories = persistenceActor.fetchMemories()
      async let fetchedElements = persistenceActor.fetchElements()
      async let fetchedAppearances = persistenceActor.fetchAppearances()
      memories = try await fetchedMemories
      elements = try await fetchedElements
      appearances = try await fetchedAppearances
    } catch {
      // Only the error type: nothing the user wrote reaches the log.
      logger.error(
        "Could not load the memory: \(String(describing: type(of: error)), privacy: .public)")
    }
  }

  func loadExampleMemory(language: ExampleMemoryLanguage) async {
    do {
      try await persistenceActor.loadExampleMemory(language: language, loadedAt: Date())
    } catch {
      logger.error(
        "Could not load the example memory: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
    await load()
  }
}
