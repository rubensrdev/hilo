//
//  ContentView.swift
//  HiloSpike
//
//  Created by Rubén Segura Romo on 20/09/2026.
//

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
