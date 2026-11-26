import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("pickTarget")
struct PickTargetTests {
  private static let box = [6.8, 45.8, 6.9, 45.9]

  @Test("a place is framed on its extent, else flown to at the point zoom, and marked at its point")
  func place() {
    #expect(pointZoom == 13)
    #expect(
      pickTarget(.place(point: [6.86, 45.83], bounds: Self.box))
        == SearchPick(camera: .fit(bounds: Self.box), mark: .place(point: [6.86, 45.83])))
    #expect(
      pickTarget(.place(point: [6.86, 45.83], bounds: nil))
        == SearchPick(
          camera: .fly(center: [6.86, 45.83], zoom: 13), mark: .place(point: [6.86, 45.83])))
    #expect(
      pickTarget(.place(point: [179.9, -16.5], bounds: [179.5, -17, -179.5, -16])).camera
        == .fit(bounds: [179.5, -17, -179.5, -16]), "an extent across the antimeridian as written")
  }

  @Test("a point of interest is flown to and marked as its category, or as none")
  func poi() {
    #expect(
      pickTarget(.poi(point: [6.85, 45.84], category: .hut))
        == SearchPick(
          camera: .fly(center: [6.85, 45.84], zoom: 13),
          mark: .poi(point: [6.85, 45.84], category: .hut)))
    #expect(
      pickTarget(.poi(point: [6.85, 45.84], category: nil)).mark
        == .poi(point: [6.85, 45.84], category: nil))
  }

  @Test("a way is framed on its extent, else flown to its anchor, and marked as itself")
  func way() {
    let line = [[6.8, 45.8], [6.86, 45.83], [6.9, 45.9]]
    #expect(
      pickTarget(.way(anchor: [6.86, 45.83], bounds: Self.box, coordinates: line))
        == SearchPick(
          camera: .fit(bounds: Self.box),
          mark: .way(anchor: [6.86, 45.83], bounds: Self.box, coordinates: line)))
    #expect(
      pickTarget(.way(anchor: [6.86, 45.83], bounds: nil, coordinates: nil))
        == SearchPick(
          camera: .fly(center: [6.86, 45.83], zoom: 13),
          mark: .way(anchor: [6.86, 45.83], bounds: nil, coordinates: nil)))
  }

  @Test("an itinerary is marked at its start and a zone at its point, each as a place")
  func itineraryAndZone() {
    #expect(
      pickTarget(.itinerary(itineraryId: "it-1", bounds: Self.box, start: [6.82, 45.82]))
        == SearchPick(camera: .fit(bounds: Self.box), mark: .place(point: [6.82, 45.82])))
    #expect(
      pickTarget(.itinerary(itineraryId: "it-1", bounds: Self.box, start: nil))
        == SearchPick(camera: .fit(bounds: Self.box), mark: nil))
    #expect(
      pickTarget(.itinerary(itineraryId: "it-1", bounds: nil, start: [6.82, 45.82]))
        == SearchPick(
          camera: .fly(center: [6.82, 45.82], zoom: 13), mark: .place(point: [6.82, 45.82])))
    #expect(
      pickTarget(.itinerary(itineraryId: "it-1", bounds: nil, start: nil))
        == SearchPick(camera: nil, mark: nil))
    #expect(
      pickTarget(.zone(zoneId: "zone-1", point: [6.88, 45.88], bounds: nil))
        == SearchPick(
          camera: .fly(center: [6.88, 45.88], zoom: 13), mark: .place(point: [6.88, 45.88])))
    #expect(
      pickTarget(.zone(zoneId: "zone-1", point: [6.88, 45.88], bounds: Self.box))
        == SearchPick(camera: .fit(bounds: Self.box), mark: .place(point: [6.88, 45.88])))
  }

  @Test("a collection moves nothing and marks nothing")
  func collection() {
    #expect(
      pickTarget(
        .collection(collectionId: "col-1", name: "Alpine", description: nil, isPrivate: false))
        == SearchPick(camera: nil, mark: nil))
  }
}
