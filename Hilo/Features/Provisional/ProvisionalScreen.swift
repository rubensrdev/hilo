import SwiftUI

// contrato 7: pantalla provisional, se sustituye en F4/F5
struct ProvisionalScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer")
                .imageScale(.large)
                .foregroundStyle(.secondary)
            Text("Hilo")
                .font(.title)
            Text("Provisional screen — replaced in F4/F5")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ProvisionalScreen()
}
