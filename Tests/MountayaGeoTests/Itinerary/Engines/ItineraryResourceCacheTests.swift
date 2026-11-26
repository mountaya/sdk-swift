import MountayaClient
import Testing

@testable import MountayaGeo

/// Every source here is a main-actor closure the test answers, so every step runs on the main
/// actor in order, and `settle()` lets a step land without a clock.
@Suite("ItineraryResourceCache")
@MainActor
struct ItineraryResourceCacheTests {
  /// readOnce has an element ask about `itineraryId` once and go, as one drawn for a moment does.
  private func readOnce(
    _ cache: ItineraryResourceCache, itineraryId: String,
    surface: RestSchema.ReadSurface? = nil
  ) {
    ItineraryResourceEngine(cache: cache, itineraryId: itineraryId, surface: surface).close()
  }

  @Test("a cache keeps 16 answers, the capacity geo/itinerary-cache.json declares")
  func capacity() {
    #expect(ItineraryResourceCache.capacity == 16)
  }

  @Test("the answers read most recently are kept to the bound, the oldest asked for again")
  func bound() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    for index in 0...ItineraryResourceCache.capacity {
      readOnce(cache, itineraryId: "i-\(index)")
      await settle()
      reads.answer(reads.sent.count - 1)
      await settle()
      // Reading the first id again keeps it the most recent.
      if index == 1 {
        readOnce(cache, itineraryId: "i-0")
        await settle()
      }
    }
    #expect(reads.sent.count == ItineraryResourceCache.capacity + 1)

    readOnce(cache, itineraryId: "i-0")
    await settle()
    #expect(reads.sent.count == ItineraryResourceCache.capacity + 1, "i-0 is kept")

    readOnce(cache, itineraryId: "i-1")
    await settle()
    #expect(reads.sent.count == ItineraryResourceCache.capacity + 2, "i-1 was dropped")
    reads.drain()
  }

  /// A read in flight is counted, as the first SDK's promise is: dropped past the bound, it still
  /// lands for the engines waiting on it, and is not kept.
  @Test("a read dropped past the bound while in flight lands for its engine, and is not kept")
  func droppedInFlight() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let waiting = ItineraryResourceEngine(cache: cache, itineraryId: "first")
    await settle()
    for index in 1...ItineraryResourceCache.capacity {
      readOnce(cache, itineraryId: "i-\(index)")
    }
    await settle()

    reads.answer(0)
    await settle()
    #expect(shownRead(waiting.state) == 0)

    readOnce(cache, itineraryId: "first")
    await settle()
    #expect(reads.sent.count == ItineraryResourceCache.capacity + 2, "first was asked for again")
    reads.drain()
  }

  @Test("an engine asking while a read is out joins it")
  func joinsRead() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let profile = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let table = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()

    reads.answer(0)
    await settle()

    #expect(reads.sent.count == 1)
    #expect(shownRead(profile.state) == 0)
    #expect(shownRead(table.state) == 0)
  }

  @Test("answers are kept apart by cache and by surface")
  func keptApart() async {
    let reads = ScriptedReads()
    let a = ItineraryResourceCache(source: reads.source("a"))
    let b = ItineraryResourceCache(source: reads.source("b"))
    let draft = ItineraryResourceEngine(cache: a, itineraryId: "itin-1")
    let other = ItineraryResourceEngine(cache: b, itineraryId: "itin-1")
    let published = ItineraryResourceEngine(
      cache: a, itineraryId: "itin-1", surface: .published)
    await settle()

    for index in 0..<3 { reads.answer(index) }
    await settle()

    #expect(reads.asked == ["a:itin-1:draft", "b:itin-1:draft", "a:itin-1:published"])
    #expect([draft, other, published].map { shownRead($0.state) } == [0, 1, 2])
  }

  @Test("a failure is dropped at once, so the next question asks again")
  func failureDropped() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let chart = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.fail(0)
    await settle()

    let table = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.answer(1)
    await settle()

    #expect(reads.sent.count == 2)
    if case .failed = chart.state {} else { Issue.record("the chart shows \(chart.state)") }
    #expect(shownRead(table.state) == 1)
  }

  @Test("an invalidation asks again on both surfaces for every engine watching, once per answer")
  func invalidation() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let draft = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let twin = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let published = ItineraryResourceEngine(
      cache: cache, itineraryId: "itin-1", surface: .published)
    let other = ItineraryResourceEngine(cache: cache, itineraryId: "itin-2")
    await settle()
    for index in 0..<3 { reads.answer(index) }
    await settle()

    cache.invalidate(itineraryId: "itin-1")
    await settle()

    #expect(Array(reads.asked.dropFirst(3)) == ["a:itin-1:draft", "a:itin-1:published"])
    #expect(shownRead(draft.state) == 0, "each shows what it showed until the new answer lands")
    #expect(shownRead(published.state) == 1)

    reads.answer(3)
    await settle()

    #expect(shownRead(draft.state) == 3)
    #expect(shownRead(twin.state) == 3)
    #expect(shownRead(published.state) == 1)
    #expect(shownRead(other.state) == 2)
    reads.drain()
  }

  @Test("an invalidation of no itinerary drops every answer of its cache and no other")
  func wholeInvalidation() async {
    let reads = ScriptedReads()
    let a = ItineraryResourceCache(source: reads.source("a"))
    let b = ItineraryResourceCache(source: reads.source("b"))
    let one = ItineraryResourceEngine(cache: a, itineraryId: "itin-1")
    let two = ItineraryResourceEngine(cache: a, itineraryId: "itin-2")
    let elsewhere = ItineraryResourceEngine(cache: b, itineraryId: "itin-1")
    await settle()
    for index in 0..<3 { reads.answer(index) }
    await settle()

    a.invalidate()
    await settle()

    #expect(Array(reads.asked.dropFirst(3)) == ["a:itin-1:draft", "a:itin-2:draft"])
    #expect([one, two, elsewhere].map { shownRead($0.state) } == [0, 1, 2])
    reads.drain()
  }

  @Test("an engine asking after an invalidation asks again, and no engine watching is asked for")
  func askAfterInvalidation() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    readOnce(cache, itineraryId: "itin-1")
    await settle()
    reads.answer(0)
    await settle()

    cache.invalidate(itineraryId: "itin-1")
    await settle()
    #expect(reads.sent.count == 1, "nothing watches, so nothing is asked")

    readOnce(cache, itineraryId: "itin-1")
    await settle()
    #expect(reads.asked == ["a:itin-1:draft", "a:itin-1:draft"])
    reads.drain()
  }

  /// The failure of a read an invalidation replaced must not evict the read that replaced it.
  @Test("a replaced read's failure leaves the answer that replaced it in the cache")
  func replacedReadFails() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let watching = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()

    cache.invalidate(itineraryId: "itin-1")
    await settle()
    reads.fail(0)
    reads.answer(1)
    await settle()

    let late = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    #expect(reads.sent.count == 2)
    #expect(shownRead(late.state) == 1)
    #expect(shownRead(watching.state) == 1, "the replaced read's failure never lands")
  }

  /// A failed element is watching still: the app's invalidation is how it is read again.
  @Test("an invalidation asks again for a failed engine, which shows its failure until it lands")
  func invalidationRetriesFailure() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    await settle()
    reads.fail(0)
    await settle()

    cache.invalidate()
    await settle()
    if case .failed = engine.state {} else { Issue.record("the engine shows \(engine.state)") }

    reads.answer(1)
    await settle()
    #expect(shownRead(engine.state) == 1)
  }

  @Test("a closed engine, an idle one and one let go of are not asked for by an invalidation")
  func notWatching() async {
    let reads = ScriptedReads()
    let cache = ItineraryResourceCache(source: reads.source())
    let closed = ItineraryResourceEngine(cache: cache, itineraryId: "itin-1")
    let idle = ItineraryResourceEngine(cache: cache)
    var released: ItineraryResourceEngine? = ItineraryResourceEngine(
      cache: cache, itineraryId: "itin-2")
    await settle()
    reads.answer(0)
    reads.answer(1)
    await settle()
    closed.close()
    released = nil

    cache.invalidate()
    await settle()

    #expect(reads.sent.count == 2)
    #expect(released == nil)
    if case .idle = idle.state {} else { Issue.record("the idle engine shows \(idle.state)") }
  }

  @Test("an engine moved to another cache is asked for by that cache's invalidations alone")
  func movedEngine() async {
    let reads = ScriptedReads()
    let a = ItineraryResourceCache(source: reads.source("a"))
    let b = ItineraryResourceCache(source: reads.source("b"))
    let engine = ItineraryResourceEngine(cache: a, itineraryId: "itin-1")
    engine.configure(cache: b, itineraryId: "itin-1")
    await settle()
    #expect(reads.asked == ["a:itin-1:draft", "b:itin-1:draft"])

    a.invalidate()
    await settle()
    #expect(reads.sent.count == 2, "the cache it left asks nothing for it")

    b.invalidate()
    await settle()
    #expect(Array(reads.asked.dropFirst(2)) == ["b:itin-1:draft"])
    reads.drain()
  }

  /// Nobody can receive the answer of a cache let go of, so the read is cancelled; a source that
  /// honours cancellation ends its call then.
  @Test("a cache let go of cancels its reads in flight")
  func releasedCacheCancels() async {
    let (outcomes, report) = AsyncStream.makeStream(of: Bool.self)
    var cache: ItineraryResourceCache? = ItineraryResourceCache { @MainActor itineraryId, _ in
      do {
        try await Task.sleep(for: .seconds(3_600))
        report.yield(false)
      } catch {
        report.yield(true)
      }
      return restItinerary(itineraryId)
    }
    if let cache {
      ItineraryResourceEngine(cache: cache, itineraryId: "itin-1").close()
    }
    await settle()

    cache = nil

    var cancelled = outcomes.makeAsyncIterator()
    #expect(await cancelled.next() == true)
  }
}
