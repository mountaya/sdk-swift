import MountayaClient

/// unclassifiedColor is the neutral grey a stretch no classification names paints a profile's
/// classification bar in, the `unclassified` `geo/profile-classification-colors.json` declares, the
/// one `surfaceColors` and `wayTypeColors` give `unknown` alike.
public let unclassifiedColor = HexColor(hex: "#94a3b8")

/// surfaceColors is the colour each surface paints a profile's surface bar in, the `surfaces`
/// `geo/profile-classification-colors.json` declares: slate and stone greys for hard surfaces,
/// browns and ambers for loose ground and greens for vegetation, a fixed scale rather than theme
/// tokens, so a legend reads the same under every brand.
public let surfaceColors: [RestSchema.SurfaceType: HexColor] = [
  "asphalt": HexColor(hex: "#334155"),
  "cobblestone": HexColor(hex: "#a8a29e"),
  "compacted-gravel": HexColor(hex: "#b45309"),
  "concrete": HexColor(hex: "#64748b"),
  "dirt": HexColor(hex: "#92400e"),
  "fine-gravel": HexColor(hex: "#ca8a04"),
  "grass": HexColor(hex: "#22c55e"),
  "grass-paver": HexColor(hex: "#65a30d"),
  "gravel": HexColor(hex: "#d4a574"),
  "ground": HexColor(hex: "#78716c"),
  "ice": HexColor(hex: "#bfdbfe"),
  "metal": HexColor(hex: "#71717a"),
  "paved": HexColor(hex: "#475569"),
  "paving-stones": HexColor(hex: "#6b7280"),
  "sand": HexColor(hex: "#fbbf24"),
  "unknown": unclassifiedColor,
  "unpaved": HexColor(hex: "#d97706"),
  "wood": HexColor(hex: "#a16207"),
  "woodchips": HexColor(hex: "#854d0e"),
]

/// surfaceColor is the colour a stretch of `surface` paints a profile's surface bar in
/// (`geo.profile.classification-colors`), `unclassifiedColor` for one the table does not name, as
/// it is for `unknown`, since the vocabulary is open and a surface a later contract adds still
/// paints.
public func surfaceColor(_ surface: RestSchema.SurfaceType) -> HexColor {
  surfaceColors[surface] ?? unclassifiedColor
}
