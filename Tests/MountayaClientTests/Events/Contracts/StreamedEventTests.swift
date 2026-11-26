import Testing

@testable import MountayaClient

@Suite("StreamedEvent")
struct StreamedEventTests {
  @Test("a record's event name is folded into its type, whatever its data says")
  func folded() throws {
    let record = EventRecord(
      event: "message", data: #"{"type":"done","content":"Hi","message_index":0}"#, id: nil)
    let event = try #require(RestSchema.AgentRunEvent.decoded(record))

    guard case .AgentMessageEvent(let message) = event else {
      Issue.record("the record's event name did not decide its member")
      return
    }
    #expect(message.content == "Hi")
  }

  @Test("data that is no JSON object is passed over")
  func notJson() {
    #expect(
      RestSchema.AgentRunEvent.decoded(EventRecord(event: "message", data: "a", id: nil)) == nil)
    #expect(
      RestSchema.AgentRunEvent.decoded(EventRecord(event: "message", data: "[1]", id: nil)) == nil)
  }
}
