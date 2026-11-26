import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchRowPayload")
struct SearchRowPayloadTests {
  @Test("two payloads are equal where they hold the same values, each number the same number")
  func equality() {
    #expect(
      SearchRowPayload.place(point: [6, .nan], bounds: nil)
        == .place(point: [6, .nan], bounds: nil))
    #expect(
      SearchRowPayload.place(point: [0, 45], bounds: nil) != .place(point: [-0.0, 45], bounds: nil))
    #expect(
      SearchRowPayload.collection(collectionId: "c", name: "n", description: nil, isPrivate: true)
        == .collection(collectionId: "c", name: "n", description: nil, isPrivate: true))
    #expect(
      SearchRowPayload.zone(zoneId: "z", point: nil, bounds: nil)
        != .itinerary(itineraryId: "z", bounds: nil, start: nil))
    #expect(
      SearchRowPayload.way(anchor: [6, 45], bounds: nil, coordinates: [[6, .nan]])
        == .way(anchor: [6, 45], bounds: nil, coordinates: [[6, .nan]]))
    #expect(
      SearchRowPayload.poi(point: [6, .nan], category: .hut).hashValue
        == SearchRowPayload.poi(point: [6, .nan], category: .hut).hashValue)
  }

  @Test("two payloads are told apart by the scalars of their texts")
  func scalars() {
    #expect(
      SearchRowPayload.itinerary(itineraryId: "\u{E9}", bounds: nil, start: nil)
        != .itinerary(itineraryId: "e\u{301}", bounds: nil, start: nil))
    #expect(
      SearchRowPayload.collection(
        collectionId: "c", name: "\u{E9}", description: nil, isPrivate: nil)
        != .collection(collectionId: "c", name: "e\u{301}", description: nil, isPrivate: nil))
    #expect(
      SearchRowPayload.collection(
        collectionId: "c", name: nil, description: "\u{E9}", isPrivate: nil)
        != .collection(collectionId: "c", name: nil, description: "e\u{301}", isPrivate: nil))
    #expect(
      SearchRowPayload.zone(zoneId: "\u{E9}", point: nil, bounds: nil)
        != .zone(zoneId: "e\u{301}", point: nil, bounds: nil))
    #expect(
      SearchRowPayload.poi(point: [6, 45], category: DataSchema.POICategory(rawValue: "\u{E9}"))
        != .poi(point: [6, 45], category: DataSchema.POICategory(rawValue: "e\u{301}")))
  }
}
