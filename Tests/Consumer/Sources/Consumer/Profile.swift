import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo

#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
#endif

/// Profile reads an itinerary's profile and tables as an app does: the rules a chart, a strip, a
/// card at the cursor and two tables stand on, a place's card, the figures written in the reader's
/// units, and the links a data element writes to a map; and, in an iOS build with the Elements
/// trait, the profile, the two tables, the sparkline and the card over a cache of the app's client.
enum Profile {
  /// chart reads what a chart draws of `itinerary` and what its cursor states.
  static func chart(_ itinerary: RestSchema.ItineraryWithDetails) -> [String] {
    let resolved = ResolvedItinerary(itinerary)
    let series = buildElevationSeries(chainGeometry(resolved.legs) ?? resolved.geometry)
    let units = UnitPreferences(language: "fr")
    let window = clampRange(
      ProfileRange(from: 0, to: series.totalDistance / 2), totalDistance: series.totalDistance)
    let domain =
      anchoredDomain(series, anchor: .seaLevel, window: window) == profileDomain(series)
      ? extentDomain(min: 0, max: 4_810) : profileDomain(series, window: window)
    var read = domainTicks(domain).map { formatElevation($0, units: units) }
    _ = (profileViewBox, profileTopInset, profileBottomInset, profileBaseline)
    _ = (minDomainSpanMeters, minRangeSpanMeters, profileScrubColumns, axisLabelGutter)
    _ = profilePolyline(series, domain: domain, window: window).map { ($0.x, $0.y) }
    for command in profileAreaPath(series, domain: domain, window: window) {
      switch command {
      case .move(let point), .line(let point): _ = point
      case .close: break
      }
    }
    let stretches = slopeStretches(series.points)
    _ = curveStops(
      stretches.map { CurveColor(from: $0.from, to: $0.to, color: $0.color) },
      totalDistance: series.totalDistance, window: window
    ).map { ($0.offset, $0.color) }
    let placement = placeOnCurve(
      series, geometry: resolved.geometry, domain: domain, window: window,
      places: resolved.waypoints.map(ProfilePlace.init))
    for stack in amenityStacks(placement.pins) {
      read += stack.shown.map { amenityName($0, in: .standard) }
      read.append("+\(stack.counted)")
    }
    let boxes = placement.dividers.map {
      AxisLabelBox(key: $0.key, left: $0.x - 4, right: $0.x + 4)
    }
    read += cullCrowdedLabels(boxes)
    _ = placement.cutoffs.map(\.cutoffAt)
    let grid = scrubGrid(series.points, window: window)
    if let index = grid.first ?? nil {
      let point = series.points[index]
      let readout = profileReadout(series, at: point, stretches: stretches)
      read += readout.cells.map { "\($0.stat.rawValue) \($0.value)" }
      _ = (readout.grade, readout.stretch?.label, gradeAt(series.points, distance: point.distance))
      _ = (profileX(point.distance, totalDistance: series.totalDistance, window: window))
      _ = profileY(point.elevation, domain: domain)
    }
    _ = scrubDistance(column: 0, window: window)
    for tick in distanceTicks(from: window.from, to: window.to, length: units.length) {
      read.append(formatDistanceTick(tick, units: units))
    }
    let characteristics = resolveCharacteristics(
      profileTotals(series), stated: resolved.characteristics)
    for cell in statStripCells(characteristics, cursor: nil) {
      read.append("\(cell.stat.rawValue) \(cell.number ?? 0)")
    }
    read.append(
      formatAltitudeRange(
        min: characteristics.altitudeMin, max: characteristics.altitudeMax, units: units))
    _ = (surfaceColor(.paved).hex, wayTypeColor(.road).hex)
    return read
  }

  /// tables reads the rows and cells of the two tables, the filter over the places and a card.
  static func tables(_ itinerary: RestSchema.ItineraryWithDetails) -> [String] {
    let resolved = ResolvedItinerary(itinerary)
    let series = buildElevationSeries(resolved.geometry)
    let units = UnitPreferences(language: "en", length: .imperial)
    let rows = itinerarySegmentRows(series, legs: resolved.legs)
    var read: [String] = []
    for row in rows {
      for column in defaultSegmentTableColumns {
        if case .segment(let name) = segmentRowCell(row, column: column) {
          read.append(name)
        }
      }
      _ = sectionChipCells(row.metrics).map { ($0.stat, $0.value) }
      _ = (sectionGrade(row.metrics), rowStandsFor(row, id: "seg_1"))
    }
    _ = rowAt(rows, distance: series.totalDistance / 2)?.id
    _ = placeSpans(rows, totalDistance: series.totalDistance).map { ($0.start, $0.end, $0.index) }
    if let first = rows.first {
      _ = lineBetween(series.points, from: first.from, to: first.to)
    }
    let places = resolved.waypoints.map(ProfilePlace.init)
    let waypointRows = itineraryWaypointRows(series, geometry: resolved.geometry, places: places)
    for row in waypointRows {
      let cell = waypointRowCell(
        row, column: .cutoff, glyphs: ElementsScope.standard.markerGlyphs, units: units,
        formatCutoffAt: { $0.formatted(date: .omitted, time: .shortened) })
      if case .cutoff(let moment) = cell {
        read.append(moment ?? "")
      }
    }
    let picked = toggleAmenity(.water, in: [])
    let filter = amenityFilter(waypointRows, picked: picked, scope: .standard)
    read += filter.available.map(\.rawValue) + filter.shown.map(\.key)
    if let place = resolved.waypoints.first {
      let facts = waypointCard(
        place.details, scope: .standard, units: units,
        formatCutoffAt: { $0.formatted(date: .abbreviated, time: .shortened) })
      read += [facts.headline ?? ""] + facts.services.map(\.name)
      read += (facts.contact + facts.timing).map { "\($0.label): \($0.value) \($0.href ?? "")" }
      read += facts.fields.map(\.value) + facts.links.map(\.label) + facts.photos.map(\.url)
      for property in place.details?.properties ?? [] {
        read.append(waypointPropertyValue(property, units: units))
        _ = waypointPropertyLink(property)
      }
    }
    return read
  }

  /// links pins a profile's cursor marker on a map, lights the leg under it, and takes both down.
  @MainActor
  static func links(on map: MapEngine, stretch: GeoJSONGeometry?) {
    var pinned: CursorMarkerPin?
    do {
      pinned = try showCursorMarker(
        on: map, pinned: pinned,
        point: CursorMarkerPoint(id: profileCursorMarkerId, lngLat: [6.86, 45.83]))
    } catch {
      _ = error.kind
    }
    var isLit = writeLegEmphasis(on: map, isLit: false, stretch: stretch, color: "#e9501e")
    hideCursorMarker(on: map, pinned: pinned, id: profileCursorMarkerId)
    isLit = writeLegEmphasis(on: map, isLit: isLit, stretch: nil)
    _ = (isLit, cursorMarkerGlyph, segmentTableCursorMarkerId, waypointTableCursorMarkerId)
  }

  #if os(iOS) && !targetEnvironment(macCatalyst)
    /// ItineraryScreen is the README's profile and tables, compiled for iOS with the Elements trait:
    /// the map, the profile over it driving its cursor marker, and the two tables, over one cache
    /// of the app's client.
    struct ItineraryScreen: View {
      let itineraries: ItineraryResourceCache
      @State private var map: MapEngine
      @State private var window: ProfileRange?
      @State private var picked: [RestSchema.WaypointAmenity] = []

      init(mountaya: Mountaya) {
        itineraries = ItineraryResourceCache { id, surface in
          try await mountaya.studio.itineraries.getItinerary(
            itinerary_id: id, query: .init { $0.surface = surface }
          ).data
        }
        _map = State(initialValue: MapEngine(client: mountaya))
      }

      var body: some View {
        VStack(spacing: 0) {
          MapView(map)
          ItineraryProfile(
            itineraryId: "itin_abc", cache: itineraries, map: map,
            units: UnitPreferences(language: "fr"), coloring: .slope(),
            parts: [.amenities, .tooltip, .elevationAxis, .distanceAxis, .sections, .navigator],
            anchor: .window, window: $window, markerColor: "#e03131",
            formatCutoffAt: { $0.formatted(date: .omitted, time: .shortened) },
            onWaypointTap: { id in _ = id }, onError: { error in _ = error }
          )
          .frame(height: 260)
          ScrollView {
            ItinerarySegmentTable(
              itineraryId: "itin_abc", cache: itineraries, map: map,
              columns: [.segment, .profile, .distance, .elevation, .altitude, .duration],
              highlighted: "seg_1", onSegmentTap: { id in _ = id })
            ItineraryWaypointTable(
              itineraryId: "itin_abc", cache: itineraries, map: map,
              picked: $picked,
              formatCutoffAt: { $0.formatted(date: .omitted, time: .shortened) })
          }
        }
        .mountayaScope(ElementsScopeStatement(language: .fr))
      }
    }

    /// HeldItinerary is the data elements over an engine the app holds, the app choosing the
    /// itinerary through it.
    struct HeldItinerary: View {
      @State private var reading: ItineraryResourceEngine

      init(itineraries: ItineraryResourceCache) {
        _reading = State(
          initialValue: ItineraryResourceEngine(cache: itineraries, itineraryId: "itin_abc"))
      }

      var body: some View {
        VStack {
          ItineraryProfile(
            engine: reading, parts: .standard, strings: ["profile.empty": "No altitude"],
            onError: { error in _ = error })
          ItinerarySegmentTable(engine: reading, strings: ["table.empty": "No leg"])
          ItineraryWaypointTable(engine: reading, strings: ["table.waypointEmpty": "No place"])
        }
      }
    }

    /// PlaceCard is a place's card beside its sparkline, the hover handed to the app.
    struct PlaceCard: View {
      let place: ItineraryPlace
      let series: ElevationSeries

      var body: some View {
        VStack {
          ItinerarySparkline(
            series: series, lit: ProfileRange(from: 0, to: series.totalDistance / 2),
            color: "#e8590c"
          )
          .frame(width: 96, height: 24)
          WaypointCard(
            place: place, units: UnitPreferences(language: "en"),
            formatCutoffAt: { $0.formatted(date: .abbreviated, time: .shortened) },
            strings: ["waypointCard.empty": "Nothing recorded"])
          WaypointCard(place: place, strings: nil) { photo in
            Text(verbatim: photo.caption ?? photo.url)
          }
        }
      }
    }

    /// LinkedPlaceCard is a place's card whose links the app takes over, as the README shows.
    struct LinkedPlaceCard: View {
      let place: ItineraryPlace
      @State private var opened: URL?

      var body: some View {
        WaypointCard(place: place)
          .environment(
            \.openURL,
            OpenURLAction { url in
              opened = url
              return .handled
            })
      }
    }
  #endif
}
