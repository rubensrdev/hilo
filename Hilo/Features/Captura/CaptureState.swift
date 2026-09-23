import Foundation
import OSLog

// contrato 1: toda la logica de S2 Captura vive aqui, la vista solo lee y emite intencion
@Observable
final class CaptureState {
  enum Phase: Equatable {
    case capturing
    case comprehending
    case reviewing
    case savingWithoutAnalyzing
    case notAnalyzed(MemoryComprehensionReason)
  }

  var narrative: String = ""
  var photoData: Data?
  private(set) var phase: Phase = .capturing
  private(set) var extractedSoFar: ExtractedMemory?
  // DEC-45: una vez fijado por el guardado automatico del error, sigue apuntando al
  // mismo recuerdo hasta que la captura se vacia — asi el reintento actualiza
  // en vez de insertar
  private(set) var savedMemoryID: MemoryID?
  // DEC-47: cerrar la revision vuelve aqui; en el reintento es el error, nunca el formulario
  private var phaseBeforeComprehension: Phase = .capturing

  private let comprehender: MemoryComprehending
  private let persistenceActor: PersistenceActor
  private let interfaceLanguage: String
  private let onUnderstood: (ExtractedMemory, String, Data?, MemoryID?) -> Void
  private var comprehensionTask: Task<Void, Never>?
  private let logger = Logger(subsystem: "com.hilo.app", category: "captura")

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

  // contrato 1: salida secundaria siempre visible, pero un relato vacio no se guarda
  // (Memory.init? lo rechazaria) y guardar a medio comprender abriria una carrera con
  // el guardado automatico del error
  var canSaveWithoutAnalyzing: Bool { canUnderstand }

  // DEC-42 + anexo DEC-46: guardarraíl y rechazo comparten texto y botones con el
  // caso generico, reintentar incluido — solo desbordamiento e idioma cierran con
  // un unico boton, porque reintentar sin cambiar nada fallaria igual
  var canRetry: Bool {
    switch phase {
    case .notAnalyzed(.generic), .notAnalyzed(.guardrail): true
    default: false
    }
  }

  func understandAndSave() {
    runComprehension()
  }

  // DEC-16/DEC-45: mismo camino, pero savedMemoryID ya esta fijado desde el fallo
  // anterior, asi que onUnderstood recibe el id a actualizar en vez de nil
  func retry() {
    runComprehension()
  }

  func saveWithoutAnalyzing() async {
    guard canSaveWithoutAnalyzing else { return }
    // la fase cambia antes del await: un segundo toque durante el guardado no puede duplicar
    phase = .savingWithoutAnalyzing
    do {
      _ = try await persist(narrative: narrative)
      // mismo camino que guardar desde la revision: vaciar es lo que impide un segundo guardado
      resetForNewMemory()
    } catch {
      // solo el tipo: el error no debe arrastrar al log nada del usuario
      logger.error(
        "No se pudo guardar sin analizar: \(String(describing: type(of: error)), privacy: .public)"
      )
      phase = .capturing
    }
  }

  func cancel() {
    comprehensionTask?.cancel()
  }

  // DEC-47: el guard lo hace inocuo si onDismiss llega despues de guardar
  func reviewDismissed() {
    guard phase == .reviewing else { return }
    phase = phaseBeforeComprehension
    extractedSoFar = nil
  }

  func reviewSaved() {
    guard phase == .reviewing else { return }
    resetForNewMemory()
  }

  private func resetForNewMemory() {
    narrative = ""
    photoData = nil
    extractedSoFar = nil
    savedMemoryID = nil
    phase = .capturing
    phaseBeforeComprehension = .capturing
  }

  private func runComprehension() {
    phaseBeforeComprehension = phase
    phase = .comprehending
    extractedSoFar = nil
    let text = narrative
    let language = interfaceLanguage
    comprehensionTask = Task { [weak self] in
      guard let self else { return }
      var lastResult: Result<ExtractedMemory, MemoryComprehensionError>?
      do {
        for try await snapshot in self.comprehender.comprehend(
          narrative: text, interfaceLanguage: language)
        {
          guard !Task.isCancelled else {
            self.phase = .capturing
            return
          }
          self.extractedSoFar = snapshot
          lastResult = .success(snapshot)
        }
      } catch let error as MemoryComprehensionError {
        lastResult = .failure(error)
      } catch {
        self.phase = .capturing  // cancelacion: contrato 3 de F3, no es un estado de producto
        return
      }
      guard !Task.isCancelled else {
        self.phase = .capturing
        return
      }
      await self.handle(MemoryComprehensionOutcome(lastResult, narrative: text))
    }
  }

  private func handle(_ outcome: MemoryComprehensionOutcome) async {
    switch outcome {
    case .understood(let extracted):
      phase = .reviewing
      onUnderstood(extracted, narrative, photoData, savedMemoryID)
    case .notAnalyzed(let text, let reason):
      // contrato 1 + DEC-43: el texto ya esta a salvo en cuanto aparece el estado de error.
      // este guardado se completa a proposito aunque cancel() llegue mientras esta en vuelo:
      // el texto del usuario nunca se pierde, no hay nada que deshacer aqui
      if let id = try? await persist(narrative: text) {
        savedMemoryID = id
      }
      phase = .notAnalyzed(reason)
    case .cancelled:
      phase = .capturing
    }
  }

  private func persist(narrative text: String) async throws -> MemoryID? {
    guard let memory = Memory(narrative: text, date: nil, savedAt: Date()) else { return nil }
    return try await persistenceActor.save(
      memory, photoData: photoData, isAnalyzed: false, isExample: false)
  }
}
