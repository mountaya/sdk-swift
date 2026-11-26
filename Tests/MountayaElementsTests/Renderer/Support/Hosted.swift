import SwiftUI
import UIKit

/// Hosted shows a SwiftUI view in a window, as an app shows one, so its tasks run, and reads how
/// it lays itself out there.
@MainActor
public enum Hosted {
  /// showing returns a controller hosting `view` and the window showing it, kept for as long as
  /// the window is held.
  public static func showing(_ view: some View) -> (UIHostingController<AnyView>, UIWindow) {
    let host = UIHostingController(rootView: AnyView(view))
    // Laid out as the view alone, the window's safe area aside.
    host.safeAreaRegions = []
    return (host, MapWindow.showing(host.view))
  }

  /// height is how high the view `host` shows lays itself out across `width` points.
  public static func height(_ host: UIHostingController<AnyView>, width: CGFloat = 390) -> CGFloat {
    host.sizeThatFits(in: CGSize(width: width, height: 10_000)).height
  }
}
