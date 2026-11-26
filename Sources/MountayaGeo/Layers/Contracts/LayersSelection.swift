import Foundation
import MountayaClient

/// LayersSelection is what a layers selection holds (`geo.layers.selection`): the layers catalogue
/// the map it drives answered, the terrain, the classic overlay and the enrichments asked for, the
/// instant pinned (`geo.layers.selection-instant`), and the refusal of the latest command or
/// catalogue read to settle, where it failed.
///
/// The selection is what was asked for and the map is what is drawn: a command the map refuses
/// keeps what it asked for, and reports the refusal until a later command settles
/// (`geo.layers.selection-outcome`), so the two disagree openly rather than a picker snapping back
/// with no word said. It holds an error, so it is not `Equatable`.
public struct LayersSelection: Sendable {
  /// catalogue is the layers catalogue the map answered, or nil before it lands.
  public var catalogue: TileSchema.Layers?
  /// terrain is the slug of the terrain selected, or, once the catalogue lands with none selected,
  /// of the terrain the map reports it shows, nil where it reports none.
  public var terrain: String?
  /// overlay is the slug of the classic overlay selected, or nil for none.
  public var overlay: String?
  /// enrichments is the slugs of the enrichments turned on, in the order they were turned on.
  public var enrichments: [String]
  /// instantTime is the instant a reader pinned last, in seconds from the reference date as a
  /// `Date` holds it, or nil for none pinned: held as plain data, as `TimeSliderRelease` holds its
  /// pin, so the selection is laid out when compiled.
  var instantTime: Double?
  /// refusal is what the map threw for the latest command or catalogue read to settle, or nil where
  /// it succeeded, or none has settled since the selection began driving its map.
  public var refusal: (any Error)?

  /// Creates a selection holding the catalogue and the choices given.
  public init(
    catalogue: TileSchema.Layers? = nil, terrain: String? = nil, overlay: String? = nil,
    enrichments: [String] = [], instant: Date? = nil, refusal: (any Error)? = nil
  ) {
    self.catalogue = catalogue
    self.terrain = terrain
    self.overlay = overlay
    self.enrichments = enrichments
    instantTime = instant?.timeIntervalSinceReferenceDate
    self.refusal = refusal
  }

  /// instant is the instant a reader pinned last, which the map draws its time-aware overlays for,
  /// or nil for none pinned, the clock's reading (`overlayInstant(pinned:now:)`).
  public var instant: Date? {
    get { instantTime.map { Date(timeIntervalSinceReferenceDate: $0) } }
    set { instantTime = newValue?.timeIntervalSinceReferenceDate }
  }
}
