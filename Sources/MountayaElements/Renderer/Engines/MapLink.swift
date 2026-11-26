#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo

  /// MapLink is what a data element points at, and what that writes to the map beside it: one
  /// cursor marker under the element's own id, moved as the reader moves
  /// (`map.profile.cursor-marker`), and the leg pointed at lit on the map's emphasis slot
  /// (`map.profile.emphasis`). A profile points at a sample by its index, a table at a row by its
  /// key.
  ///
  /// It holds what the element pinned and whether it lit the slot, so it never takes down a marker
  /// or a stretch another element wrote, and pointing where it already points writes nothing. It is
  /// bound to the main actor, as the map it writes to is.
  @MainActor
  struct MapLink<Key: Equatable> {
    let markerId: String
    private(set) var pointed: Key?
    private(set) var pinned: CursorMarkerPin?
    private(set) var isLit = false

    /// Creates the link of an element pinning its cursor under `markerId`, pointing at nothing.
    init(markerId: String) {
      self.markerId = markerId
    }

    /// point points the element at what `key` names, nil for nothing, and tells it: `onHover` is
    /// handed `value`, where the app hands a handler, and `map` is otherwise written `target`. A
    /// disabled element points at nothing new and only lets go, and pointing where it already
    /// points tells nothing, so a pointer resting on a sample writes the map once.
    mutating func point<Value>(
      at key: Key?, value: Value?, target: MapTarget, isEnabled: Bool,
      onHover: ((Value?) -> Void)?, map: MapEngine?, markerColor: String?, emphasisColor: String?
    ) {
      guard isEnabled || key == nil else { return }
      guard pointed != key else { return }
      pointed = key
      if let onHover {
        onHover(value)
        return
      }
      guard let map else { return }
      write(target, on: map, markerColor: markerColor, emphasisColor: emphasisColor)
    }

    /// write writes `target` to `map`: the marker at its position in `markerColor`, taken down
    /// where it states none, and its stretch lit in `emphasisColor`, what the element lit taken
    /// down where it states none. A position the map refuses leaves the marker as it stood.
    mutating func write(
      _ target: MapTarget, on map: MapEngine, markerColor: String?, emphasisColor: String?
    ) {
      if let lngLat = target.lngLat {
        do {
          pinned = try showCursorMarker(
            on: map, pinned: pinned,
            point: CursorMarkerPoint(id: markerId, lngLat: lngLat, color: markerColor))
        } catch {
          // The marker the map holds, if any, stands as it was.
        }
      } else {
        hideCursorMarker(on: map, pinned: pinned, id: markerId)
        pinned = nil
      }
      isLit = writeLegEmphasis(
        on: map, isLit: isLit, stretch: target.stretch, color: emphasisColor)
    }
  }
#endif
