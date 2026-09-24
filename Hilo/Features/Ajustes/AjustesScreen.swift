import SwiftUI

// contrato 1 + DEC-59: el acceso existe y es tocable, con un estado minimo — nunca un crash ni un no-op silencioso
struct AjustesScreen: View {
  let state: ExploreState
  @Environment(\.dismiss) private var dismiss
  #if DEBUG
    @State private var isWipeConfirmationPresented = false
  #endif

  private var placeholder: some View {
    ContentUnavailableView(
      "Settings are coming soon",
      systemImage: "gearshape",
      description: Text("Language and accessibility options will live here.")
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        #if DEBUG
          List {
            Section {
              placeholder
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            debugSection
          }
        #else
          placeholder
        #endif
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
            .accessibilityIdentifier("settings.close")
        }
      }
      #if DEBUG
        .alert(
          "Wipe all data?", isPresented: $isWipeConfirmationPresented
        ) {
          Button("Wipe all data", role: .destructive) {
            Task { await state.wipeAllData() }
          }
          Button("Cancel", role: .cancel) {}
        } message: {
          Text("This removes every memory, element and photo. It cannot be undone.")
        }
      #endif
    }
  }

  #if DEBUG
    // F5: bateria de docs/validacion-manual — nunca compilado en Release
    private var debugSection: some View {
      Section("Debug") {
        Button("Load validation dataset") {
          Task { await state.loadDebugValidationDataset() }
        }
        .accessibilityIdentifier("settings.debug.loadValidationDataset")
        Button("Wipe all data", role: .destructive) {
          isWipeConfirmationPresented = true
        }
        .accessibilityIdentifier("settings.debug.wipeAllData")
      }
    }
  #endif
}

#if DEBUG
  #Preview("Empty") {
    AjustesScreen(
      state: ExploreState(
        persistenceActor: PreviewFixtures.persistenceActor(),
        comprehender: PreviewComprehender(scenario: .empty),
        interfaceLanguage: "en"))
  }
  #Preview("AX5") {
    AjustesScreen(
      state: ExploreState(
        persistenceActor: PreviewFixtures.persistenceActor(),
        comprehender: PreviewComprehender(scenario: .empty),
        interfaceLanguage: "en")
    )
    .dynamicTypeSize(.accessibility5)
  }
#endif
