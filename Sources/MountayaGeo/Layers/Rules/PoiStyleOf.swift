import MountayaClient

/// poiCategoryStyles is how a point of interest of each category the Data API declares is drawn,
/// the table the points of interest's tiles are painted with, so a search result's pin lies on the
/// tile's own in the same glyph and colour (`geo.layers.poi-style`).
///
/// It names every category the contract declares. `DataSchema.POICategory` is open, so a category
/// the vocabulary gains later decodes as itself, and has no entry until this table names it.
public let poiCategoryStyles: [DataSchema.POICategory: POIStyle] = [
  .accommodation: POIStyle(glyph: "apartment-building", color: HexColor(hex: "#7b1fa2")),
  .airport: POIStyle(glyph: "airport", color: HexColor(hex: "#455a64")),
  .busStation: POIStyle(glyph: "bus", color: HexColor(hex: "#455a64")),
  .cableCar: POIStyle(glyph: "tram", color: HexColor(hex: "#455a64")),
  .cafe: POIStyle(glyph: "cutlery", color: HexColor(hex: "#e53935")),
  .campsite: POIStyle(glyph: "camping", color: HexColor(hex: "#2e7d32")),
  .caravanSite: POIStyle(glyph: "camper-van", color: HexColor(hex: "#6d4c41")),
  .hospital: POIStyle(glyph: "medical-cross", color: HexColor(hex: "#d81b60")),
  .hut: POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800")),
  .parking: POIStyle(glyph: "parking-sign", color: HexColor(hex: "#1565c0")),
  .pass: POIStyle(glyph: "pass", color: HexColor(hex: "#795548")),
  .peak: POIStyle(glyph: "mountain", color: HexColor(hex: "#5d4037")),
  .pharmacy: POIStyle(glyph: "medical-cross", color: HexColor(hex: "#4caf50")),
  .restaurant: POIStyle(glyph: "cutlery", color: HexColor(hex: "#e53935")),
  .shelter: POIStyle(glyph: "campground", color: HexColor(hex: "#ff9800")),
  .supermarket: POIStyle(glyph: "cart", color: HexColor(hex: "#8e24aa")),
  .toilets: POIStyle(glyph: "toilet", color: HexColor(hex: "#0288d1")),
  .trainStation: POIStyle(glyph: "train", color: HexColor(hex: "#455a64")),
  .viewpoint: POIStyle(glyph: "eye", color: HexColor(hex: "#00897b")),
  .waterSource: POIStyle(glyph: "droplet", color: HexColor(hex: "#2196f3")),
]

/// poiStyleOf is how a point of interest of `category` is drawn: its entry in `poiCategoryStyles`,
/// or nil for a category the table does not name, whose pin is its caller's to draw.
///
/// The category is matched exactly, by its scalars, letter case included, as the Data API spells
/// it: `"HUT"` is a hut, and `"hut"` names no category.
public func poiStyleOf(_ category: DataSchema.POICategory) -> POIStyle? {
  // A dictionary finds a key by canonical equivalence; a category is matched by its scalars.
  guard let index = poiCategoryStyles.index(forKey: category),
    sameText(poiCategoryStyles[index].key, category)
  else { return nil }
  return poiCategoryStyles[index].value
}
