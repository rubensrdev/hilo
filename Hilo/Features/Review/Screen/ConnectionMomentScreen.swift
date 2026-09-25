import SwiftUI

struct ConnectionMomentScreen: View {
  let moment: ConnectionMoment
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }
  @State private var isFormed = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.separacionSecciones) {
          savedLabel
          memoryCard
          connectionsSection
        }
        .padding(Spacing.margenPantalla)
      }
      .background(Color.fondo)
      .safeAreaInset(edge: .bottom) { doneButton }
    }
    .onAppear {
      // The announcement doesn't change with Reduce Motion; only the stroke does.
      AccessibilityNotification.Announcement(
        ReviewCopy.momentAnnouncement(connectedCount: moment.rows.count, locale: interfaceLocale)
      ).post()
      withAnimation(reduceMotion ? Motion.conexionReducida : Motion.conexion) {
        isFormed = true
      }
    }
  }

  /// The semantic colour goes on the symbol, never on the text.
  private var savedLabel: some View {
    Label {
      Text("Memory saved")
        .metadato()
    } icon: {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Color.estadoExito)
        .accessibilityHidden(true)
    }
  }

  private var memoryCard: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      Text(moment.narrative)
        .relato()
      if let dateText = moment.dateText {
        Text(dateText)
          .fechaUsuario()
          .foregroundStyle(Color.textoSecundario)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.rellenoTarjeta)
    .background(Color.superficieTarjeta)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
    .contornoTarjeta()
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("moment.memory")
  }

  private var connectionsSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      Label {
        Text("Connected with \(moment.rows.count) memories")
          .tituloSeccion()
      } icon: {
        Image(systemName: "link")
          .foregroundStyle(Color.acentoHilo)
          .accessibilityHidden(true)
      }
      .accessibilityAddTraits(.isHeader)

      HStack(spacing: 0) {
        // With Reduce Motion the stroke is already complete: only the group fades in.
        Rectangle()
          .fill(Color.acentoHilo)
          .frame(width: Spacing.trazoConexion)
          .scaleEffect(y: isFormed || reduceMotion ? 1 : 0, anchor: .top)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(moment.rows.enumerated()), id: \.element.memoryID) { index, row in
            if index > 0 {
              Rectangle()
                .fill(Color.separador)
                .trazoSeparador()
            }
            connectedRow(row)
          }
        }
        .opacity(isFormed ? 1 : 0)
      }
      .background(Color.superficieTarjeta)
      .clipShape(RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous))
      .contornoTarjeta()
      .opacity(reduceMotion && !isFormed ? 0 : 1)
    }
  }

  private func connectedRow(_ row: ConnectionMoment.Row) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text(row.narrative)
        .relatoExtracto()
        .lineLimit(2)
      // A connection always shows its motive; the names are never translated.
      Label {
        Text(
          ConnectionCopy.connectionMotive(
            names: row.motiveNames, locale: interfaceLocale)
        )
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

  /// "Done" is not the accent: the action has already happened.
  private var doneButton: some View {
    Button {
      dismiss()
    } label: {
      Text("Done")
        .botonSecundario()
        .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
    }
    .buttonStyle(.bordered)
    .accessibilityIdentifier("moment.done")
    .padding(.horizontal, Spacing.margenPantalla)
    .padding(.vertical, Spacing.espacio2)
    // .bordered fills are translucent: without an opaque background the motive showed through.
    .background(Color.fondo)
  }
}

#if DEBUG
  #Preview("One connection") {
    if let moment = PreviewFixtures.connectionMoment(connectedCount: 1) {
      ConnectionMomentScreen(moment: moment)
    }
  }
  #Preview("Several connections") {
    if let moment = PreviewFixtures.connectionMoment(connectedCount: 2) {
      ConnectionMomentScreen(moment: moment)
    }
  }
  #Preview("Several connections, dark") {
    if let moment = PreviewFixtures.connectionMoment(connectedCount: 2) {
      ConnectionMomentScreen(moment: moment).preferredColorScheme(.dark)
    }
  }
  #Preview("Several connections, AX5") {
    if let moment = PreviewFixtures.connectionMoment(connectedCount: 2) {
      ConnectionMomentScreen(moment: moment).dynamicTypeSize(.accessibility5)
    }
  }
  #Preview("Several connections, Spanish") {
    if let moment = PreviewFixtures.connectionMoment(connectedCount: 2) {
      ConnectionMomentScreen(moment: moment).environment(\.locale, Locale(identifier: "es"))
    }
  }
#endif
