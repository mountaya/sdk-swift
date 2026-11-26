#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI
  internal import UIKit

  /// tokenColor is the colour `token` reads under `scheme` (`geo.style.theme-tokens`) as SwiftUI
  /// draws it, at the token's opacity, and clear where the value is no CSS hexadecimal colour.
  func tokenColor(_ token: ThemeToken<HexColor>, in scheme: ThemeScheme) -> Color {
    hexColor(themeTokenValue(token, in: scheme))
  }

  /// hexColor is `color` as SwiftUI draws it, at its opacity, and clear where it is no CSS
  /// hexadecimal colour.
  func hexColor(_ color: HexColor) -> Color {
    uiColor(color.hex, opacity: color.opacity).map(Color.init(uiColor:)) ?? .clear
  }

  /// themeScheme is the scheme an element is drawn in under SwiftUI's colour scheme: dark under
  /// the dark one, light under any other.
  func themeScheme(_ scheme: ColorScheme) -> ThemeScheme {
    scheme == .dark ? .dark : .light
  }
#endif
