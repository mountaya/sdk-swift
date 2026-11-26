import Testing

@testable import MountayaClient

@Suite("AgentRunStream")
struct AgentRunStreamTests {
  @Test(
    "done ends the stream, an error and awaiting-input do not, and an unknown event is passed over")
  func roles() {
    func role(event: String, data: String) -> EventRole? {
      RestSchema.AgentRunEvent.read(EventRecord(event: event, data: data, id: "1-0"))?.role
    }

    #expect(role(event: "done", data: #"{"reason":"completed"}"#) == .end)
    #expect(role(event: "error", data: #"{"code":"rate-limited","message":"Slow."}"#) == .ordinary)
    #expect(role(event: "awaiting-input", data: "{}") == .ordinary)
    #expect(role(event: "reconnect", data: #"{"reason":"credential-expired"}"#) == .reconnect)
    #expect(role(event: "an-event-no-reader-knows", data: #"{"detail":"x"}"#) == nil)
    #expect(role(event: "message", data: #"{"content":7}"#) == nil)
  }

  @Test("every operation's stream of the vocabulary is an agent run's, and no event is an arrival")
  func rules() throws {
    let done = try #require(
      RestSchema.AgentRunEvent.read(
        EventRecord(event: "done", data: #"{"reason":"completed"}"#, id: "1-0")))

    #expect(RestSchema.AgentRunEvent.rules(for: "getAgentRunEvents") == .agentRun)
    #expect(done.event.arrivingMember == nil)
  }
}
