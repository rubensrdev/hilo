#if DEBUG
  import ImageIO
  import SwiftUI

  // solo previews: cada estado se alcanza por el camino real de CaptureState, sin abrir setters
  enum PreviewFixtures {
    static let narrative =
      "El verano del 87 la abuela Carmen nos llevó a Cádiz con la Singer en el coche."

    static func persistenceActor() -> PersistenceActor {
      do {
        return PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
      } catch {
        fatalError("No se pudo crear el contenedor de la preview: \(error)")
      }
    }

    // ADR-000 §4: nunca UIKit, tampoco en DEBUG; un PNG dibujado con Core Graphics
    static let photoData: Data = {
      guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(
          data: nil, width: 600, height: 400, bitsPerComponent: 8, bytesPerRow: 0,
          space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
      else { return Data() }
      context.setFillColor(red: 0.19, green: 0.69, blue: 0.78, alpha: 1)
      context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
      context.setFillColor(red: 1, green: 0.8, blue: 0, alpha: 1)
      context.fillEllipse(in: CGRect(x: 380, y: 200, width: 140, height: 140))
      let output = NSMutableData()
      guard let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil)
      else { return Data() }
      CGImageDestinationAddImage(destination, image, nil)
      return CGImageDestinationFinalize(destination) ? output as Data : Data()
    }()

    static let extracted = ExtractedMemory(
      elements: [
        ExtractedElement(name: "la abuela Carmen", type: .person, role: "quien nos llevó"),
        ExtractedElement(name: "Cádiz", type: .place, role: "el destino"),
        ExtractedElement(name: "la Singer", type: .object, role: "lo que llevamos"),
      ],
      dateText: "El verano del 87", deducedYear: 1987)
  }

  // MARK: captura

  enum CaptureScenario: Hashable, CaseIterable {
    case empty
    case writing
    case withPhoto
    case comprehending
    case notAnalyzedRetryable
    case notAnalyzedTooLong
    case reviewUnavailable
    case savedWithoutAnalyzing
    case saveFailed
  }

  // makeSharedContext es async y el canvas lo espera: cada estado ya esta alcanzado al pintar
  struct CaptureScenarios: PreviewModifier {
    private struct Key: Hashable {
      let scenario: CaptureScenario
      let language: String
    }

    let scenario: CaptureScenario
    let locale: Locale

    init(_ scenario: CaptureScenario, locale: Locale = Locale(identifier: "en")) {
      self.scenario = scenario
      self.locale = locale
    }

    static func makeSharedContext() async -> [AnyHashable: CaptureState] {
      var states: [AnyHashable: CaptureState] = [:]
      for language in ["en", "es"] {
        for scenario in CaptureScenario.allCases {
          states[Key(scenario: scenario, language: language)] = await reached(
            scenario, language: language)
        }
      }
      return states
    }

    func body(content: Content, context: [AnyHashable: CaptureState]) -> some View {
      let language = locale.language.languageCode?.identifier ?? "en"
      Group {
        if let state = context[Key(scenario: scenario, language: language)] {
          content
            .environment(state)
            .environment(\.locale, locale)
        }
      }
    }

    private static func reached(_ scenario: CaptureScenario, language: String) async
      -> CaptureState
    {
      let holder = CaptureHolder()
      let state = CaptureState(
        comprehender: PreviewComprehender(scenario: scenario),
        persistenceActor: PreviewFixtures.persistenceActor(),
        interfaceLanguage: language
      ) { _, _, _, _ in
        // sin hoja de revision en la preview: el unico camino que la usa es el fallo al prepararla
        holder.state?.reviewPreparationFailed()
      }
      holder.state = state
      if scenario == .empty { return state }
      state.narrative = PreviewFixtures.narrative
      switch scenario {
      case .empty, .writing:
        break
      case .withPhoto:
        state.photoData = PreviewFixtures.photoData
      case .comprehending:
        state.understandAndSave()
        await waitUntil { state.extractedSoFar?.elements.count == 2 }
      case .notAnalyzedRetryable, .notAnalyzedTooLong:
        state.understandAndSave()
        await waitUntil { state.canRetry || state.phase == .notAnalyzed(.contextOverflow) }
      case .reviewUnavailable:
        state.understandAndSave()
        await waitUntil { state.notice == .reviewUnavailable }
      case .savedWithoutAnalyzing:
        await state.saveWithoutAnalyzing()
      case .saveFailed:
        // PhotoStripper lanza con datos que no son una imagen: el camino real del fallo
        state.photoData = Data("not a photo".utf8)
        await state.saveWithoutAnalyzing()
      }
      return state
    }

    // tope de un segundo: si el estado no llega, la preview lo enseña tal cual en vez de colgarse
    private static func waitUntil(_ isReached: () -> Bool) async {
      for _ in 0..<100 where !isReached() {
        try? await Task.sleep(for: .milliseconds(10))
      }
    }
  }

  // la preview lee el estado que deja el modificador, como la app lo recibe de HiloApp
  struct CapturePreviewScreen: View {
    @Environment(CaptureState.self) private var state

    var body: some View {
      CaptureScreen(state: state)
    }
  }

  private final class CaptureHolder {
    weak var state: CaptureState?
  }

  nonisolated struct PreviewComprehender: MemoryComprehending {
    private enum Script: Sendable {
      case keepsReading([ExtractedMemory])
      case understands(ExtractedMemory)
      case fails(MemoryComprehensionError)
    }

    private let script: Script

    // se crea en la vista de la preview; solo comprehend corre fuera del main actor
    @MainActor init(scenario: CaptureScenario) {
      switch scenario {
      case .notAnalyzedRetryable:
        script = .fails(.noResponse)
      case .notAnalyzedTooLong:
        script = .fails(.contextOverflow)
      case .comprehending:
        let elements = PreviewFixtures.extracted.elements
        script = .keepsReading(
          (1...2).map {
            ExtractedMemory(elements: Array(elements.prefix($0)), dateText: nil, deducedYear: nil)
          })
      default:
        script = .understands(PreviewFixtures.extracted)
      }
    }

    func comprehend(narrative: String, interfaceLanguage: String)
      -> AsyncThrowingStream<ExtractedMemory, Error>
    {
      AsyncThrowingStream { continuation in
        switch script {
        case .keepsReading(let partials):
          partials.forEach { continuation.yield($0) }
          // se queda leyendo: la preview enseña «comprendiendo» con los elementos ya aparecidos
          let task = Task {
            try? await Task.sleep(for: .seconds(3600))
            continuation.finish()
          }
          continuation.onTermination = { _ in task.cancel() }
        case .understands(let extracted):
          continuation.yield(extracted)
          continuation.finish()
        case .fails(let error):
          continuation.finish(throwing: error)
        }
      }
    }
  }

  // MARK: revision

  enum ReviewScenario {
    case connected
    case beginning
    case doubts
    case nothingRecognized
  }

  extension PreviewFixtures {
    static func reviewState(_ scenario: ReviewScenario) -> ReviewState {
      let carmen = Element(id: ElementID(), displayName: "la abuela Carmen", type: .person)
      let cadiz = Element(id: ElementID(), displayName: "Cádiz", type: .place)
      switch scenario {
      case .connected:
        var state = ReviewState(
          extracted: withCar, knownElements: [carmen, cadiz],
          appearances: appearances(of: carmen, in: 3) + appearances(of: cadiz, in: 1))
        // el chip quitado con «Deshacer» sale por el mismo metodo que el boton
        if let car = state.items.first(where: { $0.originalName == "el coche" }) {
          state.remove(car.id)
        }
        return state
      case .beginning:
        return ReviewState(extracted: extracted, knownElements: [], appearances: [])
      case .doubts:
        let known = Element(id: ElementID(), displayName: "Carmen", type: .person)
        return ReviewState(
          extracted: extracted, knownElements: [known, cadiz],
          appearances: appearances(of: known, in: 2) + appearances(of: cadiz, in: 4))
      case .nothingRecognized:
        return ReviewState(
          extracted: ExtractedMemory(elements: [], dateText: nil, deducedYear: nil),
          knownElements: [], appearances: [])
      }
    }

    static func itemID(named name: String, in state: ReviewState) -> ReviewItemID? {
      state.items.first(where: { $0.originalName == name })?.id
    }

    private static let withCar = ExtractedMemory(
      elements: extracted.elements + [
        ExtractedElement(name: "el coche", type: .object, role: "en el que fuimos")
      ],
      dateText: extracted.dateText, deducedYear: extracted.deducedYear)

    private static func appearances(of element: Element, in memoryCount: Int) -> [Appearance] {
      (0..<memoryCount).map { _ in
        Appearance(
          memoryID: MemoryID(), elementID: element.id, role: nil, status: .confirmedByUser)
      }
    }
  }

  // MARK: explorar

  enum ExploreScenario: Hashable, CaseIterable {
    case empty
    case single
    case normal
    case searchingWithResults
    case searchingNoResults
    case elementsList
    case elementsFilterNoResults
  }

  struct ExploreScenarios: PreviewModifier {
    private struct Key: Hashable {
      let scenario: ExploreScenario
      let language: String
    }

    let scenario: ExploreScenario
    let locale: Locale

    init(_ scenario: ExploreScenario, locale: Locale = Locale(identifier: "en")) {
      self.scenario = scenario
      self.locale = locale
    }

    static func makeSharedContext() async -> [AnyHashable: ExploreState] {
      var states: [AnyHashable: ExploreState] = [:]
      for language in ["en", "es"] {
        for scenario in ExploreScenario.allCases {
          states[Key(scenario: scenario, language: language)] = await reached(
            scenario, language: language)
        }
      }
      return states
    }

    func body(content: Content, context: [AnyHashable: ExploreState]) -> some View {
      let language = locale.language.languageCode?.identifier ?? "en"
      Group {
        if let state = context[Key(scenario: scenario, language: language)] {
          content
            .environment(state)
            .environment(\.locale, locale)
        }
      }
    }

    private static func reached(_ scenario: ExploreScenario, language: String) async
      -> ExploreState
    {
      let actor = PreviewFixtures.persistenceActor()
      let state = ExploreState(persistenceActor: actor, defaultExtractLength: 160)
      switch scenario {
      case .empty:
        break
      case .single:
        _ = try? await actor.save(PreviewFixtures.exploreMemory, isAnalyzed: true, isExample: false)
      case .normal, .searchingWithResults, .searchingNoResults, .elementsList,
        .elementsFilterNoResults:
        await PreviewFixtures.seedExploreSample(into: actor)
      }
      await state.load()
      switch scenario {
      case .searchingWithResults:
        state.searchQuery = "Singer"
      case .searchingNoResults:
        state.searchQuery = "xyz-nada"
      case .elementsList:
        state.selectedView = .elements
      case .elementsFilterNoResults:
        state.selectedView = .elements
        // en la muestra no hay ningun objeto: filtrar por objeto siempre da "sin resultados"
        state.selectedElementTypeFilter = .object
      case .empty, .single, .normal:
        break
      }
      return state
    }
  }

  struct ExplorePreviewScreen: View {
    @Environment(ExploreState.self) private var state

    var body: some View {
      MemoriaScreen(state: state, isCapturePresented: .constant(false))
    }
  }

  extension PreviewFixtures {
    static var exploreMemory: Memory {
      // reutiliza el mismo contenido de PreviewFixtures.narrative, nunca texto de muestra nuevo
      Memory(
        narrative: narrative, date: MemoryDate(text: "El verano del 87", deducedYear: 1987),
        savedAt: .now)!
    }

    static var exploreElement: Element {
      Element(displayName: "la abuela Carmen", type: .person)!
    }

    // dos recuerdos y dos elementos, para los estados normal/buscando/lista de elementos
    static func seedExploreSample(into actor: PersistenceActor) async {
      let carmen = exploreElement
      let cadiz = Element(displayName: "Cádiz", type: .place)!
      _ = try? await actor.save(carmen)
      _ = try? await actor.save(cadiz)
      let first = exploreMemory
      let second = Memory(
        narrative:
          "Los domingos en Cádiz comíamos en la playa de la Caleta con la abuela Carmen.",
        date: MemoryDate(text: "los domingos de aquellos años"),
        savedAt: Date(timeIntervalSinceNow: -86400))!
      _ = try? await actor.save(first, isAnalyzed: true, isExample: false)
      _ = try? await actor.save(second, isAnalyzed: true, isExample: false)
      try? await actor.save(
        Appearance(memoryID: first.id, elementID: carmen.id, role: nil, status: .confirmedByUser))
      try? await actor.save(
        Appearance(memoryID: first.id, elementID: cadiz.id, role: nil, status: .confirmedByUser))
      try? await actor.save(
        Appearance(memoryID: second.id, elementID: carmen.id, role: nil, status: .confirmedByUser))
      try? await actor.save(
        Appearance(memoryID: second.id, elementID: cadiz.id, role: nil, status: .confirmedByUser))
    }
  }

  // MARK: momento de la conexion

  extension PreviewFixtures {
    static func connectionMoment(connectedCount: Int) -> ConnectionMoment? {
      let carmen = Element(id: ElementID(), displayName: "la abuela Carmen", type: .person)
      let cadiz = Element(id: ElementID(), displayName: "Cádiz", type: .place)
      let singer = Element(id: ElementID(), displayName: "la Singer", type: .object)
      let saved = Memory(
        id: MemoryID(), narrative: narrative,
        date: MemoryDate(text: "El verano del 87", deducedYear: 1987), savedAt: .now)
      let earlier = [
        Memory(
          id: MemoryID(),
          narrative:
            "La abuela Carmen cosía con la Singer junto a la ventana, y nos dejaba pisar el pedal.",
          savedAt: .now),
        Memory(
          id: MemoryID(), narrative: "Los domingos en Cádiz comíamos en la playa de la Caleta.",
          savedAt: .now),
      ].prefix(connectedCount)
      let appearances =
        [carmen, cadiz, singer].map {
          Appearance(memoryID: saved.id, elementID: $0.id, role: nil, status: .confirmedByUser)
        }
        + zip(earlier, [[carmen, singer], [cadiz]]).flatMap { memory, elements in
          elements.map {
            Appearance(memoryID: memory.id, elementID: $0.id, role: nil, status: .confirmedByUser)
          }
        }
      return ConnectionMoment(
        savedMemoryID: saved.id, memories: [saved] + earlier, elements: [carmen, cadiz, singer],
        appearances: appearances)
    }
  }
#endif
