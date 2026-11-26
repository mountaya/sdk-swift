import Foundation
import MountayaClient

/// ReadoutRow is one row of a map's readout (`geo.readout.rows`), each naming the words it is
/// written under by their paths in the elements' words.
package enum ReadoutRow: Sendable, Hashable {
  /// Reading is one reading of the terrain row: the altitude, the slope beside its colour on the
  /// profile's ascent ramp, or the aspect beside the direction it faces.
  package enum Reading: Sendable, Hashable {
    case altitude(Double)
    case slope(Double, color: String)
    case aspect(Double, cardinal: AspectCardinal)

    /// word is the path of the word the reading is written under.
    package var word: String {
      switch self {
      case .altitude: "readout.altitude"
      case .slope: "readout.slope"
      case .aspect: "readout.aspect"
      }
    }
  }

  /// poi is the topmost point of interest: its name, none where it is empty, its category read
  /// through the tiles' table, and its label, the reader's word for the category.
  case poi(name: String?, category: DataSchema.POICategory?, label: String)
  /// band is the classic overlay's band at the point: the overlay's name, the measure its values
  /// are written in and the travel-rate form where the table pins one, the two bounds where they
  /// differ, under `word`, else the one alone, and the moment the map shows, where there is one.
  case band(
    overlay: String, measure: ReadoutMeasure, pace: RestSchema.UnitPace?, values: [Double],
    word: String?, time: Date?)
  /// terrain is the terrain's readings, altitude, slope and aspect, each where the reading states
  /// it.
  case terrain([Reading])
  /// instant is the moment the map shows, alone, for a vector overlay whose band is not stated.
  case instant(Date)
  /// coordinates is the point as `formatLngLat(_:)` writes it, and the pair a copy writes.
  case coordinates(text: String, copy: String)
  /// zoomIn is the note to zoom in below the detail zoom.
  case zoomIn
  /// zone is the topmost zone: its name and description, none where empty, its level, the word and
  /// the colour of its level, and its window, under the word its bounds name, where it states one.
  case zone(
    name: String?, description: String?, level: RestSchema.ZoneLevel, levelWord: String?,
    color: String,
    window: (start: Date?, end: Date?, word: String)?)

  /// Two rows are equal where they are of one kind holding the same.
  package static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.poi(let a, let b, let c), .poi(let d, let e, let f)):
      return a == d && b == e && c == f
    case (
      .band(let a, let b, let c, let d, let e, let f),
      .band(let g, let h, let i, let j, let k, let l)
    ):
      return a == g && b == h && c == i && sameNumbers(d, j) && e == k && f == l
    case (.terrain(let a), .terrain(let b)): return a == b
    case (.instant(let a), .instant(let b)): return a == b
    case (.coordinates(let a, let b), .coordinates(let c, let d)): return a == c && b == d
    case (.zoomIn, .zoomIn): return true
    case (
      .zone(let a, let b, let c, let d, let e, let f),
      .zone(let g, let h, let i, let j, let k, let l)
    ):
      return a == g && b == h && c == i && d == j && e == k && f?.start == l?.start
        && f?.end == l?.end && f?.word == l?.word
    default: return false
    }
  }

  /// Feeds the kind of the row, which every equal pair shares.
  package func hash(into hasher: inout Hasher) {
    switch self {
    case .poi: hasher.combine(0)
    case .band: hasher.combine(1)
    case .terrain: hasher.combine(2)
    case .instant: hasher.combine(3)
    case .coordinates: hasher.combine(4)
    case .zoomIn: hasher.combine(5)
    case .zone: hasher.combine(6)
    }
  }
}
