import Foundation

// F0.2.2: doce relatos inventados, ninguno real, tal como pide la spec del spike.
enum Corpus {
  struct Story {
    let id: String
    let interfaceLanguage: String
    let text: String
  }

  static let stories: [Story] = [
    Story(
      id: "es-corto",
      interfaceLanguage: "Spanish",
      text: """
        El sábado pasado fui con mi amigo Pablo al Retiro. Nos sentamos junto al estanque y comimos unos \
        bocadillos que había preparado mi madre. Pablo llevaba su cámara vieja y sacó varias fotos de los patos.
        """
    ),
    Story(
      id: "es-cuatroParrafos",
      interfaceLanguage: "Spanish",
      text: """
        El 12 de julio de 2019 mi hermana Elena y yo cogimos el tren de madrugada hacia San Sebastián. \
        Casi no dormimos en todo el trayecto, pero llegamos con ganas de todo.

        Nos alojamos en un hostal pequeño cerca de la parte vieja, y a media tarde se unió a nosotros mi tío \
        Andrés, que llevaba viviendo allí desde hacía años y conocía la ciudad de memoria.

        Al día siguiente bajamos a la playa de la Concha. Apareció mi prima Nuria con su perro Toby, y nos \
        pasamos la mañana entera tirándole un palo al agua mientras Elena leía bajo la sombrilla.

        Por la noche cenamos los cuatro en Casa Alcalde. Pedimos de todo, y recuerdo que Andrés brindó por \
        que volviéramos a hacer el viaje juntos al año siguiente.
        """
    ),
    Story(
      id: "es-sinFecha",
      interfaceLanguage: "Spanish",
      text: """
        Cada domingo por la mañana, mi abuela Carmen prepara torrijas en su cocina de siempre. Me siento en \
        el taburete azul mientras el aroma a canela llena toda la casa. Ella nunca sigue una receta escrita: \
        lo hace todo de memoria.
        """
    ),
    Story(
      id: "es-fechaAmbigua",
      interfaceLanguage: "Spanish",
      text: """
        El verano del 87 mi padre compró la casa de la sierra. Recuerdo el olor a pino y el ruido de las \
        cigarras las primeras noches que dormimos allí con mi tío Rafael.
        """
    ),
    Story(
      id: "en-corto",
      interfaceLanguage: "English",
      text: """
        Last Friday I met my neighbor Sam at the corner bakery on Elm Street. We shared a loaf of sourdough \
        bread and talked about his trip to Portugal.
        """
    ),
    Story(
      id: "en-cuatroParrafos",
      interfaceLanguage: "English",
      text: """
        On March 3rd, 2021 my sister Laura and I drove down to Big Sur before sunrise. Neither of us had \
        slept much, but we were too excited to care.

        We checked into a small cabin near the coast, and by afternoon our uncle Mark showed up, since he'd \
        been living nearby for years and knew every trail around there.

        The next morning we hiked out to McWay Falls. My cousin Grace turned up with her dog Biscuit, and we \
        spent the whole morning throwing a stick into the stream while Laura read on a rock nearby.

        That night the four of us had dinner at The Fernwood Tavern. Mark raised a toast to doing the trip \
        again the following year, and we all agreed on the spot.
        """
    ),
    Story(
      id: "en-sinFecha",
      interfaceLanguage: "English",
      text: """
        Every Sunday morning, my grandmother Ruth bakes cinnamon rolls in her old kitchen. I sit on the green \
        stool while the smell fills the whole house. She never uses a written recipe.
        """
    ),
    Story(
      id: "en-fechaAmbigua",
      interfaceLanguage: "English",
      text: """
        The summer of '92 my father bought the cabin by the lake. I remember the smell of pine and the sound \
        of crickets the first nights we slept there with my uncle Dave.
        """
    ),
    Story(
      id: "intimo-muerte",
      interfaceLanguage: "Spanish",
      text: """
        Mi abuela Pilar murió una mañana de noviembre, tranquila, en su propia cama. Estuve con ella las \
        últimas horas, cogiéndole la mano mientras mi madre preparaba café en la cocina de al lado. No fue un \
        momento triste del todo: hablamos de cuando era joven y bailaba en las verbenas del pueblo.
        """
    ),
    Story(
      id: "intimo-enfermedad",
      interfaceLanguage: "Spanish",
      text: """
        Mi padre estuvo enfermo casi tres años antes de que pudiéramos por fin volver a llevarlo de paseo al \
        parque de siempre. Recuerdo las tardes en el hospital, el sillón verde junto a la ventana, y cómo poco \
        a poco fue recuperando las fuerzas para caminar solo otra vez.
        """
    ),
    Story(
      id: "guerra-posguerra",
      interfaceLanguage: "Spanish",
      text: """
        Mi abuelo Ezequiel contaba que, después de la guerra, pasaron dos inviernos enteros con muy poco pan \
        en casa. Él y su hermano Tomás iban a buscar leña al monte de madrugada para no perder las pocas horas \
        de escuela que quedaban. Nunca hablaba de aquello con amargura, solo decía que aprendió a no \
        desperdiciar nada.
        """
    ),
    Story(
      id: "mixto-esEn",
      interfaceLanguage: "Spanish",
      text: """
        Fui a visitar a mi prima Sofía a Chicago el pasado octubre. Su marido, John, nos llevó a un sitio que \
        él llamaba "the best deep dish in town", cerca de Wrigley Field. Sofía no paraba de decir "this is \
        amazing" mientras probábamos la pizza, y al final brindamos con un "cheers" improvisado.
        """
    ),
  ]
}
