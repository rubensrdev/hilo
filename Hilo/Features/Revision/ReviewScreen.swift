import SwiftUI

// contrato 2: S3 Revision, cuatro bloques (cada uno solo si tiene contenido) — la vista solo
// lee ReviewState y emite intencion, cada accion llama directo a un metodo ya probado (F4.1)
struct ReviewScreen: View {
  @State private var reviewState: ReviewState
  @State private var dateText: String
  let narrative: String
  let onSave: (ReviewState, String) -> Void
  @Environment(\.dismiss) private var dismiss

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

  init(initial: ReviewState, narrative: String, onSave: @escaping (ReviewState, String) -> Void) {
    _reviewState = State(initialValue: initial)
    _dateText = State(initialValue: initial.extractedDateText ?? "")
    self.narrative = narrative
    self.onSave = onSave
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.espacio5) {
          narrativeSection

          if reviewState.blocks.understood.isEmpty && reviewState.blocks.known.isEmpty
            && reviewState.blocks.doubtful.isEmpty && !hasRemovedItems
          {
            nothingRecognizedSection
          } else {
            if !reviewState.blocks.understood.isEmpty || hasRemovedItems {
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
      Text(narrative)
        .relato()
    }
  }

  // MARK: sin nada reconocido — anexo DEC-46

  private var nothingRecognizedSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("No names this time")
        .tituloSeccion()
      Text(
        "Hilo didn't find named people, places or objects. It's still a memory, and it will be saved in your words."
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
    }
  }

  // MARK: bloque 1 — lo que ha entendido, agrupado por tipo, con quitar/deshacer (DEC-17)

  private struct UnderstoodRow: Identifiable {
    let id: ReviewItemID
    let name: String
    let type: ElementType
    let isRemoved: Bool
  }

  // invariante de esta vista: quitar solo se ofrece aqui, asi que todo item isRemoved viene
  // de este bloque — no hace falta reconstruir su categoria original para agruparlo
  private var understoodRows: [UnderstoodRow] {
    let active = reviewState.blocks.understood.map {
      UnderstoodRow(id: $0.id, name: $0.name, type: $0.type, isRemoved: false)
    }
    let removed = reviewState.items.filter(\.isRemoved).map {
      UnderstoodRow(id: $0.id, name: $0.currentName, type: $0.type, isRemoved: true)
    }
    return active + removed
  }

  private var hasRemovedItems: Bool {
    reviewState.items.contains(where: \.isRemoved)
  }

  private var understoodGroups: [(type: ElementType, rows: [UnderstoodRow])] {
    let grouped = Dictionary(grouping: understoodRows, by: \.type)
    return [ElementType.person, .place, .object].compactMap { type in
      guard let rows = grouped[type], !rows.isEmpty else { return nil }
      return (type, rows)
    }
  }

  @ViewBuilder
  private var understoodSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("What Hilo understood")
        .tituloSeccion()
      ForEach(understoodGroups, id: \.type) { group in
        VStack(alignment: .leading, spacing: Spacing.espacio2) {
          Label(group.type.pluralDisplayName, systemImage: group.type.symbolName)
            .foregroundStyle(group.type.color)
            .metadato()
          ForEach(group.rows) { row in
            understoodChip(row)
          }
        }
      }
    }
  }

  private func understoodChip(_ row: UnderstoodRow) -> some View {
    HStack(spacing: Spacing.espacio2) {
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
        .accessibilityLabel("\(row.name), \(row.type.displayName), removed from this memory")
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
        }
        .buttonStyle(.plain)
        .frame(minHeight: Spacing.objetivoToqueMinimo)
        .accessibilityLabel("\(row.name), \(row.type.displayName)")
        .accessibilityHint("Double tap to rename")
      }

      if row.isRemoved {
        Text("Removed from this memory")
          .metadato()
          .foregroundStyle(Color.textoSecundario)
        Button("Undo") { reviewState.restore(row.id) }
          .frame(minHeight: Spacing.objetivoToqueMinimo)
      } else {
        Button {
          reviewState.remove(row.id)
        } label: {
          Image(systemName: "xmark")
            .frame(minWidth: Spacing.objetivoToqueMinimo, minHeight: Spacing.objetivoToqueMinimo)
        }
        .accessibilityLabel("Remove \(row.name)")
      }
    }
    .padding(.horizontal, Spacing.espacio3)
    .padding(.vertical, Spacing.espacio2)
    .background(Color.superficieHundida, in: Capsule())
  }

  // MARK: bloque 2 — ya conocia, reconocimiento rechazable con un toque, sin dialogo (DEC-22)

  @ViewBuilder
  private var knownSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("Already in your memory")
        .tituloSeccion()
      ForEach(reviewState.blocks.known) { known in
        knownRow(known)
      }
    }
  }

  private func knownRow(_ known: ReviewBlocks.Known) -> some View {
    HStack(alignment: .top, spacing: Spacing.espacio3) {
      Image(systemName: known.type.symbolName)
        .foregroundStyle(known.type.color)
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Button {
          startRenaming(
            itemID: known.id, currentName: known.name,
            otherMemoriesCount: known.otherMemoriesCount)
        } label: {
          Text(known.name)
            .nombreElemento()
            .foregroundStyle(Color.textoPrimario)
        }
        .buttonStyle(.plain)
        .frame(minHeight: Spacing.objetivoToqueMinimo, alignment: .leading)
        .accessibilityLabel("\(known.name), \(known.type.displayName)")
        .accessibilityHint("Double tap to rename")
        Text("\(known.type.displayName) · in \(known.otherMemoriesCount) memories")
          .metadato()
          .foregroundStyle(Color.textoSecundario)
      }
      Spacer()
      Button {
        reviewState.rejectRecognition(known.id)
      } label: {
        Text("Not the same \(known.name)")
          .metadato()
      }
      .frame(minHeight: Spacing.objetivoToqueMinimo)
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
    let candidate: ReviewBlocks.Doubtful.Candidate
  }

  // una tarjeta por candidato: si un item tiene mas de uno (identityDoubt raro con varias
  // coincidencias), se apilan varias preguntas binarias en vez de una sola con N respuestas
  private var doubtCards: [DoubtCard] {
    reviewState.blocks.doubtful.flatMap { item in
      item.candidates.map { candidate in
        DoubtCard(
          id: "\(item.id.value)-\(candidate.id.value)", itemID: item.id, itemName: item.name,
          candidate: candidate)
      }
    }
  }

  @ViewBuilder
  private var doubtfulSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Text("Hilo is not sure")
        .tituloSeccion()
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
      HStack(spacing: Spacing.espacio2) {
        Button {
          reviewState.confirmDoubt(card.itemID, as: card.candidate.id)
        } label: {
          Text("Same \(card.candidate.name)")
            .botonSecundario()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: Spacing.objetivoToqueMinimo)

        Button {
          reviewState.rejectDoubt(card.itemID)
        } label: {
          Text("Someone else")
            .botonSecundario()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: Spacing.objetivoToqueMinimo)
      }
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
  }

  // MARK: sin conexiones — el comienzo, nunca un fallo (anexo DEC-46)

  private var beginningSection: some View {
    let names = reviewState.blocks.understood.map(\.name)
    return VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("These are the first threads")
        .tituloSeccion()
      Text(Self.beginningBody(names: names))
        .metadato()
        .foregroundStyle(Color.textoSecundario)
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
  }

  // los nombres van tal como el usuario los confirmo, sin traducir (anexo DEC-46);
  // solo la union de la lista se localiza (ListFormatter, nunca comas a mano)
  private static func beginningBody(names: [String]) -> String {
    let joined = ListFormatter.localizedString(byJoining: names)
    if names.count == 1 {
      return String(
        localized:
          "This is the first time \(joined) appears. The next memory that mentions \(joined) will connect to this one."
      )
    }
    return String(
      localized:
        "This is the first time \(joined) appear. The next memory that shares any of them will connect to this one."
    )
  }

  // MARK: bloque 4 — la fecha, editable como texto, nunca reanalizada (contrato 2)

  private var dateSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("Date")
        .tituloSeccion()
      TextField("Add a date in your words", text: $dateText)
        .fechaUsuario()
        .padding(Spacing.espacio2)
        .background(Color.superficieHundida)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
        .accessibilityLabel("Date")
    }
  }

  // MARK: guardar — siempre disponible, ninguna duda lo bloquea (contrato 2)

  private var saveButton: some View {
    Button {
      onSave(reviewState, dateText)
      dismiss()
    } label: {
      Text("Save memory")
        .botonPrincipal()
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.acentoHilo)
    .foregroundStyle(Color.textoSobreAcento)
    .frame(minHeight: Spacing.objetivoToqueMinimo)
  }
}
