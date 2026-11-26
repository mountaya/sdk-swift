import Testing

@testable import MountayaClient

@Suite("EventRecord")
struct EventRecordTests {
  @Test("a stream read by its declaration hands every record on, and reads only a reconnect")
  func readAsAFeed() throws {
    let message = try #require(
      EventRecord.read(EventRecord(event: "message", data: "a", id: "1-0")))
    let reconnect = try #require(
      EventRecord.read(EventRecord(event: "reconnect", data: "{}", id: nil)))

    #expect(message.event.data == "a")
    #expect(message.role == .ordinary)
    #expect(reconnect.role == .reconnect)
    #expect(EventRecord.rules == .collaborationFeed)
  }
}
