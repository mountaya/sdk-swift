import Testing

@testable import MountayaClient

@Suite("MountayaError")
struct MountayaErrorTests {
  @Test("each case names the contract's class")
  func namesTheClass() {
    #expect(MountayaError.api(APIError(status: 404)).name == "NotFoundError")
    #expect(MountayaError.api(APIError(status: 418)).name == "ApiError")
    #expect(MountayaError.connection(ConnectionError()).name == "ConnectionError")
    #expect(
      MountayaError.configuration(ConfigurationError(message: "x")).name == "ConfigurationError")
    #expect(
      MountayaError.selection(SelectionError(path: ["nope"], message: "x")).name
        == "SelectionError")
    #expect(MountayaError.api(APIError(status: 200)).name == "DataError")
    #expect(MountayaError.api(APIError(status: 412)).name == "PreconditionFailedError")
    #expect(
      MountayaError.webhookSignature(WebhookSignatureError(reason: .signature, message: "x")).name
        == "WebhookSignatureError")
  }

  @Test("a webhook delivery's refusal is of the family, answered by no API, and carries no key")
  func webhookSignatureIsOfTheFamily() {
    let error = MountayaError.webhookSignature(
      WebhookSignatureError(reason: .malformedHeader, message: "x"))

    #expect(isMountayaError(error))
    #expect(!isAPIError(error))
    #expect(error.idempotencyKey == nil)
    #expect(error.carrying(idempotencyKey: "key").idempotencyKey == nil)
  }

  @Test("the description leads with the class and carries the failure, then its next step")
  func describesTheFailure() {
    let error = MountayaError.api(
      APIError(status: 429, errors: [ErrorEntry(message: "Seats used up.", code: "LIMIT_REACHED")])
    )
    let gone = MountayaError.api(
      APIError(status: 404, errors: [ErrorEntry(message: "Gone.", code: "NOT_FOUND")]))

    #expect(
      error.description == "RateLimitError: 429 LIMIT_REACHED: Seats used up. \(NextStep.ceiling)")
    #expect(gone.description == "NotFoundError: 404 NOT_FOUND: Gone.")
  }

  @Test("it is thrown and caught as a Swift error")
  func isThrownAndCaught() {
    func refuse() throws(MountayaError) {
      throw .configuration(ConfigurationError(message: "no credential"))
    }

    #expect {
      try refuse()
    } throws: { error in
      guard case .configuration(let refusal) = error as? MountayaError else { return false }
      return refusal.message == "no credential"
    }
  }
}
