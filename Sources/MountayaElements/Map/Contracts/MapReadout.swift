import MountayaClient
import MountayaGeo

/// MapReadout is the readout open on a map (`map.readout.open`): where a right-click or a long
/// press opened it, the point of the canvas and the place, and what the map held there as it
/// opened, the terrain read off the elevation tiles joining it once every tile it needs has
/// answered. `rows` is what it states (`geo.readout.rows`).
struct MapReadout: Sendable {
  /// number is how many readouts the map had opened when this one opened, which an answer for an
  /// earlier one is told apart by.
  let number: Int
  /// point is where on the canvas it opened, `[x, y]` in points from its top left corner.
  let point: [Double]
  /// facts is what the map held at the point, the terrain among it once read.
  var facts: ReadoutFacts
  /// overlayNames is the names of the classic overlay the map drew as it opened, in each language
  /// the catalogue states one, which a view names the overlay by in the language of its words, or
  /// nil where it drew none.
  var overlayNames: TileSchema.Locales?

  /// position is the place it opened at, `[longitude, latitude]`.
  var position: [Double] { facts.position }

  /// Creates the readout numbered `number`, opened at `point` over `facts`, the classic overlay
  /// drawn there named by `overlayNames`.
  init(
    number: Int, point: [Double], facts: ReadoutFacts, overlayNames: TileSchema.Locales? = nil
  ) {
    self.number = number
    self.point = point
    self.facts = facts
    self.overlayNames = overlayNames
  }

  /// facts(in:) is what the map held at the point with the classic overlay named in `language`,
  /// the language of the words the readout is written in, as every other word of it is.
  func facts(in language: RestSchema.Language) -> ReadoutFacts {
    var named = facts
    if let names = overlayNames, let overlay = named.overlay {
      named.overlay?.name = localizedName(
        locales: names, slug: overlay.slug, language: language.rawValue)
    }
    return named
  }
}
