import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "waveform")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Spike en marcha")
    }
    .padding()
    .task {
      await F023Runner().run()
    }
  }
}

#Preview {
  ContentView()
}
