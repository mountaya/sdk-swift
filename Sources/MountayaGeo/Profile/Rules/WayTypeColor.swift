import MountayaClient

/// wayTypeColors is the colour each way type paints a profile's way-type bar in, the `wayTypes`
/// `geo/profile-classification-colors.json` declares: blues for cycle ways, greens for natural
/// paths, oranges and reds for roads and purples for pedestrian ways, a fixed scale rather than
/// theme tokens, so a legend reads the same under every brand.
public let wayTypeColors: [RestSchema.WayType: HexColor] = [
  "construction": HexColor(hex: "#f43f5e"),
  "cycleway": HexColor(hex: "#3b82f6"),
  "ferry": HexColor(hex: "#06b6d4"),
  "footway": HexColor(hex: "#8b5cf6"),
  "path": HexColor(hex: "#22c55e"),
  "road": HexColor(hex: "#f97316"),
  "state-road": HexColor(hex: "#ef4444"),
  "steps": HexColor(hex: "#6366f1"),
  "street": HexColor(hex: "#eab308"),
  "track": HexColor(hex: "#a16207"),
  "unknown": unclassifiedColor,
]

/// wayTypeColor is the colour a stretch of `wayType` paints a profile's way-type bar in
/// (`geo.profile.classification-colors`), `unclassifiedColor` for one the table does not name, as
/// it is for `unknown`.
public func wayTypeColor(_ wayType: RestSchema.WayType) -> HexColor {
  wayTypeColors[wayType] ?? unclassifiedColor
}
