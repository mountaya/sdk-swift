import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("MapSurface")
@MainActor
struct MapSurfaceTests {
  /// Base is a surface drawing a base map of its own: sources it credits, labels it relabels and
  /// restores, every layer and source live.
  final class Base: MapSurface {
    var zoomLimits: ZoomBounds { ZoomBounds(minZoom: 0, maxZoom: 25.5) }
    var projection: ScreenProjection { ScreenProjection(point: { $0 }, position: { $0 }) }
    var creditedBaseSources: [CreditedSource] = []
    var symbolLabels: [SymbolLabel] = []
    private(set) var labels: [String: JSONValue?] = [:]

    func move(to target: CameraTarget, by motion: CameraMotion) {}
    func frame(_ bounds: [Double], with fit: CameraFit, within window: ZoomBounds) -> CameraPose? {
      nil
    }
    func holdsLayer(_ id: String) -> Bool { true }
    func holdsSource(_ id: String) -> Bool { true }
    func renderedFeatures(at point: [Double], in layers: [String]) -> [QueriedFeature] { [] }
    func relabel(_ id: String, to label: JSONValue?) {
      labels[id] = .some(label)
    }
    func mapMoved() {}
  }

  private static func engine() throws -> MapEngine {
    MapEngine(
      client: try Mountaya(credential: .publishable(key: "pk_test_a")),
      labelLanguage: .en, geolocation: InertGeolocation())
  }

  @Test("the base map's sources a surface reads are credited after Mountaya, the map's own after")
  func credits() throws {
    let map = try Self.engine()
    let base = Base()
    map.attach(base)
    base.creditedBaseSources = [
      CreditedSource(attribution: "Base", isDrawn: true),
      CreditedSource(attribution: "Hidden", isDrawn: false),
    ]
    map.addSource(
      MapSource(
        id: "own", kind: .geoJson(GeoJSONFeatureCollection(features: [])), attribution: "Own"))
    map.addLayer(MapLayer(id: "own-lines", type: .line, source: "own", rank: 50))
    #expect(map.credits == [mountayaCredit, "Base", "Own"])
    // A layer drawn outside its zoom window, or hidden, draws its source nowhere.
    try map.editLayer("own-lines", layout: ["visibility": "none"])
    #expect(map.credits == [mountayaCredit, "Base"])
    try map.editLayer("own-lines", layout: ["visibility": "visible"])
    map.addLayer(
      MapLayer(
        id: "own-lines", type: .line, source: "own", rank: 50,
        zoom: ZoomBounds(minZoom: 10, maxZoom: 14)))
    #expect(map.credits == [mountayaCredit, "Base"], "the camera stands at 0, out of the window")
  }

  @Test("a label rewritten is put back as written where the language leaves it as written")
  func restored() throws {
    let map = try Self.engine()
    let base = Base()
    map.attach(base)
    let written: JSONValue = ["coalesce", ["get", "name:de"], ["get", "name"]]
    base.symbolLabels = [SymbolLabel(id: "place-label", textField: written)]
    map.setLabelLanguage(.fr)
    let french = base.labels["place-label"].flatMap { $0 }
    #expect(french != nil && french != written, "\(String(describing: french))")
    map.setLabelLanguage(.de)
    let restored = base.labels["place-label"]
    #expect(restored != nil && restored.flatMap { $0 } == nil, "back to the label its style wrote")
  }

  @Test("a surface let go is no longer asked, and the map answers as one no view draws")
  func released() throws {
    let map = try Self.engine()
    var base: Base? = Base()
    if let base { map.attach(base) }
    #expect(map.surface != nil)
    base = nil
    #expect(map.surface == nil)
    #expect(map.project([6.86, 45.83]).allSatisfy { $0.isNaN })
    #expect(map.features(at: [0, 0]).isEmpty)
  }
}
