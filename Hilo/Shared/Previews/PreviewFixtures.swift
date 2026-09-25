#if DEBUG
  import ImageIO
  import SwiftUI

  /// Previews only: each state is reached through CaptureState's real path, with no open setters.
  enum PreviewFixtures {
    static let narrative =
      "El verano del 87 la abuela Carmen nos llevó a Cádiz con la Singer en el coche."

    static func persistenceActor() -> PersistenceActor {
      do {
        return PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))
      } catch {
        fatalError("Could not create the preview container: \(error)")
      }
    }

    /// No UIKit, not even in DEBUG: a PNG drawn with Core Graphics.
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

    /// A second real memory for the connected and date-range scenarios, taken from the approved
    /// example memory, never invented text.
    static let secondExample = ExampleMemoryContent.seeds(for: .spanish)[1]
    static let secondDate = secondExample.dateText.flatMap {
      MemoryDate(text: $0, deducedYear: secondExample.deducedYear)
    }
  }

  // MARK: capture

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

  /// makeSharedContext is async and the canvas waits for it, so each state is reached before drawing.
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
        // No review sheet in the preview: the only path that uses it is the preparation failure.
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
        // PhotoStripper throws on data that isn't an image: the real failure path.
        state.photoData = Data("not a photo".utf8)
        await state.saveWithoutAnalyzing()
      }
      return state
    }

    /// Capped at one second: if the state never arrives, the preview shows it as is instead of hanging.
    private static func waitUntil(_ isReached: () -> Bool) async {
      for _ in 0..<100 where !isReached() {
        try? await Task.sleep(for: .milliseconds(10))
      }
    }
  }

  /// Reads the state the modifier leaves, as the app receives it from HiloApp.
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

    /// Built in the preview's view; only comprehend runs off the main actor.
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
          // Keeps reading: the preview shows comprehending with elements already in.
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

  // MARK: review

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
        // The chip removed with "Undo" goes through the same method as the button.
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

  // MARK: explore

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
      let state = ExploreState(
        persistenceActor: actor, comprehender: PreviewComprehender(scenario: .empty),
        interfaceLanguage: language, defaultExtractLength: 160)
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
        // The sample has no objects: filtering by object always gives no results.
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
      MemoryScreen(state: state, isCapturePresented: .constant(false))
    }
  }

  extension PreviewFixtures {
    static var exploreMemory: Memory {
      // Reuses PreviewFixtures.narrative, never new sample text.
      Memory(
        id: MemoryID(), narrative: narrative,
        date: MemoryDate(text: "El verano del 87", deducedYear: 1987), savedAt: .now)
    }

    static var exploreElement: Element {
      Element(id: ElementID(), displayName: "la abuela Carmen", type: .person)
    }

    static var explorePlace: Element {
      Element(id: ElementID(), displayName: "Cádiz", type: .place)
    }

    /// Two memories and two elements, for the normal, searching and element-list states.
    static func seedExploreSample(into actor: PersistenceActor) async {
      let carmen = exploreElement
      let cadiz = explorePlace
      _ = try? await actor.save(carmen)
      _ = try? await actor.save(cadiz)
      let first = exploreMemory
      let second = Memory(
        id: MemoryID(), narrative: secondExample.narrative, date: secondDate,
        savedAt: Date(timeIntervalSinceNow: -86400))
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

  // MARK: memory detail

  enum MemoryDetailScenario: Hashable, CaseIterable {
    case withPhoto
    case withoutPhoto
    case withoutConnections
    case withoutRecognizedElements
    case notAnalyzed
  }

  struct MemoryDetailScenarios: PreviewModifier {
    private struct Key: Hashable {
      let scenario: MemoryDetailScenario
      let language: String
    }

    let scenario: MemoryDetailScenario
    let locale: Locale

    init(_ scenario: MemoryDetailScenario, locale: Locale = Locale(identifier: "en")) {
      self.scenario = scenario
      self.locale = locale
    }

    static func makeSharedContext() async -> [AnyHashable: MemoryDetailState] {
      var states: [AnyHashable: MemoryDetailState] = [:]
      for language in ["en", "es"] {
        for scenario in MemoryDetailScenario.allCases {
          states[Key(scenario: scenario, language: language)] = await reached(
            scenario, language: language)
        }
      }
      return states
    }

    func body(content: Content, context: [AnyHashable: MemoryDetailState]) -> some View {
      let language = locale.language.languageCode?.identifier ?? "en"
      Group {
        if let state = context[Key(scenario: scenario, language: language)] {
          content
            .environment(state)
            .environment(\.locale, locale)
        }
      }
    }

    private static func reached(_ scenario: MemoryDetailScenario, language: String) async
      -> MemoryDetailState
    {
      let actor = PreviewFixtures.persistenceActor()
      let target = PreviewFixtures.exploreMemory
      let carmen = PreviewFixtures.exploreElement
      let cadiz = Element(id: ElementID(), displayName: "Cádiz", type: .place)

      func saveElements() async {
        _ = try? await actor.save(carmen)
        _ = try? await actor.save(cadiz)
        try? await actor.save(
          Appearance(memoryID: target.id, elementID: carmen.id, role: nil, status: .confirmedByUser)
        )
        try? await actor.save(
          Appearance(memoryID: target.id, elementID: cadiz.id, role: nil, status: .confirmedByUser)
        )
      }

      /// The second memory shares grandma Carmen: that is what connects it to the target.
      func saveConnectedMemory() async {
        let other = Memory(
          id: MemoryID(), narrative: PreviewFixtures.secondExample.narrative,
          date: PreviewFixtures.secondDate,
          savedAt: Date(timeIntervalSinceNow: -86400))
        _ = try? await actor.save(other, isAnalyzed: true, isExample: false)
        try? await actor.save(
          Appearance(memoryID: other.id, elementID: carmen.id, role: nil, status: .confirmedByUser)
        )
      }

      switch scenario {
      case .withPhoto:
        _ = try? await actor.save(
          target, photoData: PreviewFixtures.photoData, isAnalyzed: true, isExample: false)
        await saveElements()
        await saveConnectedMemory()
      case .withoutPhoto:
        _ = try? await actor.save(target, isAnalyzed: true, isExample: false)
        await saveElements()
        await saveConnectedMemory()
      case .withoutConnections:
        _ = try? await actor.save(target, isAnalyzed: true, isExample: false)
        await saveElements()
      case .withoutRecognizedElements:
        _ = try? await actor.save(target, isAnalyzed: true, isExample: false)
      case .notAnalyzed:
        _ = try? await actor.save(target, isAnalyzed: false, isExample: false)
      }

      let state = MemoryDetailState(
        memoryID: target.id, persistenceActor: actor,
        comprehender: PreviewComprehender(scenario: .notAnalyzedRetryable),
        interfaceLanguage: language
      ) {}
      await state.load()
      return state
    }
  }

  struct MemoryDetailPreviewScreen: View {
    @Environment(MemoryDetailState.self) private var state

    var body: some View {
      NavigationStack {
        MemoryDetailScreen(state: state, reviewCoordinator: state.reviewCoordinator)
      }
    }
  }

  // MARK: element detail

  enum ElementDetailScenario: Hashable, CaseIterable {
    case several
    case single
  }

  struct ElementDetailScenarios: PreviewModifier {
    private struct Key: Hashable {
      let scenario: ElementDetailScenario
      let language: String
    }

    let scenario: ElementDetailScenario
    let locale: Locale

    init(_ scenario: ElementDetailScenario, locale: Locale = Locale(identifier: "en")) {
      self.scenario = scenario
      self.locale = locale
    }

    static func makeSharedContext() async -> [AnyHashable: ElementDetailState] {
      var states: [AnyHashable: ElementDetailState] = [:]
      for language in ["en", "es"] {
        for scenario in ElementDetailScenario.allCases {
          states[Key(scenario: scenario, language: language)] = await reached(scenario)
        }
      }
      return states
    }

    func body(content: Content, context: [AnyHashable: ElementDetailState]) -> some View {
      let language = locale.language.languageCode?.identifier ?? "en"
      Group {
        if let state = context[Key(scenario: scenario, language: language)] {
          content
            .environment(state)
            .environment(\.locale, locale)
        }
      }
    }

    /// .several reuses grandma Carmen, already connected to a second memory; .single uses
    /// "la Singer", which already appears in the fixture narrative and nowhere else.
    private static func reached(_ scenario: ElementDetailScenario) async -> ElementDetailState {
      let actor = PreviewFixtures.persistenceActor()
      let target = PreviewFixtures.exploreMemory
      _ = try? await actor.save(target, isAnalyzed: true, isExample: false)
      let elementID: ElementID

      switch scenario {
      case .several:
        let carmen = PreviewFixtures.exploreElement
        _ = try? await actor.save(carmen)
        try? await actor.save(
          Appearance(
            memoryID: target.id, elementID: carmen.id, role: nil, status: .confirmedByUser))
        let other = Memory(
          id: MemoryID(), narrative: PreviewFixtures.secondExample.narrative,
          date: PreviewFixtures.secondDate,
          savedAt: Date(timeIntervalSinceNow: -86400))
        _ = try? await actor.save(other, isAnalyzed: true, isExample: false)
        try? await actor.save(
          Appearance(
            memoryID: other.id, elementID: carmen.id, role: nil, status: .confirmedByUser))
        elementID = carmen.id
      case .single:
        let singer = Element(id: ElementID(), displayName: "la Singer", type: .object)
        _ = try? await actor.save(singer)
        try? await actor.save(
          Appearance(
            memoryID: target.id, elementID: singer.id, role: nil, status: .confirmedByUser))
        elementID = singer.id
      }

      let state = ElementDetailState(elementID: elementID, persistenceActor: actor) {}
      await state.load()
      return state
    }
  }

  struct ElementDetailPreviewScreen: View {
    @Environment(ElementDetailState.self) private var state

    var body: some View {
      NavigationStack {
        ElementDetailScreen(state: state)
      }
    }
  }

  // MARK: settings

  enum SettingsScenario: Hashable, CaseIterable {
    case withoutExample
    case withExample
  }

  struct SettingsScenarios: PreviewModifier {
    private struct Key: Hashable {
      let scenario: SettingsScenario
      let language: String
    }

    let scenario: SettingsScenario
    let locale: Locale

    init(_ scenario: SettingsScenario, locale: Locale = Locale(identifier: "en")) {
      self.scenario = scenario
      self.locale = locale
    }

    static func makeSharedContext() async -> [AnyHashable: SettingsState] {
      var states: [AnyHashable: SettingsState] = [:]
      for language in ["en", "es"] {
        for scenario in SettingsScenario.allCases {
          states[Key(scenario: scenario, language: language)] = await reached(
            scenario, language: language)
        }
      }
      return states
    }

    func body(content: Content, context: [AnyHashable: SettingsState]) -> some View {
      let language = locale.language.languageCode?.identifier ?? "en"
      Group {
        if let state = context[Key(scenario: scenario, language: language)] {
          content
            .environment(state)
            .environment(\.locale, locale)
        }
      }
    }

    private static func reached(_ scenario: SettingsScenario, language: String) async
      -> SettingsState
    {
      let state = SettingsState(
        persistenceActor: PreviewFixtures.persistenceActor(), version: "1.0",
        onMemoryChanged: {}, onWiped: {})
      if scenario == .withExample {
        await state.loadExampleMemory(
          language: ExampleMemoryLanguage(interfaceLocale: Locale(identifier: language)))
      }
      await state.load()
      return state
    }
  }

  struct SettingsPreviewScreen: View {
    @Environment(SettingsState.self) private var state

    var body: some View {
      SettingsScreen(state: state)
    }
  }

  // MARK: connection moment

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
