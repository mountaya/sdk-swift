// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/tokens.json`, model digest
// f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
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
  /// controlBgHover is the colour token `control-bg-hover`.
  public var controlBgHover: ThemeToken<HexColor>
  /// controlFg is the colour token `control-fg`.
  public var controlFg: ThemeToken<HexColor>
  /// controlFgDisabled is the colour token `control-fg-disabled`.
  public var controlFgDisabled: ThemeToken<HexColor>
  /// dimmed is the colour token `dimmed`.
  public var dimmed: ThemeToken<HexColor>
  /// focusRing is the colour token `focus-ring`.
  public var focusRing: ThemeToken<HexColor>
  /// panelBg is the colour token `panel-bg`.
  public var panelBg: ThemeToken<HexColor>
  /// panelBorder is the colour token `panel-border`.
  public var panelBorder: ThemeToken<HexColor>
  /// panelFg is the colour token `panel-fg`.
  public var panelFg: ThemeToken<HexColor>
  /// profileCursor is the colour token `profile-cursor`.
  public var profileCursor: ThemeToken<HexColor>
  /// profileGridColor is the colour token `profile-grid-color`.
  public var profileGridColor: ThemeToken<HexColor>
  /// profileLitFill is the colour token `profile-lit-fill`.
  public var profileLitFill: ThemeToken<HexColor>
  /// profileNavigatorHandle is the colour token `profile-navigator-handle`.
  public var profileNavigatorHandle: ThemeToken<HexColor>
  /// profileNavigatorVeil is the colour token `profile-navigator-veil`.
  public var profileNavigatorVeil: ThemeToken<HexColor>
  /// profileTooltipBg is the colour token `profile-tooltip-bg`.
  public var profileTooltipBg: ThemeToken<HexColor>
  /// profileTooltipFg is the colour token `profile-tooltip-fg`.
  public var profileTooltipFg: ThemeToken<HexColor>
  /// profileWaypointColor is the colour token `profile-waypoint-color`.
  public var profileWaypointColor: ThemeToken<HexColor>
  /// profileWaypointLine is the colour token `profile-waypoint-line`.
  public var profileWaypointLine: ThemeToken<HexColor>
  /// tableBorder is the colour token `table-border`.
  public var tableBorder: ThemeToken<HexColor>
  /// tableRowHover is the colour token `table-row-hover`.
  public var tableRowHover: ThemeToken<HexColor>
  /// tableSparkBase is the colour token `table-spark-base`.
  public var tableSparkBase: ThemeToken<HexColor>
  /// tooltipBg is the colour token `tooltip-bg`.
  public var tooltipBg: ThemeToken<HexColor>
  /// tooltipFg is the colour token `tooltip-fg`.
  public var tooltipFg: ThemeToken<HexColor>
  /// waypointCardMarkColor is the colour token `waypoint-card-mark-color`.
  public var waypointCardMarkColor: ThemeToken<HexColor>
  /// waypointCardMarkFg is the colour token `waypoint-card-mark-fg`.
  public var waypointCardMarkFg: ThemeToken<HexColor>
  /// controlShadow is the shadow token `control-shadow`: each layer's colour, in drawing order.
  public var controlShadow: ThemeToken<[HexColor]>
  /// profileTooltipShadow is the shadow token `profile-tooltip-shadow`: each layer's colour, in
  /// drawing order.
  public var profileTooltipShadow: ThemeToken<[HexColor]>
  /// profileCursorDash is the dash token `profile-cursor-dash`: lengths, alternately drawn and
  /// skipped.
  public var profileCursorDash: ThemeToken<[Double]>

  /// standard is every token as the contract's tokens table states it.
  public static let standard = ElementTokens(
    accent: ThemeToken(light: HexColor(hex: "#1c7ed6")),
    controlBg: ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#25262b")),
    controlBgHover: ThemeToken(light: HexColor(hex: "#f1f3f5"), dark: HexColor(hex: "#373a40")),
    controlFg: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#c1c2c5")),
    controlFgDisabled: ThemeToken(light: HexColor(hex: "#adb5bd"), dark: HexColor(hex: "#5c5f66")),
    dimmed: ThemeToken(light: HexColor(hex: "#868e96")),
    focusRing: ThemeToken(light: HexColor(hex: "#1c7ed6")),
    panelBg: ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#25262b")),
    panelBorder: ThemeToken(light: HexColor(hex: "#dee2e6"), dark: HexColor(hex: "#373a40")),
    panelFg: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#c1c2c5")),
    profileCursor: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#c1c2c5")),
    profileGridColor: ThemeToken(light: HexColor(hex: "#dee2e6"), dark: HexColor(hex: "#373a40")),
    profileLitFill: ThemeToken(light: HexColor(hex: "#e9501e", opacity: 0.12)),
    profileNavigatorHandle: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#c1c2c5")),
    profileNavigatorVeil: ThemeToken(light: HexColor(hex: "#ffffff", opacity: 0.62), dark: HexColor(hex: "#000000", opacity: 0.55)),
    profileTooltipBg: ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#2c2e33")),
    profileTooltipFg: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#c1c2c5")),
    profileWaypointColor: ThemeToken(light: HexColor(hex: "#868e96")),
    profileWaypointLine: ThemeToken(light: HexColor(hex: "#adb5bd"), dark: HexColor(hex: "#5c5f66")),
    tableBorder: ThemeToken(light: HexColor(hex: "#dee2e6"), dark: HexColor(hex: "#373a40")),
    tableRowHover: ThemeToken(light: HexColor(hex: "#f1f3f5"), dark: HexColor(hex: "#2c2e33")),
    tableSparkBase: ThemeToken(light: HexColor(hex: "#dee2e6"), dark: HexColor(hex: "#373a40")),
    tooltipBg: ThemeToken(light: HexColor(hex: "#212529"), dark: HexColor(hex: "#f1f3f5")),
    tooltipFg: ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#141517")),
    waypointCardMarkColor: ThemeToken(light: HexColor(hex: "#3b82f6")),
    waypointCardMarkFg: ThemeToken(light: HexColor(hex: "#ffffff")),
    controlShadow: ThemeToken(light: [HexColor(hex: "#000000", opacity: 0.05), HexColor(hex: "#000000", opacity: 0.1)]),
    profileTooltipShadow: ThemeToken(light: [HexColor(hex: "#000000", opacity: 0.12)]),
    profileCursorDash: ThemeToken(light: [3, 3])
  )

  /// colorTokens is each colour token's member, by the name the table gives it.
  static let colorTokens: [String: any KeyPath<ElementTokens, ThemeToken<HexColor>> & Sendable] = [
    "accent": \ElementTokens.accent,
    "control-bg": \ElementTokens.controlBg,
    "control-bg-hover": \ElementTokens.controlBgHover,
    "control-fg": \ElementTokens.controlFg,
    "control-fg-disabled": \ElementTokens.controlFgDisabled,
    "dimmed": \ElementTokens.dimmed,
    "focus-ring": \ElementTokens.focusRing,
    "panel-bg": \ElementTokens.panelBg,
    "panel-border": \ElementTokens.panelBorder,
    "panel-fg": \ElementTokens.panelFg,
    "profile-cursor": \ElementTokens.profileCursor,
    "profile-grid-color": \ElementTokens.profileGridColor,
    "profile-lit-fill": \ElementTokens.profileLitFill,
    "profile-navigator-handle": \ElementTokens.profileNavigatorHandle,
    "profile-navigator-veil": \ElementTokens.profileNavigatorVeil,
    "profile-tooltip-bg": \ElementTokens.profileTooltipBg,
    "profile-tooltip-fg": \ElementTokens.profileTooltipFg,
    "profile-waypoint-color": \ElementTokens.profileWaypointColor,
    "profile-waypoint-line": \ElementTokens.profileWaypointLine,
    "table-border": \ElementTokens.tableBorder,
    "table-row-hover": \ElementTokens.tableRowHover,
    "table-spark-base": \ElementTokens.tableSparkBase,
    "tooltip-bg": \ElementTokens.tooltipBg,
    "tooltip-fg": \ElementTokens.tooltipFg,
    "waypoint-card-mark-color": \ElementTokens.waypointCardMarkColor,
    "waypoint-card-mark-fg": \ElementTokens.waypointCardMarkFg,
  ]

  /// shadowTokens is each shadow token's member, by the name the table gives it.
  static let shadowTokens: [String: any KeyPath<ElementTokens, ThemeToken<[HexColor]>> & Sendable] = [
    "control-shadow": \ElementTokens.controlShadow,
    "profile-tooltip-shadow": \ElementTokens.profileTooltipShadow,
  ]

  /// dashTokens is each dash token's member, by the name the table gives it.
  static let dashTokens: [String: any KeyPath<ElementTokens, ThemeToken<[Double]>> & Sendable] = [
    "profile-cursor-dash": \ElementTokens.profileCursorDash,
  ]
}
