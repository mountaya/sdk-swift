import Testing

@testable import MountayaClient

@Suite("PersistedQueryAttempt")
struct PersistedQueryAttemptTests {
  @Test("an attempt is digest-only where it sends a digest and leaves the document out")
  func digestOnly() {
    #expect(PersistedQueryAttempt(digest: "abc", sendsDocument: false).isDigestOnly)
    #expect(!PersistedQueryAttempt(digest: "abc", sendsDocument: true).isDigestOnly)
    #expect(!PersistedQueryAttempt(digest: nil, sendsDocument: true).isDigestOnly)
  }
}
