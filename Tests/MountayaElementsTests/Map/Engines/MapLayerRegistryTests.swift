import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("MapLayerRegistry")
struct MapLayerRegistryTests {
  private static func layer(_ id: String, rank: LayerRank, source: String = "s") -> MapLayer {
    MapLayer(id: id, type: .line, source: source, rank: rank.rank)
  }

  @Test("layers draw by rank whatever order they were added in, two of one rank the later above")
  func ranked() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("pois", rank: .poi))
    registry.add(Self.layer("route", rank: .itineraryLine))
    registry.add(Self.layer("shade", rank: .hillshade))
    registry.add(Self.layer("detour", rank: .itineraryLine))
    registry.add(Self.layer("cursor", rank: .chrome))

    #expect(registry.layers.map(\.id) == ["shade", "route", "detour", "pois", "cursor"])
  }

  @Test("a rank between two bands draws between them")
  func between() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("pois", rank: .poi))
    registry.add(Self.layer("waypoints", rank: .itineraryPoint))
    registry.add(
      MapLayer(id: "mine", type: .line, source: "s", rank: LayerRank.poi.rank + 2))

    // 82 stands between the points of interest and the waypoints, a band of no layer of Mountaya's.
    #expect(registry.layers.map(\.id) == ["pois", "mine", "waypoints"])
  }

  @Test("a layer placed again at the rank it holds keeps its place and takes its new definition")
  func replaces() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("route", rank: .itineraryLine))
    registry.add(Self.layer("detour", rank: .itineraryLine))
    registry.add(Self.layer("route", rank: .itineraryLine, source: "other"))

    #expect(registry.layers.map(\.id) == ["route", "detour"])
    #expect(registry.layer("route")?.source == "other")
  }

  @Test("a layer placed again at another rank moves to the top of its new band, and back")
  func moves() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("a", rank: .poi))
    registry.add(Self.layer("b", rank: .poi))
    registry.add(Self.layer("c", rank: .itineraryPoint))
    registry.add(Self.layer("a", rank: .itineraryPoint))
    #expect(registry.layers.map(\.id) == ["b", "c", "a"])
    registry.add(Self.layer("a", rank: .poi))
    #expect(registry.layers.map(\.id) == ["b", "a", "c"])
    registry.remove("a")
    registry.add(Self.layer("a", rank: .poi))
    #expect(registry.layers.map(\.id) == ["b", "a", "c"], "a layer removed takes the band's top")
    registry.remove("missing")
    #expect(registry.layers.map(\.id) == ["b", "a", "c"])
  }

  @Test("a layer is changed in its place, and taken off by its id or by its source")
  func changesAndRemoves() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("route", rank: .itineraryLine, source: "a"))
    registry.add(Self.layer("detour", rank: .itineraryLine, source: "b"))
    var changed = Self.layer("route", rank: .itineraryLine, source: "a")
    changed.paint = ["line-width": 4]

    let replaced = registry.replace("route", with: changed)
    #expect(replaced)
    #expect(registry.layers.map(\.id) == ["route", "detour"])
    #expect(registry.layer("route")?.paint == ["line-width": 4])
    let missing = registry.replace("gone", with: changed)
    #expect(!missing)
    let removed = registry.remove("route")
    let again = registry.remove("route")
    #expect(removed)
    #expect(!again)
    registry.removeLayers(drawingFrom: "b")
    #expect(registry.layers.isEmpty)
  }

  @Test("an id is matched by its scalars")
  func scalars() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("caf\u{E9}", rank: .poi))

    #expect(registry.layer("cafe\u{301}") == nil)
    #expect(registry.layer("caf\u{E9}") != nil)
  }

  @Test(
    "the layers are held in the order they were placed, one placed again at its rank keeping its place"
  )
  func placement() {
    var registry = MapLayerRegistry()
    registry.add(Self.layer("itinerary-point", rank: .itineraryPoint))
    registry.add(Self.layer("poi-food", rank: .poi))
    registry.add(Self.layer("itinerary-line", rank: .itineraryLine))
    registry.add(Self.layer("poi-water", rank: .poi))
    #expect(
      registry.placement.map(\.id) == [
        "itinerary-point", "poi-food", "itinerary-line", "poi-water",
      ])
    #expect(
      registry.layers.map(\.id) == ["itinerary-line", "poi-food", "poi-water", "itinerary-point"])
    registry.add(Self.layer("poi-food", rank: .poi))
    #expect(
      registry.placement.map(\.id) == [
        "itinerary-point", "poi-food", "itinerary-line", "poi-water",
      ])
    registry.add(Self.layer("poi-food", rank: .zone))
    #expect(
      registry.placement.map(\.id) == [
        "itinerary-point", "itinerary-line", "poi-water", "poi-food",
      ])
    #expect(registry.placement.last == PlacedLayer(id: "poi-food", rank: 40))
    registry.remove("itinerary-line")
    #expect(registry.placement.map(\.id) == ["itinerary-point", "poi-water", "poi-food"])
    registry.removeLayers(drawingFrom: "s")
    #expect(registry.placement.isEmpty)
  }
}
