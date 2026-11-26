import MountayaClient

/// placeCategoryWord is a geocoded place's category as the reader reads it.
func placeCategoryWord(_ place: DataSchema.Place, wording: SearchWording) -> String {
  guard let category = place.category else { return "" }
  return wordFor(
    .placeCategory(category), fallback: titleCase(category.rawValue.lowercased()),
    wording: wording)
}

/// poiCategoryWord is a point of interest's category as the reader reads it.
func poiCategoryWord(_ poi: DataSchema.POI, wording: SearchWording) -> String {
  guard let category = poi.category else { return "" }
  return wordFor(
    .poiCategory(category), fallback: titleCase(category.rawValue.lowercased()), wording: wording)
}

/// highwayWord is a way's `highway` tag as the reader reads it.
func highwayWord(_ way: DataSchema.Way, wording: SearchWording) -> String {
  guard let highway = way.highway else { return "" }
  return wordFor(.highway(highway), fallback: titleCase(highway), wording: wording)
}

/// placeTitle is a geocoded place's title: its name, else the geocoder's address label for an
/// address with no name, else its category, so no row is titled with nothing.
func placeTitle(_ place: DataSchema.Place, wording: SearchWording) -> String {
  if let name = place.name, !name.unicodeScalars.isEmpty { return name }
  if place.category == .address, let label = place.label, !label.unicodeScalars.isEmpty {
    return label
  }
  return placeCategoryWord(place, wording: wording)
}

/// poiTitle is a point of interest's title: its name, else its category, since many carry no name.
func poiTitle(_ poi: DataSchema.POI, wording: SearchWording) -> String {
  if let name = poi.name, !name.unicodeScalars.isEmpty { return name }
  return poiCategoryWord(poi, wording: wording)
}

/// wayTitle is a way's title: its name, else its `highway` tag, since trails are often unnamed.
func wayTitle(_ way: DataSchema.Way, wording: SearchWording) -> String {
  if let name = way.name, !name.unicodeScalars.isEmpty { return name }
  return highwayWord(way, wording: wording)
}
