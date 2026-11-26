// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/tokens.json`, model digest
// c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and printed
// again (SPEC.md section 3).

/// ElementTokens is every colour and dash the elements are drawn with, as the contract's tokens
/// table names them, each spelled in camel case: `control-bg` is `controlBg`. The sizes, the radii,
/// the fonts and the geometry of the shadows are each platform's own and are not here.
///
/// A consumer restyles the elements by setting the tokens it changes on a copy of `standard`, which
/// is every token as the table states it.
public struct ElementTokens: Sendable, Hashable {
  /// accent is the colour token `accent`.
  public var accent: ThemeToken<HexColor>
  /// controlBg is the colour token `control-bg`.
  public var controlBg: ThemeToken<HexColor>
  /// profileLitFill is the colour token `profile-lit-fill`.
  public var profileLitFill: ThemeToken<HexColor>
  /// controlShadow is the shadow token `control-shadow`: each layer's colour, in drawing order.
  public var controlShadow: ThemeToken<[HexColor]>
  /// profileCursorDash is the dash token `profile-cursor-dash`: lengths, alternately drawn and
  /// skipped.
  public var profileCursorDash: ThemeToken<[Double]>

  /// standard is every token as the contract's tokens table states it.
  public static let standard = ElementTokens(
    accent: ThemeToken(light: HexColor(hex: "#1c7ed6")),
    controlBg: ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#25262b")),
    profileLitFill: ThemeToken(light: HexColor(hex: "#e9501e", opacity: 0.12)),
    controlShadow: ThemeToken(light: [HexColor(hex: "#000000", opacity: 0.05), HexColor(hex: "#000000", opacity: 0.1)]),
    profileCursorDash: ThemeToken(light: [3, 3.5])
  )

  /// colorTokens is each colour token's member, by the name the table gives it.
  static let colorTokens: [String: any KeyPath<ElementTokens, ThemeToken<HexColor>> & Sendable] = [
    "accent": \ElementTokens.accent,
    "control-bg": \ElementTokens.controlBg,
    "profile-lit-fill": \ElementTokens.profileLitFill,
  ]

  /// shadowTokens is each shadow token's member, by the name the table gives it.
  static let shadowTokens: [String: any KeyPath<ElementTokens, ThemeToken<[HexColor]>> & Sendable] = [
    "control-shadow": \ElementTokens.controlShadow,
  ]

  /// dashTokens is each dash token's member, by the name the table gives it.
  static let dashTokens: [String: any KeyPath<ElementTokens, ThemeToken<[Double]>> & Sendable] = [
    "profile-cursor-dash": \ElementTokens.profileCursorDash,
  ]
}
