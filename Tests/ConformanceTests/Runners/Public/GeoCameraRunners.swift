import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// cameraZoomBounds answers the zoom range a map is held to for the case's `zoomMin` and
  /// `zoomMax`.
  ///
  /// The floor, the buffer and the least span are held to what the rule answers: the minimum of a
  /// range that reaches zoom 0, the pull a range's maximum takes, and the span a range of one zoom
  /// is widened to. The Web Mercator limit is held to the published constant, under the one name
  /// every fixture declaring it gives it.
  static let cameraZoomBounds = Runner(id: "geo.camera.zoom-bounds", table: .public) {
    fixture, fixtureCase in
    let narrow = effectiveZoomBounds(zoomMin: 22, zoomMax: 22)
    try fixture.holdConstants(
      [
        "effectiveMinZoomFloor": effectiveZoomBounds(zoomMin: 0, zoomMax: 18).minZoom,
        "effectiveZoomMinSpan": narrow.maxZoom - narrow.minZoom,
        "webMercatorMaxLatitude": webMercatorMaxLatitude,
        "zoomBuffer": 18 - effectiveZoomBounds(zoomMin: 6, zoomMax: 18).maxZoom,
      ]
    )
    let input = fixtureCase.input
    let bounds = effectiveZoomBounds(
      zoomMin: try input.number(at: "zoomMin"), zoomMax: try input.number(at: "zoomMax"))
    return .value(
      .object([
        OrderedJSON.Member(key: "maxZoom", value: .number(bounds.maxZoom)),
        OrderedJSON.Member(key: "minZoom", value: .number(bounds.minZoom)),
      ]))
  }

  /// cameraMaxBoundsLongitudes answers the `[west, east]` edges a pan lock with the case's `west`
  /// and `east` is handed to a renderer with. The turn is held to the one the rule brings a lock
  /// back by, and the half span of the whole-world lock to that lock's east edge around the prime
  /// meridian.
  static let cameraMaxBoundsLongitudes = Runner(
    id: "geo.camera.max-bounds-longitudes", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([
      "degreesPerTurn": 365 - maxBoundsLongitudes(west: 365, east: 367)[0],
      "worldLockHalfSpanDegrees": maxBoundsLongitudes(west: -180, east: 180)[1],
    ])
    let input = fixtureCase.input
    let edges = maxBoundsLongitudes(
      west: try input.number(at: "west"), east: try input.number(at: "east"))
    return .value(GeoFixtures.numbers(edges))
  }

  /// cameraZoomAltitude answers, for a case with a `zoom`, the altitude it is seen from and the
  /// ground one pixel spans there, and for a case with an `altitudeMeters`, the zoom it is seen at,
  /// both at the case's `latitude` on the nominal canvas.
  ///
  /// The nominal canvas height is held to the one the conversion reads where none is named: the
  /// altitude is proportional to the height, so it is the altitude at the default over the
  /// altitude on a canvas one pixel tall. The field of view's factor is the camera's distance from a
  /// canvas one pixel tall, the altitude it is seen from over the ground one pixel spans, and the
  /// zoom ceiling and floor are the zooms the nearest and the farthest altitudes are held to.
  static let cameraZoomAltitude = Runner(id: "geo.camera.zoom-altitude", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [
        "defaultViewportHeightPx": zoomToAltitude(0, latitude: 0)
          / zoomToAltitude(0, latitude: 0, viewportHeightPixels: 1),
        "fieldOfViewFactor": zoomToAltitude(0, latitude: 0, viewportHeightPixels: 1)
          / groundMetersPerPixel(zoom: 0, latitude: 0),
        "zoomCeiling": altitudeToZoom(1e-3, latitude: 0),
        "zoomFloor": altitudeToZoom(1e12, latitude: 0),
      ]
    )
    let input = fixtureCase.input
    let latitude = try input.number(at: "latitude")
    guard input["zoom"] != nil else {
      let zoom = altitudeToZoom(try input.number(at: "altitudeMeters"), latitude: latitude)
      return .value(.number(zoom))
    }
    let zoom = try input.number(at: "zoom")
    return .value(
      .object([
        OrderedJSON.Member(
          key: "altitudeMeters", value: .number(zoomToAltitude(zoom, latitude: latitude))),
        OrderedJSON.Member(
          key: "groundMetersPerPixel",
          value: .number(groundMetersPerPixel(zoom: zoom, latitude: latitude))),
      ]))
  }

  /// cameraPixelPadding answers the case's `bounds` grown by its `padding`, one number for every
  /// edge or one per edge, at its `zoom` and `centerLatitude`. The tile size and the Web Mercator
  /// limit are held to the published constants, and the circumference to the ground one pixel
  /// spans at zoom 0 on the equator times the tiles across it.
  static let cameraPixelPadding = Runner(id: "geo.camera.pixel-padding", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "tileSizePx": webMercatorTileSizePixels,
      "webMercatorCircumferenceMeters": groundMetersPerPixel(zoom: 0, latitude: 0)
        * webMercatorTileSizePixels,
      "webMercatorMaxLatitude": webMercatorMaxLatitude,
    ])
    let input = fixtureCase.input
    let padding: PixelPadding
    if let all = input["padding"]?.numberValue {
      padding = PixelPadding(all)
    } else if let edges = input["padding"], edges.members != nil {
      padding = PixelPadding(
        top: try edges.number(at: "top"),
        right: try edges.number(at: "right"),
        bottom: try edges.number(at: "bottom"),
        left: try edges.number(at: "left")
      )
    } else {
      throw FixtureError(description: "the input's `padding` is neither a number nor one per edge")
    }
    let grown = boundsWithPixelPadding(
      try input.numbers(at: "bounds"),
      padding: padding,
      zoom: try input.number(at: "zoom"),
      centerLatitude: try input.number(at: "centerLatitude")
    )
    return .value(GeoFixtures.numbers(grown))
  }

  /// cameraBoundsOf answers the box around every position of the case's `geometries`, each built
  /// as the client's GeoJSON type, or null where nothing is bounded.
  static let cameraBoundsOf = Runner(id: "geo.camera.bounds-of", table: .public) {
    _, fixtureCase in
    var geometries: [GeoJSONGeometry] = []
    for geometry in try fixtureCase.input.array(at: "geometries") {
      geometries.append(try GeoFixtures.geometry(geometry))
    }
    return .value(boundsOf(geometries).map(GeoFixtures.numbers) ?? .null)
  }

  /// cameraNormalizeBoundingBox answers the case's `bounds` in canonical form. The Web Mercator
  /// limit is held to the latitude the rule holds a box reaching a pole to.
  static let cameraNormalizeBoundingBox = Runner(
    id: "geo.camera.normalize-bounding-box", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([
      "webMercatorMaxLatitude": normalizeBoundingBox([0, -90, 1, 90])[3]
    ])
    let box = normalizeBoundingBox(try fixtureCase.input.numbers(at: "bounds"))
    return .value(GeoFixtures.numbers(box))
  }

  /// cameraRouteGeometry answers the measurement a fly-through is planned on that the case's
  /// `measure` names: the `length` of its `line`, the `cumulative` distances along it, the
  /// `bearing` from its `a` to its `b`, or the `position` its `meters` along its `line`.
  static let cameraRouteGeometry = Runner(id: "geo.camera.route-geometry", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    switch try input.string(at: "measure") {
    case "length":
      return .value(.number(routeLengthMeters(try input.positions(at: "line"))))
    case "cumulative":
      return .value(GeoFixtures.numbers(cumulativeMeters(try input.positions(at: "line"))))
    case "bearing":
      let bearing = bearingDegrees(from: try input.numbers(at: "a"), to: try input.numbers(at: "b"))
      return .value(.number(bearing))
    case "position":
      let line = try input.positions(at: "line")
      return .value(
        GeoFixtures.numbers(positionAtMeters(line, meters: try input.number(at: "meters"))))
    case let other:
      throw FixtureError(
        description:
          "`measure` is `length`, `cumulative`, `bearing` or `position`, not `\(other)`")
    }
  }

  /// cameraItineraryRoute answers the route a fly-through follows over the case's `segments`, or
  /// over the one its `segmentId` names. Each segment is REST's segment as the case writes it, its
  /// `geojson` read as it stands, a bare LineString or a GeometryCollection, a coordinate the
  /// fixture writes as no number among it, into the generated `RestSchema.ItinerarySegment`, every
  /// other member it requires a placeholder the rule never reads.
  /// The route answers its `line`, and its `elevations` and `jumps` only where it states them, or
  /// null where there is none.
  static let cameraItineraryRoute = Runner(id: "geo.camera.itinerary-route", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var segments: [RestSchema.ItinerarySegment] = []
    for segment in try input.array(at: "segments") {
      guard let geojson = segment["geojson"] else {
        throw FixtureError(description: "a segment carries no `geojson`")
      }
      segments.append(
        GeoFixtures.segment(
          id: try segment.string(at: "id"),
          position: try segment.integer(at: "position"),
          geojson: try GeoFixtures.geometry(geojson)
        ))
    }
    guard
      let route = itineraryRoute(segments, segmentId: try input.optionalString(at: "segmentId"))
    else { return .value(.null) }
    var stated = [
      OrderedJSON.Member(key: "line", value: .array(route.line.map(GeoFixtures.numbers)))
    ]
    if !route.elevations.isEmpty {
      stated.append(
        OrderedJSON.Member(key: "elevations", value: GeoFixtures.numbers(route.elevations)))
    }
    if !route.jumps.isEmpty {
      stated.append(
        OrderedJSON.Member(key: "jumps", value: GeoFixtures.numbers(route.jumps.map(Double.init))))
    }
    return .value(.object(stated))
  }

  /// cameraRouteContent answers whether the case's routes `a` and `b`, each built afresh from the
  /// fixture as its own value, are the same route. A list a route leaves out is built as no list,
  /// the route's empty one, and a jump that is no vertex index fails the case.
  static let cameraRouteContent = Runner(id: "geo.camera.route-content", table: .public) {
    _, fixtureCase in
    func route(_ key: String) throws(FixtureError) -> RouteGeometry {
      guard let route = fixtureCase.input[key], route.members != nil else {
        throw FixtureError(description: "the input's `\(key)` is not an object")
      }
      var jumps: [Int] = []
      for jump in route["jumps"] == nil ? [] : try route.numbers(at: "jumps") {
        guard let index = Int(exactly: jump) else {
          throw FixtureError(description: "the jump \(jump) is not a vertex index")
        }
        jumps.append(index)
      }
      return RouteGeometry(
        line: try route.positions(at: "line"),
        elevations: route["elevations"] == nil ? [] : try route.numbers(at: "elevations"),
        jumps: jumps
      )
    }
    return .value(.bool(try route("a") == route("b")))
  }

  /// cameraSweptViewports answers whether a recording capturing the case's `captured` poses
  /// captures the viewports its sweep jumped through, its `swept` poses, each pose built as its own
  /// value.
  static let cameraSweptViewports = Runner(id: "geo.camera.swept-viewports", table: .public) {
    _, fixtureCase in
    func poses(_ key: String) throws(FixtureError) -> [CameraPose] {
      var poses: [CameraPose] = []
      for pose in try fixtureCase.input.array(at: key) {
        poses.append(
          CameraPose(
            center: try pose.numbers(at: "center"),
            zoom: try pose.number(at: "zoom"),
            pitch: try pose.number(at: "pitch"),
            bearing: try pose.number(at: "bearing")
          ))
      }
      return poses
    }
    return .value(
      .bool(capturesSweptViewports(swept: try poses("swept"), captured: try poses("captured"))))
  }
}

extension PublicRunners {
  /// cameraFit answers the camera that fits the case's `bounds` in its `canvas`, kept clear by its
  /// `padding`, one number for every edge or one per edge, under its `maxZoom` and within its
  /// `window`. The viewport the rule answers faces north, which is the expectation's `bearing` of 0,
  /// and the tile size is held to the published constant.
  static let cameraFit = Runner(id: "geo.camera.fit", table: .public) { fixture, fixtureCase in
    try fixture.holdConstants(["tileSizePx": webMercatorTileSizePixels])
    let input = fixtureCase.input
    guard
      let viewport = cameraForBounds(
        try input.numbers(at: "bounds"), canvas: try input.numbers(at: "canvas"),
        padding: try GeoCameraFixtures.padding(input["padding"]),
        maxZoom: try input.optionalNumber(at: "maxZoom"),
        window: try GeoCameraFixtures.window(input, at: "window"))
    else { return .value(.null) }
    return .value(
      .object([
        OrderedJSON.Member(key: "bearing", value: .number(0)),
        OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(viewport.center)),
        OrderedJSON.Member(key: "zoom", value: .number(viewport.zoom)),
      ]))
  }

  /// cameraContentBounds answers the box the case's content is framed on: an `itinerary`'s, from
  /// its segments as the REST API answers them, each built with the case's `position` and
  /// `geojson` and placeholders no rule reads, its waypoints handed to nothing since the rule reads
  /// segments alone; or a `collection`'s, from the `bbox` its specification states.
  static let cameraContentBounds = Runner(id: "geo.camera.content-bounds", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let bounds: [Double]?
    if let itinerary = input["itinerary"] {
      var segments: [RestSchema.ItinerarySegment] = []
      for (index, segment) in try itinerary.array(at: "segments").enumerated() {
        let written = segment["geojson"]
        segments.append(
          GeoFixtures.segment(
            id: "segment-\(index)", position: try segment.integer(at: "position"),
            geojson: try written.flatMap { geojson throws(FixtureError) in
              geojson.isNull ? nil : try GeoFixtures.geometry(geojson)
            }))
      }
      bounds = itineraryBounds(segments)
    } else if let collection = input["collection"] {
      let stated = collection["bbox"].map { !$0.isNull } ?? false
      bounds = specificationBounds(stated ? try collection.numbers(at: "bbox") : nil)
    } else {
      throw FixtureError(description: "the input states neither an itinerary nor a collection")
    }
    return .value(bounds.map(GeoFixtures.numbers) ?? .null)
  }

  /// cameraZoomIntoRange answers the zoom a camera at the case's `zoom` moves to so its `window`,
  /// written as a style's layer writes one, paints, or null where it stays.
  static let cameraZoomIntoRange = Runner(id: "geo.camera.zoom-into-range", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let window = input["window"] else {
      throw FixtureError(description: "the input states no `window`")
    }
    let zoom = zoomIntoRange(
      try input.number(at: "zoom"),
      window: ZoomBounds(
        minZoom: try window.number(at: "minzoom"), maxZoom: try window.number(at: "maxzoom")))
    return .value(zoom.map { .number($0) } ?? .null)
  }
}

/// GeoCameraFixtures reads the camera values the 8c fixtures write.
enum GeoCameraFixtures {
  /// padding reads a padding written as one number for every edge or as `{ bottom, left, right,
  /// top }`, and none where it is left out.
  static func padding(_ written: OrderedJSON?) throws(FixtureError) -> PixelPadding {
    guard let written, !written.isNull else { return PixelPadding(0) }
    if let all = written.numberValue {
      return PixelPadding(all)
    }
    guard written.members != nil else {
      throw FixtureError(description: "a padding is neither a number nor one per edge")
    }
    return PixelPadding(
      top: try written.number(at: "top"), right: try written.number(at: "right"),
      bottom: try written.number(at: "bottom"), left: try written.number(at: "left"))
  }

  /// window reads a zoom window written `{ max, min }` under a key.
  static func window(_ input: OrderedJSON, at key: String) throws(FixtureError) -> ZoomBounds {
    guard let window = input[key] else {
      throw FixtureError(description: "the input states no `\(key)`")
    }
    return ZoomBounds(minZoom: try window.number(at: "min"), maxZoom: try window.number(at: "max"))
  }

  /// windowAnswer writes a zoom window as the fixtures expect one, `{ max, min }`.
  static func windowAnswer(_ window: ZoomBounds) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "max", value: .number(window.maxZoom)),
      OrderedJSON.Member(key: "min", value: .number(window.minZoom)),
    ])
  }
}
