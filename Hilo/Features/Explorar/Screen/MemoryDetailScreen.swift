import SwiftUI

// contrato 4: S4 Detalle de recuerdo — foto si la hay, relato integro (nunca recorta), fecha
// del usuario, elementos, conectados con motivo (o el aviso que corresponda), editar y borrar
struct MemoryDetailScreen: View {
  @Bindable var state: MemoryDetailState
  // ReviewCoordinator.presentation necesita un Binding propio: reviewCoordinator es un `let`
  // en MemoryDetailState, asi que $state.reviewCoordinator.presentation no se puede formar
  @Bindable var reviewCoordinator: ReviewCoordinator
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var environmentLocale
  @Environment(\.displayScale) private var displayScale
  @State private var isEditPresented = false
  @State private var isDeleteConfirmationPresented = false

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  // proporcion original, sin recorte: se decodifica a un tamaño generoso, sin preguntar al
  // sistema el ancho de pantalla (ADR-000 §4: nunca UIKit)
  private var detailPhotoPixelSize: Int { Int(800 * displayScale) }

  var body: some View {
    Group {
      if let memory = state.memory {
        ScrollView {
          content(memory)
            .padding(Spacing.margenPantalla)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .background(Color.fondo)
    .navigationTitle("Memory")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      // .topBarTrailing: posicional, nunca colapsa en el "..." del sistema (leccion de F5.2)
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button {
            isEditPresented = true
          } label: {
            Text("Edit")
          }
          .accessibilityIdentifier("detail.edit")
          Button(role: .destructive) {
            isDeleteConfirmationPresented = true
          } label: {
            Text("Delete memory")
          }
          .accessibilityIdentifier("detail.delete")
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("More")
        .accessibilityIdentifier("detail.more")
      }
    }
    .task { await state.load() }
    .sheet(isPresented: $isEditPresented) {
      EditNarrativeScreen(narrative: state.memory?.narrative ?? "") { newText in
        _ = await state.editNarrative(newText)
      }
    }
    .sheet(
      item: $reviewCoordinator.presentation, onDismiss: state.understandLater.reviewDismissed
    ) { presentation in
      switch presentation.stage {
      case .review(let reviewState, let narrative):
        ReviewScreen(initial: reviewState, narrative: narrative) { reviewState, dateText in
          state.understandLater.reviewConfirmed(reviewState, dateTextAtSave: dateText)
        }
      case .connected(let moment):
        ConnectionMomentScreen(moment: moment)
      }
    }
    .alert(
      Text("Delete this memory?"), isPresented: $isDeleteConfirmationPresented
    ) {
      Button(role: .destructive) {
        Task {
          if await state.delete() { dismiss() }
        }
      } label: {
        Text("Delete memory")
      }
      Button(role: .cancel) {
      } label: {
        Text("Keep it")
      }
    } message: {
      Text(
        ExploreCopy.deleteConfirmationBody(
          surviving: state.deleteImpact.surviving.map(\.displayName),
          disappearing: state.deleteImpact.disappearing.map(\.displayName),
          locale: interfaceLocale))
    }
  }

  @ViewBuilder
  private func content(_ memory: Memory) -> some View {
    VStack(alignment: .leading, spacing: Spacing.separacionSecciones) {
      VStack(alignment: .leading, spacing: Spacing.espacio2) {
        photoSection
        Text(memory.narrative)
          .relato()
          .foregroundStyle(Color.textoPrimario)
          .accessibilityIdentifier("detail.narrative")
        if let dateText = memory.date?.text {
          Text(dateText)
            .fechaUsuario()
            .foregroundStyle(Color.textoSecundario)
        }
      }
      elementsSection
      if state.isAnalyzed {
        connectionsSection
      } else {
        notAnalyzedSection
      }
    }
  }

  @ViewBuilder
  private var photoSection: some View {
    if let photoData = state.photoData,
      let photo = PhotoThumbnail.image(from: photoData, maxPixelSize: detailPhotoPixelSize)
    {
      Image(decorative: photo, scale: displayScale)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radioFoto, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Attached photo")
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier("detail.photo")
    }
  }

  // MARK: elementos — sin recortar ni renombrar desde aqui (eso es Revision), no navegan todavia
  // (S5 no existe hasta F5.4 — mismo motivo que en F5.2 para la lista de elementos y las tarjetas)

  @ViewBuilder
  private var elementsSection: some View {
    if state.ownElements.isEmpty {
      Text("Hilo didn't recognize any people, places or objects in this memory.")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
        .accessibilityIdentifier("detail.noElements")
    } else {
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        ForEach(state.ownElements) { element in
          ElementChip(element: element)
        }
      }
    }
  }

  // MARK: conectados con motivo, o el aviso de que no lo esta todavia (contrato 4, DEC-16)

  @ViewBuilder
  private var connectionsSection: some View {
    if state.ownElements.isEmpty {
      EmptyView()
    } else if state.connectedRows.isEmpty {
      notConnectedYetSection
    } else {
      connectedSection
    }
  }

  private var notConnectedYetSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text("Not connected yet")
        .tituloSeccion()
        .foregroundStyle(Color.textoPrimario)
        .accessibilityAddTraits(.isHeader)
      Text(
        ConnectionCopy.firstAppearanceBody(
          names: state.ownElements.map(\.displayName), locale: interfaceLocale)
      )
      .metadato()
      .foregroundStyle(Color.textoSecundario)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.rellenoTarjeta)
    .background(Color.superficieTarjeta)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
    .accessibilityIdentifier("detail.notConnectedYet")
  }

  private var connectedSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      Label {
        Text("Connected with \(state.connectedRows.count) memories")
          .tituloSeccion()
          .foregroundStyle(Color.textoPrimario)
      } icon: {
        Image(systemName: "link")
          .foregroundStyle(Color.acentoHilo)
          .accessibilityHidden(true)
      }
      .accessibilityAddTraits(.isHeader)
      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(state.connectedRows.enumerated()), id: \.element.memoryID) { index, row in
          if index > 0 {
            Rectangle()
              .fill(Color.separador)
              .trazoSeparador()
          }
          NavigationLink(value: row.memoryID) {
            connectedRow(row)
          }
          .buttonStyle(.plain)
        }
      }
      .background(Color.superficieTarjeta)
      .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
    }
  }

  private func connectedRow(_ row: ConnectionMoment.Row) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text(row.narrative)
        .relatoExtracto()
        .lineLimit(2)
        .foregroundStyle(Color.textoPrimario)
      Label {
        Text(ConnectionCopy.connectionMotive(names: row.motiveNames, locale: interfaceLocale))
          .motivoConexion()
          .foregroundStyle(Color.textoSecundario)
      } icon: {
        Image(systemName: "link")
          .foregroundStyle(Color.acentoHilo)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.rellenoTarjeta)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      ConnectionCopy.connectionRowLabel(
        names: row.motiveNames, narrative: row.narrative, locale: interfaceLocale))
  }

  // MARK: guardado sin analizar — DEC-16: comprender mas tarde solo desde aqui

  private var notAnalyzedSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio3) {
      Label {
        VStack(alignment: .leading, spacing: Spacing.espacio1) {
          Text("Saved without analyzing")
            .tituloSeccion()
            .foregroundStyle(Color.textoPrimario)
          Text(
            "No people, places or objects yet, so this memory does not connect with the others."
          )
          .metadato()
          .foregroundStyle(Color.textoSecundario)
        }
      } icon: {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(Color.estadoAviso)
          .accessibilityHidden(true)
      }
      if case .notAnalyzed(let reason) = state.understandLater.phase {
        let notice = ComprehensionCopy.notice(reason, locale: interfaceLocale)
        Text(notice.body)
          .metadato()
          .foregroundStyle(Color.textoSecundario)
          .accessibilityIdentifier("detail.understandLaterFailed")
      }
      Button {
        Task { await state.understandLater.start(memoryID: state.memoryID) }
      } label: {
        Text("Let Hilo read this memory")
          .botonPrincipal()
          .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.acentoHilo)
      .foregroundStyle(Color.textoSobreAcento)
      .disabled(state.understandLater.phase == .comprehending)
      .accessibilityIdentifier("detail.understandLater")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.rellenoTarjeta)
    .background(Color.superficieTarjeta)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
  }
}

#if DEBUG
  #Preview("With photo", traits: .modifier(MemoryDetailScenarios(.withPhoto))) {
    MemoryDetailPreviewScreen()
  }
  #Preview("Without photo", traits: .modifier(MemoryDetailScenarios(.withoutPhoto))) {
    MemoryDetailPreviewScreen()
  }
  #Preview("Without connections", traits: .modifier(MemoryDetailScenarios(.withoutConnections))) {
    MemoryDetailPreviewScreen()
  }
  #Preview(
    "Without recognized elements",
    traits: .modifier(MemoryDetailScenarios(.withoutRecognizedElements))
  ) { MemoryDetailPreviewScreen() }
  #Preview("Saved without analyzing", traits: .modifier(MemoryDetailScenarios(.notAnalyzed))) {
    MemoryDetailPreviewScreen()
  }
  #Preview("AX5", traits: .modifier(MemoryDetailScenarios(.withPhoto))) {
    MemoryDetailPreviewScreen().dynamicTypeSize(.accessibility5)
  }
  #Preview(
    "Spanish",
    traits: .modifier(MemoryDetailScenarios(.withPhoto, locale: Locale(identifier: "es")))
  ) { MemoryDetailPreviewScreen() }
#endif
