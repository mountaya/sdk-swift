import Testing

@testable import MountayaElements

@Suite("refusesSupersededCredential")
struct RefusesSupersededCredentialTests {
  @Test("a 401 or a 403 of a credential the client no longer sends is told to nobody, nothing else")
  func statuses() {
    #expect(credentialRefusalStatuses == [401, 403])
    #expect(
      (100...599).filter { refusesSupersededCredential($0, superseded: true) } == [401, 403])
    #expect(
      (100...599).allSatisfy { !refusesSupersededCredential($0, superseded: false) },
      "a refusal of the credential the client sends is told")
    #expect(!refusesSupersededCredential(402, superseded: true), "a 402 refuses the organization")
    #expect(!refusesSupersededCredential(nil, superseded: true), "no answer is a failure")
  }
}
