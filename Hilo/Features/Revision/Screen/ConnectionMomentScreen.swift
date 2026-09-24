import SwiftUI

// contrato 5: el recuerdo ya guardado y sus conexiones formandose, cada una con su motivo
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
      // tokens §5: el anuncio no cambia con Reducir movimiento, solo el trazo
      AccessibilityNotification.Announcement(
        ReviewCopy.momentAnnouncement(connectedCount: moment.rows.count, locale: interfaceLocale)
      ).post()
      withAnimation(reduceMotion ? Motion.conexionReducida : Motion.conexion) {
        isFormed = true
      }
    }
  }

  // P1: el color semantico va en el simbolo, nunca en el texto
  private var savedLabel: some View {
    Label {
      Text("Memory saved")
        .metadato()
    } icon: {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Color.estadoExito)
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
        // con Reducir movimiento el trazo ya esta completo: solo funde el conjunto
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
      .opacity(reduceMotion && !isFormed ? 0 : 1)
    }
  }

  private func connectedRow(_ row: ConnectionMoment.Row) -> some View {
    VStack(alignment: .leading, spacing: Spacing.espacio1) {
      Text(row.narrative)
        .relatoExtracto()
        .lineLimit(2)
      // regla 4 del diseño: una conexion siempre ensena su motivo; los nombres, sin traducir
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

  // «Done» no es acento: la accion ya ha ocurrido
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
    // el relleno de .bordered es translucido: sin fondo opaco se leia el motivo de debajo
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
