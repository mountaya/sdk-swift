import MountayaGeo
import RendererSupport
import Testing

@testable import MountayaElements

/// Each cache's reads land in a task of its own, so a test waits on what the relay is handed.
@Suite("FailureRelay", .serialized)
@MainActor
struct FailureRelayTests {
  /// named is a failure as a test reads it: its type's name.
  private static func named(_ error: any Error) -> String {
    String(describing: type(of: error))
  }

  /// An invalidation asks a failed engine again, and it shows its failure until the new read fails:
  /// whether it shows a failure never changes, and the second failure is handed on all the same.
  @Test("each failure the engine shows is handed on once, one that replaces a failure included")
  func eachFailureOnce() async {
    let cache = Itineraries.unreadable()
    let engine = ItineraryResourceEngine(cache: cache)
    let handed = Held<[String]>([])
    let relay = FailureRelay()
    relay.hold { handed.value.append(Self.named($0)) }
    relay.follow(engine)
    relay.follow(engine)

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(await MapWindow.until { handed.value.count == 1 }, "\(handed.value)")
    cache.invalidate(itineraryId: "itin_test")
    #expect(await MapWindow.until { handed.value.count == 2 }, "\(handed.value)")
    // Long enough for a failure handed twice to be heard twice.
    _ = await MapWindow.until(1) { false }

    #expect(handed.value == ["Unreadable", "Unreadable"], "following twice follows once")
  }

  @Test("nothing but a failure is handed on, each to the handler held as it lands")
  func latestHandler() async {
    let answered = Itineraries.cache()
    let engine = ItineraryResourceEngine(cache: answered)
    let first = Held<[String]>([])
    let second = Held<[String]>([])
    let relay = FailureRelay()
    relay.hold { first.value.append(Self.named($0)) }
    relay.follow(engine)

    engine.configure(cache: answered, itineraryId: "itin_test")
    #expect(await MapWindow.until { Self.isResolved(engine.state) })
    engine.configure(cache: answered, itineraryId: nil)
    _ = await MapWindow.until(1) { false }
    #expect(first.value.isEmpty, "resolving, an answer and idle are no failure")

    let unreadable = Itineraries.unreadable()
    engine.configure(cache: unreadable, itineraryId: "itin_test")
    #expect(await MapWindow.until { first.value.count == 1 }, "\(first.value)")
    relay.hold { second.value.append(Self.named($0)) }
    unreadable.invalidate(itineraryId: "itin_test")
    #expect(await MapWindow.until { second.value.count == 1 }, "\(second.value)")

    #expect(first.value == ["Unreadable"])
    #expect(second.value == ["Unreadable"])
  }

  /// An app may hand an element another engine: the relay follows the one handed last, and lets the
  /// one before it go.
  @Test("a relay follows the engine handed in place of another, and hands nothing of the first")
  func anotherEngine() async {
    let first = Itineraries.unreadable()
    let second = Itineraries.unreadable()
    let before = ItineraryResourceEngine(cache: first)
    let after = ItineraryResourceEngine(cache: second)
    let handed = Held<[String]>([])
    let relay = FailureRelay()
    relay.hold { handed.value.append(Self.named($0)) }
    relay.follow(before)
    relay.follow(after)

    before.configure(cache: first, itineraryId: "itin_test")
    #expect(await MapWindow.until { Self.isFailed(before.state) })
    _ = await MapWindow.until(0.5) { false }
    #expect(handed.value.isEmpty, "the engine let go of hands nothing on")
    after.configure(cache: second, itineraryId: "itin_test")
    #expect(await MapWindow.until { handed.value == ["Unreadable"] }, "\(handed.value)")
    before.close()
    after.close()
  }

  /// The relay's task holds it weakly, so an element's state let go of takes the relay with it.
  @Test("a relay let go of hands nothing more")
  func released() async {
    let cache = Itineraries.unreadable()
    let engine = ItineraryResourceEngine(cache: cache)
    let handed = Held<[String]>([])
    var relay: FailureRelay? = FailureRelay()
    relay?.hold { handed.value.append(Self.named($0)) }
    relay?.follow(engine)
    relay = nil

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(await MapWindow.until { Self.isFailed(engine.state) })
    _ = await MapWindow.until(1) { false }

    #expect(handed.value.isEmpty)
  }

  /// isResolved tells whether an engine shows an itinerary.
  private static func isResolved(_ state: ItineraryResource) -> Bool {
    if case .resolved = state { return true }
    return false
  }

  /// isFailed tells whether an engine shows a failure.
  private static func isFailed(_ state: ItineraryResource) -> Bool {
    if case .failed = state { return true }
    return false
  }
}
