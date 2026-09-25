import Foundation
import OSLog

/// The memory detail creates it and wires it to the sheet, as HiloApp does for capture.
@Observable
final class UnderstandLaterState {
  enum Phase: Equatable {
    case idle
    case comprehending
    case reviewing
    case saving
    case notAnalyzed(MemoryComprehensionReason)

    var notAnalyzedReason: MemoryComprehensionReason? {
      if case .notAnalyzed(let reason) = self { reason } else { nil }
    }
  }

  private(set) var phase: Phase = .idle
  private(set) var notice: ReviewNotice?
  var onReviewSaved: (MemoryID) -> Void = { _ in }
  var onReviewSaveFailed: () -> Void = {}

  private let comprehender: MemoryComprehending
  private let persistenceActor: PersistenceActor
  private let interfaceLanguage: String
  private let onUnderstood: (ExtractedMemory, String, Data?, MemoryID?) -> Void
  private var reviewingMemoryID: MemoryID?
  private let logger = Logger(subsystem: "com.hilo.app", category: "review")

  init(
    comprehender: MemoryComprehending, persistenceActor: PersistenceActor,
    interfaceLanguage: String,
    onUnderstood: @escaping (ExtractedMemory, String, Data?, MemoryID?) -> Void
  ) {
    self.comprehender = comprehender
    self.persistenceActor = persistenceActor
    self.interfaceLanguage = interfaceLanguage
    self.onUnderstood = onUnderstood
  }

  /// Comprehends the narrative as it is saved now, not as it was first saved.
  func start(memoryID: MemoryID) async {
    switch phase {
    case .idle, .notAnalyzed: break
    case .comprehending, .reviewing, .saving: return
    }
    // The phase changes before the await, so a second tap can't open another comprehension.
    phase = .comprehending
    notice = nil
    let memory: Memory?
    do {
      memory = try await persistenceActor.unanalyzedMemory(id: memoryID)
    } catch {
      // Only the error type: nothing the user wrote reaches the log.
      logger.error(
        "Could not read the memory: \(String(describing: type(of: error)), privacy: .public)")
      memory = nil
    }
    guard let memory else {
      phase = .idle
      return
    }
    let outcome = await comprehender.outcome(
      narrative: memory.narrative, interfaceLanguage: interfaceLanguage
    ) { _ in }
    let extracted: ExtractedMemory
    switch outcome {
    case .understood(let understood):
      extracted = understood
    case .notAnalyzed(_, let reason):
      // Says why; the memory is already saved, so there is nothing to save.
      phase = .notAnalyzed(reason)
      return
    case .cancelled:
      phase = .idle
      return
    }
    reviewingMemoryID = memoryID
    phase = .reviewing
    onUnderstood(extracted, memory.narrative, nil, memoryID)
  }

  /// The guard makes it harmless when onDismiss arrives after saving.
  func reviewDismissed() {
    guard phase == .reviewing else { return }
    reviewingMemoryID = nil
    phase = .idle
  }

  func reviewPreparationFailed() {
    guard phase == .reviewing else { return }
    reviewDismissed()
    notice = .reviewUnavailable
  }

  func reviewConfirmed(_ reviewState: ReviewState, dateTextAtSave: String) {
    guard phase == .reviewing, let memoryID = reviewingMemoryID else { return }
    phase = .saving
    reviewingMemoryID = nil
    // Strong self: saving what the user confirmed is never skipped, even if the state goes away.
    Task {
      do {
        try await self.persistenceActor.completeAnalysis(
          of: memoryID,
          outcome: reviewState.outcome(memoryID: memoryID, dateTextAtSave: dateTextAtSave))
        self.phase = .idle
        self.onReviewSaved(memoryID)
      } catch {
        self.logger.error(
          "Could not save the review: \(String(describing: type(of: error)), privacy: .public)"
        )
        self.phase = .idle
        self.notice = .reviewNotSaved
        self.onReviewSaveFailed()
      }
    }
  }
}
