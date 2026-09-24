import SwiftUI

// contrato 4: S5 Detalle de elemento — nombre, tipo, alias, recuerdos propios en el orden de
// DEC-35, rango temporal si hay mas de uno (DEC-57, hueco A1), renombrar y añadir alias (DEC-26).
// El retrato (F7) y el tejido (F9) quedan reservados, sin dibujarse: no hay hueco para ellos aqui.
struct ElementDetailScreen: View {
  @Bindable var state: ElementDetailState
  @Environment(\.locale) private var environmentLocale
  @State private var isRenamePresented = false
  @State private var renameText = ""
  @State private var isAddAliasPresented = false
  @State private var aliasText = ""
  @State private var conflictElementName: String?

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  private var isConflictPresented: Binding<Bool> {
    Binding(get: { conflictElementName != nil }, set: { if !$0 { conflictElementName = nil } })
  }

  var body: some View {
    Group {
      if let element = state.element {
        ScrollView {
          content(element)
            .padding(Spacing.margenPantalla)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .background(Color.fondo)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      // texto plano, no un menu "...": la referencia (13) dibuja exactamente eso aqui, a
      // diferencia de S4; .topBarTrailing nunca colapsa (leccion de DEC-12/DEC-59, F5.2/F5.3)
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          renameText = state.element?.displayName ?? ""
          isRenamePresented = true
        } label: {
          Text("Rename")
        }
        .accessibilityIdentifier("elementDetail.rename")
      }
    }
    .task { await state.load() }
    .alert(renameTitle, isPresented: $isRenamePresented) {
      TextField("Name", text: $renameText)
      Button {
        Task { await confirmRename() }
      } label: {
        Text("Rename in \(state.ownMemories.count) memories")
      }
      .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      Button(role: .cancel) {
      } label: {
        Text("Cancel")
      }
    } message: {
      Text(
        "\(state.element?.displayName ?? "") appears in \(state.ownMemories.count) memories. Renaming changes the name in all of them."
      )
    }
    .alert("Add an alias", isPresented: $isAddAliasPresented) {
      TextField("Alias", text: $aliasText)
      Button {
        Task { await confirmAddAlias() }
      } label: {
        Text("Add")
      }
      .disabled(aliasText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      Button(role: .cancel) {
      } label: {
        Text("Cancel")
      }
    } message: {
      Text(
        "Hilo will recognize this name for \(state.element?.displayName ?? "") in future memories."
      )
    }
    .alert(conflictTitle, isPresented: isConflictPresented) {
      Button {
      } label: {
        Text("OK")
      }
    }
  }

  private var renameTitle: Text {
    // nunca se ve sin element (isRenamePresented solo se activa con un elemento cargado)
    guard let element = state.element else { return Text(verbatim: "") }
    return Text("Rename \(element.displayName) everywhere?")
  }

  private var conflictTitle: Text {
    Text("\(conflictElementName ?? "") already exists")
  }

  private func confirmRename() async {
    switch await state.rename(to: renameText) {
    case .applied:
      isRenamePresented = false
    case .blocked(let name):
      isRenamePresented = false
      conflictElementName = name
    case .failed:
      break  // se queda abierto, mismo texto, para reintentar (criterio de editNarrative en F5.3)
    }
  }

  private func confirmAddAlias() async {
    switch await state.addAlias(aliasText) {
    case .applied:
      isAddAliasPresented = false
      aliasText = ""
    case .blocked(let name):
      isAddAliasPresented = false
      conflictElementName = name
    case .failed:
      break
    }
  }

  @ViewBuilder
  private func content(_ element: Element) -> some View {
    VStack(alignment: .leading, spacing: Spacing.separacionSecciones) {
      VStack(alignment: .leading, spacing: Spacing.espacio2) {
        header(element)
        if !element.aliases.isEmpty {
          Text("Also known as: \(element.aliases.joinedAsList(locale: interfaceLocale))")
            .metadato()
            .foregroundStyle(Color.textoSecundario)
            .accessibilityIdentifier("elementDetail.aliases")
        }
        addAliasButton
        dateRangeText
      }
      if state.ownMemories.count == 1 {
        Text(
          ConnectionCopy.firstAppearanceBody(names: [element.displayName], locale: interfaceLocale)
        )
        .metadato()
        .foregroundStyle(Color.textoSecundario)
        .accessibilityIdentifier("elementDetail.singleMemoryInvite")
      }
      memoriesSection
    }
  }

  private func header(_ element: Element) -> some View {
    HStack(alignment: .top, spacing: Spacing.espacio3) {
      Image(systemName: element.type.symbolName)
        .font(.largeTitle)
        .foregroundStyle(element.type.color)
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Text(element.displayName)
          .tituloPantalla()
          .foregroundStyle(Color.textoPrimario)
        Text(
          ExploreCopy.elementTypeAndCount(
            element.type, count: state.ownMemories.count, locale: interfaceLocale)
        )
        .metadato()
        .foregroundStyle(Color.textoSecundario)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var addAliasButton: some View {
    Button {
      aliasText = ""
      isAddAliasPresented = true
    } label: {
      Text("Add an alias")
        .botonSecundario()
        .foregroundStyle(Color.acentoHilo)
        .frame(minHeight: Spacing.altoFilaMinimo, alignment: .leading)
    }
    .accessibilityIdentifier("elementDetail.addAlias")
  }

  // DEC-57 (A1): con los dos extremos, un label compuesto para que VoiceOver no lea el guion
  // medio como texto; con uno solo, el texto visible ya es una frase completa
  @ViewBuilder
  private var dateRangeText: some View {
    if let dateRange = state.dateRangeDisplay {
      Group {
        if let endpoints = state.dateRangeEndpoints {
          Text(dateRange)
            .accessibilityLabel(
              ExploreCopy.dateRangeAccessibilityLabel(
                oldest: endpoints.oldest, newest: endpoints.newest, locale: interfaceLocale))
        } else {
          Text(dateRange)
        }
      }
      .fechaUsuario()
      .foregroundStyle(Color.textoSecundario)
      .accessibilityIdentifier("elementDetail.dateRange")
    }
  }

  private var memoriesSection: some View {
    VStack(spacing: Spacing.separacionTarjetas) {
      ForEach(state.ownMemories) { memory in
        NavigationLink(value: memory.id) {
          MemoryCard(memory: memory)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#if DEBUG
  #Preview("Several memories", traits: .modifier(ElementDetailScenarios(.several))) {
    ElementDetailPreviewScreen()
  }
  #Preview("Single memory", traits: .modifier(ElementDetailScenarios(.single))) {
    ElementDetailPreviewScreen()
  }
  #Preview("AX5", traits: .modifier(ElementDetailScenarios(.several))) {
    ElementDetailPreviewScreen().dynamicTypeSize(.accessibility5)
  }
  #Preview(
    "Spanish",
    traits: .modifier(ElementDetailScenarios(.several, locale: Locale(identifier: "es")))
  ) { ElementDetailPreviewScreen() }
#endif
