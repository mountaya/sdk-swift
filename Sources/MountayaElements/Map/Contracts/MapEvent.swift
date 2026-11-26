import MountayaClient
import MountayaGeo

/// MapEvent is what a map tells its host, which `MapEngine.events()` hands each reader in order: a
/// gesture on the map, the features a hovering pointer is over, a refusal of access and its end, a
/// failure of one of the map's own requests, and each change of the layers catalogue it holds.
///
/// A gesture's position is the place under the pointer, `[longitude, latitude]`, its longitude
/// brought within [-180, 180] only where the renderer read it past that range, and a gesture an edit
/// in progress took is told to nobody (`map.events.pointer`). Two events are equal where they are of
/// one kind and hold the same, a text by its scalars and a number by the same-number relation, a
/// failure's cause aside, which is told for diagnostics and never compared.
public enum MapEvent: Sendable, Equatable {
  /// tap is a tap on the map, with the place and the point of the view it fell at and the topmost
  /// marker within its reach.
  case tap(MapTap)
  /// longTap is a long press on the map, or a secondary click of a pointer, told as a tap is.
  case longTap(MapTap)
  /// featureTap is a tap that landed on features the map drew, told after its `tap`, with every
  /// such feature topmost first, as `MapEngine.features(at:)` answers them.
  case featureTap(position: [Double], features: [QueriedFeature])
  /// featureHover is where a hovering pointer ended a frame, with the features of an itinerary's
  /// line and points under it, topmost first, and with none as it leaves the map
  /// (`map.events.feature-hover`). It is told only where a pointer hovers without pressing, a mouse,
  /// a trackpad or a pencil over a tablet, and never for a finger.
  case featureHover(position: [Double], features: [QueriedFeature])
  /// accessRefused is one of the map's own requests refused access, a 401, a 402 or a 403, with
  /// the status and the address refused, the empty text where the renderer reported none
  /// (`map.events.access-refused`). It is never told as a `failure` too.
  case accessRefused(status: Int, url: String)
  /// accessRestored is the end of the last refusal of access that stood, told once
  /// (`map.events.access-standing`).
  case accessRestored
  /// failure is one of the map's own requests failing for any other reason, with the address it
  /// was made to and the status it carried, or nil where none answered, and what failed where the
  /// map knows it: what a read of the client's credential threw, for a request that never left for
  /// want of one (`map.events.access-refused`), and nil otherwise. A caller reads the cause for
  /// diagnostics and never matches on it.
  case failure(url: String, status: Int?, cause: (any Error)? = nil)
  /// layersChange is a change of the layers catalogue the map holds, with the catalogue it holds
  /// from then on: one a read brought in, or nil where moving the studio scope dropped the one held
  /// (`map.layers.manifest`).
  case layersChange(TileSchema.Layers?)

  /// Two events are equal where they are of one kind and hold the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.tap(let a), .tap(let b)), (.longTap(let a), .longTap(let b)):
      return a == b
    case (.featureTap(let a, let aFeatures), .featureTap(let b, let bFeatures)),
      (.featureHover(let a, let aFeatures), .featureHover(let b, let bFeatures)):
      return sameNumbers(a, b) && aFeatures == bFeatures
    case (.accessRefused(let a, let aUrl), .accessRefused(let b, let bUrl)):
      return a == b && sameText(aUrl, bUrl)
    case (.accessRestored, .accessRestored):
      return true
    case (.failure(let aUrl, let a, _), .failure(let bUrl, let b, _)):
      return a == b && sameText(aUrl, bUrl)
    case (.layersChange(let a), .layersChange(let b)):
      return a == b
    default:
      return false
    }
  }
}
