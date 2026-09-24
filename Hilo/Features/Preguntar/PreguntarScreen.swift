import SwiftUI

// F5 alcance + DEC-59: la pestaña existe y es tocable; su contenido real es de F6
struct PreguntarScreen: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView(
        "Ask is coming soon",
        systemImage: "text.magnifyingglass",
        description: Text("You'll be able to ask about your memories here.")
      )
      .navigationTitle("Ask")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#if DEBUG
  #Preview("Empty") { PreguntarScreen() }
  #Preview("AX5") { PreguntarScreen().dynamicTypeSize(.accessibility5) }
#endif
