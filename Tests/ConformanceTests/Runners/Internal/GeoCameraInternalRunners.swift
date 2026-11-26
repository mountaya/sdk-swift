import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// cameraZoomLimitReached answers which end of its `window` a camera at the case's `zoom` stands
  /// at. The controls each answer disables are held to the rule's own table, end by end. The rule is
  /// the zoom controls' own, which a consumer observes as a control disabled, so it is reached as
  /// an internal.
  static let cameraZoomLimitReached = Runner(
    id: "geo.camera.zoom-limit-reached", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "disabledControls": .object(
          ZoomWindowEnd.allCases.sorted { $0.rawValue < $1.rawValue }.map { end in
            OrderedJSON.Member(
              key: end.rawValue,
              value: .array(zoomControlsDisabled(at: end).map { .string($0.rawValue) }))
          })
      ])
    let end = zoomLimitReached(
      try fixtureCase.input.number(at: "zoom"),
      window: try GeoCameraFixtures.window(fixtureCase.input, at: "window"))
    return .value(.string(end.rawValue))
  }

  /// cameraAccuracyBounds answers the box the case's `center` is framed by, at its
  /// `radiusMeters`. The circumference is held to the published constant, which the rule reads, and
  /// the zoom a fix is framed at at most to the one a map's locate frames with.
  static let cameraAccuracyBounds = Runner(id: "geo.camera.accuracy-bounds", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "circumferenceMeters": webMercatorCircumferenceMeters, "maxZoom": locateMaxZoom,
    ])
    let input = fixtureCase.input
    return .value(
      GeoFixtures.numbers(
        accuracyBounds(
          try input.numbers(at: "center"), radiusMeters: try input.number(at: "radiusMeters"))))
  }

  /// layersHoveredItinerary answers the leg and the place the case's `features` name, topmost
  /// first, read from each feature's `properties`, an absent or null one holding none; a feature's
  /// own `id` is handed to nothing, since the rule never reads it. The property names are held to
  /// the rule's own.
  static let layersHoveredItinerary = Runner(
    id: "geo.layers.hovered-itinerary", table: .internal
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "segmentProperty": .string(segmentIdProperty),
        "waypointProperty": .string(waypointIdProperty),
      ])
    var features: [[String: JSONValue]] = []
    for feature in try fixtureCase.input.array(at: "features") {
      guard let properties = feature["properties"], !properties.isNull else {
        features.append([:])
        continue
      }
      features.append(try GeoFixtures.jsonObject(properties, naming: "properties"))
    }
    let hovered = hoveredItineraryOf(features)
    return .value(
      .object([
        OrderedJSON.Member(key: "segmentId", value: hovered.segmentId.map { .string($0) } ?? .null),
        OrderedJSON.Member(
          key: "waypointId", value: hovered.waypointId.map { .string($0) } ?? .null),
      ]))
  }
}
