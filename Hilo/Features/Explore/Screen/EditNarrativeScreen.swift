import SwiftUI

/// Editing the text never re-analyses and leaves date, photo and appearances alone, so this is
/// a minimal editor of its own, not the review.
struct EditNarrativeScreen: View {
  @State private var draft: String
  @Environment(\.dismiss) private var dismiss
  let onSave: (String) async -> Void

  init(narrative: String, onSave: @escaping (String) async -> Void) {
    _draft = State(initialValue: narrative)
    self.onSave = onSave
  }

  private var canSave: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      TextEditor(text: $draft)
        .relato()
        .padding(Spacing.espacio2)
        .background(Color.superficieHundida)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous))
        .padding(Spacing.margenPantalla)
        .accessibilityLabel("Your memory")
        .accessibilityIdentifier("detail.editNarrative")
        .navigationTitle("Edit memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
              .accessibilityIdentifier("detail.editCancel")
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              Task {
                await onSave(draft)
                dismiss()
              }
            }
            .disabled(!canSave)
            .accessibilityIdentifier("detail.editSave")
          }
        }
    }
  }
}

#if DEBUG
  #Preview {
    EditNarrativeScreen(narrative: PreviewFixtures.narrative) { _ in }
  }
  #Preview("AX5") {
    EditNarrativeScreen(narrative: PreviewFixtures.narrative) { _ in }
      .dynamicTypeSize(.accessibility5)
  }
#endif
