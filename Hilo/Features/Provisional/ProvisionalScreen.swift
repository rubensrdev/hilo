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

    // sin token para el tamano de esta cuadricula de depuracion: no es producto
    // y se borra entera en F4/F5 (contrato 7), tokens.md no cubre cajas de icono
    private let columns = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.espacio4) {
                Image(systemName: "hammer")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                Text("Hilo")
                    .tituloSeccion()
                Text("Provisional screen — replaced in F4/F5")
                    .metadato()
                    .foregroundStyle(.secondary)

                // contrato 3: la cuadricula demuestra que los 16 tokens se resuelven
                LazyVGrid(columns: columns, spacing: Spacing.espacio3) {
                    ForEach(swatches, id: \.name) { swatch in
                        VStack(spacing: Spacing.espacio1) {
                            RoundedRectangle(cornerRadius: Spacing.radioCampo, style: .continuous)
                                .fill(swatch.color)
                                .frame(width: 60, height: 60)
                            Text(swatch.name)
                                .metadato()
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
