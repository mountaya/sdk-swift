#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  public import SwiftUI

  /// CompassControl turns a map back to north and level, and reads its bearing: its rose turns
  /// against the camera's bearing so it keeps pointing north (`map.camera.control-moves`).
  ///
  /// A press drives the map, `MapEngine.resetNorth()`, unless the app hands `onTap` in its place,
  /// which a press then calls alone; with neither a map nor a handler it is inert, and its rose
  /// points up. Where the reader asked for reduced motion, the map turns back at once rather than
  /// easing there. `.disabled(true)` disables it. Its words are the scope's, `controls.compass`
  /// naming it and `tooltips.compass` describing it (`mountayaScope(_:)`), each replaced by
  /// `strings` where it names the word's path.
  public struct CompassControl: View {
    private let map: MapEngine?
    private let onTap: (() -> Void)?

    @ViewScope private var scope: ElementsScope
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    /// Creates the compass over `map`, its words replaced by `strings` where it names theirs, a
    /// press handed to `onTap` in place of the map where the app hands one.
    public init(map: MapEngine?, strings: [String: String]? = nil, onTap: (() -> Void)? = nil) {
      self.map = map
      self.onTap = onTap
      _scope = ViewScope(strings: strings)
    }

    /// body is the rose on a disc.
    public var body: some View {
      ControlChip(isRound: true) {
        ControlButton(
          label: scope.word("controls.compass"), help: scope.word("tooltips.compass.description"),
          action: { tap(reducingMotion: reducesMotion) }
        ) {
          CompassRose(bearing: map?.state.camera.bearing ?? 0)
        }
        .disabled(map == nil && onTap == nil)
      }
    }

    /// tap is a press: the handler where the app handed one, the map's reset otherwise, landing at
    /// once where `reducingMotion`.
    func tap(reducingMotion: Bool = false) {
      if let onTap {
        onTap()
      } else {
        map?.reducesMotion = reducingMotion
        map?.resetNorth()
      }
    }
  }
#endif
