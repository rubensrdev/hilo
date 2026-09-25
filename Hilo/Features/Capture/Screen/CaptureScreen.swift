import PhotosUI
import SwiftUI

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
      // There is always background under the glass bar.
      .background(Color.fondo)
      .navigationTitle("Tell a memory")
      .navigationBarTitleDisplayMode(.inline)
      // In the bar, so it stays in view with a long narrative and the chips never push it away.
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
    // Blocking and error-toned: no memory has been saved behind it.
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
      guard let newValue else { return }
      state.loadPhoto { try? await newValue.loadTransferable(type: Data.self) }
    }
    // Once the capture is cleared, the same photo must be selectable again.
    .onChange(of: state.photoData) { _, newValue in
      if newValue == nil { photosPickerItem = nil }
    }
    // The same announcement with or without Reduce Motion; only the animation changes.
    .onChange(of: state.extractedSoFar?.elements.map(\.name) ?? []) { previousNames, _ in
      guard
        let announcement = CaptureCopy.elementsAppeared(
          state.extractedSoFar?.elements ?? [], after: previousNames, locale: interfaceLocale)
      else { return }
      AccessibilityNotification.Announcement(announcement).post()
    }
    .onChange(of: state.notice) { _, newNotice in
      guard let newNotice else { return }
      AccessibilityNotification.Announcement(
        CaptureCopy.notice(newNotice, locale: interfaceLocale)
      ).post()
    }
    .announcesComprehension(
      isReading: state.phase == .comprehending, failure: state.phase.notAnalyzedReason)
  }

  // MARK: capturing (empty, typing, with a photo, comprehending)

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
        .frame(minHeight: Spacing.altoMinimoCampoCaptura)
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

  /// Decoded at display size: the long side is the width of the 3:2 thumbnail.
  private var thumbnailPixelSize: Int {
    Int((Spacing.altoFotoCaptura * Spacing.proporcionFotoTarjeta * displayScale).rounded(.up))
  }

  @ViewBuilder
  private var photoSection: some View {
    if let photoData = state.photoData,
      let thumbnail = PhotoThumbnail.image(from: photoData, maxPixelSize: thumbnailPixelSize)
    {
      HStack(alignment: .top, spacing: Spacing.espacio3) {
        // The spacer fixes the visible size; the photo fills it without overflowing the VoiceOver frame.
        Color.clear
          .aspectRatio(Spacing.proporcionFotoTarjeta, contentMode: .fit)
          .frame(height: Spacing.altoFotoCaptura)
          .overlay {
            Image(decorative: thumbnail, scale: displayScale)
              .resizable()
              .scaledToFill()
          }
          .clipShape(RoundedRectangle(cornerRadius: Spacing.radioFoto, style: .continuous))
          // Not decorative: the user needs to know there is a photo.
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Attached photo")
          .accessibilityAddTraits(.isImage)
          .accessibilityIdentifier("capture.photo")
        Spacer()
        Button {
          state.removePhoto()
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

  // MARK: comprehending

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
      // Colour, symbol and text travel together, also while reading.
      ViewThatFits(in: .horizontal) {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.espacio2) { chipTexts(element) }
        VStack(alignment: .leading, spacing: Spacing.espacio1) { chipTexts(element) }
      }
    } icon: {
      Image(systemName: ElementType(element.type).symbolName)
        .foregroundStyle(ElementType(element.type).color)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      CaptureCopy.elementAppeared(
        name: element.name, type: ElementType(element.type), locale: interfaceLocale)
    )
    .transition(.opacity)
  }

  @ViewBuilder
  private func chipTexts(_ element: ExtractedElement) -> some View {
    Text(element.name)
      .chipElemento()
      .foregroundStyle(Color.textoPrimario)
    Text(ElementType(element.type).localizedName(locale: interfaceLocale))
      .metadato()
      .foregroundStyle(Color.textoSecundario)
  }

  // MARK: actions — "save without analyzing" is always visible

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

  // MARK: comprehension error

  @ViewBuilder
  private func errorState(_ reason: MemoryComprehensionReason) -> some View {
    let notice = ComprehensionCopy.notice(reason, locale: interfaceLocale)
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
    .frame(maxWidth: .infinity, alignment: .leading)
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

  /// The memory is already saved; these buttons only clear the capture.
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

  // MARK: review notice and save confirmation

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

  // MARK: helpers

  /// The hint teaches with a real example memory, never with an instruction.
  private static func placeholder(locale: Locale) -> String {
    ExampleMemoryContent.seeds(for: ExampleMemoryLanguage(interfaceLocale: locale)).first?
      .narrative ?? ""
  }
}

/// PhotosPicker builds its label off the main actor; the body still runs on it.
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
