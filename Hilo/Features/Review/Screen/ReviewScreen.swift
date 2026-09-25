import SwiftUI

struct ReviewScreen: View {
  @State private var reviewState: ReviewState
  @State private var dateText: String
  let narrative: String
  let onSave: (ReviewState, String) -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var environmentLocale
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  // MARK: rename

  /// One system alert with a text field for any element; the scope notice only for one that already existed.
  private struct RenamePrompt {
    let itemID: ReviewItemID
    let currentName: String
    let otherMemoriesCount: Int?  // nil means new: no scope notice
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

  /// Each action replaces the focused view; without an explicit target VoiceOver jumps back to the top.
  private enum ReviewFocus: Hashable {
    case item(ReviewItemID)
    case removal(ReviewItemID)
  }
  @AccessibilityFocusState private var focused: ReviewFocus?

  /// renaming is only for previews, which open with the rename alert already up.
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
      // There is always background under the glass bar.
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

  // MARK: rename helpers — presentation only, ReviewState decides

  private var isRenamePromptPresented: Binding<Bool> {
    Binding(get: { renamePrompt != nil }, set: { if !$0 { renamePrompt = nil } })
  }

  private var isRenameConflictPresented: Binding<Bool> {
    Binding(get: { renameConflict != nil }, set: { if !$0 { renameConflict = nil } })
  }

  private var renameAlertTitle: Text {
    // Never seen: the alert only presents while renamePrompt is set.
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

  /// Names the conflict by its current visible name, the pending one if it has one.
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

  // MARK: narrative — never truncated, read as one block

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

  // MARK: nothing recognized

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

  // MARK: block 1 — what it understood, by type, with remove and undo

  @ViewBuilder
  private var understoodSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("What Hilo understood")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      ForEach(reviewState.blocks.understoodGroups, id: \.type) { group in
        VStack(alignment: .leading, spacing: Spacing.espacio2) {
          // The type's colour goes on the symbol; the footnote text stays texto-secundario.
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
    let layout = dynamicTypeSize.rowLayout(spacing: Spacing.espacio2)
    return layout {
      if row.isRemoved {
        // Removed: renaming isn't offered until it is undone.
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
        // The chip's label already says it: VoiceOver doesn't read it twice.
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

  /// Stacked, the capsule eats the text's corners, so it takes the card shape.
  private var chipShape: AnyShape {
    dynamicTypeSize.isAccessibilitySize
      ? AnyShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
      : AnyShape(Capsule())
  }

  // MARK: block 2 — already known, rejectable with one tap, no dialog

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
    // By baseline: the name grows to a 44 pt target and the symbol must stay level with it.
    let layout = dynamicTypeSize.rowLayout(alignment: .firstTextBaseline, spacing: Spacing.espacio3)
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
        // The name's label already says it: VoiceOver doesn't read it twice.
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

  // MARK: block 3 — identity doubt, two answers of equal weight, neither preselected

  private struct DoubtCard: Identifiable {
    let id: String
    let itemID: ReviewItemID
    let itemName: String
    let itemType: ElementType
    let candidate: ReviewBlocks.Doubtful.Candidate
  }

  /// One card per candidate: an item with several matches stacks binary questions instead of
  /// one question with N answers.
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
      // At accessibility sizes the two answers stack, with equal weight.
      let answersLayout = dynamicTypeSize.rowLayout(spacing: Spacing.espacio2)
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

  // MARK: no connections — the beginning, never a failure

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

  // MARK: block 4 — the date, editable as text, never re-analysed

  private var dateSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("Date")
        .tituloSeccion()
        .accessibilityAddTraits(.isHeader)
      // The date is the user's text: at AX5 it grows downwards instead of scrolling sideways.
      ZStack(alignment: .topLeading) {
        TextField(text: $dateText, axis: .vertical) { EmptyView() }
          .fechaUsuario()
          .focused($isDateFocused)
          .accessibilityLabel("Date")
          .accessibilityHint("Add a date in your words")
          .accessibilityIdentifier("review.date")
        // The system placeholder doesn't wrap, and was cut off at AX5.
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
      // The field is one line tall: the whole background focuses, so the tap target reaches 44 pt.
      .contentShape(Rectangle())
      .onTapGesture { isDateFocused = true }
    }
  }

  // MARK: save — always available, no doubt blocks it

  private var saveButton: some View {
    Button {
      // The sheet doesn't close here: it moves to the connection moment, or the coordinator closes it.
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
