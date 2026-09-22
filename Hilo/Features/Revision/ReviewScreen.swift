import SwiftUI

// contrato 2: S3 Revision, cuatro bloques (cada uno solo si tiene contenido) — la vista solo
// lee ReviewState y emite intencion, cada accion llama directo a un metodo ya probado (F4.1)
struct ReviewScreen: View {
  @State private var reviewState: ReviewState
  @State private var dateText: String
  let narrative: String
  let onSave: (ReviewState, String) -> Void
  @Environment(\.dismiss) private var dismiss

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
      Label {
        Text(row.name)
          .chipElemento()
          .foregroundStyle(row.isRemoved ? Color.textoSecundario : Color.textoPrimario)
          .strikethrough(row.isRemoved)
      } icon: {
        Image(systemName: row.type.symbolName)
          .foregroundStyle(row.isRemoved ? Color.textoSecundario : row.type.color)
      }
      .accessibilityLabel(
        "\(row.name), \(row.type.displayName)\(row.isRemoved ? ", removed from this memory" : "")"
      )

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
        Text(known.name)
          .nombreElemento()
          .foregroundStyle(Color.textoPrimario)
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
