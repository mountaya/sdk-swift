import Testing

@testable import MountayaGeo

@Suite("ScriptedRouteRequest")
@MainActor
struct ScriptedRouteRequestTests {
  private struct Unreachable: Error {}

  private let route = NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600)

  @Test("a request is answered once")
  func answeredOnce() throws {
    let engine = ScriptedNavigationEngine<String>()
    engine.start("summit")
    try engine.sent[0].fail(Unreachable())

    let twice = #expect(throws: ScriptedAnswerError.self) { try engine.sent[0].answer(route) }
    #expect(twice?.description.contains("summit") == true)
    #expect(throws: ScriptedAnswerError.self) { try engine.sent[0].fail(Unreachable()) }
    #expect(engine.state.status == .failed)
  }

  @Test("a request holds what the app asked, unanswered and not abandoned until it is")
  func asMade() {
    let engine = ScriptedNavigationEngine<String>()
    engine.start("summit")

    #expect(engine.sent[0].request == "summit")
    #expect(!engine.sent[0].isAnswered)
    #expect(!engine.sent[0].isAbandoned)
  }
}
