import MountayaClient
import MountayaGeo
import RendererSupport
import Testing

@testable import MountayaElements

@Suite("ItineraryReading", .serialized)
@MainActor
struct ItineraryReadingTests {
  @Test("a question changes with the engine handed, or with the cache, the id or the surface")
  func question() {
    let cache = Itineraries.cache()
    let other = Itineraries.cache()
    let engine = ItineraryResourceEngine(cache: cache)
    let read = ItineraryReading.cache(cache, itineraryId: "itin_test", surface: nil)

    let same = ItineraryReading.cache(cache, itineraryId: "itin_test", surface: nil)
    let otherCache = ItineraryReading.cache(other, itineraryId: "itin_test", surface: nil)
    let otherId = ItineraryReading.cache(cache, itineraryId: "itin_b", surface: nil)
    #expect(read.question == same.question)
    #expect(read.question != otherCache.question)
    #expect(read.question != otherId.question)
    #expect(
      read.question
        != ItineraryReading.cache(cache, itineraryId: "itin_test", surface: .published).question)
    #expect(ItineraryReading.engine(engine).question == ItineraryReading.engine(engine).question)
    #expect(
      ItineraryReading.engine(engine).question
        != ItineraryReading.engine(ItineraryResourceEngine(cache: cache)).question)
    #expect(ItineraryReading.engine(engine).handed === engine)
    #expect(read.handed == nil)
    engine.close()
  }

  /// An element's own engine is made as it is first asked, and asked again as the question
  /// changes; the app's engine is followed and never asked.
  @Test("an element's own engine is made and asked, and the app's is followed and never asked")
  func read() async {
    let cache = Itineraries.cache()
    let failures = FailureRelay()
    let own = ItineraryReading.cache(cache, itineraryId: "itin_test", surface: nil)
      .read(nil, following: failures)

    #expect(own != nil)
    #expect(await MapWindow.until { if case .resolved? = own?.state { true } else { false } })
    let again = ItineraryReading.cache(cache, itineraryId: nil, surface: nil)
      .read(own, following: failures)
    #expect(again === own, "an element keeps its own engine")
    #expect(await MapWindow.until { if case .idle? = own?.state { true } else { false } })

    let handed = ItineraryResourceEngine(cache: cache)
    let kept = ItineraryReading.engine(handed).read(own, following: failures)
    #expect(kept === own)
    _ = await MapWindow.until(0.3) { false }
    if case .idle = handed.state {} else { Issue.record("an engine handed is never asked") }
    handed.close()
    own?.close()
  }
}
