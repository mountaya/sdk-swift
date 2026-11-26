#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import MapLibre
  import MountayaGeo
  internal import UIKit

  /// MeasuredMapView is MapLibre's map as a `MapView` hosts it, which tells how far inside its
  /// edges its safe area stands, the part of it the device leaves visible, each time its layout,
  /// its window or its safe area changes (`sdk/SPEC.md` §15). On each edge it is the depth the view
  /// reaches past what its window's own insets leave visible, the status bar, a notch or display
  /// cutout and every window inset the system reports: the inset the operating system reports, and
  /// never the view's own `safeAreaInsets`, which an app's layout rewrites, a view controller's
  /// `additionalSafeAreaInsets` or a SwiftUI safe-area modifier above the map among them. So a map
  /// drawn full bleed, under SwiftUI's `ignoresSafeArea()`, reads the device's insets whatever safe
  /// area SwiftUI hands the views under it, and a map out of any window reads none. A move in its
  /// window with no layout of its own, a scroll view's scroll, a sheet's detent, an offset or a
  /// transform, reaches none of its own methods, so it measures again as the chrome over it,
  /// `MapChrome`, which SwiftUI tells of every such move, tells its engine where the map stands,
  /// and the engine hands its renderer the move (`measureLater()`). It is bound to the main actor,
  /// as every UIKit view is.
  final class MeasuredMapView: MLNMapView {
    /// onSafeArea is told the map's safe area each time it is measured.
    var onSafeArea: ((PixelPadding) -> Void)?

    override func layoutSubviews() {
      super.layoutSubviews()
      measure()
    }

    override func safeAreaInsetsDidChange() {
      super.safeAreaInsetsDidChange()
      measure()
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      measure()
    }

    /// measuredSafeArea is how far inside the map's edges its safe area stands now, read off its
    /// window's insets alone, or none while it is in no window.
    var measuredSafeArea: PixelPadding {
      guard let window else { return PixelPadding(0) }
      let shown = Self.screenRect(convert(bounds, to: window))
      let visible = Self.screenRect(window.bounds.inset(by: window.safeAreaInsets))
      return mapSafeArea(shown, visible: visible)
    }

    /// measure tells `onSafeArea` the safe area as it stands.
    private func measure() {
      onSafeArea?(measuredSafeArea)
    }

    /// measureLater tells `onSafeArea` the safe area once the drawing under way ends, read as the
    /// map then stands in its window, which a move with no layout of its own leaves its methods
    /// unaware of: its engine hands it each move the chrome over it sees (`MapSurface.mapMoved()`).
    func measureLater() {
      Task { @MainActor [weak self] in
        self?.measure()
      }
    }

    /// screenRect is `rect` as the geo layer measures a rectangle.
    static func screenRect(_ rect: CGRect) -> ScreenRect {
      ScreenRect(
        x: Double(rect.minX), y: Double(rect.minY), width: Double(rect.width),
        height: Double(rect.height))
    }

    /// cgRect is a rectangle the geo layer measures, as UIKit and SwiftUI measure one.
    static func cgRect(_ rect: ScreenRect) -> CGRect {
      CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    }
  }
#endif
