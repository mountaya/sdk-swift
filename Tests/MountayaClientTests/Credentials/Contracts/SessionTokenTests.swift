import Foundation
import Testing

@testable import MountayaClient

@Suite("SessionToken")
struct SessionTokenTests {
  private static let minted = RestSchema.Session(
    expires_at: Date(timeIntervalSince1970: 1_800_000_000),
    user_id: "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1",
    token: "sess_minted"
  )

  @Test("a string literal is a token whose user the client is not told")
  func literalIsAValue() {
    let token: SessionToken = "sess_abc"

    guard case .value(let value) = token else {
      Issue.record("a string literal is not a value")
      return
    }
    #expect(value == "sess_abc")
    #expect(token.token == "sess_abc")
  }

  @Test("a minted token is the token postSession answered")
  func mintedCarriesItsToken() {
    #expect(SessionToken.minted(Self.minted).token == "sess_minted")
  }

  @Test("a session token prints by its prefix alone, however it is printed")
  func redactedWhenPrinted() {
    let minted = SessionToken.minted(Self.minted)

    #expect("\(SessionToken.value("sess_abc"))" == "SessionToken.value(sess_…)")
    #expect("\(minted)" == "SessionToken.minted(sess_…)")
    #expect(String(reflecting: minted) == "SessionToken.minted(sess_…)")

    var dumped = ""
    dump(minted, to: &dumped)
    #expect(!dumped.contains("sess_minted"))
    #expect(!dumped.contains("7a4e1c98"))
  }
}
