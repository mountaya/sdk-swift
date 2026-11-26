import Testing

@testable import MountayaClient

@Suite("ConfigurationError")
struct ConfigurationErrorTests {
  @Test("its description is the message")
  func describesTheFailure() {
    let error = ConfigurationError(message: "a publishable key starts with `pk_`")

    #expect(error.description == "a publishable key starts with `pk_`")
  }

  @Test("it carries what made the refusal as its cause")
  func cause() {
    struct MintFailed: Error {}
    let error = ConfigurationError(
      message: "no session", idempotencyKey: "key", cause: MintFailed())

    #expect(error.cause is MintFailed)
    #expect(error.idempotencyKey == "key")
    #expect(ConfigurationError(message: "no session").cause == nil)
  }
}
