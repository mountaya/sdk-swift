import MountayaClient

/// utf16 is each range of a title as the UTF-16 offsets it spans, the indexes `sdk-kotlin` answers,
/// so a test holds the same numbers its twin holds.
func utf16(_ ranges: [Range<String.Index>], in title: String) -> [Range<Int>] {
  ranges.map { $0.lowerBound.utf16Offset(in: title)..<$0.upperBound.utf16Offset(in: title) }
}

/// SearchEntities builds the Data API's search results a row rule reads, with an OpenStreetMap
/// identity and a point.
enum SearchEntities {
  static func osm(type: String = "NODE", id: String = "9") -> DataSchema.OSMRef {
    DataSchema.OSMRef {
      $0.type = DataSchema.OSMType(rawValue: type)
      $0.id = id
    }
  }

  static func poi(
    name: String? = "Refuge du Go\u{FB}ter", category: String? = "HUT", elevation: Double? = nil,
    distance: Double? = nil, city: String? = nil, region: String? = nil, country: String? = nil,
    countryName: String? = nil, point: [Double]? = [6.5, 45.8]
  ) -> DataSchema.POI {
    DataSchema.POI {
      $0.osm = osm()
      $0.name = name
      $0.category = category.map(DataSchema.POICategory.init(rawValue:))
      $0.elevation = elevation
      $0.distanceMeters = distance
      $0.city = city
      $0.region = region
      $0.country = country
      $0.countryName = countryName
      $0.point = point
    }
  }

  static func place(
    name: String? = "Annecy", category: String? = "POPULATED_PLACE", label: String? = "",
    region: String? = nil, country: String? = nil, countryName: String? = nil,
    point: [Double]? = [6.13, 45.9], bounds: [Double]? = nil
  ) -> DataSchema.Place {
    DataSchema.Place {
      $0.osm = osm(type: "WAY", id: "7")
      $0.name = name
      $0.category = category.map(DataSchema.PlaceCategory.init(rawValue:))
      $0.label = label
      $0.region = region
      $0.country = country
      $0.countryName = countryName
      $0.point = point
      $0.bounds = bounds
    }
  }

  static func way(
    name: String? = "GR 5", highway: String? = "path", sacScale: String? = nil,
    surface: String? = nil, point: [Double]? = [6.5, 45.5]
  ) -> DataSchema.Way {
    DataSchema.Way {
      $0.osm = osm(type: "WAY", id: "3")
      $0.name = name
      $0.highway = highway
      $0.sacScale = sacScale
      $0.surface = surface
      $0.point = point
    }
  }
}
