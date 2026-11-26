import Foundation
import MountayaClient

/// readoutDetailZoom is the zoom from which a readout states the point of interest, the terrain
/// and the zone, and below which it notes that a zoom in shows more.
package let readoutDetailZoom: Double = 13

/// readoutCopyDecimals is the places a copied coordinate is written to.
package let readoutCopyDecimals = 5

/// OverlayReadout is how a readout writes the band of a classic overlay: the measure, the
/// travel-rate form it pins where it pins one, and the scale its values are multiplied by.
package struct OverlayReadout: Sendable, Hashable {
  package let measure: ReadoutMeasure
  package let pace: RestSchema.UnitPace?
  package let scale: Double

  package init(measure: ReadoutMeasure, pace: RestSchema.UnitPace? = nil, scale: Double = 1) {
    self.measure = measure
    self.pace = pace
    self.scale = scale
  }
}

/// overlayReadouts is the classic overlays whose band a readout states, by slug: a temperature as
/// a temperature, a humidity as a humidity, a snowfall and a snow depth, given in meters and so
/// scaled to centimeters, as a snowfall, a visibility as a distance, and a wind as a speed per time
/// whatever the reader's pace, since a wind is no travel rate.
package let overlayReadouts: [String: OverlayReadout] = [
  "humidity": OverlayReadout(measure: .humidity),
  "snowdepth": OverlayReadout(measure: .snowfall, scale: 100),
  "snowfall-daily": OverlayReadout(measure: .snowfall),
  "snowfall-hourly": OverlayReadout(measure: .snowfall),
  "temperature-actual": OverlayReadout(measure: .temperature),
  "temperature-perceived": OverlayReadout(measure: .temperature),
  "temperature-soil": OverlayReadout(measure: .temperature),
  "visibility": OverlayReadout(measure: .distance),
  "wind": OverlayReadout(measure: .speed, pace: .perTime),
]

/// zoneLevelColors is the colour of each level a zone states, the level's word being
/// `readout.zoneLevels.<level>`.
package let zoneLevelColors: [RestSchema.ZoneLevel: String] = [
  .danger: "#f03e3e",
  .info: "#1c7ed6",
  .resolved: "#37b24d",
  .warning: "#f59f00",
]

/// zoneLevelFallback is the level whose colour a level the table does not name is shown in.
package let zoneLevelFallback: RestSchema.ZoneLevel = .info

/// readoutRows answers what the readout a right-click or a long press opens on a map states, in
/// order and each only where the map holds it (`geo.readout.rows`):
///
/// 1. at the detail zoom, 13 and above, the topmost point of interest: its name, its category read
///    through `poiTileCategories`, and the reader's word for it as `geo.search.describe` words a
///    category, `wording` naming it, its English title where it names none, and the tile's own
///    category titled where the table names none;
/// 2. at any zoom, the band of the classic overlay for a vector overlay `overlayReadouts` names,
///    its two bounds under `readout.overlayRange` where they differ, else the one, a bound of no
///    number being none, scaled as the table says, with the moment under `readout.overlayTime`;
/// 3. at the detail zoom, the terrain's altitude, slope and aspect, each where it is stated, the
///    slope beside its colour on the profile's ascent ramp and the aspect beside its direction;
/// 4. the moment alone, for a vector overlay with no band row;
/// 5. the coordinates as `formatLngLat(_:)` writes them, and the pair a copy writes, the latitude
///    then the longitude, each rounded to five places half away from zero on its binary value, a
///    minus before a negative value and none before one that rounds to zero, joined by a comma and
///    a space;
/// 6. below the detail zoom, `readout.zoomInForDetails`;
/// 7. at the detail zoom, the topmost zone: its name and description, its level with its word and
///    its colour, a level the table does not name shown as written in `info`'s colour, and its
///    window, both bounds under `readout.zoneWindowRange`, the start alone under
///    `readout.zoneWindowFrom` and the end alone under `readout.zoneWindowUntil`.
///
/// A readout holds no place link, no waypoint action and no street-level view: those are the
/// studio's and the embed page's own.
package func readoutRows(_ facts: ReadoutFacts, wording: SearchWording = SearchWording())
  -> [ReadoutRow]
{
  let detail = facts.zoom >= readoutDetailZoom
  var rows: [ReadoutRow] = []
  if detail, let poi = facts.poi {
    let category = poiCategoryOf(poi.category)
    let label =
      category.map {
        wordFor(
          .poiCategory($0), fallback: titleCase($0.rawValue.lowercased()), wording: wording)
      } ?? titleCase(poi.category)
    rows.append(
      .poi(name: poi.name.unicodeScalars.isEmpty ? nil : poi.name, category: category, label: label)
    )
  }
  var bandShown = false
  if let overlay = facts.overlay, overlay.vector,
    let readout = overlayReadouts.first(where: { sameText($0.key, overlay.slug) })?.value,
    !overlay.name.unicodeScalars.isEmpty, let band = facts.band
  {
    let bounds = [band.min, band.max].compactMap { $0 }.filter(\.isFinite).map {
      $0 * readout.scale
    }
    if !bounds.isEmpty {
      let differ = bounds.count == 2 && bounds[0] != bounds[1]
      bandShown = true
      rows.append(
        .band(
          overlay: overlay.name, measure: readout.measure, pace: readout.pace,
          values: differ ? bounds : [bounds[0]], word: differ ? "readout.overlayRange" : nil,
          time: facts.instant))
    }
  }
  if detail, let terrain = facts.terrain {
    var readings: [ReadoutRow.Reading] = []
    if terrain.elevation.isFinite {
      readings.append(.altitude(terrain.elevation))
    }
    if terrain.slope.isFinite {
      readings.append(.slope(terrain.slope, color: slopeRampColor(max(terrain.slope, 0))))
    }
    if let aspect = terrain.aspect, let cardinal = aspectCardinal(aspect) {
      readings.append(.aspect(aspect, cardinal: cardinal))
    }
    if !readings.isEmpty {
      rows.append(.terrain(readings))
    }
  }
  if !bandShown, facts.overlay?.vector == true, let instant = facts.instant {
    rows.append(.instant(instant))
  }
  if let text = formatLngLat(facts.position) {
    rows.append(.coordinates(text: text, copy: copiedPair(facts.position)))
  }
  if !detail {
    rows.append(.zoomIn)
  }
  if detail, let zone = facts.zone {
    // A dictionary finds a key by canonical equivalence; a level is matched by its scalars.
    let named = zoneLevelColors.index(forKey: zone.level).flatMap {
      sameText(zoneLevelColors[$0].key, zone.level) ? zoneLevelColors[$0] : nil
    }
    let start = zone.startAt.flatMap { $0.isFinite ? Date(timeIntervalSince1970: $0) : nil }
    let end = zone.endAt.flatMap { $0.isFinite ? Date(timeIntervalSince1970: $0) : nil }
    let window: (start: Date?, end: Date?, word: String)? =
      switch (start, end) {
      case (.some, .some): (start, end, "readout.zoneWindowRange")
      case (.some, nil): (start, nil, "readout.zoneWindowFrom")
      case (nil, .some): (nil, end, "readout.zoneWindowUntil")
      case (nil, nil): nil
      }
    rows.append(
      .zone(
        name: zone.name.unicodeScalars.isEmpty ? nil : zone.name,
        description: zone.description.unicodeScalars.isEmpty ? nil : zone.description,
        level: zone.level, levelWord: named.map { "readout.zoneLevels.\($0.key.rawValue)" },
        color: named?.value ?? zoneLevelColors[zoneLevelFallback] ?? "#1c7ed6", window: window))
  }
  return rows
}

/// copiedPair is the pair a readout's copy writes for `position`, `[longitude, latitude]`: the
/// latitude then the longitude, each rounded to five places half away from zero on its binary
/// value, with a point, no grouping, a minus before a negative value and none before one that
/// rounds to zero, joined by a comma and a space, the pair another map, a device or a spreadsheet
/// reads back.
package func copiedPair(_ position: [Double]) -> String {
  guard position.count >= 2 else { return "" }
  func written(_ value: Double) -> String {
    guard value.isFinite else { return "" }
    let digits = decimalPlaces(abs(value), places: readoutCopyDecimals)
    let isZero = digits.unicodeScalars.allSatisfy { $0 == "0" || $0 == "." }
    return value < 0 && !isZero ? "-" + digits : digits
  }
  return written(position[1]) + ", " + written(position[0])
}
