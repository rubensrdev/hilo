import Foundation
import ImageIO
import SwiftData
import Testing

@testable import Hilo

// F2.2: values Sendable de ida y vuelta por el actor de modelo, sin reglas de dominio de por medio
struct PersistenceActorTests {
  static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  @Test
  func `A memory saved without a date is fetched with the same id, narrative, savedAt and no date`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Aprendí a nadar en la piscina del pueblo.", savedAt: Self.fixedSavedAt))

    let savedID = try await actor.save(memory, isAnalyzed: false, isExample: false)
    #expect(savedID == memory.id)

    let fetched = try #require(try await actor.fetchMemories().first)
    #expect(fetched.id == memory.id)
    #expect(fetched.narrative == memory.narrative)
    #expect(fetched.savedAt == memory.savedAt)
    #expect(fetched.date == nil)
  }

  @Test func `A memory saved with a MemoryDate keeps its text and deduced year after fetching`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let date = try #require(MemoryDate(text: "el verano del 87", deducedYear: 1987))
    let memory = try #require(
      Memory(narrative: "Aquel verano en la playa.", date: date, savedAt: Self.fixedSavedAt))

    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)

    let fetched = try #require(try await actor.fetchMemories().first)
    #expect(fetched.date?.text == "el verano del 87")
    #expect(fetched.date?.deducedYear == 1987)
  }

  @Test
  func
    `An element saved with non-empty aliases is fetched with the same id, displayName, type and aliases`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let element = try #require(
      Element(displayName: "Manuel", type: .person, aliases: ["Manolo", "Tío Manuel"]))

    let savedID = try await actor.save(element)
    #expect(savedID == element.id)

    let fetched = try #require(try await actor.fetchElements().first)
    #expect(fetched.id == element.id)
    #expect(fetched.displayName == "Manuel")
    #expect(fetched.type == .person)
    #expect(fetched.aliases == ["Manolo", "Tío Manuel"])
  }

  @Test
  func
    `Saving an element stores its canonical name without the leading article, in the underlying record`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let element = try #require(Element(displayName: "El Abuelo", type: .person))

    _ = try await actor.save(element)

    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<ElementRecord>()).first)
    #expect(record.canonicalName == CanonicalName.of("El Abuelo"))
  }

  @Test
  func
    `An appearance connecting a saved memory and element is fetched with the same ids, role and status`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Comimos en casa de mi tía.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Tía Rosa", type: .person))
    let role = try #require(ElementRole(text: "la anfitriona"))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    let appearance = Appearance(
      memoryID: memory.id, elementID: element.id, role: role, status: .confirmedByUser)

    try await actor.save(appearance)

    let fetched = try #require(try await actor.fetchAppearances().first)
    #expect(fetched.memoryID == memory.id)
    #expect(fetched.elementID == element.id)
    #expect(fetched.role?.text == "la anfitriona")
    #expect(fetched.status == .confirmedByUser)
  }

  @Test func `Saving an appearance whose memory was never saved throws memoryNotFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let missingMemoryID = MemoryID()
    let element = try #require(Element(displayName: "Un banco del parque", type: .object))
    _ = try await actor.save(element)
    let appearance = Appearance(
      memoryID: missingMemoryID, elementID: element.id, role: nil, status: .proposed)

    await #expect(throws: PersistenceActor.WriteError.memoryNotFound) {
      try await actor.save(appearance)
    }
  }

  @Test func `Saving an appearance whose element was never saved throws elementNotFound`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un paseo por el parque.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    let missingElementID = ElementID()
    let appearance = Appearance(
      memoryID: memory.id, elementID: missingElementID, role: nil, status: .proposed)

    await #expect(throws: PersistenceActor.WriteError.elementNotFound) {
      try await actor.save(appearance)
    }
  }

  @Test
  func `A freshly created container returns empty arrays for memories, elements and appearances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
    #expect(try await actor.fetchAppearances().isEmpty)
  }

  // contrato 3 + DEC-27: la foto se guarda como pixeles, nunca con sus metadatos de ubicacion
  @Test func `A memory saved with a photo is fetched with pixel data stripped of its GPS metadata`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Una tarde en el mirador.", savedAt: Self.fixedSavedAt))
    let originalPhoto = try PhotoStripperTests.jpegWithGPS()
    #expect(PhotoStripperTests.gpsDictionary(in: originalPhoto) != nil)

    let savedID = try await actor.save(
      memory, photoData: originalPhoto, isAnalyzed: false, isExample: false)

    let storedPhoto = try #require(try await actor.photoData(for: savedID))
    #expect(storedPhoto != originalPhoto)
    #expect(PhotoStripperTests.gpsDictionary(in: storedPhoto) == nil)
  }

  @Test func `A memory saved without a photo has no photo data when fetched`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un domingo sin cámara.", savedAt: Self.fixedSavedAt))

    let savedID = try await actor.save(memory, isAnalyzed: false, isExample: false)

    #expect(try await actor.photoData(for: savedID) == nil)
  }

  @Test func `Fetching photo data for a memory id that was never saved returns nil`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    #expect(try await actor.photoData(for: MemoryID()) == nil)
  }

  // contrato 4 + reglas 11/12: la limpieza de huerfanos ocurre en el camino de escritura
  @Test func `Deleting a memory removes an element that only appeared in it`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un paseo por el puerto con mi abuelo.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Abuelo", type: .person))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(memoryID: memory.id, elementID: element.id, role: nil, status: .confirmedByUser))

    try await actor.deleteMemory(id: memory.id)

    let remainingElements = try await actor.fetchElements()
    #expect(!remainingElements.contains { $0.id == element.id })
  }

  @Test func `Deleting a memory keeps an element that still appears in another memory`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let firstMemory = try #require(
      Memory(narrative: "Comimos marisco en la lonja.", savedAt: Self.fixedSavedAt))
    let secondMemory = try #require(
      Memory(narrative: "Volvimos a la lonja al año siguiente.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Tío Paco", type: .person))
    _ = try await actor.save(firstMemory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(secondMemory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(
        memoryID: firstMemory.id, elementID: element.id, role: nil, status: .confirmedByUser))
    try await actor.save(
      Appearance(
        memoryID: secondMemory.id, elementID: element.id, role: nil, status: .confirmedByUser))

    try await actor.deleteMemory(id: firstMemory.id)

    let remainingElements = try await actor.fetchElements()
    #expect(remainingElements.contains { $0.id == element.id })
  }

  @Test func `Deleting a memory with a photo removes its photo data`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "La última tarde en el mirador.", savedAt: Self.fixedSavedAt))
    let photo = try PhotoStripperTests.jpegWithGPS()
    let savedID = try await actor.save(
      memory, photoData: photo, isAnalyzed: false, isExample: false)

    try await actor.deleteMemory(id: savedID)

    #expect(try await actor.photoData(for: savedID) == nil)
  }

  @Test func `Deleting a memory removes its appearances`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Cena de despedida en casa de Elena.", savedAt: Self.fixedSavedAt))
    let element = try #require(Element(displayName: "Elena", type: .person))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)
    _ = try await actor.save(element)
    try await actor.save(
      Appearance(memoryID: memory.id, elementID: element.id, role: nil, status: .proposed))

    try await actor.deleteMemory(id: memory.id)

    let remainingAppearances = try await actor.fetchAppearances()
    #expect(!remainingAppearances.contains { $0.memoryID == memory.id })
  }

  @Test func `Deleting a memory id that was never saved throws memoryNotFound`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    await #expect(throws: PersistenceActor.WriteError.memoryNotFound) {
      try await actor.deleteMemory(id: MemoryID())
    }
  }

  @Test func `Deleting a memory with no elements or appearances leaves it out of fetchMemories`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Un día cualquiera sin nada especial.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(memory, isAnalyzed: false, isExample: false)

    try await actor.deleteMemory(id: memory.id)

    let remainingMemories = try await actor.fetchMemories()
    #expect(!remainingMemories.contains { $0.id == memory.id })
  }

  // F2.5: memoria de ejemplo, carga, borrado e idempotencia
  @Test func `Loading the example memory in Spanish produces five memories`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == 5)
  }

  @Test
  func `Loading the example memory in Spanish gives José four appearances and el reloj three`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    let elements = try await actor.fetchElements()
    let appearances = try await actor.fetchAppearances()
    let jose = try #require(elements.first { $0.displayName == "José" })
    let watch = try #require(elements.first { $0.displayName == "el reloj" })
    #expect(appearances.filter { $0.elementID == jose.id }.count == 4)
    #expect(appearances.filter { $0.elementID == watch.id }.count == 3)
  }

  @Test
  func `Loading the example memory in English gives José four appearances and the watch three`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .english, loadedAt: Self.fixedSavedAt)

    let elements = try await actor.fetchElements()
    let appearances = try await actor.fetchAppearances()
    let jose = try #require(elements.first { $0.displayName == "José" })
    let watch = try #require(elements.first { $0.displayName == "the watch" })
    #expect(appearances.filter { $0.elementID == jose.id }.count == 4)
    #expect(appearances.filter { $0.elementID == watch.id }.count == 3)
  }

  @Test
  func
    `Loading the example memory saves every memory analyzed and every appearance confirmed by the user`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    let context = ModelContext(container)
    let memoryRecords = try context.fetch(FetchDescriptor<MemoryRecord>())
    #expect(memoryRecords.count == 5)
    #expect(memoryRecords.allSatisfy { $0.isAnalyzed })

    let appearances = try await actor.fetchAppearances()
    #expect(!appearances.isEmpty)
    #expect(appearances.allSatisfy { $0.status == .confirmedByUser })
  }

  @Test
  func `Loading the example memory twice does not duplicate memories, elements or appearances`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    let memoriesAfterFirstLoad = try await actor.fetchMemories().count
    let elementsAfterFirstLoad = try await actor.fetchElements().count
    let appearancesAfterFirstLoad = try await actor.fetchAppearances().count

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == memoriesAfterFirstLoad)
    #expect(try await actor.fetchElements().count == elementsAfterFirstLoad)
    #expect(try await actor.fetchAppearances().count == appearancesAfterFirstLoad)
  }

  @Test
  func
    `Loading the example memory in English after Spanish is a no-op once an example already exists`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    try await actor.loadExampleMemory(language: .english, loadedAt: Self.fixedSavedAt)

    #expect(try await actor.fetchMemories().count == 5)
    let elements = try await actor.fetchElements()
    #expect(elements.contains { $0.displayName == "el reloj" })
    #expect(!elements.contains { $0.displayName == "the watch" })
  }

  @Test func `Deleting the example memory removes its memories and leaves no elements behind`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)

    try await actor.deleteExampleMemory()

    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
  }

  @Test
  func
    `Deleting the example memory keeps an element that also appears in a real memory, with only that appearance left`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    let joseFromExample = try #require(
      try await actor.fetchElements().first { $0.displayName == "José" })
    let realMemory = try #require(
      Memory(narrative: "Comimos con José el domingo pasado.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(realMemory, isAnalyzed: false, isExample: false)
    try await actor.save(
      Appearance(
        memoryID: realMemory.id, elementID: joseFromExample.id, role: nil,
        status: .confirmedByUser))

    try await actor.deleteExampleMemory()

    let remainingElements = try await actor.fetchElements()
    #expect(remainingElements.count == 1)
    let jose = try #require(remainingElements.first { $0.displayName == "José" })
    let remainingAppearances = try await actor.fetchAppearances()
    #expect(remainingAppearances.filter { $0.elementID == jose.id }.count == 1)
  }

  // contrato 6 + regla 25: el borrado total no deja recuerdos, elementos ni apariciones
  @Test
  func `Wiping all data with memories, elements, appearances and a photo leaves every fetch empty`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Una comida familiar en la terraza.", savedAt: Self.fixedSavedAt))
    let photo = try PhotoStripperTests.jpegWithGPS()
    let savedID = try await actor.save(
      memory, photoData: photo, isAnalyzed: false, isExample: false)
    let element = try #require(Element(displayName: "Tía Carmen", type: .person))
    let elementID = try await actor.save(element)
    try await actor.save(
      Appearance(memoryID: savedID, elementID: elementID, role: nil, status: .confirmedByUser))

    try await actor.wipeAllData()

    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
    #expect(try await actor.fetchAppearances().isEmpty)
  }

  @Test func `Wiping all data removes an orphaned discard record with no element`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let context = ModelContext(container)
    context.insert(DiscardRecord(gapType: "unsupportedLanguage", element: nil))
    try context.save()

    try await actor.wipeAllData()

    let remainingDiscards = try ModelContext(container).fetch(FetchDescriptor<DiscardRecord>())
    #expect(remainingDiscards.isEmpty)
  }

  @Test func `Wiping all data on an already empty container does not throw`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)

    try await actor.wipeAllData()

    #expect(try await actor.fetchMemories().isEmpty)
  }

  // contrato 6: la foto externalizada tambien desaparece del disco, no solo del store
  @Test func `Wiping all data with a real on-disk container frees the externally stored photo`()
    async throws
  {
    let storeDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
      at: storeDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: storeDirectory) }
    let storeURL = storeDirectory.appendingPathComponent("test.store")
    let configuration = ModelConfiguration(url: storeURL)
    let container = try ModelContainer(
      for: PersistenceContainer.schema, configurations: [configuration])
    let actor = PersistenceActor(modelContainer: container)
    // el propio fichero SQLite (y su -wal/-shm) no se encoge al borrar filas: se excluyen
    // para medir solo lo que Core Data guarda fuera del store, es decir, el dato externo
    let storeFileNames = Set(
      [storeURL.lastPathComponent, "test.store-wal", "test.store-shm"])
    let baselineSize = try Self.externalByteSize(of: storeDirectory, excluding: storeFileNames)

    let memory = try #require(
      Memory(narrative: "Un viaje largo con muchas fotos.", savedAt: Self.fixedSavedAt))
    let photo = try Self.noiseJPEG(width: 900, height: 900)
    _ = try await actor.save(memory, photoData: photo, isAnalyzed: false, isExample: false)

    let sizeAfterSaving = try Self.externalByteSize(of: storeDirectory, excluding: storeFileNames)
    #expect(sizeAfterSaving > baselineSize)

    try await actor.wipeAllData()

    let sizeAfterWipe = try Self.externalByteSize(of: storeDirectory, excluding: storeFileNames)
    #expect(sizeAfterWipe <= baselineSize)
  }

  private static func externalByteSize(of directory: URL, excluding storeFileNames: Set<String>)
    throws -> Int
  {
    guard
      let enumerator = FileManager.default.enumerator(
        at: directory, includingPropertiesForKeys: [.fileSizeKey], options: [])
    else { return 0 }
    var total = 0
    for entry in enumerator {
      guard let url = entry as? URL, !storeFileNames.contains(url.lastPathComponent) else {
        continue
      }
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
      if values.isDirectory == true { continue }
      total += values.fileSize ?? 0
    }
    return total
  }

  // ruido por pixel, no un color plano: el JPEG debe pesar lo bastante para forzar almacenamiento externo
  private static func noiseJPEG(width: Int, height: Int) throws -> Data {
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let bytesPerPixel = 4
    var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    for index in pixels.indices {
      pixels[index] = UInt8.random(in: 0...255)
    }
    let context = try #require(
      pixels.withUnsafeMutableBytes { buffer in
        CGContext(
          data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
          bytesPerRow: width * bytesPerPixel, space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
      })
    let image = try #require(context.makeImage())

    let output = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return output as Data
  }
}

// F4.5.2 + DEC-40: el ReviewOutcome entero se aplica en una sola operacion, o no se aplica
struct PersistenceActorReviewTests {
  static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  @Test
  func `Saving a reviewed memory inserts it analyzed with its narrative, date and stripped photo`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let date = try #require(MemoryDate(text: "el verano del 87", deducedYear: 1987))
    let memory = try #require(
      Memory(narrative: "Aquel verano en la playa de Cádiz.", date: date, savedAt: Self.fixedSavedAt))
    let originalPhoto = try PhotoStripperTests.jpegWithGPS()

    let savedID = try await actor.saveReviewed(
      memory, photoData: originalPhoto, outcome: Self.outcome(date: date))

    #expect(savedID == memory.id)
    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let record = try #require(records.first)
    #expect(record.id == memory.id.value)
    #expect(record.isAnalyzed)
    #expect(record.narrative == "Aquel verano en la playa de Cádiz.")
    #expect(record.dateText == "el verano del 87")
    #expect(record.deducedYear == 1987)
    #expect(record.savedAt == Self.fixedSavedAt)
    let storedPhoto = try #require(record.photoData)
    #expect(PhotoStripperTests.gpsDictionary(in: storedPhoto) == nil)
  }

  @Test
  func `A new element in the outcome is created with its canonical name and a confirmed appearance with its role`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "La tía Marta hacía rosquillas.", savedAt: Self.fixedSavedAt))
    let marta = try #require(Element(displayName: "la tía Marta", type: .person))

    _ = try await actor.saveReviewed(
      memory, photoData: nil,
      outcome: Self.outcome(
        elementsToCreate: [.init(element: marta, role: ElementRole(text: "mi tía"))]))

    let elements = try ModelContext(container).fetch(FetchDescriptor<ElementRecord>())
    #expect(elements.count == 1)
    let record = try #require(elements.first)
    #expect(record.id == marta.id.value)
    #expect(record.displayName == "la tía Marta")
    #expect(record.canonicalName == "tia marta")
    #expect(record.type == .person)
    let appearances = try await actor.fetchAppearances()
    #expect(appearances.count == 1)
    let appearance = try #require(appearances.first)
    #expect(appearance.memoryID == memory.id)
    #expect(appearance.elementID == marta.id)
    #expect(appearance.role?.text == "mi tía")
    #expect(appearance.status == .confirmedByUser)
  }

  @Test
  func `A confirmed appearance links the existing element without creating another one`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let jose = try #require(Element(displayName: "José", type: .person))
    _ = try await actor.save(jose)
    let memory = try #require(
      Memory(narrative: "José me enseñó a pescar.", savedAt: Self.fixedSavedAt))

    _ = try await actor.saveReviewed(
      memory, photoData: nil,
      outcome: Self.outcome(confirmedAppearances: [.init(elementID: jose.id, role: nil)]))

    let elements = try await actor.fetchElements()
    #expect(elements.map(\.id) == [jose.id])
    #expect(elements.first?.displayName == "José")
    let appearances = try await actor.fetchAppearances()
    #expect(appearances.count == 1)
    #expect(appearances.first?.memoryID == memory.id)
    #expect(appearances.first?.elementID == jose.id)
    #expect(appearances.first?.status == .confirmedByUser)
  }

  // regla 7: el nombre usado en este recuerdo pasa a ser alias del elemento existente
  @Test func `An alias added on save makes the element resolve by that name`() async throws {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let manuel = try #require(Element(displayName: "Manuel", type: .person))
    _ = try await actor.save(manuel)
    let memory = try #require(
      Memory(narrative: "Manolo arreglaba bicis en el garaje.", savedAt: Self.fixedSavedAt))

    _ = try await actor.saveReviewed(
      memory, photoData: nil,
      outcome: Self.outcome(
        confirmedAppearances: [.init(elementID: manuel.id, role: nil)],
        aliasesToAdd: [.init(elementID: manuel.id, alias: "Manolo")]))

    let elements = try await actor.fetchElements()
    #expect(elements.first?.aliases == ["Manolo"])
    #expect(
      ElementResolution.resolving(name: "Manolo", type: .person, against: elements)
        == .exactMatch([manuel.id]))
  }

  // regla 10: renombrar un elemento lo renombra en toda la memoria, tambien en recuerdos anteriores
  @Test
  func `A rename applied on save changes the element's name and canonical name everywhere`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let abuelo = try #require(Element(displayName: "el abuelo", type: .person))
    _ = try await actor.save(abuelo)
    let earlier = try #require(
      Memory(narrative: "El abuelo tenía un huerto.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(earlier, isAnalyzed: true, isExample: false)
    try await actor.save(
      Appearance(memoryID: earlier.id, elementID: abuelo.id, role: nil, status: .confirmedByUser))
    let memory = try #require(
      Memory(narrative: "El abuelo Ramón nos llevó al río.", savedAt: Self.fixedSavedAt))

    _ = try await actor.saveReviewed(
      memory, photoData: nil,
      outcome: Self.outcome(
        confirmedAppearances: [.init(elementID: abuelo.id, role: nil)],
        renamesToApply: [.init(elementID: abuelo.id, newName: "abuelo Ramón")]))

    let records = try ModelContext(container).fetch(FetchDescriptor<ElementRecord>())
    #expect(records.count == 1)
    #expect(records.first?.displayName == "abuelo Ramón")
    #expect(records.first?.canonicalName == "abuelo ramon")
    let appearances = try await actor.fetchAppearances()
    #expect(Set(appearances.map(\.memoryID)) == [earlier.id, memory.id])
    #expect(appearances.allSatisfy { $0.elementID == abuelo.id })
  }

  // DEC-45 + DEC-35: comprender mas tarde actualiza el mismo recuerdo, sin tocar savedAt ni la foto
  @Test
  func `Completing the analysis updates the same memory without touching savedAt, photo or narrative`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "La boda de Elena en el pueblo.", savedAt: Self.fixedSavedAt))
    let savedID = try await actor.save(
      memory, photoData: try PhotoStripperTests.jpegWithGPS(), isAnalyzed: false,
      isExample: false)
    let photoBefore = try await actor.photoData(for: savedID)
    let elena = try #require(Element(displayName: "Elena", type: .person))
    let date = try #require(MemoryDate(text: "en mayo", deducedYear: nil))

    try await actor.completeAnalysis(
      of: savedID,
      outcome: Self.outcome(
        elementsToCreate: [.init(element: elena, role: nil)], date: date))

    let records = try ModelContext(container).fetch(FetchDescriptor<MemoryRecord>())
    #expect(records.count == 1)
    let record = try #require(records.first)
    #expect(record.id == savedID.value)
    #expect(record.isAnalyzed)
    #expect(record.savedAt == Self.fixedSavedAt)
    #expect(record.narrative == "La boda de Elena en el pueblo.")
    #expect(record.photoData == photoBefore)
    #expect(record.dateText == "en mayo")
    #expect(record.deducedYear == nil)
    let appearances = try await actor.fetchAppearances()
    #expect(appearances.map(\.memoryID) == [savedID])
    #expect(appearances.map(\.elementID) == [elena.id])
  }

  @Test func `Completing the analysis of a memory that was never saved throws memoryNotFound`()
    async throws
  {
    let actor = PersistenceActor(modelContainer: try PersistenceContainer.make(inMemory: true))

    await #expect(throws: PersistenceActor.WriteError.memoryNotFound) {
      try await actor.completeAnalysis(of: MemoryID(), outcome: Self.outcome())
    }
  }

  // DEC-40: "en la misma operacion que el resto" — un fallo a mitad no deja nada a medias
  @Test
  func `A failure halfway through saving leaves neither the memory nor the new element in the store`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "Pintamos la valla con Irene.", savedAt: Self.fixedSavedAt))
    let irene = try #require(Element(displayName: "Irene", type: .person))

    await #expect(throws: PersistenceActor.WriteError.elementNotFound) {
      try await actor.saveReviewed(
        memory, photoData: nil,
        outcome: Self.outcome(
          elementsToCreate: [.init(element: irene, role: nil)],
          confirmedAppearances: [.init(elementID: ElementID(), role: nil)]))
    }

    // lo que quedara a medias en el contexto del actor saldria en su siguiente guardado
    let later = try #require(Element(displayName: "el taller", type: .place))
    _ = try await actor.save(later)

    let context = ModelContext(container)
    #expect(try context.fetch(FetchDescriptor<MemoryRecord>()).isEmpty)
    #expect(try context.fetch(FetchDescriptor<ElementRecord>()).map(\.id) == [later.id.value])
    #expect(try context.fetch(FetchDescriptor<AppearanceRecord>()).isEmpty)
  }

  @Test
  func `A failure halfway through completing the analysis leaves the memory unanalyzed and untouched`()
    async throws
  {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let memory = try #require(
      Memory(narrative: "La excursión con Irene al pantano.", savedAt: Self.fixedSavedAt))
    let savedID = try await actor.save(memory, isAnalyzed: false, isExample: false)
    let irene = try #require(Element(displayName: "Irene", type: .person))
    let date = try #require(MemoryDate(text: "en otoño", deducedYear: nil))

    await #expect(throws: PersistenceActor.WriteError.elementNotFound) {
      try await actor.completeAnalysis(
        of: savedID,
        outcome: Self.outcome(
          elementsToCreate: [.init(element: irene, role: nil)],
          confirmedAppearances: [.init(elementID: ElementID(), role: nil)], date: date))
    }

    let later = try #require(Element(displayName: "el taller", type: .place))
    _ = try await actor.save(later)

    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<MemoryRecord>()).first)
    #expect(record.isAnalyzed == false)
    #expect(record.dateText == nil)
    #expect(try context.fetch(FetchDescriptor<ElementRecord>()).map(\.id) == [later.id.value])
    #expect(try context.fetch(FetchDescriptor<AppearanceRecord>()).isEmpty)
  }

  private static func outcome(
    elementsToCreate: [ReviewOutcome.NewElement] = [],
    confirmedAppearances: [ReviewOutcome.ConfirmedAppearance] = [],
    aliasesToAdd: [ReviewOutcome.AliasToAdd] = [],
    renamesToApply: [ReviewOutcome.RenameToApply] = [],
    date: MemoryDate? = nil
  ) -> ReviewOutcome {
    ReviewOutcome(
      elementsToCreate: elementsToCreate, confirmedAppearances: confirmedAppearances,
      aliasesToAdd: aliasesToAdd, renamesToApply: renamesToApply, date: date)
  }
}
