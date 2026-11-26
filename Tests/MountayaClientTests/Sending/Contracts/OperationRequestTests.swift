import Testing

@testable import MountayaClient

@Suite("OperationRequest")
struct OperationRequestTests {
  @Test("a request fills its path and keeps only the headers the caller set")
  func fills() {
    let request = OperationRequest(
      facts: .getAgentRunEvents,
      pathParameters: ["run_id": "r/1"],
      headers: ["X-Trace": nil]
    )

    #expect(request.path == "/v1/agent/runs/r%2F1/events")
    #expect(request.headers.isEmpty)
    #expect(request.query.isEmpty)
    #expect(request.idempotencyKey == nil)
    #expect(request.ifMatch == nil)
    guard case .none = request.body else {
      Issue.record("a request with no body carries one")
      return
    }
  }

  @Test("a write carries the key and the tag its caller passed")
  func keyAndTag() {
    let request = OperationRequest(
      facts: .deleteCollection,
      pathParameters: ["collection_id": "co"],
      idempotencyKey: "order-7f3a",
      ifMatch: "\"d43\""
    )

    #expect(request.idempotencyKey == "order-7f3a")
    #expect(request.ifMatch == "\"d43\"")
  }
}
