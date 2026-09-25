import Foundation
import SwiftData
import Testing

@testable import Hilo

// F8 contrato 1 (S7): ejemplo cargar/borrar y borrado total con doble confirmacion, sin la vista
struct SettingsStateTests {
  private static let fixedSavedAt = Date(timeIntervalSince1970: 0)

  private final class Calls {
    var memoryChanged = 0
    var wiped = 0
  }

  private static func makeState() throws -> (SettingsState, PersistenceActor, Calls) {
    let container = try PersistenceContainer.make(inMemory: true)
    let actor = PersistenceActor(modelContainer: container)
    let calls = Calls()
    let state = SettingsState(
      persistenceActor: actor, version: "1.0",
      onMemoryChanged: { calls.memoryChanged += 1 },
      onWiped: { calls.wiped += 1 })
    return (state, actor, calls)
  }

  // MARK: memoria de ejemplo

  @Test func `Loading reports whether the example memory is present`() async throws {
    let (state, actor, _) = try Self.makeState()
    await state.load()
    #expect(state.hasExampleMemory == false)

    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    await state.load()

    #expect(state.hasExampleMemory == true)
  }

  @Test func `Loading the example memory writes it, flags it and notifies the memory change`()
    async throws
  {
    let (state, actor, calls) = try Self.makeState()

    await state.loadExampleMemory(language: .english)

    #expect(state.hasExampleMemory == true)
    #expect(calls.memoryChanged == 1)
    let elements = try await actor.fetchElements()
    #expect(elements.contains { $0.displayName == "the watch" })
  }

  @Test func `Deleting the example memory removes it and keeps a real memory untouched`()
    async throws
  {
    let (state, actor, calls) = try Self.makeState()
    let real = try #require(
      Memory(narrative: "Comimos en la terraza el domingo.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(real, isAnalyzed: false, isExample: false)
    await state.loadExampleMemory(language: .spanish)

    await state.deleteExampleMemory()

    #expect(state.hasExampleMemory == false)
    #expect(calls.memoryChanged == 2)
    let remaining = try await actor.fetchMemories()
    #expect(remaining.map(\.id) == [real.id])
  }

  // MARK: borrado total — doble confirmacion (regla 25)

  @Test func `Requesting the wipe opens the first confirmation only`() throws {
    let (state, _, _) = try Self.makeState()

    state.requestWipe()

    #expect(state.wipeStep == .first)
    #expect(state.isFirstWipeConfirmationPresented)
    #expect(!state.isSecondWipeConfirmationPresented)
  }

  @Test func `Continuing from the first confirmation opens the second`() throws {
    let (state, _, _) = try Self.makeState()
    state.requestWipe()

    state.continueWipe()

    #expect(state.wipeStep == .second)
    #expect(!state.isFirstWipeConfirmationPresented)
    #expect(state.isSecondWipeConfirmationPresented)
  }

  @Test func `Cancelling at either step returns to no confirmation`() throws {
    let (state, _, _) = try Self.makeState()
    state.requestWipe()
    state.cancelWipe()
    #expect(state.wipeStep == .none)

    state.requestWipe()
    state.continueWipe()
    state.cancelWipe()
    #expect(state.wipeStep == .none)
  }

  // deslizar o tocar fuera de la alerta del sistema la cierra: cuenta como cancelar
  @Test func `Dismissing a presented confirmation from the binding cancels that step`() throws {
    let (state, _, _) = try Self.makeState()
    state.requestWipe()
    state.isFirstWipeConfirmationPresented = false
    #expect(state.wipeStep == .none)

    state.requestWipe()
    state.continueWipe()
    state.isSecondWipeConfirmationPresented = false
    #expect(state.wipeStep == .none)
  }

  // el false que el sistema pone al cerrar la primera alerta no puede deshacer el avance al segundo
  @Test func `Closing the first confirmation binding once at the second step keeps the second`()
    throws
  {
    let (state, _, _) = try Self.makeState()
    state.requestWipe()
    state.continueWipe()

    state.isFirstWipeConfirmationPresented = false

    #expect(state.wipeStep == .second)
  }

  // el sistema puede poner el binding a false antes de la accion del boton: el avance sobrevive
  @Test func `Dismissing the first confirmation before continuing still reaches the second step`()
    throws
  {
    let (state, _, _) = try Self.makeState()
    state.requestWipe()

    state.isFirstWipeConfirmationPresented = false
    state.continueWipe()

    #expect(state.wipeStep == .second)
  }

  @Test func `Confirming at the second step empties the store, notifies and closes the flow`()
    async throws
  {
    let (state, actor, calls) = try Self.makeState()
    try await actor.loadExampleMemory(language: .spanish, loadedAt: Self.fixedSavedAt)
    let real = try #require(
      Memory(narrative: "Comimos en la terraza el domingo.", savedAt: Self.fixedSavedAt))
    _ = try await actor.save(real, isAnalyzed: false, isExample: false)
    state.requestWipe()
    state.continueWipe()

    let wiped = await state.confirmWipe()

    #expect(wiped)
    #expect(try await actor.fetchMemories().isEmpty)
    #expect(try await actor.fetchElements().isEmpty)
    #expect(state.wipeStep == .none)
    #expect(state.hasExampleMemory == false)
    #expect(calls.wiped == 1)
  }

  // "deleting is real": un borrado que falla no se cuenta como hecho ni cierra la hoja
  @Test func `A wipe whose write fails reports failure and never notifies as wiped`() async throws {
    let storeURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let writable = try ModelContainer(
      for: PersistenceContainer.schema, configurations: [ModelConfiguration(url: storeURL)])
    try await PersistenceActor(modelContainer: writable).loadExampleMemory(
      language: .spanish, loadedAt: Self.fixedSavedAt)
    let readOnly = try ModelContainer(
      for: PersistenceContainer.schema,
      configurations: [ModelConfiguration(url: storeURL, allowsSave: false)])
    let calls = Calls()
    let state = SettingsState(
      persistenceActor: PersistenceActor(modelContainer: readOnly), version: "1.0",
      onMemoryChanged: { calls.memoryChanged += 1 }, onWiped: { calls.wiped += 1 })
    state.requestWipe()
    state.continueWipe()

    let wiped = await state.confirmWipe()

    #expect(!wiped)
    #expect(state.wipeStep == .none)
    #expect(calls.wiped == 0)
    #expect(try await PersistenceActor(modelContainer: writable).fetchMemories().count == 5)
  }
}
