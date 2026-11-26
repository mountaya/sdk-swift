import MountayaClient
import MountayaGeo
import RendererSupport
import Testing

@testable import MountayaElements

@Suite("MapLink")
@MainActor
struct MapLinkTests {
  private static let stretch = GeoJSONGeometry.lineString(
    GeoJSONLineString(coordinates: [[6, 45], [6, 45.01]]))
  private static let target = MapTarget(lngLat: [6, 45.005], stretch: stretch)

  /// Told is every value an element tells the handler an app hands it.
  final class Told {
    var values: [String?] = []
  }

  @Test("pointing writes the target to the map, and letting go takes down what it wrote")
  func points() throws {
    let map = try Maps.engine()
    var link = MapLink<String>(markerId: profileCursorMarkerId)
    link.point(
      at: "climb", value: "climb", target: Self.target, isEnabled: true, onHover: nil, map: map,
      markerColor: "#e03131", emphasisColor: "#2f9e44")

    let marker = try #require(map.state.markers.first)
    #expect(link.pointed == "climb")
    #expect(map.state.markers.count == 1)
    #expect(marker.id == profileCursorMarkerId)
    #expect(marker.position == [6, 45.005])
    #expect(marker.color == "#e03131")
    #expect(marker.glyph == cursorMarkerGlyph, "the filled pin, the pin's dot on the marker set")
    #expect(map.geometry(in: .emphasis) == SlotGeometry(geometry: Self.stretch, color: "#2f9e44"))
    #expect(link.isLit)

    link.point(
      at: nil, value: String?.none, target: MapTarget(), isEnabled: true, onHover: nil, map: map,
      markerColor: nil, emphasisColor: nil)
    #expect(link.pointed == nil)
    #expect(map.state.markers.isEmpty)
    #expect(map.geometry(in: .emphasis).geometry == nil)
    #expect(!link.isLit && link.pinned == nil)
  }

  @Test("pointing where it already points tells nothing, and a disabled element only lets go")
  func unchanged() throws {
    let map = try Maps.engine()
    let told = Told()
    var link = MapLink<String>(markerId: "mine")
    let tell = { (value: String?) in told.values.append(value) }

    link.point(
      at: "a", value: "a", target: Self.target, isEnabled: true, onHover: tell, map: map,
      markerColor: nil, emphasisColor: nil)
    link.point(
      at: "a", value: "a", target: Self.target, isEnabled: true, onHover: tell, map: map,
      markerColor: nil, emphasisColor: nil)
    #expect(told.values == ["a"])

    link.point(
      at: "b", value: "b", target: Self.target, isEnabled: false, onHover: tell, map: map,
      markerColor: nil, emphasisColor: nil)
    #expect(told.values == ["a"], "a disabled element points at nothing new")
    #expect(link.pointed == "a")

    link.point(
      at: nil, value: String?.none, target: MapTarget(), isEnabled: false, onHover: tell,
      map: map, markerColor: nil, emphasisColor: nil)
    #expect(told.values == ["a", nil], "the row pointed at is let go, and the leave is told once")
    link.point(
      at: nil, value: String?.none, target: MapTarget(), isEnabled: false, onHover: tell,
      map: map, markerColor: nil, emphasisColor: nil)
    #expect(told.values == ["a", nil])
  }

  @Test("an onHover handler takes the map over, and no map is written nothing")
  func handed() throws {
    let map = try Maps.engine()
    let told = Told()
    var handed = MapLink<String>(markerId: "mine")
    handed.point(
      at: "a", value: "a", target: Self.target, isEnabled: true,
      onHover: { told.values.append($0) }, map: map, markerColor: nil, emphasisColor: nil)
    #expect(told.values == ["a"])
    #expect(map.state.markers.isEmpty)
    #expect(map.geometry(in: .emphasis).geometry == nil)

    var mapless = MapLink<String>(markerId: "mine")
    mapless.point(
      at: "a", value: "a", target: Self.target, isEnabled: true, onHover: nil, map: nil,
      markerColor: nil, emphasisColor: nil)
    #expect(mapless.pointed == "a", "the row is lit all the same")
  }

  @Test("a move takes the marker along, and a stretch named no colour is the slot's own")
  func moves() throws {
    let map = try Maps.engine()
    var link = MapLink<Int>(markerId: "mine")
    link.write(MapTarget(lngLat: [6, 45]), on: map, markerColor: nil, emphasisColor: nil)
    link.write(
      MapTarget(lngLat: [6, 45.01], stretch: Self.stretch), on: map, markerColor: nil,
      emphasisColor: nil)

    #expect(map.state.markers.map(\.id) == ["mine"])
    #expect(map.state.markers.first?.position == [6, 45.01])
    #expect(map.geometry(in: .emphasis).color == GeometrySlot.emphasis.color)
  }

  @Test("an element takes down only what it wrote: another's marker and another's stretch stay")
  func ownOnly() throws {
    let map = try Maps.engine()
    try map.addMarker(MapMarker(id: "other", position: [6.1, 45]))
    map.setGeometry(Self.stretch, in: .emphasis)
    var link = MapLink<Int>(markerId: "mine")
    link.write(MapTarget(), on: map, markerColor: nil, emphasisColor: nil)

    #expect(map.state.markers.map(\.id) == ["other"])
    #expect(map.geometry(in: .emphasis).geometry == Self.stretch)
  }

  @Test("a marker something else took down is pinned again at the next move")
  func pinnedAgain() throws {
    let map = try Maps.engine()
    var link = MapLink<Int>(markerId: "mine")
    link.write(MapTarget(lngLat: [6, 45]), on: map, markerColor: nil, emphasisColor: nil)
    map.removeMarker("mine")
    link.write(MapTarget(lngLat: [6, 45.01]), on: map, markerColor: nil, emphasisColor: nil)

    #expect(map.state.markers.map(\.position) == [[6, 45.01]])
  }

  @Test("a position the map refuses leaves the marker where it stood")
  func refused() throws {
    let map = try Maps.engine()
    var link = MapLink<Int>(markerId: "mine")
    link.write(MapTarget(lngLat: [6, 45]), on: map, markerColor: nil, emphasisColor: nil)
    link.write(MapTarget(lngLat: [6, 95]), on: map, markerColor: nil, emphasisColor: nil)

    #expect(map.state.markers.map(\.position) == [[6, 45]])
  }
}
