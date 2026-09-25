import SwiftUI

// contrato 2: S3 Revision, cuatro bloques (cada uno solo si tiene contenido) — la vista solo
// lee ReviewState y emite intencion, cada accion llama directo a un metodo ya probado (F4.1)
struct ReviewScreen: View {
  @State private var reviewState: ReviewState
  @State private var dateText: String
  let narrative: String
  let onSave: (ReviewState, String) -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var environmentLocale
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  // P2: en tamaños de accesibilidad lo que va en fila se apila
  private func rowLayout(
    alignment: VerticalAlignment = .center, spacing: CGFloat
  ) -> AnyLayout {
    dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
      : AnyLayout(HStackLayout(alignment: alignment, spacing: spacing))
  }

  // MARK: renombrar — contrato 4, DEC-40/DEC-26/DEC-41/DEC-48: un unico alert del sistema con
  // campo de texto, para cualquier elemento; el aviso de alcance solo si ya existia (DEC-22)
  private struct RenamePrompt {
    let itemID: ReviewItemID
    let currentName: String
    let otherMemoriesCount: Int?  // nil = elemento nuevo, sin aviso de alcance
  }

  private struct RenameConflict {
    let conflictName: String
    let isReviewSibling: Bool
  }

  @State private var renamePrompt: RenamePrompt?
  @State private var renameText = ""
  @State private var renameConflict: RenameConflict?
  @State private var pendingRenamePrompt: RenamePrompt?
  @FocusState private var isDateFocused: Bool

  // F8.4: quitar, deshacer, rechazar y responder sustituyen la vista enfocada; VoiceOver
  // volveria al principio de la hoja sin un destino explicito
  private enum ReviewFocus: Hashable {
    case item(ReviewItemID)
    case removal(ReviewItemID)
  }
  @AccessibilityFocusState private var focused: ReviewFocus?

  // renaming solo lo usan las previews: arrancan con el alert de renombrar ya abierto
  init(
    initial: ReviewState, narrative: String, renaming itemID: ReviewItemID? = nil,
    onSave: @escaping (ReviewState, String) -> Void
  ) {
    _reviewState = State(initialValue: initial)
    _dateText = State(initialValue: initial.extractedDateText ?? "")
    self.narrative = narrative
    self.onSave = onSave
    if let itemID, let prompt = Self.initialRenamePrompt(for: itemID, in: initial.blocks) {
      _renamePrompt = State(initialValue: prompt)
      _renameText = State(initialValue: prompt.currentName)
    }
  }

  private static func initialRenamePrompt(for itemID: ReviewItemID, in blocks: ReviewBlocks)
    -> RenamePrompt?
  {
    if let understood = blocks.understood.first(where: { $0.id == itemID }) {
      return RenamePrompt(itemID: itemID, currentName: understood.name, otherMemoriesCount: nil)
    }
    if let known = blocks.known.first(where: { $0.id == itemID }) {
      return RenamePrompt(
        itemID: itemID, currentName: known.name, otherMemoriesCount: known.otherMemoriesCount)
    }
    return nil
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.espacio5) {
          narrativeSection

          if reviewState.blocks.isNothingRecognized {
            nothingRecognizedSection
          } else {
            if reviewState.blocks.showsUnderstood {
              understoodSection
            }
            if !reviewState.blocks.known.isEmpty {
              knownSection
            }
            if !reviewState.blocks.doubtful.isEmpty {
              doubtfulSection
            }
            if reviewState.blocks.isBeginning {
              beginningSection
            }
          }

          dateSection
          saveButton
        }
        .padding(Spacing.margenPantalla)
      }
      // tokens.md §1.8: debajo de la barra de vidrio siempre queda fondo
      .background(Color.fondo)
      .navigationTitle("Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert(
        renameAlertTitle, isPresented: isRenamePromptPresented, presenting: renamePrompt
      ) { prompt in
        TextField("Name", text: $renameText)
        Button(prompt.otherMemoriesCount == nil ? "Rename" : "Rename Everywhere") {
          confirmRename(prompt)
        }
        .disabled(isRenameConfirmDisabled(prompt))
        Button("Cancel", role: .cancel) {}
      } message: { prompt in
        if let otherMemoriesCount = prompt.otherMemoriesCount {
          Text(
            "\(prompt.currentName) appears in \(otherMemoriesCount) other memories. The new name will show there too."
          )
        }
      }
      .alert(
        renameConflictTitle, isPresented: isRenameConflictPresented, presenting: renameConflict
      ) { conflict in
        Button("OK") {
          renameConflict = nil
          renamePrompt = pendingRenamePrompt
          pendingRenamePrompt = nil
        }
      } message: { conflict in
        Text(
          conflict.isReviewSibling
            ? "Choose a different name, or rename \(conflict.conflictName) first."
            : "Choose a different name."
        )
      }
    }
  }

  // MARK: renombrar — helpers puros de presentacion, la decision (aplicar/bloquear) es de ReviewState

  private var isRenamePromptPresented: Binding<Bool> {
    Binding(get: { renamePrompt != nil }, set: { if !$0 { renamePrompt = nil } })
  }

  private var isRenameConflictPresented: Binding<Bool> {
    Binding(get: { renameConflict != nil }, set: { if !$0 { renameConflict = nil } })
  }

  private var renameAlertTitle: Text {
    // nunca se ve: el alert solo se presenta cuando renamePrompt no es nil (isRenamePromptPresented)
    guard let renamePrompt else { return Text(verbatim: "") }
    return renamePrompt.otherMemoriesCount == nil
      ? Text("Rename \(renamePrompt.currentName)?")
      : Text("Rename \(renamePrompt.currentName) everywhere?")
  }

  private var renameConflictTitle: Text {
    guard let renameConflict else { return Text(verbatim: "") }
    return renameConflict.isReviewSibling
      ? Text("\(renameConflict.conflictName) is already in this memory")
      : Text("\(renameConflict.conflictName) already exists")
  }

  private func isRenameConfirmDisabled(_ prompt: RenamePrompt) -> Bool {
    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty || trimmed == prompt.currentName
  }

  private func startRenaming(itemID: ReviewItemID, currentName: String, otherMemoriesCount: Int?) {
    renamePrompt = RenamePrompt(
      itemID: itemID, currentName: currentName, otherMemoriesCount: otherMemoriesCount)
    renameText = currentName
  }

  // DEC-26/DEC-48: nombra al conflicto por su nombre visible actual, pendiente si lo tiene
  private func confirmRename(_ prompt: RenamePrompt) {
    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
    switch reviewState.rename(prompt.itemID, to: trimmed) {
    case .applied, .becameRecognized:
      renamePrompt = nil
    case .blocked(let elementID):
      let name = reviewState.knownElements.first(where: { $0.id == elementID })?.displayName ?? ""
      pendingRenamePrompt = prompt
      renamePrompt = nil
      renameConflict = RenameConflict(conflictName: name, isReviewSibling: false)
    case .blockedByReviewItem(let siblingID):
      let name = reviewState.items.first(where: { $0.id == siblingID })?.currentName ?? ""
      pendingRenamePrompt = prompt
      renamePrompt = nil
      renameConflict = RenameConflict(conflictName: name, isReviewSibling: true)
    }
  }

  // MARK: relato — contrato de accesibilidad de Hilo: nunca se trunca, se lee como un bloque

  private var narrativeSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("Your words, as you wrote them")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
        .accessibilityAddTraits(.isHeader)
      Text(narrative)
        .relato()
        .accessibilityIdentifier("review.narrative")
    }
  }

  // MARK: sin nada reconocido — anexo DEC-46

  private var nothingRecognizedSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("No names this time")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      Text(
        "Hilo didn't find named people, places or objects. It's still a memory, and it will be saved in your words."
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
    }
  }

  // MARK: bloque 1 — lo que ha entendido, agrupado por tipo, con quitar/deshacer (DEC-17)

  @ViewBuilder
  private var understoodSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("What Hilo understood")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      ForEach(reviewState.blocks.understoodGroups, id: \.type) { group in
        VStack(alignment: .leading, spacing: Spacing.espacio2) {
          // P1: el color del tipo va en el simbolo; el texto footnote queda en texto-secundario
          Label {
            Text(group.type.localizedPluralName(locale: interfaceLocale))
              .foregroundStyle(Color.textoSecundario)
          } icon: {
            Image(systemName: group.type.symbolName)
              .foregroundStyle(group.type.color)
              .accessibilityHidden(true)
          }
          .metadato()
          ForEach(group.rows) { row in
            understoodChip(row)
          }
        }
      }
    }
  }

  private func understoodChip(_ row: ReviewBlocks.UnderstoodRow) -> some View {
    let layout = rowLayout(spacing: Spacing.espacio2)
    return layout {
      if row.isRemoved {
        // quitado: no se ofrece renombrar hasta deshacer (regla del proyecto, F4.1 rename())
        Label {
          Text(row.name)
            .chipElemento()
            .foregroundStyle(Color.textoSecundario)
            .strikethrough()
        } icon: {
          Image(systemName: row.type.symbolName)
            .foregroundStyle(Color.textoSecundario)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          ReviewCopy.removedElementLabel(name: row.name, type: row.type, locale: interfaceLocale))
      } else {
        Button {
          startRenaming(itemID: row.id, currentName: row.name, otherMemoriesCount: nil)
        } label: {
          Label {
            Text(row.name)
              .chipElemento()
              .foregroundStyle(Color.textoPrimario)
          } icon: {
            Image(systemName: row.type.symbolName)
              .foregroundStyle(row.type.color)
          }
          .frame(minHeight: Spacing.objetivoToqueMinimo)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          ReviewCopy.elementLabel(
            name: row.name, type: row.type, otherMemories: nil, locale: interfaceLocale)
        )
        .accessibilityHint("Double tap to rename")
        .accessibilityFocused($focused, equals: .item(row.id))
      }

      if row.isRemoved {
        // ya lo dice la etiqueta del chip: VoiceOver no lo lee dos veces
        Text("Removed from this memory")
          .metadato()
          .foregroundStyle(Color.textoSecundario)
          .accessibilityHidden(true)
        Button {
          reviewState.restore(row.id)
          focused = .removal(row.id)
        } label: {
          Text("Undo")
            .frame(minWidth: Spacing.objetivoToqueMinimo, minHeight: Spacing.objetivoToqueMinimo)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Undo removing \(row.name)")
        .accessibilityFocused($focused, equals: .removal(row.id))
      } else {
        Button {
          reviewState.remove(row.id)
          focused = .removal(row.id)
          AccessibilityNotification.Announcement(
            ReviewCopy.removedElementLabel(name: row.name, type: row.type, locale: interfaceLocale)
          ).post()
        } label: {
          Image(systemName: "xmark")
            .frame(minWidth: Spacing.objetivoToqueMinimo, minHeight: Spacing.objetivoToqueMinimo)
        }
        .accessibilityLabel("Remove \(row.name)")
        .accessibilityHint("Leaves it out of this memory. You can undo it.")
        .accessibilityFocused($focused, equals: .removal(row.id))
      }
    }
    .padding(.horizontal, Spacing.espacio3)
    .padding(.vertical, Spacing.espacio2)
    .background(Color.superficieHundida, in: chipShape)
  }

  // apilado, la capsula se come las esquinas del texto: pasa a la forma de las tarjetas
  private var chipShape: AnyShape {
    dynamicTypeSize.isAccessibilitySize
      ? AnyShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
      : AnyShape(Capsule())
  }

  // MARK: bloque 2 — ya conocia, reconocimiento rechazable con un toque, sin dialogo (DEC-22)

  @ViewBuilder
  private var knownSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("Already in your memory")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      ForEach(reviewState.blocks.known) { known in
        knownRow(known)
      }
    }
  }

  private func knownRow(_ known: ReviewBlocks.Known) -> some View {
    // por la linea base: el nombre crece a 44pt de toque y el simbolo debe seguir a su altura
    let layout = rowLayout(alignment: .firstTextBaseline, spacing: Spacing.espacio3)
    return layout {
      Image(systemName: known.type.symbolName)
        .foregroundStyle(known.type.color)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Button {
          startRenaming(
            itemID: known.id, currentName: known.name,
            otherMemoriesCount: known.otherMemoriesCount)
        } label: {
          Text(known.name)
            .nombreElemento()
            .foregroundStyle(Color.textoPrimario)
            .frame(minHeight: Spacing.objetivoToqueMinimo, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          ReviewCopy.elementLabel(
            name: known.name, type: known.type, otherMemories: known.otherMemoriesCount,
            locale: interfaceLocale)
        )
        .accessibilityHint("Double tap to rename")
        .accessibilityFocused($focused, equals: .item(known.id))
        // ya lo dice la etiqueta del nombre: VoiceOver no lo lee dos veces
        Text(
          "\(known.type.localizedName(locale: interfaceLocale)) · in \(known.otherMemoriesCount) memories"
        )
        .metadato()
        .foregroundStyle(Color.textoSecundario)
        .accessibilityHidden(true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        reviewState.rejectRecognition(known.id)
        focused = .item(known.id)
      } label: {
        Text("Not the same \(known.name)")
          .metadato()
          .frame(minHeight: Spacing.objetivoToqueMinimo)
          .contentShape(Rectangle())
      }
      .accessibilityHint("Keeps it apart from the one you already know")
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
  }

  // MARK: bloque 3 — duda de identidad, dos respuestas de igual peso, ninguna preseleccionada

  private struct DoubtCard: Identifiable {
    let id: String
    let itemID: ReviewItemID
    let itemName: String
    let itemType: ElementType
    let candidate: ReviewBlocks.Doubtful.Candidate
  }

  // una tarjeta por candidato: si un item tiene mas de uno (identityDoubt raro con varias
  // coincidencias), se apilan varias preguntas binarias en vez de una sola con N respuestas
  private var doubtCards: [DoubtCard] {
    reviewState.blocks.doubtful.flatMap { item in
      item.candidates.map { candidate in
        DoubtCard(
          id: "\(item.id.value)-\(candidate.id.value)", itemID: item.id, itemName: item.name,
          itemType: item.type, candidate: candidate)
      }
    }
  }

  @ViewBuilder
  private var doubtfulSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("Hilo is not sure")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      ForEach(doubtCards) { card in
        doubtCard(card)
      }
      Text("You can save without answering. Hilo will keep them apart.")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
    }
  }

  private func doubtCard(_ card: DoubtCard) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      Text("Is \(card.itemName) the same \(card.candidate.name) you already know?")
        .preguntaIdentidad()
      Text("\(card.candidate.name) appears in \(card.candidate.otherMemoriesCount) memories")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
      // tokens §2.2: en AX las dos respuestas se apilan, con el mismo peso
      let answersLayout = rowLayout(spacing: Spacing.espacio2)
      answersLayout {
        Button {
          reviewState.confirmDoubt(card.itemID, as: card.candidate.id)
          focused = .item(card.itemID)
        } label: {
          Text("Same \(card.candidate.name)")
            .botonSecundario()
            .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
        }
        .buttonStyle(.bordered)

        Button {
          reviewState.rejectDoubt(card.itemID)
          focused = .item(card.itemID)
        } label: {
          Text(ReviewCopy.doubtRejection(type: card.itemType, locale: interfaceLocale))
            .botonSecundario()
            .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
        }
        .buttonStyle(.bordered)
      }
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
  }

  // MARK: sin conexiones — el comienzo, nunca un fallo (anexo DEC-46)

  private var beginningSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("These are the first threads")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      Text(
        ConnectionCopy.firstAppearanceBody(
          names: reviewState.blocks.beginningNames,
          locale: interfaceLocale)
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
  }

  // MARK: bloque 4 — la fecha, editable como texto, nunca reanalizada (contrato 2)

  private var dateSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("Date")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      // la fecha es texto del usuario: a AX5 crece hacia abajo en vez de desplazarse de lado
      ZStack(alignment: .topLeading) {
        TextField(text: $dateText, axis: .vertical) { EmptyView() }
          .fechaUsuario()
          .focused($isDateFocused)
          .accessibilityLabel("Date")
          .accessibilityHint("Add a date in your words")
          .accessibilityIdentifier("review.date")
        // el placeholder del sistema no reparte lineas y a AX5 se cortaba
        if dateText.isEmpty {
          Text("Add a date in your words")
            .fechaUsuario()
            .foregroundStyle(Color.textoDeshabilitado)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      .frame(minHeight: Spacing.objetivoToqueMinimo, alignment: .leading)
      .padding(Spacing.espacio2)
      .background(Color.superficieHundida)
      .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
      // el campo mide una linea: todo el fondo enfoca, para que el toque llegue a 44pt
      .contentShape(Rectangle())
      .onTapGesture { isDateFocused = true }
    }
  }

  // MARK: guardar — siempre disponible, ninguna duda lo bloquea (contrato 2)

  private var saveButton: some View {
    Button {
      // la hoja no se cierra aqui: pasa al momento de la conexion o la cierra el coordinador
      onSave(reviewState, dateText)
    } label: {
      Text("Save memory")
        .botonPrincipal()
        .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.acentoHilo)
    .foregroundStyle(Color.textoSobreAcento)
    .accessibilityIdentifier("review.save")
  }
}

#if DEBUG
  #Preview("Connected") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.connected), narrative: PreviewFixtures.narrative
    ) { _, _ in }
  }
  #Preview("Beginning") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.beginning), narrative: PreviewFixtures.narrative
    ) { _, _ in }
  }
  #Preview("Doubts") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.doubts), narrative: PreviewFixtures.narrative
    ) { _, _ in }
  }
  #Preview("Nothing recognized") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.nothingRecognized), narrative: PreviewFixtures.narrative
    ) { _, _ in }
  }
  #Preview("Rename everywhere alert") {
    let state = PreviewFixtures.reviewState(.connected)
    ReviewScreen(
      initial: state, narrative: PreviewFixtures.narrative,
      renaming: PreviewFixtures.itemID(named: "la abuela Carmen", in: state)
    ) { _, _ in }
  }
  #Preview("Connected, dark") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.connected), narrative: PreviewFixtures.narrative
    ) { _, _ in }
    .preferredColorScheme(.dark)
  }
  #Preview("Doubts, AX5") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.doubts), narrative: PreviewFixtures.narrative
    ) { _, _ in }
    .dynamicTypeSize(.accessibility5)
  }
  #Preview("Doubts, Spanish") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.doubts), narrative: PreviewFixtures.narrative
    ) { _, _ in }
    .environment(\.locale, Locale(identifier: "es"))
  }
  #Preview("Beginning, Spanish") {
    ReviewScreen(
      initial: PreviewFixtures.reviewState(.beginning), narrative: PreviewFixtures.narrative
    ) { _, _ in }
    .environment(\.locale, Locale(identifier: "es"))
  }
#endif
