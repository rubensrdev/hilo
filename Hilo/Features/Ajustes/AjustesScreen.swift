import SwiftUI

// F8 contrato 1: S7 es una hoja, superficie del sistema como contenedor (tokens.md §7)
struct AjustesScreen: View {
  @Bindable var state: AjustesState
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var environmentLocale
  @State private var isDeleteExamplePresented = false

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    NavigationStack {
      List {
        privacySection
        exampleMemorySection
        wipeSection
        aboutSection
        #if DEBUG
          debugSection
        #endif
      }
      .scrollContentBackground(.hidden)
      .background(Color.fondo)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
            .accessibilityIdentifier("settings.close")
        }
      }
      .task { await state.load() }
      .alert("Delete the example memory?", isPresented: $isDeleteExamplePresented) {
        Button("Delete the example", role: .destructive) {
          Task { await state.deleteExampleMemory() }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Your own memories stay. Only the example memories are deleted.")
      }
      // regla 25, doble confirmacion: dos alertas encadenadas por el paso del estado
      .alert("Delete everything?", isPresented: $state.isFirstWipeConfirmationPresented) {
        Button("Continue", role: .destructive) { state.continueWipe() }
        Button("Cancel", role: .cancel) { state.cancelWipe() }
      } message: {
        Text(AjustesCopy.wipeFirstStepBody(locale: interfaceLocale))
      }
      .alert(
        "Delete everything for good?", isPresented: $state.isSecondWipeConfirmationPresented
      ) {
        Button("Delete everything", role: .destructive) {
          Task { if await state.confirmWipe() { dismiss() } }
        }
        Button("Cancel", role: .cancel) { state.cancelWipe() }
      } message: {
        Text(AjustesCopy.wipeSecondStepBody(locale: interfaceLocale))
      }
    }
  }

  // MARK: privacidad — amplia la afirmacion del vacio, no la repite (§9.2)

  private var privacySection: some View {
    Section {
      Text(
        "Your memories, the people, places and objects in them, and your photos live only on this iPhone. Hilo has no account, sends nothing anywhere and reads your memories on the device itself. It works the same without a connection."
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
      .accessibilityIdentifier("settings.privacy")
    } header: {
      Text("Privacy")
    }
    .listRowBackground(Color.superficieTarjeta)
  }

  // MARK: memoria de ejemplo — cargar o borrar segun este (F2 contrato 5 y 6)

  private var exampleMemorySection: some View {
    Section {
      if state.hasExampleMemory {
        Button(role: .destructive) {
          isDeleteExamplePresented = true
        } label: {
          Text("Delete the example memory")
            .botonSecundario()
            .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
        }
        .accessibilityIdentifier("settings.deleteExample")
      } else {
        Button {
          Task {
            await state.loadExampleMemory(
              language: ExampleMemoryLanguage(interfaceLocale: interfaceLocale))
          }
        } label: {
          Text("Load the example memory")
            .botonSecundario()
            .foregroundStyle(Color.acentoHilo)
            .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
        }
        .accessibilityIdentifier("settings.loadExample")
      }
    } header: {
      Text("Example memory")
    } footer: {
      Text("A few made-up memories to see how Hilo connects them. You can delete them at any time.")
    }
    .listRowBackground(Color.superficieTarjeta)
  }

  // MARK: borrado total (regla 25)

  private var wipeSection: some View {
    Section {
      Button(role: .destructive) {
        state.requestWipe()
      } label: {
        Text("Delete everything")
          .botonSecundario()
          .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
      }
      .accessibilityIdentifier("settings.wipeAll")
    } footer: {
      Text(
        "Deletes every memory, every person, place and object, and every photo from this iPhone.")
    }
    .listRowBackground(Color.superficieTarjeta)
  }

  // MARK: informacion del producto — nombre y version, sin enlaces

  private var aboutSection: some View {
    Section {
      LabeledContent {
        Text(AjustesCopy.versionLine(state.version, locale: interfaceLocale))
          .metadato()
          .foregroundStyle(Color.textoSecundario)
      } label: {
        Text("Hilo")
          .botonSecundario()
          .foregroundStyle(Color.textoPrimario)
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("settings.about")
    } header: {
      Text("About")
    }
    .listRowBackground(Color.superficieTarjeta)
  }

  #if DEBUG
    // F5: bateria de docs/validacion-manual — nunca compilado en Release
    private var debugSection: some View {
      Section("Debug") {
        Button("Load validation dataset") {
          Task { await state.loadDebugValidationDataset() }
        }
        .accessibilityIdentifier("settings.debug.loadValidationDataset")
      }
      .listRowBackground(Color.superficieTarjeta)
    }
  #endif
}

#if DEBUG
  #Preview("Without example", traits: .modifier(AjustesScenarios(.withoutExample))) {
    AjustesPreviewScreen()
  }
  #Preview("With example", traits: .modifier(AjustesScenarios(.withExample))) {
    AjustesPreviewScreen()
  }
  #Preview("AX5", traits: .modifier(AjustesScenarios(.withExample))) {
    AjustesPreviewScreen().dynamicTypeSize(.accessibility5)
  }
  #Preview("Dark", traits: .modifier(AjustesScenarios(.withoutExample))) {
    AjustesPreviewScreen().preferredColorScheme(.dark)
  }
  #Preview(
    "Spanish",
    traits: .modifier(AjustesScenarios(.withExample, locale: Locale(identifier: "es")))
  ) { AjustesPreviewScreen() }
#endif
