import Foundation
import MountayaClient

/// ReadoutFacts is what a map holds at the point a readout opens at (`geo.readout.rows`): the
/// point and the camera's zoom, the terrain read off the elevation tiles there, the topmost point
/// of interest and zone the map draws there, the classic overlay it draws with the band of it at
/// the point, and the moment it shows. Each is nil where the map holds none.
package struct ReadoutFacts: Sendable {
  /// POI is the topmost point of interest drawn at the point: its name and the category its tile
  /// states, as OpenMapTiles spells it.
  package struct POI: Sendable, Hashable {
    package var name: String
    package var category: String

    package init(name: String, category: String) {
      self.name = name
      self.category = category
    }
  }

  /// Zone is the topmost zone drawn at the point: its name, its description, its level, a level
  /// the vocabulary does not name kept as its tile spells it, and the bounds of its window, in whole
  /// Unix seconds, the numbers its tile states truncated to the second, each nil where it has none
  /// or writes it as a string.
  package struct Zone: Sendable, Hashable {
    package var name: String
    package var description: String
    package var level: RestSchema.ZoneLevel
    package var startAt: Double?
    package var endAt: Double?

    package init(
      name: String, description: String, level: RestSchema.ZoneLevel, startAt: Double?,
      endAt: Double?
    ) {
      self.name = name
      self.description = description
      self.level = level
      self.startAt = startAt
      self.endAt = endAt
    }
  }

  /// Overlay is the classic overlay the map draws: its slug, its name in the reader's language
  /// and whether it is drawn from vector tiles.
  package struct Overlay: Sendable, Hashable {
    package var slug: String
    package var name: String
    package var vector: Bool

    package init(slug: String, name: String, vector: Bool) {
      self.slug = slug
      self.name = name
      self.vector = vector
    }
  }

  /// position is the point, `[longitude, latitude]`.
  package var position: [Double]
  /// zoom is the camera's zoom when the readout opened.
  package var zoom: Double
  /// terrain is the terrain read off the elevation tiles at the point.
  package var terrain: TerrainReading?
  /// poi is the topmost point of interest drawn there.
  package var poi: POI?
  /// zone is the topmost zone drawn there.
  package var zone: Zone?
  /// overlay is the classic overlay the map draws.
  package var overlay: Overlay?
  /// band is the `minValue` and the `maxValue` of the first feature of the classic overlay at the
  /// point stating one, each nil, or no number, where it states none.
  package var band: (min: Double?, max: Double?)?
  /// instant is the moment the map shows (`geo.layers.overlay-instant`).
  package var instant: Date?

  /// Creates the facts of a point, every one the map does not hold left out.
  package init(
    position: [Double], zoom: Double, terrain: TerrainReading? = nil, poi: POI? = nil,
    zone: Zone? = nil, overlay: Overlay? = nil, band: (min: Double?, max: Double?)? = nil,
    instant: Date? = nil
  ) {
    self.position = position
    self.zoom = zoom
    self.terrain = terrain
    self.poi = poi
    self.zone = zone
    self.overlay = overlay
    self.band = band
    self.instant = instant
  }
}
