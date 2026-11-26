import Foundation
import Testing

@testable import MountayaClient

@Suite("ResolvedSession")
struct ResolvedSessionTests {
  private struct MintFailed: Error {}

  private final class Moving: SessionTokenSource {
    let changes: AsyncStream<SessionSnapshot>
    let snapshot: SessionSnapshot

    init(_ snapshot: SessionSnapshot, then changes: [SessionSnapshot]) {
      self.snapshot = snapshot
      self.changes = AsyncStream { continuation in
        continuation.yield(snapshot)
        for change in changes {
          continuation.yield(change)
        }
        continuation.finish()
      }
    }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      changes
    }
  }

  @Test("a session read for a request prints its token by its prefix alone, however printed")
  func printsNoToken() throws {
    let read = try ResolvedSession.reading("sess_9f2c4e", snapshot: nil)
    var dumped = ""
    dump(read, to: &dumped)

    for printed in [String(describing: read), String(reflecting: read), "\(read)", dumped] {
      #expect(!printed.contains("9f2c4e"), "\(printed)")
      #expect(printed.contains("sess_…"), "\(printed)")
    }
  }

  @Test("a function is read for the request, and a wrong prefix it answers is refused at the read")
  func function() throws {
    #expect(
      try ResolvedSession.reading(.function { "sess_read" }, snapshot: nil).token == "sess_read")
    #expect(try ResolvedSession.reading(.function { nil }, snapshot: nil).token == nil)
    #expect(throws: MountayaError.self) {
      try ResolvedSession.reading(.function { "tok_read" }, snapshot: nil)
    }
  }

  @Test("a source names its user, and a source with none carries the failure of its mint")
  func source() throws {
    let held = Moving(SessionSnapshot(token: "sess_a", userId: nil), then: [])
    let failed = Moving(SessionSnapshot(error: MintFailed()), then: [])
    let read = try ResolvedSession.reading(.source(held), snapshot: nil)
    let none = try ResolvedSession.reading(.source(failed), snapshot: nil)

    #expect(read.token == "sess_a")
    guard case .known(nil) = read.user else {
      Issue.record("a source's token minted without user_id is not known as such")
      return
    }
    #expect(none.token == nil)
    #expect(none.mintError is MintFailed)
  }

  @Test("a request waits while a token is on its way, and not once none is")
  func waits() async throws {
    let arriving = Moving(
      SessionSnapshot(isMinting: true),
      then: [
        SessionSnapshot(isMinting: true), SessionSnapshot(token: "sess_minted"),
      ])
    let failing = Moving(
      SessionSnapshot(isMinting: true), then: [SessionSnapshot(error: MintFailed())])
    let idle = Moving(SessionSnapshot(), then: [SessionSnapshot(token: "sess_later")])

    #expect(try await ResolvedSession.awaitingFirstToken(from: arriving).token == "sess_minted")
    #expect(try await ResolvedSession.awaitingFirstToken(from: failing).error is MintFailed)
    #expect(try await ResolvedSession.awaitingFirstToken(from: idle).token == nil)
  }

  /// Minting is a source whose first token is on its way and never lands.
  private final class Minting: SessionTokenSource {
    let snapshot = SessionSnapshot(isMinting: true)
    private let changes: AsyncStream<SessionSnapshot>
    private let continuation: AsyncStream<SessionSnapshot>.Continuation

    init() {
      (changes, continuation) = AsyncStream.makeStream(of: SessionSnapshot.self)
      continuation.yield(snapshot)
    }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      changes
    }
  }

  /// A view's task torn down during the first mint ends its request as cancelled, never as a
  /// request that went out with no token, which the projection would refuse as the caller's
  /// mistake.
  @Test("a task cancelled while a first token is on its way throws its cancellation")
  func cancelledWhileWaiting() async {
    let minting = Minting()
    let waiting = Task { try await ResolvedSession.awaitingFirstToken(from: minting) }
    waiting.cancel()

    await #expect(throws: CancellationError.self) { try await waiting.value }
  }
}
