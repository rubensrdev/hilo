import Foundation
import OSLog

@Observable
final class CaptureState {
  enum Phase: Equatable {
    case capturing
    case comprehending
    case reviewing
    case savingWithoutAnalyzing
    case savingReview
    case notAnalyzed(MemoryComprehensionReason)

    var notAnalyzedReason: MemoryComprehensionReason? {
      if case .notAnalyzed(let reason) = self { reason } else { nil }
    }
  }

  /// Editing the narrative is the next intent, so the previous notice no longer applies.
  var narrative: String = "" { didSet { notice = nil } }
  var photoData: Data?
  private(set) var phase: Phase = .capturing
  private(set) var extractedSoFar: ExtractedMemory?
  private(set) var notice: ReviewNotice?
  /// The direct save failed with nothing saved behind it: a real error, not a notice.
  private(set) var saveWithoutAnalyzingFailed = false
  /// Once the error's auto-save sets it, it keeps pointing at that memory until the capture clears,
  /// so a retry updates instead of inserting.
  private(set) var savedMemoryID: MemoryID?
  /// Closing the review returns here: on a retry that is the error, never the form.
  private var phaseBeforeComprehension: Phase = .capturing
  var onReviewSaved: (MemoryID) -> Void = { _ in }
  var onReviewSaveFailed: () -> Void = {}

  private let comprehender: MemoryComprehending
  private let persistenceActor: PersistenceActor
  private let interfaceLanguage: String
  private let onUnderstood: (ExtractedMemory, String, Data?, MemoryID?) -> Void
  private var comprehensionTask: Task<Void, Never>?
  private var photoLoadTask: Task<Void, Never>?
  @ObservationIgnored private var isSavingFailedNarrative = false
  private let logger = Logger(subsystem: "com.hilo.app", category: "capture")

  private enum SaveError: Error {
    case blankNarrative
  }

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

  var canUnderstand: Bool {
    !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && phase == .capturing
  }

  /// Always visible, but an empty narrative can't be saved, and saving mid-comprehension would
  /// race the error's auto-save.
  var canSaveWithoutAnalyzing: Bool { canUnderstand }

  /// The same rule that decides the notice's buttons.
  var canRetry: Bool {
    guard case .notAnalyzed(let reason) = phase else { return false }
    return reason.allowsRetry
  }

  func understandAndSave() {
    runComprehension()
  }

  /// Same path as understanding, but savedMemoryID is already set, so onUnderstood gets the id to update.
  func retry() {
    runComprehension()
  }

  func saveWithoutAnalyzing() async {
    guard canSaveWithoutAnalyzing else { return }
    notice = nil
    // The phase changes before the await, so a second tap during the save can't duplicate it.
    phase = .savingWithoutAnalyzing
    photoLoadTask?.cancel()
    do {
      _ = try await persist(narrative: narrative)
      // Same as saving from the review: clearing is what prevents a second save.
      resetForNewMemory()
      notice = .savedWithoutAnalyzing
    } catch {
      // Only the error type: nothing the user wrote reaches the log.
      logger.error(
        "Could not save without analyzing: \(String(describing: type(of: error)), privacy: .public)"
      )
      phase = .capturing
      saveWithoutAnalyzingFailed = true
    }
  }

  /// Loads finish whenever they like: only the latest pick counts, and only while capturing.
  @discardableResult
  func loadPhoto(_ load: @escaping @MainActor () async -> Data?) -> Task<Void, Never> {
    photoLoadTask?.cancel()
    let task = Task {
      let data = await load()
      guard !Task.isCancelled, phase == .capturing else { return }
      photoData = data
    }
    photoLoadTask = task
    return task
  }

  func removePhoto() {
    photoLoadTask?.cancel()
    photoData = nil
  }

  func acknowledgeSaveFailure() {
    saveWithoutAnalyzingFailed = false
  }

  /// No time limit: the user decides when to stop, and gets back to where they were at once.
  func cancel() {
    comprehensionTask?.cancel()
    guard phase == .comprehending, !isSavingFailedNarrative else { return }
    phase = phaseBeforeComprehension
    extractedSoFar = nil
  }

  /// The guard makes it harmless when onDismiss arrives after saving.
  func reviewDismissed() {
    guard phase == .reviewing else { return }
    phase = phaseBeforeComprehension
    extractedSoFar = nil
  }

  /// Returns as when the review closes, but says it couldn't open.
  func reviewPreparationFailed() {
    guard phase == .reviewing else { return }
    reviewDismissed()
    notice = .reviewUnavailable
  }

  /// The memory is already saved unanalyzed; acknowledging only clears the capture.
  func acknowledgeNotAnalyzed() {
    guard case .notAnalyzed = phase else { return }
    resetForNewMemory()
  }

  /// Leaving .reviewing before the sheet closes makes its onDismiss harmless.
  func reviewConfirmed(_ reviewState: ReviewState, dateTextAtSave: String) {
    guard phase == .reviewing else { return }
    phase = .savingReview
    let text = narrative
    let photo = photoData
    let existingID = savedMemoryID
    // Strong self: saving the user's text is never skipped, even if the capture goes away.
    Task {
      do {
        let savedID = try await self.persistReview(
          reviewState, dateTextAtSave: dateTextAtSave, narrative: text, photoData: photo,
          existingID: existingID)
        self.resetForNewMemory()
        self.onReviewSaved(savedID)
      } catch {
        // Only the error type: nothing the user wrote reaches the log.
        self.logger.error(
          "Could not save the review: \(String(describing: type(of: error)), privacy: .public)"
        )
        self.phase = self.phaseBeforeComprehension
        self.extractedSoFar = nil
        self.notice = .reviewNotSaved
        self.onReviewSaveFailed()
      }
    }
  }

  private func resetForNewMemory() {
    photoLoadTask?.cancel()
    narrative = ""
    photoData = nil
    extractedSoFar = nil
    notice = nil
    savedMemoryID = nil
    phase = .capturing
    phaseBeforeComprehension = .capturing
  }

  private func runComprehension() {
    // A double tap must not leave an orphaned comprehension that cancel could no longer stop.
    guard phase != .comprehending else { return }
    phaseBeforeComprehension = phase
    phase = .comprehending
    // What is read is what was there at the tap: a photo arriving later is left out.
    photoLoadTask?.cancel()
    notice = nil
    extractedSoFar = nil
    let text = narrative
    let language = interfaceLanguage
    comprehensionTask = Task { [weak self] in
      guard let self else { return }
      let outcome = await self.comprehender.outcome(
        narrative: text, interfaceLanguage: language
      ) { partial in
        if !Task.isCancelled { self.extractedSoFar = partial }
      }
      // cancel() has already given the capture back: a late result must not open the review.
      guard !Task.isCancelled else { return }
      await self.handle(outcome)
    }
  }

  private func handle(_ outcome: MemoryComprehensionOutcome) async {
    switch outcome {
    case .understood(let extracted):
      phase = .reviewing
      onUnderstood(extracted, narrative, photoData, savedMemoryID)
    case .notAnalyzed(let text, let reason):
      // With the text being saved, cancelling can no longer go back to the form.
      isSavingFailedNarrative = true
      defer { isSavingFailedNarrative = false }
      // On a retry the narrative is already saved: don't insert another copy.
      if savedMemoryID == nil {
        do {
          savedMemoryID = try await persist(narrative: text)
        } catch {
          // With no saved memory behind it, it can't say "saved": same error as a direct save.
          logger.error(
            "Could not save the narrative after the comprehension error: \(String(describing: type(of: error)), privacy: .public)"
          )
          phase = .capturing
          extractedSoFar = nil
          saveWithoutAnalyzingFailed = true
          return
        }
      }
      phase = .notAnalyzed(reason)
    case .cancelled:
      phase = phaseBeforeComprehension
      extractedSoFar = nil
    }
  }

  /// With a memory already saved by the error, analyses that one instead of inserting another.
  private func persistReview(
    _ reviewState: ReviewState, dateTextAtSave: String, narrative text: String, photoData: Data?,
    existingID: MemoryID?
  ) async throws -> MemoryID {
    if let existingID {
      try await persistenceActor.completeAnalysis(
        of: existingID,
        outcome: reviewState.outcome(memoryID: existingID, dateTextAtSave: dateTextAtSave))
      return existingID
    }
    guard let memory = Memory(narrative: text, savedAt: Date()) else {
      throw SaveError.blankNarrative
    }
    return try await persistenceActor.saveReviewed(
      memory, photoData: photoData,
      outcome: reviewState.outcome(memoryID: memory.id, dateTextAtSave: dateTextAtSave))
  }

  /// A narrative Memory rejects is a failure, never a "saved" with no memory behind it.
  private func persist(narrative text: String) async throws -> MemoryID {
    guard let memory = Memory(narrative: text, date: nil, savedAt: Date()) else {
      throw SaveError.blankNarrative
    }
    return try await persistenceActor.save(
      memory, photoData: photoData, isAnalyzed: false, isExample: false)
  }
}
