#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  import Observation

  /// ProfileCursor is where a profile's cursor stands, and what that writes to the map beside the
  /// profile, held apart from the profile's root: the parts the cursor moves read it, the cursor's
  /// layer, the card at it, the strip stating it and what assistive technologies read of the chart,
  /// and a scrub redraws them alone, never the root, whose redraw would read the whole itinerary
  /// again and redraw every part of the profile for every pointer position (`scrub-root` in the
  /// contract's `sdk/hot-paths.yaml`).
  ///
  /// The sample it stands on changes only where a scrub moves it to another, so a pointer moving
  /// within one column of the chart redraws nothing, and it writes the map through `MapLink`, which
  /// pointing where it already points writes nothing. It is bound to the main actor, where SwiftUI
  /// draws the profile and the map lives.
  @MainActor
  @Observable
  final class ProfileCursor {
    /// index is the index of the sample the cursor stands on, or nil where none stands.
    private(set) var index: Int?
    /// link is what the cursor writes to the map, which no view reads.
    @ObservationIgnored private var link: MapLink<Int>

    /// Creates the cursor of a profile pinning its marker under `markerId`, standing nowhere.
    init(markerId: String) {
      link = MapLink(markerId: markerId)
    }

    /// point moves the cursor to the sample at `index`, nil for none, and tells it as `MapLink`
    /// tells a point: `onHover` is handed `value` where the app hands a handler, and `map` is
    /// otherwise written `target`. A disabled profile points at nothing new and only lets go.
    func point(
      at index: Int?, value: ElevationPoint?, target: MapTarget, isEnabled: Bool,
      onHover: ((ElevationPoint?) -> Void)?, map: MapEngine?, markerColor: String?,
      emphasisColor: String?
    ) {
      link.point(
        at: index, value: value, target: target, isEnabled: isEnabled, onHover: onHover, map: map,
        markerColor: markerColor, emphasisColor: emphasisColor)
      // Told only where it moved, so a view reading it is drawn again only then.
      if link.pointed != self.index {
        self.index = link.pointed
      }
    }

    /// sample is the sample of `series` the cursor stands on, or nil where it stands on none.
    func sample(in series: ElevationSeries) -> ElevationPoint? {
      index.flatMap { series.points.indices.contains($0) ? series.points[$0] : nil }
    }
  }
#endif
