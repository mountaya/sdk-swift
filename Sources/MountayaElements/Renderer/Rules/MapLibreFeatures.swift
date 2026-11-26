#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  import MountayaGeo

  /// mapLibreFeatures are `features` as MapLibre is handed them: each feature whose geometry is a
  /// GeometryCollection laid out as one feature per geometry it holds, each with the feature's
  /// properties, a GeometryCollection held in another read in turn, and one holding none handing
  /// none. A segment's geometry is one, its routed LineString and a MultiPoint of the points it was
  /// routed through (`ItinerarySegment.geojson`).
  ///
  /// MapLibre on iOS, handed a feature of a GeometryCollection as GeoJSON, throws an exception
  /// nothing catches and ends the app. Every other platform draws such a feature as the geometries
  /// it holds, so laid out so the map draws the same everywhere.
  func mapLibreFeatures(_ features: [GeoJSONFeature]) -> [GeoJSONFeature] {
    var laid: [GeoJSONFeature] = []
    laid.reserveCapacity(features.count)
    for feature in features {
      if case .geometryCollection(let collection)? = feature.geometry {
        layOut(collection, properties: feature.properties, into: &laid)
      } else {
        laid.append(feature)
      }
    }
    return laid
  }

  /// layOut appends to `laid` a feature carrying `properties` for each geometry `collection`
  /// holds, those of a GeometryCollection it holds in turn.
  private func layOut(
    _ collection: GeoJSONGeometryCollection, properties: [String: JSONValue],
    into laid: inout [GeoJSONFeature]
  ) {
    for geometry in collection.geometries {
      if case .geometryCollection(let held) = geometry {
        layOut(held, properties: properties, into: &laid)
      } else {
        laid.append(GeoJSONFeature(geometry: geometry, properties: properties))
      }
    }
  }
#endif
