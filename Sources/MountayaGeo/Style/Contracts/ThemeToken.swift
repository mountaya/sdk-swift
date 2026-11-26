/// ThemeToken is one of the values the elements are drawn with: its value under the light scheme,
/// and its value under the dark scheme where it states one of its own.
///
/// `ElementTokens` holds every token the contract's tokens table names, and a consumer restyles the
/// elements by setting the tokens it changes on a copy of `ElementTokens.standard`.
///
/// Two are equal where both values are the same, a number or a list of numbers by the same-number
/// relation, `NaN` the same as `NaN` and 0 another than -0, as every value of the geo layer
/// compares, so a dash compares number by number; equal tokens hash alike.
public struct ThemeToken<Value: Sendable & Hashable>: Sendable, Hashable {
  /// light is the value under the light scheme, and under the dark one where `dark` is nil.
  public var light: Value
  /// dark is the value under the dark scheme, or nil where the token reads `light` there too.
  public var dark: Value?

  /// Creates a token from its light value and, where it has one, its own dark value.
  public init(light: Value, dark: Value? = nil) {
    self.light = light
    self.dark = dark
  }

  /// Two tokens are equal where both values are the same, an absent dark value the same only as
  /// another absent one.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameValue(lhs.light, rhs.light) && sameValue(lhs.dark, rhs.dark)
  }

  /// hash feeds both values, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameValue: light)
    hasher.combine(sameValue: dark)
  }
}
