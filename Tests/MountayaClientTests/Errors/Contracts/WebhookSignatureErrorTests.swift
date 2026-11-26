import Testing

@testable import MountayaClient

@Suite("WebhookSignatureError")
struct WebhookSignatureErrorTests {
  @Test("each reason is spelled as the contract spells it")
  func reasons() {
    #expect(WebhookSignatureError.Reason.missingHeader.rawValue == "missing-header")
    #expect(WebhookSignatureError.Reason.malformedHeader.rawValue == "malformed-header")
    #expect(WebhookSignatureError.Reason.signature.rawValue == "signature")
    #expect(WebhookSignatureError.Reason.timestamp.rawValue == "timestamp")
    #expect(WebhookSignatureError.Reason(rawValue: "timestamp") == .timestamp)
  }

  @Test("it carries its reason and describes itself by its message")
  func describes() {
    let refusal = WebhookSignatureError(reason: .timestamp, message: "Too late.")

    #expect(refusal.reason == .timestamp)
    #expect(refusal.description == "Too late.")
    #expect(
      MountayaError.webhookSignature(refusal).description == "WebhookSignatureError: Too late.")
  }
}
