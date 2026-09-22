import OSLog
import SwiftData
import SwiftUI

@main
struct HiloApp: App {
  // sin carga inicial (contrato 2 de F2): el contenedor se crea una vez y se inyecta, nada más
  static let container: ModelContainer = {
    do {
      return try PersistenceContainer.make(inMemory: false)
    } catch {
      fatalError("No se pudo crear el ModelContainer: \(error)")
    }
  }()

  private static let logger = Logger(subsystem: "com.hilo.app", category: "captura")

  // contrato 1: S2 Captura sustituye la pantalla provisional (F4/F5). onUnderstood
  // solo registra por ahora: la navegacion a Revision llega en F4.3
  @State private var captureState = CaptureState(
    comprehender: FoundationModelsMemoryComprehender(),
    persistenceActor: PersistenceActor(modelContainer: Self.container),
    interfaceLanguage: Locale.current.language.languageCode?.identifier ?? "en"
  ) { _, _, _, _ in
    Self.logger.notice("Memory understood")
  }

  var body: some Scene {
    WindowGroup {
      CaptureScreen(state: captureState)
    }
    .modelContainer(Self.container)
  }
}
