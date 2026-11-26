import Foundation
import MountayaClient
import MountayaGeo
import Observation

/// Geo reads the geo layer as an app does: a rule of every topic, the values a rule answers and a
/// host builds for its own screens, the navigation engine conformed from outside, the scripted
/// engine an app's tests answer, and every error the layer reports.
enum Geo {
  /// measurements calls the rules a screen reads a route and a reader's units through.
  static func measurements() {
    let line: [[Double]] = [[6.8652, 45.9237], [6.9271, 45.9682]]
    let meters = haversineMeters(from: line[0], to: line[1])
    let units = UnitPreferences(language: "fr-CH", length: .imperial)
    _ = (
      convertLength(meters, from: .meter, to: .mile), formatDistance(meters, units: units),
      formatElevation(1_035, units: units), formatDuration(5_400, units: units),
      formatLngLat(line[0]), formatNumber(1_531.25, locale: "de-CH"),
      bearingDegrees(from: line[0], to: line[1]), routeLengthMeters(line),
      cumulativeMeters(line), positionAtMeters(line, meters: 100),
      metersToRoute([6.9, 45.95], lines: [GeoJSONLineString(coordinates: line)])
    )
    let series = buildElevationSeries(
      .lineString(GeoJSONLineString(coordinates: [[6.86, 45.92, 1_035], [6.93, 45.97, 1_210]])))
    _ = (profileTotals(series), series.hasElevation, series.points.first?.distance)
    _ = (
      boundsOf([.lineString(GeoJSONLineString(coordinates: line))]),
      normalizeBoundingBox([6.8, 45.9, 6.9, 46]), timeZoneViewport("Europe/Zurich")?.zoom,
      segmentColorAt(3), highlightParts("Chamonix", query: "cham").map(\.match),
      searchQueryChangeOf(settled: "", typed: "Cham"),
      zoneRow(DataSchema.ZoneSearchResult { $0.id = "z" }, query: "cham")?.parts.map(\.text)
    )
    // The camera a map frames: a box fitted on a canvas, an itinerary's and a collection's box, a
    // window a camera eases into, and the box a device fix spans.
    let fitted = cameraForBounds(
      [6.8, 45.8, 6.95, 45.9], canvas: [800, 600], padding: PixelPadding(48), maxZoom: 15,
      window: ZoomBounds(minZoom: 0, maxZoom: 25.5))
    _ = (fitted?.center, fitted?.zoom)
    _ = (
      itineraryBounds([]), specificationBounds([179.8, -17, -179.9, -16]),
      zoomIntoRange(6, window: ZoomBounds(minZoom: 10, maxZoom: 14)),
      accuracyBounds([6.86, 45.83], radiusMeters: 25), locateMaxZoom,
      trimWhiteSpace("  credit  "),
      selectBoundary(
        [RestSchema.Boundaries(bbox: [5, 44, 8, 47], name: "alps")], center: [6.86, 45.83])?.name
    )
  }

  /// glyphs builds a licensed glyph set of the host's own, chains it over the bundled one, and
  /// reads how each shape of a glyph is painted and which glyph a marker draws.
  static func glyphs() -> [ShapePaint] {
    guard
      let licensed = GlyphSet(
        name: "licensed", paint: .stroke, strokeWidth: 2, viewBox: 24,
        markup: ["refuge": #"<path d="M3 21h18" stroke-linecap="square"/>"#]),
      let chain = GlyphSet(chaining: [licensed, .marker]),
      GlyphSet(name: "solid", paint: .fill, markup: [:]) != nil
    else { return [] }
    _ = (chain.name, chain.paint, chain.strokeWidth, chain.viewBox, GlyphSet.control.markup.count)
    _ = (
      activityMarkerGlyph(.hikingAndTrail, in: chain), roadAccessGlyph(.localAccess),
      roadAccessColor(.permit).hex, glyphAttributes.contains("stroke-miterlimit")
    )
    let painted = parseGlyph(chain.markup["refuge"] ?? "").map { glyphPaint($0, in: chain) }
    for paint in painted {
      _ = (paint.isFilled, paint.isStroked, paint.strokeWidth, paint.miterLimit)
      switch (paint.lineCap, paint.lineJoin, paint.fillRule) {
      case (.butt, .arcs, .nonZero), (.round, .bevel, .evenOdd), (.square, .miter, _),
        (_, .miterClip, _), (_, .round, _):
        break
      default:
        break
      }
    }
    _ = ShapePaint(
      isFilled: true, isStroked: false, strokeWidth: 2, lineCap: .round, lineJoin: .round,
      miterLimit: 4, fillRule: .nonZero)
    return painted
  }

  /// paint reads the rules a map's content is painted by: the paint restyled on a copy, an
  /// itinerary's strokes, a point of interest's style and category, an isochrone band's colour,
  /// and a route's restricted stretches as features.
  static func paint() {
    var paint = MapPaint.standard
    paint.itinerary.casingColor = "#1b1b1b"
    paint.itinerary.lineWidthStops = [10, 3, 16, 6]
    paint.segments.palette = ["#e64980", "#228be6"]
    paint.layerRanks["acme_avalanche"] = 40
    _ = (
      paint == .standard, paint.itinerary.casingOpacity, paint.itinerary.casingWidthStops,
      paint.itinerary.dashArray, paint.itinerary.dashedOpacity, paint.segments.defaultColor
    )
    let strokes: [ItineraryStroke] = [
      .line(color: "#e64980"), .dashed(color: ["get", "color"]), .casing,
    ]
    for stroke in strokes {
      let style: LineLayerStyle = itineraryStrokeStyle(stroke, paint: paint)
      _ = (style.layout, style.paint)
    }
    if let hut = poiStyleOf(.hut) {
      _ = (hut.glyph, hut.color.hex)
    }
    _ = (poiCategoryStyles.count, poiTileCategories.count, poiCategoryOf("Alpine_Hut"))
    _ = (POIStyle(glyph: "hut", color: HexColor(hex: "#0b7285")), isochroneColor(-1))
    _ = LineLayerStyle(layout: ["line-cap": "round"], paint: ["line-width": 4])
    let stretches = roadAccessFeatures(
      .lineString(GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.84]])), info: nil)
    _ = stretches.map { $0.properties["kind"] }
  }

  /// itineraries reads an itinerary by id as an element does: one cache per client, an engine over
  /// it, and the projections a resolved itinerary holds, with the rules that read them off the wire.
  @MainActor
  static func itineraries(_ mountaya: Mountaya) async {
    let cache = ItineraryResourceCache { id, surface in
      try await mountaya.studio.itineraries.getItinerary(
        itinerary_id: id, query: .init { $0.surface = surface }
      ).data
    }
    _ = ItineraryResourceCache.capacity
    let engine = ItineraryResourceEngine(cache: cache, itineraryId: "itn_4e5f")
    for await resource in engine.subscribe() {
      switch resource {
      case .idle, .resolving:
        continue
      case .resolved(let itinerary):
        _ = (
          itinerary.geometry, itinerary.characteristics, itinerary.legs.map(\.name),
          itinerary.waypoints.compactMap(\.name)
        )
      case .failed(let error):
        _ = error
      }
      break
    }
    _ = engine.state
    engine.configure(cache: cache, itineraryId: nil)
    cache.invalidate(itineraryId: "itn_4e5f")
    cache.invalidate()
    engine.close()
    _ = (itineraryGeometry([]), itinerarySegments([], groups: []), itineraryWaypoints([]))
    let leg = ItineraryLeg(id: "climb", name: "Montée", sectionDistance: 4_200, sectionAscent: 850)
    let place = ItineraryPlace(
      id: "w1", lngLat: [6.86, 45.83], name: "Refuge",
      details: WaypointDetails(
        description: "Gardé de juin à septembre",
        timing: WaypointDetails.Timing(stopDuration: 900)))
    _ = (leg.memberIds, leg.geometry, place.glyph, place.details?.contact)
  }

  /// navigation reads a route's steps, follows it on a scripted engine and on the host's own,
  /// and reads every value a navigation reports.
  @MainActor
  static func navigation() throws {
    let reading = readItineraryDirectionsSteps(
      [
        RestSchema.ItineraryDirectionsStep(
          distance: 5_200, duration: 3_600, exit_number: nil, from_index: 0, name: "-",
          to_index: 1, type: .depart)
      ],
      coordinateCount: 2)
    let data = readDirectionsSteps(nil, coordinateCount: 2)
    _ = (reading.refused, reading.steps.first?.maneuver, data.steps.isEmpty)

    let route = NavigationRoute(
      line: [[6.8652, 45.9237], [6.9271, 45.9682]], steps: reading.steps, duration: 3_600)
    if let followed = followedRouteOf(route) {
      let progress = navigationProgressAt(followed, position: [6.9, 45.95], previous: 0)
      let instruction = stepInstruction(followed.steps[progress.step])
      _ = (followed.line, instruction.key.id, instruction.key.arguments, instruction.name)
      _ = (instruction.exit, progress.next, progress.toManeuver.duration, progress.along)
    }

    let navigation = ScriptedNavigationEngine<String>()
    try follow(navigation)
    let request = navigation.sent[0]
    _ = (request.request, request.isAnswered, request.isAbandoned)
    do {
      try request.answer(route)
    } catch {
      _ = error.description
    }
    try follow(StandingStill())
  }

  /// follow is an app's own code, written against the protocol whatever engine it is handed.
  @MainActor
  static func follow(_ navigation: some NavigationEngine<String>) throws {
    navigation.start("summit")
    if let request = (navigation as? ScriptedNavigationEngine<String>)?.sent.first {
      try request.answer(NavigationRoute(line: [[6.8652, 45.9237], [6.9271, 45.9682]]))
    }
    do {
      try navigation.setPosition([.nan, 45.9])
    } catch {
      _ = (error.position, error.description)
    }
    try navigation.setPosition([6.9, 45.95])
    navigation.reroute("from here")
    let state = navigation.state
    _ = (state.status.id, state.route?.steps, state.progress?.toArrival.distance)
    _ = NavigationStatus.allCases.map(\.id)
    if let error = state.error {
      said(error)
    }
    _ = navigation.subscribe()
    navigation.stop()
    navigation.close()
  }

  /// said reads a navigation's failure, its kinds open to the ones a later release adds.
  static func said(_ error: NavigationError) {
    switch error.kind {
    case .routeFailed: _ = error.cause
    case .emptyRoute: _ = error.description
    @unknown default: _ = error
    }
    _ = (NavigationError.routeFailed(CancellationError()), NavigationError.emptyRoute())
  }

  /// state builds the states a host's own screen is tested against.
  static func state() -> NavigationState {
    NavigationState(
      status: .navigating,
      progress: NavigationProgress(
        along: 120, step: 0, next: 1,
        toManeuver: NavigationRemainder(distance: 380, duration: 240),
        toArrival: NavigationRemainder(distance: 5_080, duration: nil)),
      error: .emptyRoute())
  }
}

/// StandingStill is a host's own engine, conformed from outside: it follows nothing, and reports
/// the one state it holds. It is bound to the main actor, as every engine is, and observable.
@MainActor
@Observable
final class StandingStill: NavigationEngine {
  private(set) var state = NavigationState.idle

  func subscribe() -> AsyncStream<NavigationState> {
    let (stream, continuation) = AsyncStream.makeStream(of: NavigationState.self)
    continuation.yield(state)
    continuation.finish()
    return stream
  }

  func start(_ request: String) {
    state = NavigationState(status: .routing)
  }

  func reroute(_ request: String) {}

  func setPosition(_ position: [Double]) throws(PositionError) {
    guard position.count >= 2, position[0].isFinite, position[1].isFinite else {
      throw PositionError(position: position)
    }
  }

  func stop() {
    state = .idle
  }

  func close() {}
}
