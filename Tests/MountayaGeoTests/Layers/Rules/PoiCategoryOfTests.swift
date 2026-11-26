import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("poiCategoryOf")
struct PoiCategoryOfTests {
  @Test("a tile's category reads as the API's through the table, several naming one")
  func reads() {
    #expect(poiCategoryOf("alpine_hut") == .hut)
    #expect(poiCategoryOf("wilderness_hut") == .hut)
    #expect(poiCategoryOf("camp_site") == .campsite)
    #expect(poiCategoryOf("restaurant") == .restaurant)
    #expect(poiCategoryOf("fast_food") == .restaurant)
    #expect(poiCategoryOf("food_court") == .restaurant)
    #expect(poiCategoryOf("spring") == .waterSource)
    #expect(poiCategoryOf("drinking_water") == .waterSource)
    #expect(poiCategoryOf("water_well") == .waterSource)
  }

  @Test("the table is the contract's, every entry read through the rule")
  func table() {
    let table: [String: String] = [
      "alpine_hut": "HUT", "cafe": "CAFE", "camp_site": "CAMPSITE",
      "caravan_site": "CARAVAN_SITE", "chalet": "ACCOMMODATION", "drinking_water": "WATER_SOURCE",
      "fast_food": "RESTAURANT", "food_court": "RESTAURANT", "guest_house": "ACCOMMODATION",
      "hospital": "HOSPITAL", "hostel": "ACCOMMODATION", "hotel": "ACCOMMODATION",
      "parking": "PARKING", "pharmacy": "PHARMACY", "restaurant": "RESTAURANT",
      "shelter": "SHELTER", "spring": "WATER_SOURCE", "toilets": "TOILETS",
      "viewpoint": "VIEWPOINT", "water_well": "WATER_SOURCE", "wilderness_hut": "HUT",
    ]
    #expect(poiTileCategories.mapValues(\.rawValue) == table)
    for (tile, category) in table {
      #expect(poiCategoryOf(tile)?.rawValue == category, "\(tile)")
    }
  }

  /// The two tables are written apart, so a tile category could name a category with no style,
  /// which would draw no pin.
  @Test("every tile category reads as a category that has a style")
  func styled() {
    for (tile, category) in poiTileCategories {
      #expect(poiStyleOf(category) != nil, "\(tile)")
    }
  }

  @Test("a category reads without regard to the case of its ASCII letters")
  func asciiCase() {
    #expect(poiCategoryOf("Restaurant") == .restaurant)
    #expect(poiCategoryOf("DRINKING_WATER") == .waterSource)
    #expect(poiCategoryOf("ALPINE_HUT") == .hut)
  }

  /// Only A to Z fold: a capital outside ASCII, a full-width letter and the Kelvin sign, which
  /// Unicode's lowercasing reads as `k`, name another category.
  @Test("only the ASCII capitals fold, and nothing is trimmed")
  func asciiOnly() {
    #expect(poiCategoryOf("ALP\u{130}NE_HUT") == nil)
    #expect(poiCategoryOf("ＣＡＦＥ") == nil)
    #expect(poiCategoryOf("PAR\u{212A}ING") == nil)
    #expect(poiCategoryOf(" cafe") == nil)
    #expect(poiCategoryOf("cafe ") == nil)
  }

  @Test("a category the table does not name reads as none, a name every object inherits included")
  func unnamed() {
    #expect(poiCategoryOf("nuclear_power_plant") == nil)
    #expect(poiCategoryOf("") == nil)
    for name in ["constructor", "toString", "hasOwnProperty", "__proto__", "valueOf"] {
      #expect(poiCategoryOf(name) == nil, "\(name)")
    }
  }
}
