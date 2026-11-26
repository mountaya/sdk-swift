/// HexColor is a colour as the contract's tables write one: its red, green and blue as six
/// hexadecimal digits, `#rrggbb`, and its opacity, 1 where it is opaque.
///
/// It names no platform's colour type, so it builds and compares everywhere; a renderer reads it
/// into its own where it draws. Two are equal where their digits are written with the same scalars
/// and their opacities are the same number, `NaN` the same as `NaN` and 0 another than -0, as every
/// value of the geo layer compares; equal colours hash alike.
public struct HexColor: Sendable, Hashable {
  /// hex is the colour's red, green and blue, `#rrggbb`, as the table writes them.
  public var hex: String
  /// opacity is how opaque the colour is, from 0 to 1.
  public var opacity: Double

  /// Creates a colour from its six hexadecimal digits and its opacity, opaque where none is given.
  public init(hex: String, opacity: Double = 1) {
    self.hex = hex
    self.opacity = opacity
  }

  /// Two colours are equal where their digits and their opacity are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.hex, rhs.hex) && sameNumber(lhs.opacity, rhs.opacity)
  }

  /// hash feeds the digits, then the opacity as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(hex)
    hasher.combine(sameNumber: opacity)
  }
}
