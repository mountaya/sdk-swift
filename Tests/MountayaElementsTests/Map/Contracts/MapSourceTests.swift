import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("MapSource")
struct MapSourceTests {
  private static func tileSource(
    _ type: TileSchema.TileSourceType, size: TileSchema.TileSourceSize? = nil
  )
    -> TileSchema.TileSource
  {
    TileSchema.TileSource(
      id: "zones", layers: [], tiles: ["https://tiles.mountaya.com/v1/zones/{z}/{x}/{y}"],
      type: type, zoom_max: 14, zoom_min: 2
    ) {
      $0.size = size
      $0.attribution = "Mountaya"
    }
  }

  @Test("a tile specification's source is read as the tiles it serves, at their zoom levels")
  func fromSpecification() throws {
    let source = try MapSource(Self.tileSource(.vector))
    let zoom = ZoomBounds(minZoom: 2, maxZoom: 14)

    #expect(source.id == "zones")
    #expect(source.attribution == "Mountaya")
    #expect(
      source.kind == .vector(tiles: ["https://tiles.mountaya.com/v1/zones/{z}/{x}/{y}"], zoom: zoom)
    )
  }

  @Test("a raster and an elevation raster keep their size, the renderer's own where none is stated")
  func rasters() throws {
    let tiles = ["https://tiles.mountaya.com/v1/zones/{z}/{x}/{y}"]
    let zoom = ZoomBounds(minZoom: 2, maxZoom: 14)

    #expect(
      try MapSource(Self.tileSource(.raster, size: .size256)).kind
        == .raster(tiles: tiles, tileSize: 256, zoom: zoom))
    #expect(
      try MapSource(Self.tileSource(.rasterDem)).kind
        == .rasterDem(tiles: tiles, tileSize: nil, zoom: zoom))
    #expect(
      try MapSource(Self.tileSource(.rasterDem, size: .size512)).kind
        == .rasterDem(tiles: tiles, tileSize: 512, zoom: zoom))
  }

  @Test("a source of a type the contract does not declare is refused, naming the type")
  func refused() {
    for type in ["pmtiles", "geojson", "Vector", ""] {
      #expect(throws: MapError(kind: .typeRefused, name: type)) {
        try MapSource(Self.tileSource(TileSchema.TileSourceType(rawValue: type)))
      }
    }
  }

  @Test("two sources are equal where they serve the same, each template by its scalars")
  func equality() {
    let features = GeoJSONFeatureCollection(features: [
      GeoJSONFeature(geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])), properties: [:])
    ])
    let source = MapSource(id: "pins", kind: .geoJson(features))

    #expect(source == MapSource(id: "pins", kind: .geoJson(features)))
    #expect(source != MapSource(id: "pins", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    #expect(
      MapSource(
        id: "a", kind: .vector(tiles: ["caf\u{E9}"], zoom: ZoomBounds(minZoom: 0, maxZoom: 1)))
        != MapSource(
          id: "a", kind: .vector(tiles: ["cafe\u{301}"], zoom: ZoomBounds(minZoom: 0, maxZoom: 1))))
  }
}
