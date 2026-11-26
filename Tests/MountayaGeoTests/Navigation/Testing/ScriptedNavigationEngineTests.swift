import Testing

@testable import MountayaGeo

@Suite("ScriptedNavigationEngine")
@MainActor
struct ScriptedNavigationEngineTests {
  private let route = NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600)

  /// An app's code takes the protocol; its test hands it the scripted engine and answers for it.
  private func startTrip(_ navigation: some NavigationEngine<String>, to destination: String) {
    navigation.start(destination)
  }

  @Test("each request is kept in the order it left, with what the app asked")
  func keptInOrder() throws {
    let engine = ScriptedNavigationEngine<String>()

    startTrip(engine, to: "summit")
    engine.start("refuge")
    engine.start("lake")
    #expect(engine.sent.map(\.request) == ["summit"])

    try engine.sent[0].answer(route)
    #expect(engine.sent.map(\.request) == ["summit", "lake"])
    #expect(engine.sent[0].isAnswered)
    #expect(!engine.sent[1].isAnswered)
  }

  /// No task and no executor to wait on: the state a command leaves is the state when it returns.
  @Test("each command has its effect before it returns")
  func effectBeforeReturn() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    try engine.sent[0].answer(route)
    try engine.setPosition([0.01, 0])

    #expect(engine.state.status == .arrived)
  }

  @Test("a stop or a close marks the request in flight abandoned, and its answer is dropped")
  func abandoned() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    engine.stop()
    engine.start("refuge")
    engine.close()

    #expect(engine.sent.map(\.isAbandoned) == [true, true])
    try engine.sent[1].answer(route)
    #expect(engine.state.status == .routing)
    #expect(engine.sent[1].isAnswered)
  }

  /// A request answered while another waited behind it was replaced, not abandoned: its answer is
  /// dropped by the contract's rule, and the engine stops nothing.
  @Test("a replaced request is not abandoned")
  func replaced() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    engine.start("refuge")
    try engine.sent[0].answer(route)

    #expect(!engine.sent[0].isAbandoned)
    #expect(engine.state.status == .routing)
  }

  @Test("the sent list is a snapshot")
  func snapshot() {
    let engine = ScriptedNavigationEngine<String>()
    let before = engine.sent

    engine.start("summit")

    #expect(before.isEmpty)
    #expect(engine.sent.count == 1)
  }
}
