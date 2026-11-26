#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  import MountayaGeo

  /// ItineraryDrawing is what the data elements draw of one itinerary, read once from its answer:
  /// the geometry its curve walks, the series, the figures stated over derived, the legs as rows,
  /// and the places as profile places and as rows.
  ///
  /// A chain the app states is also the curve (`sdk/SPEC.md` §7): its legs' geometries are walked
  /// in place of the itinerary's, which a chain carrying none falls back to, so a chip never
  /// describes a line it was not cut from.
  struct ItineraryDrawing {
    let geometry: GeoJSONGeometry?
    let series: ElevationSeries
    let characteristics: ResolvedCharacteristics
    let rows: [ItinerarySegmentRow]
    let places: [ProfilePlace]

    /// Creates what is drawn of `resolved`, its chain `legs` where the app states one.
    init(resolved: ResolvedItinerary?, legs: [ItineraryLeg]?) {
      let chain = legs ?? resolved?.legs ?? []
      let walked = legs.flatMap(chainGeometry) ?? resolved?.geometry
      let series = buildElevationSeries(walked)
      geometry = walked
      self.series = series
      characteristics = resolveCharacteristics(
        profileTotals(series), stated: resolved?.characteristics)
      rows = itinerarySegmentRows(series, legs: chain)
      places = (resolved?.waypoints ?? []).map(ProfilePlace.init)
    }

    /// waypointRows is the itinerary's places as its waypoint table's rows.
    var waypointRows: [ItineraryWaypointRow] {
      itineraryWaypointRows(series, geometry: geometry, places: places)
    }

    /// whole is the window of the whole itinerary.
    var whole: ProfileRange {
      ProfileRange(from: 0, to: series.totalDistance)
    }

    /// cursorTarget is what a profile's cursor on sample `index` writes to a map: the marker at the
    /// sample, and the leg under it lit, the later of two at the meter they share
    /// (`rowAt(_:distance:)`); nothing where no sample stands at `index`.
    func cursorTarget(at index: Int?) -> MapTarget {
      guard let index, series.points.indices.contains(index) else { return MapTarget() }
      let point = series.points[index]
      let row = rowAt(rows, distance: point.distance)
      return MapTarget(
        lngLat: point.lngLat,
        stretch: row.flatMap { lineBetween(series.points, from: $0.from, to: $0.to) })
    }

    /// segmentTarget is what pointing a segment table's row writes to a map
    /// (`segmentRowTarget(_:series:)`).
    func segmentTarget(_ row: ItinerarySegmentRow?) -> MapTarget {
      segmentRowTarget(row, series: series)
    }

    /// waypointTarget is what pointing a waypoint table's row writes to a map
    /// (`waypointRowTarget(_:series:)`).
    func waypointTarget(_ row: ItineraryWaypointRow?) -> MapTarget {
      waypointRowTarget(row, series: series)
    }
  }
#endif
