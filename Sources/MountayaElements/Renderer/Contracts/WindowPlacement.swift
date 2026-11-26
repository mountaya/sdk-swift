#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo

  /// WindowPlacement is where a view stands in its window and the part of that window the device
  /// leaves visible, the status bar, a notch or display cutout and every window inset the system
  /// reports left out, both in the window's coordinates as UIKit reports them, from its top-left
  /// corner whatever way the text runs (`sdk/SPEC.md` §15). It is the inset the operating system
  /// reports, never a value of the app's layout.
  struct WindowPlacement: Equatable {
    /// view is where the view stands in its window.
    let view: ScreenRect
    /// visible is the part of the window the device leaves visible.
    let visible: ScreenRect

    /// safeArea is how far inside the view's edges the part of it the device leaves visible stands,
    /// as a map's safe area is read (`mapSafeArea`).
    var safeArea: PixelPadding {
      mapSafeArea(view, visible: visible)
    }
  }
#endif
