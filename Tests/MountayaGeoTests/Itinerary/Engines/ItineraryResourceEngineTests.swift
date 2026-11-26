import MountayaClient
import Testing

@testable import MountayaGeo

/// Every source here is a main-actor closure the test answers, so every step of an engine runs on
/// the main actor in order, and `settle()` lets a step land without a clock.
@Suite("ItineraryResourceEngine")
@MainActor
struct ItineraryResourceEngineTests {
  /// state names what an engine shows, as the contract's fixtures name it: `idle`, `resolving`,
  /// `failed`, or the read whose answer it shows.
  private func state(_ engine: ItineraryResourceEngine) -> String {
    switch engine.state {
    case .idle: "idle"
    case .resolving: "resolving"
    case .failed: "failed"
    case .resolved: shownRead(engine.state).map { "read-\($0)" } ?? "resolved"
    }
  }

  @Test("an engine with no id is idle and asks nothing")
  func idle() async {
    let reads = ScriptedReads()
    let engine = ItineraryResourceEngine(cache: ItineraryResourceCache(source: reads.source()))
    await settle()

    #expect(state(engine) == "idle")
    #expect(reads.sent.isEmpty)
  }

  /// A binding holds an empty id while it holds no itinerary; asked as an id, it would read as
  /// resolving and cost a read for no itinerary.
  @Test("an empty id is no id: the engine is idle and asks nothing, before and after an answer")
  func emptyId() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "")
    await settle()
    #expect(state(engine) == "idle")
    #expect(reads.sent.isEmpty)

    engine.configure(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.answer(0)
    await settle()
    engine.configure(cache: cache, itineraryId: "")

    #expect(state(engine) == "idle")
    #expect(reads.asked == ["a:itin-1:draft"])
    reads.drain()
  }

  @Test("an engine handed an id asks at once, and is resolving with nothing shown until it lands")
  func resolvesOnAnswer() async throws {
    let reads = ScriptedReads()
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source()), itineraryId: "itin-1")
    #expect(state(engine) == "resolving", "a question shows nothing as soon as it is asked")
    await settle()
    #expect(reads.asked == ["a:itin-1:draft"])

    reads.answer(0)
    await settle()

    guard case .resolved(let itinerary) = engine.state else {
      Issue.record("the engine shows \(state(engine))")
      return
    }
    #expect(itinerary.geometry != nil)
    #expect(itinerary.characteristics.distance == 1_000)
    #expect(itinerary.legs.map(\.id) == ["read-0"])
    #expect(itinerary.waypoints.isEmpty)
  }

  @Test("a failure shows no projection, only what the source threw")
  func failureShowsNothing() async {
    let reads = ScriptedReads()
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source()), itineraryId: "itin-1")
    await settle()

    reads.fail(0)
    await settle()

    guard case .failed(let error) = engine.state else {
      Issue.record("the engine shows \(state(engine))")
      return
    }
    #expect(error as? ScriptedReads.Failed == ScriptedReads.Failed(index: 0))
  }

  @Test("the published surface is asked when named, and kept apart from the draft")
  func publishedSurface() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let draft = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let published = ItineraryResourceEngine(
      cache: cache, itineraryId: "itin-1", surface: .published)
    await settle()

    reads.answer(1)
    await settle()

    #expect(reads.asked == ["a:itin-1:draft", "a:itin-1:published"])
    #expect(state(draft) == "resolving")
    #expect(state(published) == "read-1")
    reads.drain()
  }

  /// A profile and a table on one screen are the case the cache is for: a read per element is
  /// wrong by exactly one round trip.
  @Test("two engines over one itinerary and one cache make one read, and show one answer")
  func shareOneRead() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let profile = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let table = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()

    reads.answer(0)
    await settle()

    #expect(reads.sent.count == 1)
    guard case .resolved(let first) = profile.state, case .resolved(let second) = table.state
    else {
      Issue.record("the engines show \(state(profile)) and \(state(table))")
      return
    }
    #expect(first == second)
  }

  /// Two credentials may see two itineraries under one id: a shared answer would draw one reader's
  /// itinerary for the other.
  @Test("two caches asking one id each read their own answer")
  func cachesApart() async throws {
    let reads = ScriptedReads()
    let left = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source("a")), itineraryId: "itin-1")
    let right = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source("b")), itineraryId: "itin-1")
    await settle()

    reads.answer(0, distance: 1_000)
    reads.answer(1, distance: 2_000)
    await settle()

    #expect(reads.asked == ["a:itin-1:draft", "b:itin-1:draft"])
    #expect(distance(left) == 1_000)
    #expect(distance(right) == 2_000)
  }

  @Test("another cache is asked again, and nothing of the one before is shown meanwhile")
  func replacingCache() async {
    let reads = ScriptedReads()
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source("a")), itineraryId: "itin-1")
    await settle()
    reads.answer(0, distance: 1_000)
    await settle()

    engine.configure(
      cache: ItineraryResourceCache(source: reads.source("b")), itineraryId: "itin-1")
    #expect(state(engine) == "resolving")
    await settle()
    reads.answer(1, distance: 2_000)
    await settle()

    #expect(reads.asked == ["a:itin-1:draft", "b:itin-1:draft"])
    #expect(distance(engine) == 2_000)
  }

  @Test("an answer from a cache no longer asked never lands")
  func staleCache() async {
    let reads = ScriptedReads()
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source("a")), itineraryId: "itin-1")
    engine.configure(
      cache: ItineraryResourceCache(source: reads.source("b")), itineraryId: "itin-1")
    await settle()

    reads.answer(0)
    await settle()
    #expect(state(engine) == "resolving")

    reads.answer(1)
    await settle()
    #expect(state(engine) == "read-1")
  }

  @Test("an answer, or a failure, for an id no longer asked never lands")
  func staleId() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-a")
    await settle()
    engine.configure(cache: cache, itineraryId: "itin-b")
    await settle()

    reads.answer(1)
    await settle()
    reads.answer(0)
    await settle()
    #expect(state(engine) == "read-1")

    engine.configure(cache: cache, itineraryId: "itin-c")
    await settle()
    engine.configure(cache: cache, itineraryId: "itin-b")
    reads.fail(2)
    await settle()
    #expect(state(engine) == "read-1", "the answer held is shown again, and the failure is dropped")
    #expect(reads.asked == ["a:itin-a:draft", "a:itin-b:draft", "a:itin-c:draft"])
  }

  /// Between a question changing and its answer landing, the itinerary before is someone else's
  /// under this id, and showing it would call it current.
  @Test("a new id resolves with nothing of the one before it")
  func newIdShowsNothing() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-a")
    await settle()
    reads.answer(0)
    await settle()

    engine.configure(cache: cache, itineraryId: "itin-b")

    #expect(state(engine) == "resolving")
    reads.drain()
  }

  @Test("dropping the id returns to idle")
  func dropToIdle() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.answer(0)
    await settle()

    engine.configure(cache: cache, itineraryId: nil)

    #expect(state(engine) == "idle")
  }

  @Test("a question whose answer the cache holds is shown from it at once, with no read")
  func heldAnswerAtOnce() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-a")
    await settle()
    reads.answer(0)
    await settle()
    engine.configure(cache: cache, itineraryId: "itin-b")
    await settle()

    engine.configure(cache: cache, itineraryId: "itin-a")

    #expect(state(engine) == "read-0", "shown before the command returns")
    await settle()
    #expect(reads.asked == ["a:itin-a:draft", "a:itin-b:draft"])
    reads.drain()
  }

  @Test("the same question asked again asks nothing, and a failure is not asked again by it")
  func sameQuestion() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    for _ in 0..<3 {
      engine.configure(cache: cache, itineraryId: "itin-1")
    }
    reads.fail(0)
    await settle()
    for _ in 0..<3 {
      engine.configure(cache: cache, itineraryId: "itin-1")
    }
    await settle()

    #expect(reads.sent.count == 1)
    #expect(state(engine) == "failed")
  }

  /// A failed read is evicted at once: replaying a network blip for the life of the screen would
  /// keep every later element failed.
  @Test("a failure is not kept, so the next question asks again")
  func failureNotKept() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let failing = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.fail(0)
    await settle()

    let retry = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.answer(1)
    await settle()

    #expect(state(failing) == "failed")
    #expect(state(retry) == "read-1")
    #expect(reads.sent.count == 2)
  }

  /// A failed element asked again after an invalidation shows its failure until the new read fails,
  /// so a reader asking only whether the engine shows a failure never sees the second one land.
  @Test("a failure that replaces a failure is a state of its own, which a stream yields")
  func failureReplacesFailure() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let states = engine.subscribe()
    await settle()
    reads.fail(0)
    await settle()

    cache.invalidate(itineraryId: "itin-1")
    await settle()
    #expect(state(engine) == "failed", "the failure is shown until the new read lands")
    reads.fail(1)
    await settle()
    engine.close()

    guard case .failed(let error) = engine.state else {
      Issue.record("the engine shows \(state(engine))")
      return
    }
    #expect(error as? ScriptedReads.Failed == ScriptedReads.Failed(index: 1))
    var read: [String] = []
    for await state in states {
      switch state {
      case .failed(let error):
        read.append("failed-\((error as? ScriptedReads.Failed)?.index ?? -1)")
      case .idle: read.append("idle")
      case .resolving: read.append("resolving")
      case .resolved: read.append("resolved")
      }
    }
    #expect(read == ["resolving", "failed-0", "failed-1"])
  }

  @Test("a stream yields the state now, then every change in order, and ends at a close")
  func streams() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache)
    let states = engine.subscribe()

    engine.configure(cache: cache, itineraryId: "itin-1")
    engine.configure(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.answer(0)
    await settle()
    engine.configure(cache: cache, itineraryId: nil)
    engine.close()

    var read: [String] = []
    for await state in states {
      switch state {
      case .idle: read.append("idle")
      case .resolving: read.append("resolving")
      case .failed: read.append("failed")
      case .resolved: read.append(shownRead(state).map { "read-\($0)" } ?? "resolved")
      }
    }
    #expect(read == ["idle", "resolving", "read-0", "idle"])
  }

  @Test("a closed engine is inert: no answer lands, no question is asked, and its streams end")
  func closed() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    let early = engine.subscribe()

    engine.close()
    engine.close()
    reads.answer(0)
    engine.configure(cache: cache, itineraryId: "itin-2")
    await settle()

    #expect(state(engine) == "resolving")
    #expect(reads.sent.count == 1)
    var fromEarly = 0
    for await _ in early { fromEarly += 1 }
    #expect(fromEarly == 1, "the stream yielded the state it was returned with, then ended")
    var fromLate = 0
    for await _ in engine.subscribe() { fromLate += 1 }
    #expect(fromLate == 1, "a stream of a closed engine yields its state and ends")
  }

  /// The answer an engine stops waiting for is the cache's still: it is shared, so it is never
  /// cancelled, and an element asking next is shown it.
  @Test("an answer that lands after its engine closed is kept for the next engine")
  func answerOutlivesItsEngine() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let first = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    first.close()
    reads.answer(0)
    await settle()

    let next = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")

    #expect(state(next) == "read-0")
    #expect(reads.sent.count == 1)
  }

  @Test("an engine let go of ends its streams")
  func releasedEndsStreams() async {
    let reads = ScriptedReads()
    var engine: ItineraryResourceEngine? = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: reads.source()))
    let states = engine?.subscribe()
    engine = nil

    var count = 0
    if let states {
      for await _ in states { count += 1 }
    }
    #expect(count == 1)
  }

  private func distance(_ engine: ItineraryResourceEngine) -> Double? {
    guard case .resolved(let itinerary) = engine.state else { return nil }
    return itinerary.characteristics.distance
  }
}
