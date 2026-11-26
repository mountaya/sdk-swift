import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("poiStyleOf")
struct PoiStyleOfTests {
  /// Every category the Data API declares, as `DataSchema.POICategory` names them.
  private let declared: [DataSchema.POICategory] = [
    .hut, .peak, .pass, .viewpoint, .parking, .waterSource, .cafe, .restaurant, .supermarket,
    .pharmacy, .toilets, .campsite, .shelter, .cableCar, .busStation, .trainStation, .airport,
    .accommodation, .caravanSite, .hospital,
  ]

  @Test("every category the Data API declares has a style, and the table holds no other")
  func everyCategory() {
    for category in declared {
      #expect(poiStyleOf(category) != nil, "\(category.rawValue)")
    }
    #expect(poiCategoryStyles.count == declared.count)
    #expect(Set(poiCategoryStyles.keys.map(\.rawValue)) == Set(declared.map(\.rawValue)))
  }

  @Test("each category is drawn with the contract's glyph and colour")
  func table() {
    let table: [String: (glyph: String, color: String)] = [
      "ACCOMMODATION": ("apartment-building", "#7b1fa2"), "AIRPORT": ("airport", "#455a64"),
      "BUS_STATION": ("bus", "#455a64"), "CABLE_CAR": ("tram", "#455a64"),
      "CAFE": ("cutlery", "#e53935"), "CAMPSITE": ("camping", "#2e7d32"),
      "CARAVAN_SITE": ("camper-van", "#6d4c41"), "HOSPITAL": ("medical-cross", "#d81b60"),
      "HUT": ("hut", "#ff9800"), "PARKING": ("parking-sign", "#1565c0"),
      "PASS": ("pass", "#795548"), "PEAK": ("mountain", "#5d4037"),
      "PHARMACY": ("medical-cross", "#4caf50"), "RESTAURANT": ("cutlery", "#e53935"),
      "SHELTER": ("campground", "#ff9800"), "SUPERMARKET": ("cart", "#8e24aa"),
      "TOILETS": ("toilet", "#0288d1"), "TRAIN_STATION": ("train", "#455a64"),
      "VIEWPOINT": ("eye", "#00897b"), "WATER_SOURCE": ("droplet", "#2196f3"),
    ]
    #expect(table.count == poiCategoryStyles.count)
    for (category, expected) in table {
      #expect(
        poiStyleOf(DataSchema.POICategory(rawValue: category))
          == POIStyle(glyph: expected.glyph, color: HexColor(hex: expected.color)),
        "\(category)")
    }
  }

  @Test("several categories share a glyph, each told apart by its colour")
  func sharedGlyph() throws {
    let pharmacy = try #require(poiStyleOf(.pharmacy))
    let hospital = try #require(poiStyleOf(.hospital))
    #expect(pharmacy.glyph == hospital.glyph)
    #expect(pharmacy.color != hospital.color)
  }

  /// A pin no set can draw would be drawn as the glyph fallback rather than as the category's own.
  @Test("every glyph is one the marker set holds, in an opaque colour of six small hex digits")
  func drawable() {
    let digits = Set("0123456789abcdef".unicodeScalars)
    for (category, style) in poiCategoryStyles {
      #expect(GlyphSet.marker.markup[style.glyph] != nil, "\(category.rawValue)")
      #expect(style.color.opacity == 1, "\(category.rawValue)")
      let scalars = Array(style.color.hex.unicodeScalars)
      #expect(scalars.count == 7 && scalars.first == "#", "\(category.rawValue)")
      #expect(scalars.dropFirst().allSatisfy { digits.contains($0) }, "\(category.rawValue)")
    }
  }

  /// Matched by its scalars, letter case included: `PAR\u{212A}ING` is written with the Kelvin
  /// sign, canonically equivalent to `K`, so Swift's `==` calls it `PARKING`.
  @Test("a category the table does not name, in another case or another spelling, has no style")
  func unnamed() {
    #expect(poiStyleOf("hut") == nil)
    #expect(poiStyleOf("Hut") == nil)
    #expect(poiStyleOf("SKI_LIFT") == nil)
    #expect(poiStyleOf("") == nil)
    #expect(poiStyleOf(" HUT") == nil)
    #expect(poiStyleOf(DataSchema.POICategory(rawValue: "PAR\u{212A}ING")) == nil)
    #expect(DataSchema.POICategory(rawValue: "PAR\u{212A}ING") == .parking)
  }
}
