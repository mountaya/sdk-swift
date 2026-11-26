import MountayaGeo

/// MapError is a command a map engine refuses: because what it names is not there, a layer, a
/// marker or a result no command added, or a terrain or an overlay the catalogue does not list;
/// because what it is handed is no value a map takes, a position that names no place, a number
/// that is not finite, a pan lock that encloses no area, a zoom range a camera cannot take or a
/// source of a type the contract does not declare; because it names something of another kind; or
/// because the device answered no fix to locate, or the map is closed. The map is left as it was.
///
/// Each kind is a refusal the contract names for the map engines, kebab-case there
/// (`position-refused`, `number-refused`, `window-refused` for `zoomBoundsRefused`, `fix-refused`,
/// `closed`, `type-refused`, `kind-mismatch`, `no-input`, and `not-found` for every kind that
/// names what is not there), and the map is left as it was whichever is raised. A query or a
/// read the map gave up on is no refusal: the call waiting on it throws `CancellationError`, the
/// platform's word for the contract's `cancelled`.
public struct MapError: Error, Sendable, Hashable, CustomStringConvertible {
  /// Kind is every reason a map command is refused that this build knows.
  ///
  /// The set grows where the engine adds a reason, so a `switch` over it outside this module ends
  /// in `@unknown default`.
  @nonexhaustive
  public enum Kind: Sendable, Hashable {
    /// layerNotFound is a command naming a layer the map does not draw.
    case layerNotFound
    /// terrainNotFound is a base map naming a terrain the Tile API's catalogue does not list.
    case terrainNotFound
    /// markerNotFound is a command naming a marker the map does not show.
    case markerNotFound
    /// positionRefused is a marker or a waypoint placed at a position that names no place a map
    /// draws: one that is not two finite numbers, its latitude within [-90, 90].
    case positionRefused
    /// maxBoundsRefused is a pan lock that encloses no area once it is read as a lock: its west
    /// and east edges on one meridian, its south and north edges on one parallel, or an edge at no
    /// finite coordinate (`geo.camera.max-bounds-refusal`).
    case maxBoundsRefused
    /// zoomBoundsRefused is a zoom range a camera cannot be held to: a least zoom under the
    /// renderer's floor, or a least zoom above the greatest, the one stated beside it or the one
    /// the map holds where the call states one end alone (`map.camera.zoom-window`).
    case zoomBoundsRefused
    /// numberRefused is a number a camera cannot take: a zoom, a bearing, a pitch, a zoom limit or
    /// a fit's ceiling that is not a finite number, or a fit's padding or duration that is not one
    /// from 0 up (`map.camera.pose`, `map.camera.fit-options`, `map.camera.zoom-window`).
    case numberRefused
    /// fixRefused is a locate the device's geolocation answered with no fix, for the reason it
    /// named; nothing moved (`map.camera.locate`).
    case fixRefused(GeolocationRefusal)
    /// closed is a locate asked of a closed map, which asks the device nothing, since a fix may
    /// prompt its reader and nothing would follow the prompt.
    case closed
    /// typeRefused is a tile specification holding a source of a type the contract does not
    /// declare, which a newer Tile API may add; nothing of the specification is drawn
    /// (`map.specification.style`).
    case typeRefused
    /// overlayNotFound is an overlay slug the layers catalogue holds under neither kind
    /// (`map.overlays.composition`).
    case overlayNotFound
    /// kindMismatch is a slug or an id that names something of the other kind: an enrichment's slug
    /// drawn as the classic overlay or the other way round (`map.overlays.composition`), or an edit
    /// of a result of another kind than the one it names (`map.analysis.edit`).
    case kindMismatch
    /// analysisNotFound is an edit of a result id nothing is drawn under (`map.analysis.edit`).
    case analysisNotFound
    /// noInput is an edit that states a member to ask again with, of a result drawn from an answer
    /// handed over rather than asked for, which holds no input to merge it onto
    /// (`map.analysis.edit`).
    case noInput
  }

  /// kind is which refusal it is.
  public let kind: Kind
  /// name is what the command named: the layer's, the marker's or the result's id, the terrain's
  /// or the overlay's slug, the id of the marker or the waypoint placed nowhere, the pan lock or the
  /// zoom range as written, the member of a camera move or a fit refused, the type of a source
  /// refused, or the call a closed map refused.
  public let name: String

  /// Creates the refusal of a command naming `name`.
  public init(kind: Kind, name: String) {
    self.kind = kind
    self.name = name
  }

  /// Two refusals are equal where they are of one kind and name the same, by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.kind == rhs.kind && sameText(lhs.name, rhs.name)
  }

  /// hash feeds the kind and the name, whose hash agrees with the stricter relation.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(kind)
    hasher.combine(name)
  }

  /// description is the refusal as a developer reads it in a log.
  public var description: String {
    switch kind {
    case .layerNotFound:
      "MapEngine: no layer is drawn under \"\(name)\". It was never added, or it was removed."
    case .terrainNotFound:
      "MapEngine: the Tile API's catalogue lists no terrain \"\(name)\"; pass a slug its "
        + "`getTileLayers` lists, or none for its first."
    case .markerNotFound:
      "MapEngine: no marker is shown under \"\(name)\". It was never added, or it was removed."
    case .positionRefused:
      "MapEngine: \"\(name)\" is placed at a position that names no place a map draws; pass "
        + "[longitude, latitude] as two finite numbers, the latitude from -90 to 90."
    case .maxBoundsRefused:
      "MapEngine: the pan lock \(name) encloses no area, held within the latitudes a map draws; "
        + "give it two finite longitudes that differ and two finite latitudes that differ, or "
        + "nil to lift the lock."
    case .zoomBoundsRefused:
      "MapEngine: the zoom range \(name) is no range a camera takes; pass a least zoom from the "
        + "renderer's floor up, at or under the greatest zoom, or release a limit to the renderer's own."
    case .numberRefused:
      "MapEngine: \(name) is no number a camera takes; pass a finite number, from 0 up for a "
        + "padding or a duration, or leave it out."
    case .fixRefused(let reason):
      "MapEngine: the device answered no fix to locate (\(reason.rawValue)); nothing moved. A "
        + "fix the app holds no permission for is denied: ask the reader in the app's own flow."
    case .closed:
      "MapEngine: \(name) was asked of a closed map, which asks the device nothing."
    case .typeRefused:
      "MapEngine: a specification holds a source of type \"\(name)\", which this build does not "
        + "draw; it draws a \"vector\", a \"raster\" or a \"raster-dem\" source. Nothing of the "
        + "specification was drawn."
    case .overlayNotFound:
      "MapEngine: the Tile API's catalogue lists no overlay \"\(name)\"; pass a slug its "
        + "`getTileLayers` lists."
    case .kindMismatch:
      "MapEngine: \"\(name)\" names something of the other kind: an enrichment is added with "
        + "`addEnrichment(_:)` and a classic overlay drawn with `setOverlay(_:)`, and a result is "
        + "edited through the edit of its own kind."
    case .analysisNotFound:
      "MapEngine: no result is drawn under \"\(name)\". It was never added, or it was removed."
    case .noInput:
      "MapEngine: \"\(name)\" was drawn from an answer handed over, which holds no input to ask "
        + "again with; edit its draw options alone, or add it again from an input."
    }
  }
}
