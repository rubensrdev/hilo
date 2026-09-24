#if DEBUG
  import Foundation

  // F5: dos recuerdos deterministas que completan la memoria de ejemplo para la bateria de
  // docs/validacion-manual — colision de nombre al renombrar (Martina -> Marta), una coincidencia
  // de busqueda que solo viene del elemento (Marta nunca se nombra en su relato) y un extracto que
  // tiene que centrarse (DEC-20). Nunca compilado en Release, nunca mostrado como contenido real.
  nonisolated enum DebugValidationContent {
    static let seeds: [ExampleMemorySeed] = [
      ExampleMemorySeed(
        narrative:
          "Fuimos a merendar al parque con ella una tarde de domingo, ya de vuelta del colegio.",
        dateText: "por 1990", deducedYear: 1990,
        appearances: [
          ExampleAppearanceSeed(displayName: "Marta", type: .person, role: nil),
          ExampleAppearanceSeed(displayName: "el parque", type: .place, role: nil),
        ]),
      ExampleMemorySeed(
        narrative:
          "Aquel domingo decidimos madrugar mucho más de lo habitual porque queríamos aprovechar la mañana entera. Desayunamos rápido, guardamos las cosas en el coche y salimos hacia la sierra sin apenas hablar, todavía medio dormidos. Martina se empeñó en llevar la radio puesta todo el trayecto, cantando canciones que ni siquiera conocíamos bien. Cuando llegamos, sacamos la bicicleta vieja del maletero y la dejamos apoyada contra un árbol mientras preparábamos el picnic.",
        dateText: nil, deducedYear: nil,
        appearances: [
          ExampleAppearanceSeed(displayName: "Martina", type: .person, role: nil),
          ExampleAppearanceSeed(displayName: "la bicicleta vieja", type: .object, role: nil),
        ]),
    ]
  }
#endif
