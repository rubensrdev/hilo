import PhotosUI
import SwiftUI

// contrato 1: S2 Captura, cinco estados — la vista solo lee CaptureState y emite intencion
struct CaptureScreen: View {
  @Bindable var state: CaptureState
  @State private var photosPickerItem: PhotosPickerItem?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.locale) private var environmentLocale
  @Environment(\.displayScale) private var displayScale

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
      // en la barra: con un relato largo siempre esta a la vista, y las fichas no lo desplazan
      .toolbar {
        if state.phase == .comprehending {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { state.cancel() }
              .accessibilityHint("Stops reading. Your text and photo stay here.")
              .accessibilityIdentifier("capture.cancel")
          }
        }
      }
    }
    .onDisappear { state.cancel() }
    // bloqueante y con tono de error: aqui no hay ningun recuerdo guardado detras
    .alert(
      "Your memory couldn't be saved",
      isPresented: Binding(
        get: { state.saveWithoutAnalyzingFailed },
        set: { isPresented in if !isPresented { state.acknowledgeSaveFailure() } })
    ) {
      Button("OK") {}
    } message: {
      Text("Nothing has been saved. Your text and photo are still here — you can try again.")
    }
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
        .accessibilityIdentifier("capture.narrative")
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
    if let photoData = state.photoData,
      let thumbnail = PhotoThumbnail.image(
        from: photoData, maxPixelSize: Int((120 * Spacing.proporcionFotoTarjeta * displayScale).rounded(.up)))
    {
      HStack(alignment: .top, spacing: Spacing.espacio3) {
        // el hueco fija el tamaño visible; la foto lo llena sin desbordar el marco de VoiceOver
        Color.clear
          .aspectRatio(Spacing.proporcionFotoTarjeta, contentMode: .fit)
          .frame(height: 120)
          .overlay {
            Image(decorative: thumbnail, scale: displayScale)
              .resizable()
              .scaledToFill()
          }
          .clipShape(RoundedRectangle(cornerRadius: Spacing.radioFoto, style: .continuous))
          // no es decorativa: el usuario tiene que saber que hay foto
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Attached photo")
          .accessibilityAddTraits(.isImage)
          .accessibilityIdentifier("capture.photo")
        Spacer()
        Button {
          state.photoData = nil
          photosPickerItem = nil
        } label: {
          Image(systemName: "xmark")
            .frame(minWidth: Spacing.objetivoToqueMinimo, minHeight: Spacing.objetivoToqueMinimo)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Remove photo")
        .accessibilityIdentifier("capture.removePhoto")
        .disabled(state.phase != .capturing)
      }
    } else {
      PhotosPicker(selection: $photosPickerItem, matching: .images) {
        AddPhotoLabel()
      }
      .accessibilityIdentifier("capture.addPhoto")
      .disabled(state.phase != .capturing)
    }
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
      reduceMotion ? Motion.aparicionElementoReducida : Motion.aparicionElemento,
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
        .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.acentoHilo)
    .foregroundStyle(Color.textoSobreAcento)
    .disabled(!state.canUnderstand)
    .accessibilityIdentifier("capture.understand")

    Button {
      Task { await state.saveWithoutAnalyzing() }
    } label: {
      Text("Save without analyzing")
        .botonSecundario()
        .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
        .contentShape(Rectangle())
    }
    .disabled(!state.canSaveWithoutAnalyzing)
    .accessibilityHint("Saves your words without looking for people, places or objects")
    .accessibilityIdentifier("capture.saveWithoutAnalyzing")
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
        .accessibilityHidden(true)
    }
    .padding(Spacing.espacio3)
    .background(Color.superficieHundida)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("capture.comprehensionNotice")

    switch notice.actions {
    case .retryOrLeave:
      Button {
        state.retry()
      } label: {
        Text("Try reading it again")
          .botonPrincipal()
          .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.acentoHilo)
      .foregroundStyle(Color.textoSobreAcento)
      .accessibilityIdentifier("capture.retry")

      acknowledgeButton("Leave it as it is")
    case .done:
      acknowledgeButton("Done")
    }
  }

  // DEC-18: el recuerdo ya esta guardado, estos botones solo vacian la captura
  private func acknowledgeButton(_ title: LocalizedStringKey) -> some View {
    Button {
      state.acknowledgeNotAnalyzed()
    } label: {
      Text(title)
        .botonSecundario()
        .frame(maxWidth: .infinity, minHeight: Spacing.objetivoToqueMinimo)
        .contentShape(Rectangle())
    }
    .accessibilityHint("Clears the form to tell another memory")
    .accessibilityIdentifier("capture.acknowledge")
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
    .accessibilityIdentifier("capture.notice")
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

// nonisolated: el label de PhotosPicker se construye fuera del main actor; su body si corre en el
private nonisolated struct AddPhotoLabel: View {
  var body: some View {
    Label("Add a photo", systemImage: "photo")
      .botonSecundario()
      .frame(minHeight: Spacing.objetivoToqueMinimo, alignment: .leading)
      .contentShape(Rectangle())
  }
}

#if DEBUG
  #Preview("Empty", traits: .modifier(CaptureScenarios(.empty))) { CapturePreviewScreen() }
  #Preview("Writing", traits: .modifier(CaptureScenarios(.writing))) { CapturePreviewScreen() }
  #Preview("With photo", traits: .modifier(CaptureScenarios(.withPhoto))) {
    CapturePreviewScreen()
  }
  #Preview("Comprehending", traits: .modifier(CaptureScenarios(.comprehending))) {
    CapturePreviewScreen()
  }
  #Preview("Not analyzed, retry", traits: .modifier(CaptureScenarios(.notAnalyzedRetryable))) {
    CapturePreviewScreen()
  }
  #Preview("Not analyzed, too long", traits: .modifier(CaptureScenarios(.notAnalyzedTooLong))) {
    CapturePreviewScreen()
  }
  #Preview("Review unavailable", traits: .modifier(CaptureScenarios(.reviewUnavailable))) {
    CapturePreviewScreen()
  }
  #Preview("Saved without analyzing", traits: .modifier(CaptureScenarios(.savedWithoutAnalyzing))) {
    CapturePreviewScreen()
  }
  #Preview("Save failed alert", traits: .modifier(CaptureScenarios(.saveFailed))) {
    CapturePreviewScreen()
  }
  #Preview("Comprehending, dark", traits: .modifier(CaptureScenarios(.comprehending))) {
    CapturePreviewScreen().preferredColorScheme(.dark)
  }
  #Preview("With photo, AX5", traits: .modifier(CaptureScenarios(.withPhoto))) {
    CapturePreviewScreen().dynamicTypeSize(.accessibility5)
  }
  #Preview(
    "Not analyzed, Spanish",
    traits: .modifier(CaptureScenarios(.notAnalyzedRetryable, locale: Locale(identifier: "es")))
  ) { CapturePreviewScreen() }
  #Preview(
    "Review unavailable, Spanish",
    traits: .modifier(CaptureScenarios(.reviewUnavailable, locale: Locale(identifier: "es")))
  ) { CapturePreviewScreen() }
#endif
