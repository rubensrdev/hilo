import Foundation
import OSLog

// contratos 1-4 (S1 Memoria): las dos vistas y los cuatro estados de Recuerdos viven aqui, no en la vista
@Observable
final class ExploreState {
  enum SelectedView: Equatable {
    case memories
    case elements
  }

  // contrato 2: los cuatro estados de la vista de Recuerdos
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
  // el ancho del extracto depende de la tipografia y la tarjeta (F5.5), no de Domain: se inyecta
  private let defaultExtractLength: Int
  private let logger = Logger(subsystem: "com.hilo.app", category: "explorar")

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

  // contrato 3, DEC-57: buscando manda siempre sobre el recuento, incluso con 0 o 1 recuerdo
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

  // DEC-13: filtro de tipo de seleccion unica; sin orden fijado por la spec, alfabetico por defecto
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

  // contrato 4 (S4): cada detalle crea su propio understandLater/reviewCoordinator (comentario en
  // UnderstandLaterState.swift); S1 recarga en cuanto el detalle edita, borra o completa un analisis
  func makeDetailState(for memoryID: MemoryID) -> MemoryDetailState {
    MemoryDetailState(
      memoryID: memoryID, persistenceActor: persistenceActor, comprehender: comprehender,
      interfaceLanguage: interfaceLanguage
    ) { [weak self] in await self?.load() }
  }

  // contrato 4 (S5): sin ReviewCoordinator/UnderstandLaterState — renombrar no reanaliza nada
  func makeElementDetailState(for elementID: ElementID) -> ElementDetailState {
    ElementDetailState(
      elementID: elementID, persistenceActor: persistenceActor
    ) { [weak self] in await self?.load() }
  }

  // F8 contrato 1 (S7): el ejemplo recarga S1; el borrado total lo devuelve al vacio de primera vez
  func makeAjustesState() -> AjustesState {
    AjustesState(
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
      // solo el tipo: el error no debe arrastrar al log nada del usuario
      logger.error(
        "No se pudo cargar la memoria: \(String(describing: type(of: error)), privacy: .public)")
    }
  }

  func loadExampleMemory(language: ExampleMemoryLanguage) async {
    do {
      try await persistenceActor.loadExampleMemory(language: language, loadedAt: Date())
    } catch {
      logger.error(
        "No se pudo cargar la memoria de ejemplo: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
    await load()
  }
}
