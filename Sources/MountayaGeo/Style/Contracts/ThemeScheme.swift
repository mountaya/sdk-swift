/// ThemeScheme is the colour scheme an element is drawn under, light or dark, its raw value the
/// contract's spelling (`geo.style.theme-tokens`).
///
/// It names no platform's scheme, so it builds and compares everywhere: a view reads the scheme its
/// platform draws under into it, SwiftUI's `colorScheme` among them.
public enum ThemeScheme: String, Sendable, Hashable, CaseIterable {
  /// light is the light scheme, under which every token reads its light value.
  case light
  /// dark is the dark scheme, under which a token reads its dark value where it states one.
  case dark
}
