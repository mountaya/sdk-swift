#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import SwiftUI
  internal import UIKit

  /// textWidth is how wide `text` is laid out in the system font of `style` at the text size
  /// `size`, the reader's where it is nil, in points, which a row of names measures to leave the
  /// crowded ones out (`geo.profile.axis-label-culling`). A view hands the size SwiftUI's
  /// environment carries, so the names it measures are the names it draws.
  func textWidth(_ text: String, style: UIFont.TextStyle, size: DynamicTypeSize? = nil) -> Double {
    let font =
      size.map { size in
        UIFont.preferredFont(
          forTextStyle: style,
          compatibleWith: UITraitCollection(
            preferredContentSizeCategory: UIContentSizeCategory(size))
        )
      } ?? UIFont.preferredFont(forTextStyle: style)
    return Double((text as NSString).size(withAttributes: [.font: font]).width)
  }
#endif
