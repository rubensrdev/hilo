import Foundation
import OSLog

// contrato 4 (S4): el recuerdo, sus elementos propios, sus conexiones con motivo, editar y
// borrar. Crea su propio understandLater/reviewCoordinator, igual que HiloApp hace con la
// captura (UnderstandLaterState ya lo anticipa: "F5.3: el detalle lo crea y lo conecta a la hoja")
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
  private let logger = Logger(subsystem: "com.hilo.app", category: "explorar")

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

  // DEC-24 + regla 11: elementos propios que sobreviven en otro recuerdo frente a los que
  // se quedarian sin ninguno si este recuerdo se borrara
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

  // F5.5: ElementChip necesita el recuento total del elemento (no solo "propio de este recuerdo")
  // para anunciar nombre, tipo y en cuantos recuerdos aparece, igual que ElementRow en S1
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
        "No se pudo editar el relato: \(String(describing: type(of: error)), privacy: .public)")
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
        "No se pudo borrar el recuerdo: \(String(describing: type(of: error)), privacy: .public)")
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
        "No se pudo cargar el detalle: \(String(describing: type(of: error)), privacy: .public)")
    }
  }
}
