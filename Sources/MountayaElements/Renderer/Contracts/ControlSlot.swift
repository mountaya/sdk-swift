#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  /// ControlSlot is one place of a map's control stack, top to bottom.
  enum ControlSlot: Hashable, Sendable {
    /// zoom is the zoom pair.
    case zoom
    /// panels is the panel toggles, one group, in the order given.
    case panels([MapPanel])
    /// content is the app's own controls.
    case content
    /// geolocate is the locate control.
    case geolocate
    /// compass is the compass.
    case compass

    /// stack is the places of a stack showing the controls each flag turns on, from the top: zoom;
    /// the layers, points-of-interest and preferences toggles as one group; the app's own controls;
    /// geolocate; the compass.
    static func stack(
      zoom: Bool, layers: Bool, pois: Bool, preferences: Bool, geolocate: Bool, compass: Bool
    ) -> [ControlSlot] {
      var slots: [ControlSlot] = zoom ? [.zoom] : []
      let panels = [(layers, MapPanel.layers), (pois, .pois), (preferences, .preferences)]
        .filter(\.0).map(\.1)
      if !panels.isEmpty {
        slots.append(.panels(panels))
      }
      slots.append(.content)
      if geolocate {
        slots.append(.geolocate)
      }
      if compass {
        slots.append(.compass)
      }
      return slots
    }
  }
#endif
