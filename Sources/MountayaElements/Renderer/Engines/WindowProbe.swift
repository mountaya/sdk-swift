#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI
  internal import UIKit

  /// WindowProbe reads where the view it marks is laid in its window, and the part of that window
  /// the device leaves visible, as UIKit reports them, and tells `onPlaced` each time that changes,
  /// nil while the view is in no window (`sdk/SPEC.md` §15). It stands at the marked view's top-left
  /// corner and takes no room, so nothing of it is ever drawn: `moved` is where SwiftUI last saw the
  /// marked view, in global coordinates, its size the view's, and a change of it, the view laid out
  /// again or moved in its window with no layout of its own by a scroll view, a sheet or a
  /// transform, has the probe read its window again, as its window and its window's insets changing
  /// do. It reads the insets the operating system reports, never a view's own `safeAreaInsets`,
  /// which an app's layout rewrites, so a view under SwiftUI's `ignoresSafeArea()` reads the
  /// device's. It takes no touch.
  struct WindowProbe: UIViewRepresentable {
    let moved: CGRect
    let onPlaced: (WindowPlacement?) -> Void

    /// makeUIView makes the view that reads its window.
    func makeUIView(context: Context) -> WindowProbeView {
      let view = WindowProbeView()
      view.isUserInteractionEnabled = false
      view.size = moved.size
      view.onPlaced = onPlaced
      return view
    }

    /// updateUIView hands the view the marked view's size and the handler drawn last, and reads
    /// its window again, since the marked view may have moved in it.
    func updateUIView(_ view: WindowProbeView, context: Context) {
      view.size = moved.size
      view.onPlaced = onPlaced
      view.measureLater()
    }

    /// sizeThatFits answers no room, so the probe is never drawn.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WindowProbeView, context: Context)
      -> CGSize?
    {
      .zero
    }
  }

  /// WindowProbeView is the view under a `WindowProbe`, standing at the top-left corner of the view
  /// it marks, which reads where that view stands in its window. It is bound to the main actor, as
  /// every UIKit view is.
  final class WindowProbeView: UIView {
    /// size is the size of the view it marks.
    var size = CGSize.zero
    /// onPlaced is told where the marked view stands each time that changes.
    var onPlaced: ((WindowPlacement?) -> Void)?
    /// told is the placement told last, and isTold whether one was.
    private var told: WindowPlacement?
    private var isTold = false

    override func layoutSubviews() {
      super.layoutSubviews()
      measureLater()
    }

    override func safeAreaInsetsDidChange() {
      super.safeAreaInsetsDidChange()
      measureLater()
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      measureLater()
    }

    /// placement is where the marked view stands in its window now, or nil while it is in no window.
    var placement: WindowPlacement? {
      guard let window else { return nil }
      let corner = convert(CGPoint.zero, to: window)
      return WindowPlacement(
        view: MeasuredMapView.screenRect(CGRect(origin: corner, size: size)),
        visible: MeasuredMapView.screenRect(window.bounds.inset(by: window.safeAreaInsets)))
    }

    /// measureLater tells `onPlaced` the placement once the drawing under way ends, read as it then
    /// stands, so a state SwiftUI holds is never written while SwiftUI draws, and the last reading
    /// told is the latest.
    func measureLater() {
      Task { @MainActor [weak self] in
        self?.measure()
      }
    }

    /// measure tells `onPlaced` the placement as it stands, where it changed.
    func measure() {
      let placement = self.placement
      guard !isTold || placement != told else { return }
      isTold = true
      told = placement
      onPlaced?(placement)
    }
  }
#endif
