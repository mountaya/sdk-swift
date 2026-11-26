import Testing

@testable import MountayaClient

@Suite("EventStream")
struct EventStreamTests {
  private struct Dropped: Error {}

  @Test("each iteration opens the stream afresh and reads its frames in order")
  func cold() async throws {
    let stream = EventStream(frames: [
      EventFrame(id: "1", event: 10), EventFrame(id: "2", event: 20),
    ])

    for _ in 0..<2 {
      var events: [Int] = []
      for try await frame in stream {
        events.append(frame.event)
      }
      #expect(events == [10, 20])
    }
  }

  /// Failing hands on one frame, then fails.
  private final class Failing: FrameReading {
    private var handed = false

    func next() async throws -> EventFrame<Int>? {
      guard !handed else { throw Dropped() }
      handed = true
      return EventFrame(id: "1", event: 1)
    }
  }

  @Test("a failure ends the iteration with the error the stream raised")
  func failure() async {
    let stream = EventStream<Int> { _ in Failing() }
    var events: [Int] = []

    await #expect(throws: Dropped.self) {
      for try await frame in stream {
        events.append(frame.event)
      }
    }
    #expect(events == [1])
  }

  /// Member records the user each iteration's open was handed.
  private final class Member: FrameReading {
    let member: String?

    init(_ member: String?) {
      self.member = member
    }

    func next() async throws -> EventFrame<RestSchema.CollabStreamEvent>? {
      nil
    }
  }

  @Test("a collaboration stream read as a user opens every iteration as that user, and only it")
  func readsAsUser() {
    let stream = EventStream<RestSchema.CollabStreamEvent> { Member($0) }
    let member = stream.reading(asUser: "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1")

    #expect((stream.makeAsyncIterator().reading as? Member)?.member == nil)
    #expect(
      (member.makeAsyncIterator().reading as? Member)?.member
        == "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1")
    #expect(
      (member.reading(asUser: "2b8d4f19").makeAsyncIterator().reading as? Member)?.member
        == "2b8d4f19")
  }
}
