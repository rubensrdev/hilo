import PhotosUI
import SwiftUI

// contrato 1: S2 Captura, cinco estados — la vista solo lee CaptureState y emite intencion
struct CaptureScreen: View {
  @Bindable var state: CaptureState
  @State private var photosPickerItem: PhotosPickerItem?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.espacio4) {
          if let notice = state.notice {
            noticeBanner(notice)
          }
          switch state.phase {
          case .capturing, .comprehending, .reviewing, .savingWithoutAnalyzing, .savingReview:
            captureForm
          case .notAnalyzed(let reason):
            errorState(reason)
          }
        }
        .padding(Spacing.margenPantalla)
      }
      .navigationTitle("Tell a memory")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onDisappear { state.cancel() }
    .onChange(of: photosPickerItem) { _, newValue in
      Task { state.photoData = try? await newValue?.loadTransferable(type: Data.self) }
    }
    // al vaciarse la captura, la misma foto debe poder elegirse otra vez
    .onChange(of: state.photoData) { _, newValue in
      if newValue == nil { photosPickerItem = nil }
    }
    // contrato 6: el mismo anuncio con o sin Reducir movimiento, solo cambia la animacion
    .onChange(of: state.extractedSoFar?.elements.count) { _, _ in
      guard let element = state.extractedSoFar?.elements.last else { return }
      AccessibilityNotification.Announcement(
        CaptureCopy.elementAppeared(
          name: element.name, type: ElementType(element.type), locale: interfaceLocale)
      ).post()
    }
    .onChange(of: state.notice) { _, newNotice in
      guard let newNotice else { return }
      AccessibilityNotification.Announcement(
        CaptureCopy.notice(newNotice, locale: interfaceLocale)
      ).post()
    }
    .onChange(of: state.phase) { _, newPhase in
      guard case .notAnalyzed(let reason) = newPhase else { return }
      AccessibilityNotification.Announcement(
        CaptureCopy.comprehensionNotice(reason, locale: interfaceLocale).announcement
      ).post()
    }
  }

  // MARK: capturando (vacio, escribiendo, con foto, comprendiendo)

  @ViewBuilder
  private var captureForm: some View {
    narrativeField
    photoSection
    if state.phase == .comprehending {
      comprehendingSection
    }
    actions
  }

  private var narrativeField: some View {
    ZStack(alignment: .topLeading) {
      TextEditor(text: $state.narrative)
        .relato()
        .scrollContentBackground(.hidden)
        .frame(minHeight: 160)
        .padding(Spacing.espacio2)
        .accessibilityLabel("Your memory")
      if state.narrative.isEmpty {
        Text(Self.placeholder(locale: interfaceLocale))
          .relato()
          .foregroundStyle(Color.textoDeshabilitado)
          .lineLimit(3)
          .padding(Spacing.espacio2)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
    }
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
    .disabled(state.phase != .capturing)
  }

  @ViewBuilder
  private var photoSection: some View {
    if let photoData = state.photoData, let uiImage = UIImage(data: photoData) {
      HStack(alignment: .top, spacing: Spacing.espacio3) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(3 / 2, contentMode: .fill)
          .frame(height: 120)
          .clipShape(RoundedRectangle(cornerRadius: Spacing.radioFoto, style: .continuous))
          .accessibilityHidden(true)
        Spacer()
        Button {
          state.photoData = nil
          photosPickerItem = nil
        } label: {
          Image(systemName: "xmark")
            .frame(minWidth: Spacing.objetivoToqueMinimo, minHeight: Spacing.objetivoToqueMinimo)
        }
        .accessibilityLabel("Remove photo")
        .disabled(state.phase != .capturing)
      }
    } else {
      PhotosPicker(selection: $photosPickerItem, matching: .images) {
        addPhotoLabel
      }
      .frame(minHeight: Spacing.objetivoToqueMinimo, alignment: .leading)
      .disabled(state.phase != .capturing)
    }
  }

  // nonisolated: el init de PhotosPicker es nonisolated y su label corre fuera del
  // main actor, asi que no puede leer state.botonSecundario() (MainActor); font(.body)
  // es el mismo valor que boton-secundario en tokens.md §2.2, aplicado aqui a mano
  private nonisolated var addPhotoLabel: some View {
    Label("Add a photo", systemImage: "photo")
      .font(.body)
  }

  // MARK: comprendiendo — mov-aparicion-elemento (tokens.md §5)

  @ViewBuilder
  private var comprehendingSection: some View {
    VStack(alignment: .leading, spacing: Spacing.espacio2) {
      Text("Reading your memory…")
        .metadato()
        .foregroundStyle(Color.textoSecundario)
      ForEach(Array((state.extractedSoFar?.elements ?? []).enumerated()), id: \.offset) {
        _, element in
        elementChip(element)
      }
    }
    .animation(
      reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 1),
      value: state.extractedSoFar?.elements.count)
  }

  private func elementChip(_ element: ExtractedElement) -> some View {
    Label {
      Text(element.name)
        .chipElemento()
        .foregroundStyle(Color.textoPrimario)
    } icon: {
      Image(systemName: ElementType(element.type).symbolName)
        .foregroundStyle(ElementType(element.type).color)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      CaptureCopy.elementAppeared(
        name: element.name, type: ElementType(element.type), locale: interfaceLocale))
    .transition(.opacity)
  }

  // MARK: acciones — contrato 1, "guardar sin analizar" siempre visible

  @ViewBuilder
  private var actions: some View {
    Button {
      state.understandAndSave()
    } label: {
      Text("Understand & save")
        .botonPrincipal()
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.acentoHilo)
    .foregroundStyle(Color.textoSobreAcento)
    .disabled(!state.canUnderstand)
    .frame(minHeight: Spacing.objetivoToqueMinimo)

    Button {
      Task { await state.saveWithoutAnalyzing() }
    } label: {
      Text("Save without analyzing")
        .botonSecundario()
        .frame(maxWidth: .infinity)
    }
    .disabled(!state.canSaveWithoutAnalyzing)
    .frame(minHeight: Spacing.objetivoToqueMinimo)
  }

  // MARK: error de comprension — DEC-43 (estado-aviso) + anexo DEC-46

  @ViewBuilder
  private func errorState(_ reason: MemoryComprehensionReason) -> some View {
    let notice = CaptureCopy.comprehensionNotice(reason, locale: interfaceLocale)
    Label {
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Text(notice.title)
          .tituloSeccion()
        Text(notice.body)
          .metadato()
      }
    } icon: {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(Color.estadoAviso)
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
    .accessibilityElement(children: .combine)

    switch notice.actions {
    case .retryOrLeave:
      Button {
        state.retry()
      } label: {
        Text("Try reading it again")
          .botonPrincipal()
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.acentoHilo)
      .foregroundStyle(Color.textoSobreAcento)
      .frame(minHeight: Spacing.objetivoToqueMinimo)

      Button("Leave it as it is") { state.acknowledgeNotAnalyzed() }
        .frame(minHeight: Spacing.objetivoToqueMinimo)
    case .done:
      Button("Done") { state.acknowledgeNotAnalyzed() }
        .frame(minHeight: Spacing.objetivoToqueMinimo)
    }
  }

  // MARK: aviso de la revision y confirmacion del guardado — punto 3 de F4.6

  private func noticeBanner(_ notice: ReviewNotice) -> some View {
    Label {
      Text(CaptureCopy.notice(notice, locale: interfaceLocale))
        .metadato()
        .foregroundStyle(Color.textoPrimario)
    } icon: {
      noticeSymbol(notice)
        .accessibilityHidden(true)
    }
    .padding(Spacing.espacio3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func noticeSymbol(_ notice: ReviewNotice) -> some View {
    switch notice {
    case .reviewUnavailable, .reviewNotSaved:
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(Color.estadoAviso)
    case .savedWithoutAnalyzing:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Color.estadoExito)
    }
  }

  // MARK: ayudas — placeholder de contrato 1 (simbolo/color/nombre por tipo: DesignSystem)

  // contrato 1: el texto de ayuda enseña con un recuerdo de ejemplo real, nunca una instruccion
  private static func placeholder(locale: Locale) -> String {
    let language: ExampleMemoryLanguage =
      locale.language.languageCode?.identifier == "es" ? .spanish : .english
    return ExampleMemoryContent.seeds(for: language).first?.narrative ?? ""
  }
}
