import Testing

@testable import MountayaClient

@Suite("PersistedQueryRefusal")
struct PersistedQueryRefusalTests {
  private static let digestOnly = PersistedQueryAttempt(digest: "abc", sendsDocument: false)
  private static let withDocument = PersistedQueryAttempt(digest: "abc", sendsDocument: true)
  private static let documentOnly = PersistedQueryAttempt(digest: nil, sendsDocument: true)
  private static let extensionOff = ErrorEntry(
    message: "no operation provided",
    code: "GRAPHQL_VALIDATION_FAILED"
  )

  private static func read(
    _ errors: [ErrorEntry], answering attempt: PersistedQueryAttempt = digestOnly
  )
    -> PersistedQueryRefusal?
  {
    PersistedQueryRefusal(errors: errors, answering: attempt)
  }

  @Test("the server asking for the document is read by message or by code")
  func register() {
    #expect(Self.read([ErrorEntry(message: "PersistedQueryNotFound")]) == .register)
    #expect(
      Self.read([ErrorEntry(message: "not found", code: "PERSISTED_QUERY_NOT_FOUND")]) == .register
    )
  }

  @Test("the server declining the protocol is read by message or by code")
  func unsupported() {
    #expect(Self.read([ErrorEntry(message: "PersistedQueryNotSupported")]) == .unsupported)
    #expect(
      Self.read([ErrorEntry(message: "x", code: "PERSISTED_QUERY_NOT_SUPPORTED")]) == .unsupported
    )
  }

  @Test("a parse failure is an ordinary failure")
  func parseFailure() {
    #expect(
      Self.read([ErrorEntry(message: "unexpected token", code: "GRAPHQL_PARSE_FAILED")]) == nil)
  }

  @Test("the extension turned off declines the protocol by its code and its message together")
  func extensionOff() {
    #expect(Self.read([Self.extensionOff]) == .unsupported)
    #expect(
      Self.read([ErrorEntry(message: "Cannot query field.", code: "GRAPHQL_VALIDATION_FAILED")])
        == nil
    )
    #expect(Self.read([ErrorEntry(message: "no operation provided")]) == nil)
    #expect(
      Self.read([ErrorEntry(message: "No operation provided", code: "GRAPHQL_VALIDATION_FAILED")])
        == nil)
  }

  @Test("the extension turned off is an ordinary failure where the attempt sent its document")
  func extensionOffAnswersADigestOnlyAttempt() {
    #expect(Self.read([Self.extensionOff], answering: Self.withDocument) == nil)
    #expect(Self.read([Self.extensionOff], answering: Self.documentOnly) == nil)
  }

  @Test(
    "an attempt that sent its document is never asked for it, and one with no digest reads none")
  func attemptsThatSentTheDocument() {
    #expect(
      Self.read([ErrorEntry(message: "PersistedQueryNotFound")], answering: Self.withDocument)
        == nil)
    #expect(
      Self.read([ErrorEntry(message: "PersistedQueryNotSupported")], answering: Self.withDocument)
        == .unsupported
    )
    #expect(
      Self.read([ErrorEntry(message: "PersistedQueryNotSupported")], answering: Self.documentOnly)
        == nil)
    #expect(
      Self.read([ErrorEntry(message: "PersistedQueryNotFound")], answering: Self.documentOnly)
        == nil)
  }

  @Test("an ordinary error is not a refusal")
  func ordinary() {
    #expect(Self.read([]) == nil)
    #expect(Self.read([ErrorEntry(message: "boom", code: "INTERNAL")]) == nil)
  }

  @Test("a refusal is read wherever it sits, and declining the protocol outranks asking")
  func anyEntryAndRank() {
    #expect(
      Self.read([ErrorEntry(message: "boom"), ErrorEntry(message: "PersistedQueryNotFound")])
        == .register
    )
    #expect(
      Self.read([
        ErrorEntry(message: "PersistedQueryNotFound"),
        ErrorEntry(message: "PersistedQueryNotSupported"),
      ]) == .unsupported
    )
    #expect(
      Self.read([ErrorEntry(message: "PersistedQueryNotFound"), Self.extensionOff]) == .unsupported)
  }

  @Test("a message is matched whole and exactly")
  func exactMessages() {
    #expect(Self.read([ErrorEntry(message: "persistedquerynotfound")]) == nil)
    #expect(Self.read([ErrorEntry(message: "PersistedQueryNotFound: retry")]) == nil)
  }
}
