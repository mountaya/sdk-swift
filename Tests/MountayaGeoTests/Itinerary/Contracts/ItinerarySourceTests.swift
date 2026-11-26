import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ItinerarySource")
@MainActor
struct ItinerarySourceTests {
  /// Asked keeps every read a source is handed, off the main actor, where an app's source runs.
  private actor Asked {
    var reads: [String] = []

    func record(_ itineraryId: String, surface: RestSchema.ReadSurface?) {
      reads.append("\(itineraryId):\(surface?.rawValue ?? "draft")")
    }
  }

  @Test("a source is the app's async call, handed the id and the surface the engine asks about")
  func handedTheQuestion() async throws {
    let asked = Asked()
    let source: ItinerarySource = { itineraryId, surface in
      await asked.record(itineraryId, surface: surface)
      return restItinerary(
        itineraryId, segments: [restSegment("s1", geojson: lineString([6, 45], [6.01, 45]))])
    }
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache(source: source), itineraryId: "itin_abc",
      surface: .published)
    let states = engine.subscribe()

    for await state in states {
      if case .resolved = state { break }
    }

    #expect(await asked.reads == ["itin_abc:published"])
    #expect(shownLegs(engine.state) == ["s1"])
    engine.close()
  }

  @Test("what a source throws is the element's failure")
  func throwsFailure() async throws {
    struct Offline: Error {}
    let engine = ItineraryResourceEngine(
      cache: ItineraryResourceCache { _, _ in throw Offline() }, itineraryId: "itin_abc")
    let states = engine.subscribe()

    var failure: (any Error)?
    for await state in states {
      if case .failed(let error) = state {
        failure = error
        break
      }
    }

    #expect(failure is Offline)
    engine.close()
  }

  private func shownLegs(_ state: ItineraryResource) -> [String] {
    guard case .resolved(let itinerary) = state else { return [] }
    return itinerary.legs.map(\.id)
  }
}
