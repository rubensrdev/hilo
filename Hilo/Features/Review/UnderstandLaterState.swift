import Foundation
import OSLog

// F5.3: el detalle lo crea y lo conecta a la hoja, como HiloApp hace con la captura
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
  private let logger = Logger(subsystem: "com.hilo.app", category: "revision")

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

  // DEC-45: comprende el relato guardado ahora, no el de cuando se guardo
  func start(memoryID: MemoryID) async {
    switch phase {
    case .idle, .notAnalyzed: break
    case .comprehending, .reviewing, .saving: return
    }
    // la fase cambia antes del await: un segundo toque no abre otra comprension
    phase = .comprehending
    notice = nil
    let memory: Memory?
    do {
      memory = try await persistenceActor.unanalyzedMemory(id: memoryID)
    } catch {
      // solo el tipo: el error no debe arrastrar al log nada del usuario
      logger.error(
        "No se pudo leer el recuerdo: \(String(describing: type(of: error)), privacy: .public)")
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
      // contrato 4: se dice por que; el recuerdo ya esta guardado, no hay nada que guardar
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

  // DEC-47: el guard lo hace inocuo si onDismiss llega despues de guardar
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
    // self fuerte: el guardado de lo que el usuario confirmo no se salta aunque el estado desaparezca
    Task {
      do {
        try await self.persistenceActor.completeAnalysis(
          of: memoryID,
          outcome: reviewState.outcome(memoryID: memoryID, dateTextAtSave: dateTextAtSave))
        self.phase = .idle
        self.onReviewSaved(memoryID)
      } catch {
        self.logger.error(
          "No se pudo guardar la revision: \(String(describing: type(of: error)), privacy: .public)"
        )
        self.phase = .idle
        self.notice = .reviewNotSaved
        self.onReviewSaveFailed()
      }
    }
  }
}
