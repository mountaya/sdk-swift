import MountayaClient
import MountayaGeo

/// geometrySlotLayers answers the layers `slot` draws its geometry with, in `color`, from its own
/// source, at its band, in the order they stack (`map.geometry.layers`): the itinerary's cased line
/// in `paint`, a `-casing` then a `-line` in the slot's colour (`geo.style.itinerary-stroke`), and,
/// for the highlight alone, a `-point` circle drawn only for a point or a multi-point, in its colour,
/// ringed in the paint's casing colour, since a picked place is a point.
func geometrySlotLayers(_ slot: GeometrySlot, color: String, paint: MapPaint) -> [MapLayer] {
  let source = slot.sourceId
  func stroke(_ stroke: ItineraryStroke, role: String) -> MapLayer {
    let style = itineraryStrokeStyle(stroke, paint: paint)
    return MapLayer(
      id: source + role, type: .line, source: source, rank: slot.rank,
      paint: style.paint, layout: style.layout)
  }
  var layers = [
    stroke(.casing, role: "-casing"), stroke(.line(color: .string(color)), role: "-line"),
  ]
  if slot == .highlight {
    layers.append(
      MapLayer(
        id: source + "-point", type: .circle, source: source, rank: slot.rank,
        paint: [
          "circle-color": .string(color),
          "circle-radius": .number(resultPointRadius),
          "circle-stroke-color": .string(paint.itinerary.casingColor),
          "circle-stroke-width": .number(resultPointStrokeWidth),
        ],
        filter: ["in", ["geometry-type"], ["literal", ["Point", "MultiPoint"]]]))
  }
  return layers
}
