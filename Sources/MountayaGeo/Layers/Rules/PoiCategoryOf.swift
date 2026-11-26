import MountayaClient

/// poiTileCategories is the Data API category each category of the points of interest's tiles
/// reads as, keyed by the tile's category as OpenMapTiles spells it, in small letters
/// (`geo.layers.poi-category`). Several tile categories read as one: a spring, a drinking water tap
/// and a well are each a water source, since the API's category says what a place is for.
public let poiTileCategories: [String: DataSchema.POICategory] = [
  "alpine_hut": .hut,
  "cafe": .cafe,
  "camp_site": .campsite,
  "caravan_site": .caravanSite,
  "chalet": .accommodation,
  "drinking_water": .waterSource,
  "fast_food": .restaurant,
  "food_court": .restaurant,
  "guest_house": .accommodation,
  "hospital": .hospital,
  "hostel": .accommodation,
  "hotel": .accommodation,
  "parking": .parking,
  "pharmacy": .pharmacy,
  "restaurant": .restaurant,
  "shelter": .shelter,
  "spring": .waterSource,
  "toilets": .toilets,
  "viewpoint": .viewpoint,
  "water_well": .waterSource,
  "wilderness_hut": .hut,
]

/// poiCategoryOf reads the Data API category a point of interest of the tiles is, from the
/// `category` its feature carries: its entry in `poiTileCategories`, or nil where the table names
/// none, so a tap on the map never asks the API about a category the reader did not point at.
///
/// The category is read with its ASCII capitals folded and nothing else, never by a locale's case
/// rules, and matched by its scalars, nothing trimmed: `Restaurant` and `DRINKING_WATER` read as
/// the table's, while ` cafe`, a full-width `ＣＡＦＥ`, the empty category and `constructor`, which
/// another language's objects all inherit, read as none.
public func poiCategoryOf(_ category: String) -> DataSchema.POICategory? {
  let key = asciiLowercase(category)
  // A dictionary finds a key by canonical equivalence; a tile's category is matched by its scalars.
  guard let index = poiTileCategories.index(forKey: key),
    sameText(poiTileCategories[index].key, key)
  else { return nil }
  return poiTileCategories[index].value
}
