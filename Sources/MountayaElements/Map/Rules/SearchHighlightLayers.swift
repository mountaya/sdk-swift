import MountayaClient
import MountayaGeo

/// searchHighlightSourceId is the source a map draws a picked search result from, and the stem of
/// its layers' ids, each the source's followed by its role.
let searchHighlightSourceId = "mountaya-search-highlight"

/// searchHighlightPlaceGlyph is the glyph a place's pin carries, and searchHighlightFallbackGlyph
/// the one it carries under a glyph set that holds no point.
let searchHighlightPlaceGlyph = "point"
let searchHighlightFallbackGlyph = "map-pin"

/// searchHighlightPinSize is the size a pin's sprite is drawn at, the size the tiles draw a point
/// of interest at, so the two overlap where both are drawn.
let searchHighlightPinSize = 0.7

/// The halo under a way's line, a soft wash of the accent that lifts it off whatever it runs over:
/// its blur, its opacity and its width, in pixels.
let searchHighlightHaloBlur = 6.0
let searchHighlightHaloOpacity = 0.25
let searchHighlightHaloWidth = 16.0

/// The white casing that parts a way's line from the tiles' own lines: its colour and its width.
let searchHighlightCasingColor = "#ffffff"
let searchHighlightCasingWidth = 8.0

/// searchHighlightLineWidth is the width of a way's line, in the accent.
let searchHighlightLineWidth = 5.0

/// The dot at each end of a way's line: its radius and the width of its white ring.
let searchHighlightEndRadius = 5.0
let searchHighlightEndStrokeWidth = 2.0

/// A way's extent, a faint wash of the accent outlined dashed and thinner than a line, so it reads
/// as an approximate extent rather than the way itself: its dash, the wash's opacity and the
/// outline's width.
let searchHighlightExtentDash: [Double] = [2, 2]
let searchHighlightExtentFillOpacity = 0.08
let searchHighlightExtentWidth = 2.0

/// searchHighlightLayers answers what a map draws for `highlight`, the result a reader picked from
/// a search, in `accent` (`map.search.result-highlight`): the features of its one source, and its
/// layers in the order they stack, every one at the chrome band, `LayerRank.chrome`, above every
/// content band.
///
/// - A place is a pin, the marker sprite of `searchHighlightPlaceGlyph` in the accent, or of
///   `searchHighlightFallbackGlyph` where the map's glyph set holds no point, `hasPointGlyph`, named
///   as `poi-icon-` followed by the glyph, a hyphen and the colour's six small hexadecimal digits,
///   drawn whatever it overlaps (`map.icons.marker-sprite`).
/// - A point of interest is the pin of its category's own glyph in its category's own colour
///   (`geo.layers.poi-style`), its feature carrying its `category`; one of no category the table
///   styles is pinned as a place.
/// - A way with a line of two positions or more is that line under a halo in the accent and a white
///   casing, with a dot at each of its two ends, which read the collection's points alone, since a
///   circle is drawn at every position of whatever it reads; else its extent, a rectangle washed in
///   the accent and outlined dashed, traced with its east edge a turn further east where its west
///   edge lies east of its east one, so it runs the short way across the antimeridian; else, where
///   the extent has an edge at no finite coordinate, no height, or no width once traced, a place's
///   pin at its anchor.
func searchHighlightLayers(_ highlight: SearchHighlight, accent: HexColor, hasPointGlyph: Bool)
  -> (features: GeoJSONFeatureCollection, layers: [MapLayer])
{
  let source = searchHighlightSourceId
  let rank = LayerRank.chrome.rank
  func pin(
    _ role: String, at point: [Double], glyph: String, color: String,
    properties: [String: JSONValue]
  ) -> (features: GeoJSONFeatureCollection, layers: [MapLayer]) {
    (
      GeoJSONFeatureCollection(features: [
        GeoJSONFeature(geometry: .point(GeoJSONPoint(coordinates: point)), properties: properties)
      ]),
      [
        MapLayer(
          id: "\(source)-\(role)", type: .symbol, source: source, rank: rank,
          layout: [
            "icon-allow-overlap": true,
            "icon-ignore-placement": true,
            "icon-image": .string(poiIconImageId(glyph: glyph, color: color)),
            "icon-size": .number(searchHighlightPinSize),
          ])
      ]
    )
  }
  func placePin(_ point: [Double]) -> (features: GeoJSONFeatureCollection, layers: [MapLayer]) {
    pin(
      "place", at: point,
      glyph: hasPointGlyph ? searchHighlightPlaceGlyph : searchHighlightFallbackGlyph,
      color: accent.hex, properties: [:])
  }

  switch highlight {
  case .place(let point):
    return placePin(point)
  case .poi(let point, let category):
    guard let category, let style = poiStyleOf(category) else { return placePin(point) }
    return pin(
      "poi", at: point, glyph: style.glyph, color: style.color.hex,
      properties: ["category": .string(category.rawValue)])
  case .way(let anchor, let bounds, let coordinates):
    if let coordinates, coordinates.count >= 2, let first = coordinates.first,
      let last = coordinates.last
    {
      return wayLine(coordinates, ends: [first, last], accent: accent.hex)
    }
    guard let extent = tracedExtent(bounds) else { return placePin(anchor) }
    return wayExtent(extent, accent: accent.hex)
  }
}

/// wayLine is a way's line, haloed and cased, with a dot at each of `ends`, the dots reading the
/// collection's points alone.
private func wayLine(_ coordinates: [[Double]], ends: [[Double]], accent: String)
  -> (features: GeoJSONFeatureCollection, layers: [MapLayer])
{
  let source = searchHighlightSourceId
  let rank = LayerRank.chrome.rank
  let rounded: [String: JSONValue] = ["line-cap": "round", "line-join": "round"]
  var features = [
    GeoJSONFeature(
      geometry: .lineString(GeoJSONLineString(coordinates: coordinates)), properties: [:])
  ]
  for end in ends {
    features.append(
      GeoJSONFeature(geometry: .point(GeoJSONPoint(coordinates: end)), properties: [:]))
  }
  return (
    GeoJSONFeatureCollection(features: features),
    [
      MapLayer(
        id: "\(source)-halo", type: .line, source: source, rank: rank,
        paint: [
          "line-blur": .number(searchHighlightHaloBlur),
          "line-color": .string(accent),
          "line-opacity": .number(searchHighlightHaloOpacity),
          "line-width": .number(searchHighlightHaloWidth),
        ],
        layout: rounded),
      MapLayer(
        id: "\(source)-casing", type: .line, source: source, rank: rank,
        paint: [
          "line-color": .string(searchHighlightCasingColor),
          "line-width": .number(searchHighlightCasingWidth),
        ],
        layout: rounded),
      MapLayer(
        id: "\(source)-line", type: .line, source: source, rank: rank,
        paint: [
          "line-color": .string(accent), "line-width": .number(searchHighlightLineWidth),
        ],
        layout: rounded),
      MapLayer(
        id: "\(source)-endpoints", type: .circle, source: source, rank: rank,
        paint: [
          "circle-color": .string(accent),
          "circle-radius": .number(searchHighlightEndRadius),
          "circle-stroke-color": .string(searchHighlightCasingColor),
          "circle-stroke-width": .number(searchHighlightEndStrokeWidth),
        ],
        filter: ["==", ["geometry-type"], "Point"]),
    ]
  )
}

/// wayExtent is a way's extent as traced, `[west, south, east, north]`, washed in the accent and
/// outlined dashed.
private func wayExtent(_ extent: [Double], accent: String)
  -> (features: GeoJSONFeatureCollection, layers: [MapLayer])
{
  let source = searchHighlightSourceId
  let rank = LayerRank.chrome.rank
  let (west, south, east, north) = (extent[0], extent[1], extent[2], extent[3])
  let ring = [[west, south], [east, south], [east, north], [west, north], [west, south]]
  return (
    GeoJSONFeatureCollection(features: [
      GeoJSONFeature(geometry: .polygon(GeoJSONPolygon(coordinates: [ring])), properties: [:])
    ]),
    [
      MapLayer(
        id: "\(source)-bounds-fill", type: .fill, source: source, rank: rank,
        paint: [
          "fill-color": .string(accent),
          "fill-opacity": .number(searchHighlightExtentFillOpacity),
        ]),
      MapLayer(
        id: "\(source)-bounds", type: .line, source: source, rank: rank,
        paint: [
          "line-color": .string(accent),
          "line-dasharray": .array(searchHighlightExtentDash.map(JSONValue.number)),
          "line-width": .number(searchHighlightExtentWidth),
        ]),
    ]
  )
}

/// tracedExtent reads a way's extent, `bounds`, as the rectangle the highlight traces, or nil where
/// it traces none and the way is pinned at its anchor.
///
/// A box whose west edge lies east of its east edge crosses the antimeridian, as GeoJSON writes
/// one, and is traced with its east edge a turn further east, past 180, so the ring runs the short
/// way over the line. A box that is not four finite numbers, a south edge not south of its north
/// edge, or an east edge as traced not east of its west edge is none: the last holds two meridians
/// that are one however they are written, 6 and 6, 180 and -180, an outline nobody sees.
private func tracedExtent(_ bounds: [Double]?) -> [Double]? {
  guard let bounds, bounds.count == 4, bounds.allSatisfy(\.isFinite) else { return nil }
  let (west, south, east, north) = (bounds[0], bounds[1], bounds[2], bounds[3])
  let tracedEast = west > east ? east + 360 : east
  guard south < north, tracedEast > west else { return nil }
  return [west, south, tracedEast, north]
}
