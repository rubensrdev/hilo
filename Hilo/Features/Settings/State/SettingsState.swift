import Foundation
import OSLog

/// Rule 25: the double confirmation's step lives here; the sheet only emits intent.
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
  private let logger = Logger(subsystem: "com.hilo.app", category: "settings")

  init(
    persistenceActor: PersistenceActor, version: String,
    onMemoryChanged: @escaping () async -> Void, onWiped: @escaping () async -> Void
  ) {
    self.persistenceActor = persistenceActor
    self.version = version
    self.onMemoryChanged = onMemoryChanged
    self.onWiped = onWiped
  }

  /// Dismissing the alert cancels only that step: the false sent while advancing no longer finds .first.
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
        "Could not check for the example memory: \(String(describing: type(of: error)), privacy: .public)"
      )
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
    await onMemoryChanged()
  }

  func deleteExampleMemory() async {
    do {
      try await persistenceActor.deleteExampleMemory()
    } catch {
      logger.error(
        "Could not delete the example memory: \(String(describing: type(of: error)), privacy: .public)"
      )
    }
    await load()
    await onMemoryChanged()
  }

  func requestWipe() {
    wipeStep = .first
  }

  /// No guard on the previous step: SwiftUI may set the binding to false before or after the action.
  func continueWipe() {
    wipeStep = .second
  }

  func cancelWipe() {
    wipeStep = .none
  }

  /// Rule 25, deleting is real: if the write fails, the sheet doesn't close as if it had deleted.
  func confirmWipe() async -> Bool {
    wipeStep = .none
    do {
      try await persistenceActor.wipeAllData()
    } catch {
      logger.error(
        "Could not delete everything: \(String(describing: type(of: error)), privacy: .public)")
      return false
    }
    await load()
    await onWiped()
    return true
  }

  #if DEBUG
    /// The Debug panel's dataset for docs/validacion-manual; never in Release.
    func loadDebugValidationDataset() async {
      do {
        try await persistenceActor.loadDebugValidationDataset(loadedAt: Date())
      } catch {
        logger.error(
          "Could not load the validation dataset: \(String(describing: type(of: error)), privacy: .public)"
        )
      }
      await load()
      await onMemoryChanged()
    }
  #endif
}
