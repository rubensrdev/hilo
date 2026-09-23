import PhotosUI
import SwiftUI

// contrato 1: S2 Captura, cinco estados — la vista solo lee CaptureState y emite intencion
struct CaptureScreen: View {
  @Bindable var state: CaptureState
  @State private var photosPickerItem: PhotosPickerItem?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.espacio4) {
          switch state.phase {
          case .capturing, .comprehending, .reviewing, .savingWithoutAnalyzing:
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
    .onChange(of: state.extractedSoFar?.elements.count) { _, _ in
      guard let element = state.extractedSoFar?.elements.last else { return }
      AccessibilityNotification.Announcement(
        "\(element.name), \(ElementType(element.type).displayName)"
      ).post()
    }
    .onChange(of: state.phase) { _, newPhase in
      guard case .notAnalyzed = newPhase else { return }
      AccessibilityNotification.Announcement(Self.errorTitle).post()
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
        Text(Self.placeholder)
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
    .accessibilityLabel("\(element.name), \(ElementType(element.type).displayName)")
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

  private static let errorTitle = "Your memory is saved just as you told it"

  @ViewBuilder
  private func errorState(_ reason: MemoryComprehensionReason) -> some View {
    Label {
      VStack(alignment: .leading, spacing: Spacing.espacio1) {
        Text(Self.errorTitle)
          .tituloSeccion()
        Text(Self.errorBody(reason))
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

    // "Leave it as it is"/"Done" solo reconocen el aviso: el texto ya esta a salvo.
    // Su salida de esta pantalla es de F5 (aun no hay lista a la que volver).
    if state.canRetry {
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

      Button("Leave it as it is") {}
        .frame(minHeight: Spacing.objetivoToqueMinimo)
    } else {
      Button("Done") {}
        .frame(minHeight: Spacing.objetivoToqueMinimo)
    }
  }

  private static func errorBody(_ reason: MemoryComprehensionReason) -> String {
    switch reason {
    case .generic, .guardrail:
      "Hilo couldn't read it this time. It's saved without people, places or objects — you can try again now, or later from the memory."
    case .contextOverflow:
      "This memory is too long for Hilo to read in one go. It's saved without people, places or objects. If you shorten it, you can ask Hilo to read it from the memory."
    case .unsupportedLanguage:
      "Hilo can't read memories in this language. It's saved without people, places or objects."
    }
  }

  // MARK: ayudas — placeholder de contrato 1 (simbolo/color/nombre por tipo: DesignSystem)

  // contrato 1: el texto de ayuda enseña con un recuerdo de ejemplo real, nunca una instruccion
  private static var placeholder: String {
    let language: ExampleMemoryLanguage =
      Locale.current.language.languageCode?.identifier == "es" ? .spanish : .english
    return ExampleMemoryContent.seeds(for: language).first?.narrative ?? ""
  }
}
