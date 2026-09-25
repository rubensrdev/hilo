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
      // F8.5 D3: tarjetas propias, no List — su recorte no admite contorno-tarjeta (alto contraste)
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
    section(header: "Privacy") {
      Text(
        "Your memories, the people, places and objects in them, and your photos live only on this iPhone. Hilo has no account, sends nothing anywhere and reads your memories on the device itself. It works the same without a connection."
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
      .accessibilityIdentifier("settings.privacy")
    }
  }

  // MARK: memoria de ejemplo — cargar o borrar segun este (F2 contrato 5 y 6)

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

  // MARK: borrado total (regla 25)

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

  // MARK: informacion del producto — nombre y version, sin enlaces

  private var aboutSection: some View {
    section(header: "About") {
      LabeledContent {
        Text(AjustesCopy.versionLine(state.version, locale: interfaceLocale))
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
    // F5: bateria de docs/validacion-manual — nunca compilado en Release
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

  // MARK: seccion como tarjeta — encabezado para el rotor, contenido sobre superficie-tarjeta

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
