import SwiftUI

// contrato 7: pantalla provisional, se sustituye en F4/F5
struct ProvisionalScreen: View {
    private let swatches: [(name: String, color: Color)] = [
        ("fondo", .fondo),
        ("superficie-tarjeta", .superficieTarjeta),
        ("superficie-hundida", .superficieHundida),
        ("superficie-generada", .superficieGenerada),
        ("texto-primario", .textoPrimario),
        ("texto-secundario", .textoSecundario),
        ("texto-deshabilitado", .textoDeshabilitado),
        ("acento-hilo", .acentoHilo),
        ("texto-sobre-acento", .textoSobreAcento),
        ("tipo-persona", .tipoPersona),
        ("tipo-lugar", .tipoLugar),
        ("tipo-objeto", .tipoObjeto),
        ("estado-exito", .estadoExito),
        ("estado-aviso", .estadoAviso),
        ("estado-error", .estadoError),
        ("separador", .separador),
    ]

    private let columns = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "hammer")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                Text("Hilo")
                    .font(.title)
                Text("Provisional screen — replaced in F4/F5")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                // contrato 3: la cuadricula demuestra que los 16 tokens se resuelven
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(swatches, id: \.name) { swatch in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(swatch.color)
                                .frame(width: 60, height: 60)
                            Text(swatch.name)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ProvisionalScreen()
}
