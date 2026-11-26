import Foundation
import Testing

@testable import MountayaClient

@Suite("SessionSnapshot")
struct SessionSnapshotTests {
  private struct Failed: Error {}

  @Test("two snapshots are equal where they hold the same token and agree on a mint and a failure")
  func equality() {
    let expiry = Date(timeIntervalSince1970: 1_800_000_000)

    #expect(SessionSnapshot() == SessionSnapshot())
    #expect(
      SessionSnapshot(token: "sess_a", expiresAt: expiry)
        == SessionSnapshot(token: "sess_a", expiresAt: expiry))
    #expect(SessionSnapshot(token: "sess_a") != SessionSnapshot(token: "sess_b"))
    #expect(SessionSnapshot(isMinting: true) != SessionSnapshot())
    #expect(SessionSnapshot(error: Failed()) != SessionSnapshot())
  }

  @Test("a snapshot prints its token by its prefix alone, however it is printed")
  func redacted() {
    let snapshot = SessionSnapshot(token: "sess_secret", userId: "u1", isMinting: true)
    var dumped = ""
    dump(snapshot, to: &dumped)

    #expect("\(snapshot)" == "SessionSnapshot(token: sess_…, isMinting: true)")
    #expect(String(reflecting: snapshot) == "SessionSnapshot(token: sess_…, isMinting: true)")
    #expect("\([snapshot])" == "[SessionSnapshot(token: sess_…, isMinting: true)]")
    #expect(!dumped.contains("sess_secret"))
  }
}
