import MountayaClient

/// itineraryStrokeStyle is how `stroke` draws under `paint`, the shipped paint unless the caller
/// hands its own (`geo.style.itinerary-stroke`), so an itinerary drawn from data, a directions
/// answer or a draft looks as the itineraries the tiles draw.
///
/// Every stroke draws round, `line-cap` and `line-join` `round`, at a `line-width` interpolated
/// linearly on zoom over a flat table of zoom and width pairs,
/// `["interpolate", ["linear"], ["zoom"], 7, 2, 10, 2, 13, 3, 16, 5]`. The line paints in its
/// colour over the paint's `lineWidthStops`; the dashed stroke paints in its colour over the same
/// table, in the paint's `dashArray` at its `dashedOpacity`; and the casing paints in the paint's
/// `casingColor` at its `casingOpacity` over its `casingWidthStops`. Each table and dash is written
/// as the paint holds it.
///
/// The answer is the style of a layer of type `line`; the layer's id, source, source layer and
/// filter are the caller's, and a casing is added before the line it lies beneath, since two
/// layers of one rank draw in the order they are added.
public func itineraryStrokeStyle(
  _ stroke: ItineraryStroke, paint: MapPaint = .standard
) -> LineLayerStyle {
  let itinerary = paint.itinerary
  switch stroke {
  case .line(let color):
    return LineLayerStyle(
      layout: roundLineLayout,
      paint: [
        "line-color": color,
        "line-width": zoomInterpolatedWidth(itinerary.lineWidthStops),
      ])
  case .dashed(let color):
    return LineLayerStyle(
      layout: roundLineLayout,
      paint: [
        "line-color": color,
        "line-dasharray": .array(itinerary.dashArray.map { .number($0) }),
        "line-opacity": .number(itinerary.dashedOpacity),
        "line-width": zoomInterpolatedWidth(itinerary.lineWidthStops),
      ])
  case .casing:
    return LineLayerStyle(
      layout: roundLineLayout,
      paint: [
        "line-color": .string(itinerary.casingColor),
        "line-opacity": .number(itinerary.casingOpacity),
        "line-width": zoomInterpolatedWidth(itinerary.casingWidthStops),
      ])
  }
}

/// roundLineLayout is the layout every stroke of an itinerary shares: round caps and joins, which
/// make a routed line read as one drawn line, where a butt cap notches every vertex and a mitre
/// join throws a spike off every switchback.
private let roundLineLayout: [String: JSONValue] = ["line-cap": "round", "line-join": "round"]

/// zoomInterpolatedWidth is the `line-width` expression a flat table of zoom and width pairs reads
/// as: each width at its zoom, interpolated linearly between them.
private func zoomInterpolatedWidth(_ stops: [Double]) -> JSONValue {
  let head: [JSONValue] = ["interpolate", ["linear"], ["zoom"]]
  return .array(head + stops.map { .number($0) })
}
