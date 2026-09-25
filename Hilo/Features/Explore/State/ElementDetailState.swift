import Foundation
import OSLog

// contrato 4 (S5): el elemento, sus recuerdos propios en el orden de DEC-35, el rango temporal
// (DEC-57, hueco A1), renombrar y añadir alias con las validaciones de F1 (contrato 5, DEC-26)
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
  private let logger = Logger(subsystem: "com.hilo.app", category: "explorar")

  init(
    elementID: ElementID, persistenceActor: PersistenceActor,
    onMaterialChanged: @escaping () async -> Void
  ) {
    self.elementID = elementID
    self.persistenceActor = persistenceActor
    self.onMaterialChanged = onMaterialChanged
  }

  // DEC-57 (A1): las palabras del usuario del recuerdo mas antiguo y del mas reciente, en ese
  // orden; ownMemories ya viene ordenado por DEC-35 (mas reciente primero), asi que los extremos
  // son first/last. Con menos de dos recuerdos propios no hay rango que mostrar.
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

  // solo cuando los dos extremos existen: el label compuesto de VoiceOver (evita leer el guion
  // medio de dateRangeDisplay como si fuera texto) no aplica cuando solo hay un lado que mostrar
  var dateRangeEndpoints: (oldest: String, newest: String)? {
    guard ownMemories.count > 1, let oldest = ownMemories.last?.date?.text,
      let newest = ownMemories.first?.date?.text
    else { return nil }
    return (oldest, newest)
  }

  func load() async {
    await refresh()
  }

  // contrato 5 + DEC-26: el dominio rechaza la colision antes de escribir; regla 1, un elemento
  // sin nombre no existe, asi que un nombre vacio ni se intenta persistir
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
          "No se pudo renombrar el elemento: \(String(describing: type(of: error)), privacy: .public)"
        )
        return .failed
      }
    }
  }

  // mismo camino de colision que renombrar; un alias que ya coincide con el propio nombre o con
  // un alias existente no se duplica, y eso no es un error (exito silencioso)
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
          "No se pudo añadir el alias: \(String(describing: type(of: error)), privacy: .public)")
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
        "No se pudo cargar el detalle del elemento: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
  }
}
