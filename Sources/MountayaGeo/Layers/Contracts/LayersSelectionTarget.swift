import Foundation
import MountayaClient

/// LayersSelectionTarget is the map a layers selection drives (`geo.layers.selection`): the layers
/// catalogue it reads, the terrain, classic overlay and enrichments it draws, the instant it draws
/// its time-aware overlays for, and the terrain it reports it shows. `MapEngine` is one; a map of
/// an app's own, or a test's double, is another.
///
/// Each command answers once the map drew what it asked for, and throws where the map refused it,
/// which the selection reports. It is bound to the main actor, as every map is, and compared by
/// identity, so a selection handed the map it drives already changes nothing.
@MainActor
public protocol LayersSelectionTarget: AnyObject {
  /// terrain is the slug of the catalogue terrain the map shows, or nil where it shows none: before
  /// one is up, or under a style of the app's own.
  var terrain: String? { get }

  /// loadLayers answers the layers catalogue: every terrain and overlay the credential draws.
  func loadLayers() async throws -> TileSchema.Layers

  /// setTerrain switches the base map to the terrain `slug` names.
  func setTerrain(_ slug: String?) async throws

  /// setOverlay draws the classic overlay `slug` names in place of the one drawn before.
  func setOverlay(_ slug: String) async throws

  /// clearOverlay takes the classic overlay drawn off.
  func clearOverlay() async throws

  /// addEnrichment draws the enrichment `slug` names on top of what is drawn.
  func addEnrichment(_ slug: String) async throws

  /// removeEnrichment takes the enrichment `slug` names off.
  func removeEnrichment(_ slug: String) async throws

  /// setInstant draws the map's time-aware overlays for `instant`, or for the present where it is
  /// nil (`geo.layers.selection-instant`). A map that draws no overlay for an instant answers at
  /// once.
  func setInstant(_ instant: Date?) async throws
}
