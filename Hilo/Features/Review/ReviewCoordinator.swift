import Foundation
import OSLog

/// Bridges Capture and Review. onUnderstood is built in HiloApp.init before self exists, so it
/// captures this reference instead of an app @State.
@Observable
final class ReviewCoordinator {
  /// One sheet goes from the review to the connection moment: the id stays, so it isn't re-presented.
  struct Presentation: Identifiable {
    enum Stage {
      case review(ReviewState, narrative: String)
      case connected(ConnectionMoment)
    }

    let id = UUID()
    var stage: Stage
  }

  var presentation: Presentation?
  /// If the sheet never opens, go back as if it had closed, with a notice.
  var onPreparationFailed: () -> Void = {}

  private let persistenceActor: PersistenceActor
  private let logger = Logger(subsystem: "com.hilo.app", category: "review")

  init(persistenceActor: PersistenceActor) {
    self.persistenceActor = persistenceActor
  }

  /// No photo here: the review doesn't show it, and the real save reuses it from persistence.
  func present(extracted: ExtractedMemory, narrative: String, savedMemoryID: MemoryID?) {
    Task {
      do {
        // In parallel: two independent reads on the same actor.
        async let knownElements = persistenceActor.fetchElements()
        async let appearances = persistenceActor.fetchAppearances()
        presentation = try await Presentation(
          stage: .review(
            ReviewState(
              extracted: extracted, knownElements: knownElements, appearances: appearances,
              excludingMemoryID: savedMemoryID),
            narrative: narrative))
      } catch {
        // Only the error type: nothing the user wrote reaches the log.
        logger.error(
          "Could not prepare the review: \(String(describing: type(of: error)), privacy: .public)"
        )
        onPreparationFailed()
      }
    }
  }

  /// No connections, no moment: the sheet closes and the capture is left empty.
  @discardableResult
  func showConnections(savedMemoryID: MemoryID) -> Task<Void, Never> {
    // Swiped away during the save: neither read nor reopened.
    guard let sheetID = presentation?.id else { return Task {} }
    return Task {
      let moment: ConnectionMoment?
      do {
        moment = try await persistenceActor.connectionMoment(for: savedMemoryID)
      } catch {
        // The memory is already saved: without its connections, close as if it had none.
        logger.error(
          "Could not read the connections: \(String(describing: type(of: error)), privacy: .public)"
        )
        moment = nil
      }
      // Only this save's sheet: if it closed or another one opened, leave it alone.
      guard presentation?.id == sheetID else { return }
      if let moment {
        presentation?.stage = .connected(moment)
      } else {
        presentation = nil
      }
    }
  }

  func closeAfterFailedSave() {
    presentation = nil
  }
}
