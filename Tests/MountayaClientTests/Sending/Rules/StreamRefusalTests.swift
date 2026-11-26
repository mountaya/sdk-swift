import Testing

@testable import MountayaClient

@Suite("StreamRefusal")
struct StreamRefusalTests {
  @Test(
    "an Accept naming an event stream among its ranges, in any case and with parameters, is one")
  func asksForStream() {
    #expect(StreamRefusal.asksForStream("text/event-stream"))
    #expect(StreamRefusal.asksForStream("Text/Event-Stream; charset=utf-8"))
    #expect(StreamRefusal.asksForStream("application/json, text/event-stream"))
    #expect(!StreamRefusal.asksForStream("application/json"))
    #expect(!StreamRefusal.asksForStream("text/event-streams"))
  }

  @Test("a buffered request asking for a stream is refused, and one with no Accept is not")
  func refused() {
    #expect(throws: MountayaError.self) { try StreamRefusal.check(["accept": "text/event-stream"]) }
    #expect(throws: Never.self) { try StreamRefusal.check([:]) }
  }
}
