import Foundation
import OSLog

// F8 contrato 1 (S7) + regla 25: el paso de la doble confirmacion vive aqui, la hoja solo emite intenciones
@Observable
final class SettingsState: Identifiable {
  enum WipeStep: Equatable {
    case none
    case first
    case second
  }

  private(set) var hasExampleMemory = false
  private(set) var wipeStep: WipeStep = .none
  let version: String

  private let persistenceActor: PersistenceActor
  private let onMemoryChanged: () async -> Void
  private let onWiped: () async -> Void
  private let logger = Logger(subsystem: "com.hilo.app", category: "ajustes")

  init(
    persistenceActor: PersistenceActor, version: String,
    onMemoryChanged: @escaping () async -> Void, onWiped: @escaping () async -> Void
  ) {
    self.persistenceActor = persistenceActor
    self.version = version
    self.onMemoryChanged = onMemoryChanged
    self.onWiped = onWiped
  }

  // cerrar la alerta por fuera cancela solo ese paso: el false al avanzar ya no encuentra .first
  var isFirstWipeConfirmationPresented: Bool {
    get { wipeStep == .first }
    set { if !newValue, wipeStep == .first { wipeStep = .none } }
  }

  var isSecondWipeConfirmationPresented: Bool {
    get { wipeStep == .second }
    set { if !newValue, wipeStep == .second { wipeStep = .none } }
  }

  func load() async {
    do {
      hasExampleMemory = try await persistenceActor.hasExampleMemory()
    } catch {
      logger.error(
        "No se pudo leer si hay memoria de ejemplo: \(String(describing: type(of: error)), privacy: .public)"
      )
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
    await onMemoryChanged()
  }

  func deleteExampleMemory() async {
    do {
      try await persistenceActor.deleteExampleMemory()
    } catch {
      logger.error(
        "No se pudo borrar la memoria de ejemplo: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
    await load()
    await onMemoryChanged()
  }

  func requestWipe() {
    wipeStep = .first
  }

  // sin guard del paso anterior: SwiftUI puede poner el binding a false antes o despues de la accion
  func continueWipe() {
    wipeStep = .second
  }

  func cancelWipe() {
    wipeStep = .none
  }

  // regla 25, "deleting is real": si la escritura falla, la hoja no se cierra como si hubiera borrado
  func confirmWipe() async -> Bool {
    wipeStep = .none
    do {
      try await persistenceActor.wipeAllData()
    } catch {
      logger.error(
        "No se pudo borrar todo: \(String(describing: type(of: error)), privacy: .public)")
      return false
    }
    await load()
    await onWiped()
    return true
  }

  #if DEBUG
    // F5: panel Debug de Ajustes, para docs/validacion-manual — nunca en Release
    func loadDebugValidationDataset() async {
      do {
        try await persistenceActor.loadDebugValidationDataset(loadedAt: Date())
      } catch {
        logger.error(
          "No se pudo cargar el set de validacion: \(String(describing: type(of: error)), privacy: .public)"
        )
      }
      await load()
      await onMemoryChanged()
    }
  #endif
}
