import Testing

@testable import MountayaClient

@Suite("PersistedQuerySupport")
struct PersistedQuerySupportTests {
  @Test("a transport starts by sending the digest alone")
  func probesFirst() {
    let support = PersistedQuerySupport()

    #expect(support.firstAttempt(digest: "abc") == .init(digest: "abc", sendsDocument: false))
  }

  @Test("a digest that could not be computed sends the document in full, and is not kept")
  func rejectedDigest() {
    var support = PersistedQuerySupport()
    let attempt = support.firstAttempt(digest: nil)

    #expect(attempt == .init(digest: nil, sendsDocument: true))
    #expect(support.read([ErrorEntry(message: "boom")], answering: attempt) == nil)
    #expect(!support.isDeclined)
    #expect(support.firstAttempt(digest: "abc").isDigestOnly)
  }

  @Test("a declined protocol is not probed again for the transport's lifetime")
  func declined() {
    var support = PersistedQuerySupport()
    let refusal = support.read(
      [ErrorEntry(message: "PersistedQueryNotSupported")],
      answering: support.firstAttempt(digest: "abc")
    )

    #expect(refusal == .unsupported)
    #expect(support.isDeclined)
    #expect(support.firstAttempt(digest: "abc") == .init(digest: nil, sendsDocument: true))
    #expect(support.firstAttempt(digest: "def") == .init(digest: nil, sendsDocument: true))
  }

  @Test("a digest the server asked to have registered is probed again on the next operation")
  func registered() {
    var support = PersistedQuerySupport()
    let refusal = support.read(
      [ErrorEntry(message: "PersistedQueryNotFound")],
      answering: support.firstAttempt(digest: "abc")
    )

    #expect(refusal == .register)
    #expect(!support.isDeclined)
    #expect(support.firstAttempt(digest: "abc").isDigestOnly)
  }

  @Test("an ordinary failure declines nothing")
  func ordinaryFailure() {
    var support = PersistedQuerySupport()
    _ = support.read(
      [ErrorEntry(message: "boom", code: "INTERNAL_SERVER_ERROR")],
      answering: support.firstAttempt(digest: "abc")
    )

    #expect(!support.isDeclined)
  }
}
