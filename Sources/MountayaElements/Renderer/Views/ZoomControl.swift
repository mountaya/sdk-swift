#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// ZoomControl is a map's zoom in and zoom out, one chip, each half a step of the camera
  /// (`map.camera.control-moves`).
  ///
  /// Each half drives the map, `MapEngine.zoomIn()` and `zoomOut()`, unless the app hands a handler
  /// in its place, `onZoomInTap` or `onZoomOutTap`, which a press then calls alone; a half with
  /// neither a map nor a handler is inert. Each half follows the map's zoom window whoever answers
  /// its press: zoom in is disabled while the camera stands at the window's ceiling, and zoom out
  /// at its floor (`geo.camera.zoom-limit-reached`). Where the reader asked for reduced motion, the
  /// map's step lands at once rather than easing there. `.disabled(true)` disables both.
  ///
  /// Its words are the scope's, `controls.zoomIn` and `controls.zoomOut` naming each half and the
  /// `tooltips` describing it, each replaced by `strings` where it names the word's path, and its
  /// glyphs the scope's control set (`mountayaScope(_:)`).
  public struct ZoomControl: View {
    private let map: MapEngine?
    private let onZoomInTap: (() -> Void)?
    private let onZoomOutTap: (() -> Void)?

    @ViewScope private var scope: ElementsScope
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    /// Creates the pair over `map`, its words replaced by `strings` where it names theirs, each
    /// half's press handed to its handler in place of the map where the app hands one.
    public init(
      map: MapEngine?, strings: [String: String]? = nil, onZoomInTap: (() -> Void)? = nil,
      onZoomOutTap: (() -> Void)? = nil
    ) {
      self.map = map
      self.onZoomInTap = onZoomInTap
      self.onZoomOutTap = onZoomOutTap
      _scope = ViewScope(strings: strings)
    }

    /// body is the two halves, zoom in above zoom out, on one chip.
    public var body: some View {
      let disabled = Self.disabledSteps(map)
      ControlChip {
        ControlButton(
          label: scope.word("controls.zoomIn"), help: scope.word("tooltips.zoomIn.description"),
          action: { zoomIn(reducingMotion: reducesMotion) }
        ) {
          Glyph("zoom-in", in: scope.controlGlyphs, size: 20, ink: .foreground)
        }
        .disabled(disabled.contains(.zoomIn) || (map == nil && onZoomInTap == nil))
        ControlButton(
          label: scope.word("controls.zoomOut"), help: scope.word("tooltips.zoomOut.description"),
          action: { zoomOut(reducingMotion: reducesMotion) }
        ) {
          Glyph("zoom-out", in: scope.controlGlyphs, size: 20, ink: .foreground)
        }
        .disabled(disabled.contains(.zoomOut) || (map == nil && onZoomOutTap == nil))
      }
    }

    /// zoomIn is a press on zoom in: the handler where the app handed one, the map's step
    /// otherwise, landing at once where `reducingMotion`.
    func zoomIn(reducingMotion: Bool = false) {
      if let onZoomInTap {
        onZoomInTap()
      } else {
        map?.reducesMotion = reducingMotion
        map?.zoomIn()
      }
    }

    /// zoomOut is a press on zoom out: the handler where the app handed one, the map's step
    /// otherwise, landing at once where `reducingMotion`.
    func zoomOut(reducingMotion: Bool = false) {
      if let onZoomOutTap {
        onZoomOutTap()
      } else {
        map?.reducesMotion = reducingMotion
        map?.zoomOut()
      }
    }

    /// disabledSteps is the halves the end of its zoom window the camera of `map` stands at
    /// disables, none with no map.
    static func disabledSteps(_ map: MapEngine?) -> [ZoomStep] {
      guard let map else { return [] }
      let state = map.state
      return zoomControlsDisabled(at: zoomLimitReached(state.camera.zoom, window: state.zoomBounds))
    }
  }
#endif
