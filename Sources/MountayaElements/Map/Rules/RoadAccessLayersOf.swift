import MountayaClient
import MountayaGeo

/// itineraryLineSourceLayer is the source layer an itinerary's tiles carry its lines in.
let itineraryLineSourceLayer = "itinerary_lines"

/// itineraryPointSourceLayer is the source layer an itinerary's tiles carry its waypoints in.
let itineraryPointSourceLayer = "itinerary_points"

/// itineraryRestrictionSourceLayer is the source layer an itinerary's tiles carry its restricted
/// stretches in, one line feature per stretch carrying its `kind`, which no specification declares
/// a layer for, so a map draws it with layers of its own.
let itineraryRestrictionSourceLayer = "itinerary_restrictions"

/// itineraryCasingSuffix ends the id of the white halo drawn beneath an itinerary's line, which
/// shares the line's source layer, so its id alone tells the two apart.
let itineraryCasingSuffix = "-casing"

/// roadAccessStripeImagePrefix opens the id of the image a kind's stripe pattern is drawn as:
/// `road-access-stripe-` then the kind, which the stripe layer names and the renderer draws.
let roadAccessStripeImagePrefix = "road-access-stripe-"

/// roadAccessStripeOpacity is the opacity the stripes paint at: below full, so the route under them
/// shows through a little and a stretch reads as a mark on the route rather than a second line.
let roadAccessStripeOpacity = 0.9

/// roadAccessIconSize scales a kind's 48-pixel warning sprite to the size a waypoint's marker is
/// drawn at, so a warning on the route reads as clearly as the stops along it.
let roadAccessIconSize = 0.7

/// unstatedLineWidth is the width a renderer draws a line that states none at, in pixels: the
/// width of the stripes over such a line, which then cover the route they mark.
let unstatedLineWidth = 1.0

/// roadAccessStripeLayerSuffix and roadAccessIconLayerSuffix end the ids of the two layers a
/// source's restricted stretches are drawn on, after the id of the line they are drawn beside.
let roadAccessStripeLayerSuffix = "__road-access-stripe"

/// roadAccessIconLayerSuffix ends the id of the layer a source's restricted-stretch warnings are
/// drawn on, after the id of the line they are drawn beside.
let roadAccessIconLayerSuffix = "__road-access-icon"

/// roadAccessLayersOf answers the two layers an itinerary source's restricted stretches are drawn
/// on, each at its rank, or none for a source that draws no itinerary line
/// (`map.road-access.layers`).
///
/// The pair stands beside the source's first `itinerary_lines` layer that is a line and no casing
/// (an id ending in `-casing`), binds that line's source, its own where it names one, and reads
/// the `itinerary_restrictions` source layer; its ids are the line's followed by
/// `__road-access-stripe` and `__road-access-icon`. The stripes are a line at the line's width, 1
/// where it states none, and in its zoom window, with round caps and joins, painting each stretch's
/// kind's stripe pattern (`road-access-stripe-` then the kind) at 0.9, at
/// `LayerRank.itineraryRestriction`. The icons stamp each kind's warning sprite, its glyph on a
/// disc of its colour as `map.icons.missing-image` names it, at a size of 0.7, upright and giving
/// way to one another, at the middle of each stretch, in the zoom window of the source's first
/// `itinerary_points` layer or the line's where it has none, at `LayerRank.itineraryPoint`. Each
/// image is matched on the feature's `kind` over `RoadAccessKind.allCases`, most severe first, and
/// a kind the table does not name draws as `restricted`. Where `isShown` is false, the host hid
/// the stretches, and both are born hidden.
func roadAccessLayersOf(_ source: TileSchema.TileSource, isShown: Bool = true) -> [MapLayer] {
  guard
    let line = source.layers.first(where: { layer in
      sameText(layer.source_layer, itineraryLineSourceLayer)
        && sameText(layer.type, .line)
        && !layer.id.unicodeScalars.reversed().starts(
          with: itineraryCasingSuffix.unicodeScalars.reversed())
    })
  else { return [] }
  let sourceId = line.source ?? source.id
  let points = source.layers.first { sameText($0.source_layer, itineraryPointSourceLayer) }
  var stripesLayout: [String: JSONValue] = ["line-cap": "round", "line-join": "round"]
  var iconsLayout: [String: JSONValue] = [
    "icon-allow-overlap": false,
    "icon-ignore-placement": false,
    "icon-image": kindMatch(roadAccessIconImageId),
    "icon-rotation-alignment": "viewport",
    "icon-size": .number(roadAccessIconSize),
    "symbol-placement": "line-center",
  ]
  if !isShown {
    stripesLayout["visibility"] = "none"
    iconsLayout["visibility"] = "none"
  }
  return [
    MapLayer(
      id: line.id + roadAccessStripeLayerSuffix, type: .line, source: sourceId,
      sourceLayer: itineraryRestrictionSourceLayer, rank: LayerRank.itineraryRestriction.rank,
      paint: [
        "line-opacity": .number(roadAccessStripeOpacity),
        "line-pattern": kindMatch { roadAccessStripeImagePrefix + $0.id },
        "line-width": line.paint?["line-width"] ?? .number(unstatedLineWidth),
      ],
      layout: stripesLayout,
      zoom: ZoomBounds(minZoom: Double(line.zoom_min), maxZoom: Double(line.zoom_max))),
    MapLayer(
      id: line.id + roadAccessIconLayerSuffix, type: .symbol, source: sourceId,
      sourceLayer: itineraryRestrictionSourceLayer, rank: LayerRank.itineraryPoint.rank,
      paint: ["icon-opacity": 1],
      layout: iconsLayout,
      zoom: ZoomBounds(
        minZoom: Double(points?.zoom_min ?? line.zoom_min),
        maxZoom: Double(points?.zoom_max ?? line.zoom_max))),
  ]
}

/// roadAccessIconImageId is the id of the image a restricted stretch of `kind` is marked with: the
/// marker sprite of its glyph on a disc of its colour, `section-icon-road-access-permit-9c36b5`,
/// which the map draws as it draws a waypoint's (`map.icons.missing-image`).
func roadAccessIconImageId(_ kind: RoadAccessKind) -> String {
  let hex = roadAccessColor(kind).hex.unicodeScalars
  var digits = String.UnicodeScalarView()
  for scalar in hex.first == "#" ? hex.dropFirst() : hex[...] {
    // The ASCII capitals alone are written small, as a sprite id spells its colour.
    let isCapital = scalar.value >= 0x41 && scalar.value <= 0x5A
    digits.append(
      isCapital ? Unicode.Scalar(UInt8(truncatingIfNeeded: scalar.value + 0x20)) : scalar)
  }
  return waypointIconPrefix + roadAccessGlyph(kind) + "-" + String(digits)
}

/// kindMatch is a `match` on a feature's `kind` answering `answer` for each kind, most severe first,
/// and `restricted`'s for a kind the table does not name.
private func kindMatch(_ answer: (RoadAccessKind) -> String) -> JSONValue {
  var match: [JSONValue] = ["match", ["get", "kind"]]
  for kind in RoadAccessKind.allCases {
    match.append(.string(kind.id))
    match.append(.string(answer(kind)))
  }
  match.append(.string(answer(.restricted)))
  return .array(match)
}
