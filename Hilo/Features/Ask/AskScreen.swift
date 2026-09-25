import SwiftUI

/// The tab exists and responds to taps; its content is not built yet.
struct AskScreen: View {
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
  #Preview("Empty") { AskScreen() }
  #Preview("AX5") { AskScreen().dynamicTypeSize(.accessibility5) }
#endif
