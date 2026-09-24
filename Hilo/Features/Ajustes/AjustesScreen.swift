import SwiftUI

// contrato 1 + DEC-59: el acceso existe y es tocable, con un estado minimo — nunca un crash ni un no-op silencioso
struct AjustesScreen: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ContentUnavailableView(
        "Settings are coming soon",
        systemImage: "gearshape",
        description: Text("Language and accessibility options will live here.")
      )
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
            .accessibilityIdentifier("settings.close")
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Empty") { AjustesScreen() }
  #Preview("AX5") { AjustesScreen().dynamicTypeSize(.accessibility5) }
#endif
