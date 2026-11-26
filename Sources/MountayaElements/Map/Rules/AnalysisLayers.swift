import MountayaClient
import MountayaGeo

/// directionsLineColor is the colour a directions result's line is drawn in.
let directionsLineColor = "#1c7ed6"

/// isochroneFillOpacity is the opacity an isochrone band's fill paints at.
let isochroneFillOpacity = 0.35

/// isochroneOutlineColor and isochroneOutlineWidth paint the outline of an isochrone band, which
/// tells two nested bands apart where their translucent fills would not.
let isochroneOutlineColor = "#0b7285"

/// isochroneOutlineWidth is the width of an isochrone band's outline, in pixels.
let isochroneOutlineWidth = 1.0

/// matrixLineColor is the colour a matrix draws its connectors and its locations in.
let matrixLineColor = "#7048e8"

/// matrixLineOpacity is the opacity a matrix's connectors paint at.
let matrixLineOpacity = 0.55

/// resultPointRadius is the radius of the circle a place, a point of interest or a matrix location
/// is drawn as, in pixels.
let resultPointRadius = 6.0

/// resultPointStrokeColor is the colour of the ring around a result's circle.
let resultPointStrokeColor = "#ffffff"

/// resultPointStrokeWidth is the width of the ring around a result's circle, in pixels.
let resultPointStrokeWidth = 2.0

/// analysisLayers answers the layers a Data API result of `kind` is drawn through, from the GeoJSON
/// source of id `sourceId`, each at the kind's rank and named after the source and its role, in the
/// order they stack (`map.analysis.layers`).
///
/// Directions draw a `-casing` then a `-line` in `directionsLineColor`, and suggestions an
/// `-alternative` dashed for every candidate not chosen then a `-chosen`, each in the colour its
/// feature is stamped with, all four stroked as an itinerary is in `paint`
/// (`geo.style.itinerary-stroke`), at `LayerRank.itineraryLine`; isochrones a `-fill` in the band's
/// stamped colour and an `-outline`, a matrix a `-connector` at its stamped width and a `-location`
/// circle, at `LayerRank.zone`; places and points of interest a `-point` circle in their stamped
/// colour, at `LayerRank.poi`. A stamped colour or width is read from the feature's own property,
/// `mtyaColor` or `mtyaWidth` (`geo.layers.data-geojson`), so a redrawn result needs no new layer.
func analysisLayers(_ kind: AnalysisKind, sourceId: String, paint: MapPaint) -> [MapLayer] {
  let stamped: JSONValue = ["get", .string(featureColorProperty)]
  func stroke(_ stroke: ItineraryStroke, role: String, filter: JSONValue? = nil) -> MapLayer {
    let style = itineraryStrokeStyle(stroke, paint: paint)
    return MapLayer(
      id: sourceId + role, type: .line, source: sourceId,
      rank: LayerRank.itineraryLine.rank, paint: style.paint, layout: style.layout, filter: filter)
  }
  func point(_ role: String, color: JSONValue, rank: Int, filter: JSONValue? = nil) -> MapLayer {
    MapLayer(
      id: sourceId + role, type: .circle, source: sourceId, rank: rank,
      paint: [
        "circle-color": color,
        "circle-radius": .number(resultPointRadius),
        "circle-stroke-color": .string(resultPointStrokeColor),
        "circle-stroke-width": .number(resultPointStrokeWidth),
      ],
      filter: filter)
  }
  switch kind {
  case .directions:
    return [
      stroke(.casing, role: "-casing"),
      stroke(.line(color: .string(directionsLineColor)), role: "-line"),
    ]
  case .suggestions:
    return [
      stroke(.dashed(color: stamped), role: "-alternative", filter: ["!", ["get", "chosen"]]),
      stroke(.line(color: stamped), role: "-chosen", filter: ["get", "chosen"]),
    ]
  case .isochrones:
    return [
      MapLayer(
        id: sourceId + "-fill", type: .fill, source: sourceId,
        rank: LayerRank.zone.rank,
        paint: ["fill-color": stamped, "fill-opacity": .number(isochroneFillOpacity)]),
      MapLayer(
        id: sourceId + "-outline", type: .line, source: sourceId,
        rank: LayerRank.zone.rank,
        paint: [
          "line-color": .string(isochroneOutlineColor),
          "line-width": .number(isochroneOutlineWidth),
        ]),
    ]
  case .matrix:
    return [
      MapLayer(
        id: sourceId + "-connector", type: .line, source: sourceId,
        rank: LayerRank.zone.rank,
        paint: [
          "line-color": .string(matrixLineColor),
          "line-opacity": .number(matrixLineOpacity),
          "line-width": ["get", .string(featureWidthProperty)],
        ],
        layout: ["line-cap": "round", "line-join": "round"],
        filter: ["==", ["get", .string(featureKindProperty)], "matrix-connector"]),
      point(
        "-location", color: .string(matrixLineColor), rank: LayerRank.zone.rank,
        filter: ["==", ["get", .string(featureKindProperty)], "matrix-location"]),
    ]
  case .places, .pois:
    return [point("-point", color: stamped, rank: LayerRank.poi.rank)]
  }
}
