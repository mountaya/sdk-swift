#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import UIKit

  /// uiColor reads a CSS hexadecimal colour, `#rgb`, `#rrggbb` or `#rrggbbaa` in either case, into
  /// UIKit's, at `opacity` times its own alpha, or nil where it is none.
  func uiColor(_ written: String, opacity: Double = 1) -> UIColor? {
    let scalars = Array(written.unicodeScalars)
    guard scalars.first == "#",
      scalars.dropFirst().allSatisfy({ $0.properties.isASCIIHexDigit })
    else { return nil }
    var digits = String(String.UnicodeScalarView(scalars.dropFirst()))
    if digits.count == 3 {
      digits = digits.map { "\($0)\($0)" }.joined()
    }
    if digits.count == 6 {
      digits += "ff"
    }
    guard digits.count == 8, let value = UInt32(digits, radix: 16) else { return nil }
    return UIColor(
      red: CGFloat((value >> 24) & 0xff) / 255, green: CGFloat((value >> 16) & 0xff) / 255,
      blue: CGFloat((value >> 8) & 0xff) / 255,
      alpha: CGFloat(value & 0xff) / 255 * CGFloat(opacity))
  }
#endif
