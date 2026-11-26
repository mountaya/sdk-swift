import Testing

@testable import MountayaClient

@Suite("SessionTokenSource")
struct SessionTokenSourceTests {
  private struct Held: SessionTokenSource {
    let snapshot: SessionSnapshot

    func subscribe() -> AsyncStream<SessionSnapshot> {
      AsyncStream { continuation in
        continuation.yield(snapshot)
        continuation.finish()
      }
    }
  }

  @Test("a source of the application's own stands where the engine does")
  func conformance() async {
    let token = SessionToken.source(Held(snapshot: SessionSnapshot(token: "sess_abc")))
    var told: [String?] = []
    if case .source(let source) = token {
      for await snapshot in source.subscribe() {
        told.append(snapshot.token)
      }
    }

    #expect(token.token == "sess_abc")
    #expect(told == ["sess_abc"])
    #expect("\(token)" == "SessionToken.source")
  }
}
