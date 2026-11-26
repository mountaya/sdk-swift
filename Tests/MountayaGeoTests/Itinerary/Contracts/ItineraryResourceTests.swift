import Testing

@testable import MountayaGeo

@Suite("ItineraryResource")
struct ItineraryResourceTests {
  private struct Unreachable: Error {}

  @Test("a resolved resource holds every projection of its itinerary at once")
  func resolved() throws {
    let itinerary = ResolvedItinerary(
      restItinerary(segments: [restSegment("s1", geojson: lineString([6, 45], [6.01, 45]))]))
    let resource = ItineraryResource.resolved(itinerary)

    guard case .resolved(let shown) = resource else {
      Issue.record("a resolved resource reads as \(resource)")
      return
    }
    #expect(shown == itinerary)
    #expect(shown.legs.map(\.id) == ["s1"])
  }

  @Test("a failed resource holds what its source threw, and shows nothing")
  func failed() {
    let resource = ItineraryResource.failed(Unreachable())

    guard case .failed(let error) = resource else {
      Issue.record("a failed resource reads as \(resource)")
      return
    }
    #expect(error is Unreachable)
  }

  @Test("an idle and a resolving resource hold nothing")
  func holdsNothing() {
    for resource in [ItineraryResource.idle, .resolving] {
      if case .resolved = resource { Issue.record("\(resource) shows an itinerary") }
      if case .failed = resource { Issue.record("\(resource) shows a failure") }
    }
  }
}
