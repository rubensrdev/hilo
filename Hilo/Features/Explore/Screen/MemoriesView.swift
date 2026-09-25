import SwiftUI

struct MemoriesView: View {
  let state: ExploreState
  let openCapture: () -> Void
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  private var exampleLanguage: ExampleMemoryLanguage {
    ExampleMemoryLanguage(interfaceLocale: interfaceLocale)
  }

  var body: some View {
    ScrollView {
      Group {
        switch state.memoriesDisplay {
        case .empty: emptyState
        case .single(let memory): singleState(memory)
        case .normal(let groups): normalState(groups)
        case .searching(let results): searchingState(results)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(Spacing.margenPantalla)
    }
    .background(Color.fondo)
  }

  // MARK: empty — the promise, privacy said once, two ways out

  private var emptyState: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio4) {
      Text(
        "Hilo remembers the people, places and objects in your memories, and connects them for you."
      )
      .tituloSeccion()
      .foregroundStyle(Color.textoPrimario)
      Text("Everything stays on your iPhone. No account, no connection.")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
      Button {
        openCapture()
      } label: {
        Text("Tell your first memory")
          .botonPrincipal()
          .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.acentoHilo)
      .foregroundStyle(Color.textoSobreAcento)
      .accessibilityIdentifier("explore.tellFirstMemory")
      Button {
        Task { await state.loadExampleMemory(language: exampleLanguage) }
      } label: {
        Text("Load an example memory")
          .botonSecundario()
          .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
          .contentShape(Rectangle())
      }
      .accessibilityIdentifier("explore.loadExample")
    }
  }

  // MARK: a single memory — nudges towards the second

  private func singleState(_ memory: Memory) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio4) {
      NavigationLink(value: memory.id) {
        MemoryCard(memory: memory)
      }
      .buttonStyle(.plain)
      Text("This is where connections begin.")
        .tituloSeccion()
        .foregroundStyle(Color.textoPrimario)
      Button {
        openCapture()
      } label: {
        Text("Tell a second memory")
          .botonPrincipal()
          .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.acentoHilo)
      .foregroundStyle(Color.textoSobreAcento)
      .accessibilityIdentifier("explore.tellSecondMemory")
    }
  }

  // MARK: normal — grouped by decade, uncapped

  private func normalState(_ groups: [MemoryGroup]) -> some View {
    LazyVStack(alignment: .leading, spacing: Spacing.separacionSecciones) {
      ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
        Section {
          VStack(spacing: Spacing.separacionTarjetas) {
            ForEach(group.memories) { memory in
              NavigationLink(value: memory.id) {
                MemoryCard(memory: memory)
              }
              .buttonStyle(.plain)
            }
          }
        } header: {
          Text(ExploreCopy.decadeHeader(group.decade, locale: interfaceLocale))
            .encabezadoEpoca()
            .foregroundStyle(Color.textoPrimario)
            // Outside a List, Section doesn't mark itself as a header: without this the VoiceOver rotor
            // can't find the decades.
            .accessibilityAddTraits(.isHeader)
        }
      }
    }
  }

  // MARK: searching — with and without results, never the first-time empty state

  private func searchingState(_ results: [MemorySearchResult]) -> some View {
    Group {
      if results.isEmpty {
        Text("Nothing matches yet")
          .tituloSeccion()
          .foregroundStyle(Color.textoSecundario)
          .accessibilityIdentifier("explore.searchNoResults")
      } else {
        LazyVStack(spacing: Spacing.separacionTarjetas) {
          ForEach(results, id: \.memoryID) { result in
            if let memory = state.memories.first(where: { $0.id == result.memoryID }) {
              NavigationLink(value: memory.id) {
                MemoryCard(
                  memory: memory, searchMatches: result.narrativeMatches,
                  searchExtract: result.extract,
                  matchedElements: result.narrativeMatches.isEmpty
                    ? result.matchedElementIDs.compactMap { id in
                      state.elements.first(where: { $0.id == id })
                    }.map { ($0, state.memoryCount(for: $0)) } : [])
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Empty", traits: .modifier(ExploreScenarios(.empty))) {
    ExplorePreviewScreen()
  }
  #Preview("Single memory", traits: .modifier(ExploreScenarios(.single))) {
    ExplorePreviewScreen()
  }
  #Preview(
    "Normal, grouped by decade", traits: .modifier(ExploreScenarios(.normal))
  ) {
    ExplorePreviewScreen()
  }
  #Preview(
    "Searching, with results",
    traits: .modifier(ExploreScenarios(.searchingWithResults))
  ) { ExplorePreviewScreen() }
  #Preview(
    "Searching, no results",
    traits: .modifier(ExploreScenarios(.searchingNoResults))
  ) { ExplorePreviewScreen() }
  #Preview(
    "Normal, AX5", traits: .modifier(ExploreScenarios(.normal))
  ) { ExplorePreviewScreen().dynamicTypeSize(.accessibility5) }
  #Preview(
    "Empty, Spanish",
    traits: .modifier(ExploreScenarios(.empty, locale: Locale(identifier: "es")))
  ) { ExplorePreviewScreen() }
#endif
