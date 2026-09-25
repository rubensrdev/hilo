import SwiftUI

struct SettingsScreen: View {
  @Bindable var state: SettingsState
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var environmentLocale
  @State private var isDeleteExamplePresented = false

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    NavigationStack {
      // Cards of its own, not a List: a List's clipping can't take the high-contrast card outline.
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.separacionSecciones) {
          privacySection
          exampleMemorySection
          wipeSection
          aboutSection
          #if DEBUG
            debugSection
          #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.margenPantalla)
      }
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
      // Rule 25, double confirmation: two alerts chained through the state's step.
      .alert("Delete everything?", isPresented: $state.isFirstWipeConfirmationPresented) {
        Button("Continue", role: .destructive) { state.continueWipe() }
        Button("Cancel", role: .cancel) { state.cancelWipe() }
      } message: {
        Text(SettingsCopy.wipeFirstStepBody(locale: interfaceLocale))
      }
      .alert(
        "Delete everything for good?", isPresented: $state.isSecondWipeConfirmationPresented
      ) {
        Button("Delete everything", role: .destructive) {
          Task { if await state.confirmWipe() { dismiss() } }
        }
        Button("Cancel", role: .cancel) { state.cancelWipe() }
      } message: {
        Text(SettingsCopy.wipeSecondStepBody(locale: interfaceLocale))
      }
    }
  }

  // MARK: privacy — expands on the empty state's promise without repeating it

  private var privacySection: some View {
    section(header: "Privacy") {
      Text(
        "Your memories, the people, places and objects in them, and your photos live only on this iPhone. Hilo has no account, sends nothing anywhere and reads your memories on the device itself. It works the same without a connection."
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
      .accessibilityIdentifier("settings.privacy")
    }
  }

  // MARK: example memory — load or delete, depending on whether it is there

  private var exampleMemorySection: some View {
    section(
      header: "Example memory",
      footer:
        "A few made-up memories to see how Hilo connects them. You can delete them at any time."
    ) {
      if state.hasExampleMemory {
        Button(role: .destructive) {
          isDeleteExamplePresented = true
        } label: {
          Text("Delete the example memory")
            .botonSecundario()
            .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
            .contentShape(Rectangle())
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
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("settings.loadExample")
      }
    }
  }

  // MARK: delete everything (rule 25)

  private var wipeSection: some View {
    section(
      footer:
        "Deletes every memory, every person, place and object, and every photo from this iPhone."
    ) {
      Button(role: .destructive) {
        state.requestWipe()
      } label: {
        Text("Delete everything")
          .botonSecundario()
          .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
          .contentShape(Rectangle())
      }
      .accessibilityIdentifier("settings.wipeAll")
    }
  }

  // MARK: product information — name and version, no links

  private var aboutSection: some View {
    section(header: "About") {
      LabeledContent {
        Text(SettingsCopy.versionLine(state.version, locale: interfaceLocale))
          .metadato()
          .foregroundStyle(Color.textoSecundario)
      } label: {
        Text("Hilo")
          .botonSecundario()
          .foregroundStyle(Color.textoPrimario)
      }
      .frame(minHeight: Spacing.altoFilaMinimo)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("settings.about")
    }
  }

  #if DEBUG
    /// The docs/validacion-manual battery; never compiled into Release.
    private var debugSection: some View {
      section(header: "Debug") {
        Button {
          Task { await state.loadDebugValidationDataset() }
        } label: {
          Text("Load validation dataset")
            .frame(maxWidth: .infinity, minHeight: Spacing.altoFilaMinimo, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("settings.debug.loadValidationDataset")
      }
    }
  #endif

  // MARK: section as a card — a rotor header, content on the card surface

  private func section<Content: View>(
    header: LocalizedStringKey? = nil, footer: LocalizedStringKey? = nil,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      if let header {
        Text(header)
          .tituloSeccion()
          .foregroundStyle(Color.textoPrimario)
          .accessibilityAddTraits(.isHeader)
      }
      content()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.rellenoTarjeta)
        .background(Color.superficieTarjeta)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
        .contornoTarjeta()
      if let footer {
        Text(footer)
          .metadato()
          .foregroundStyle(Color.textoSecundario)
      }
    }
  }
}

#if DEBUG
  #Preview("Without example", traits: .modifier(SettingsScenarios(.withoutExample))) {
    SettingsPreviewScreen()
  }
  #Preview("With example", traits: .modifier(SettingsScenarios(.withExample))) {
    SettingsPreviewScreen()
  }
  #Preview("AX5", traits: .modifier(SettingsScenarios(.withExample))) {
    SettingsPreviewScreen().dynamicTypeSize(.accessibility5)
  }
  #Preview("Dark", traits: .modifier(SettingsScenarios(.withoutExample))) {
    SettingsPreviewScreen().preferredColorScheme(.dark)
  }
  #Preview(
    "Spanish",
    traits: .modifier(SettingsScenarios(.withExample, locale: Locale(identifier: "es")))
  ) { SettingsPreviewScreen() }
#endif
