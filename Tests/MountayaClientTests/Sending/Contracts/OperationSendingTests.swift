import Testing

@testable import MountayaClient

@Suite("OperationSending")
struct OperationSendingTests {
  @Test("a call's options reach the seam unchanged")
  func options() async throws {
    let sender = ScriptedSender()
    let options = RequestOptions(retry: try RetryPolicy(maxRetries: 1))
    _ = try? await sender.client.studio.zones.getZone(zone_id: "zo", options: options)

    #expect(await sender.sent.first?.options == options)
  }
}
