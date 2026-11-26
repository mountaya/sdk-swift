import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// layersOverlayInstant answers the moment the case's `pinned` instant and the clock's reading
  /// `nowMs` show, in milliseconds. A pin that names no instant is handed as a `Date` of no number,
  /// which Swift's `Date` holds, and a clock that reads none, NaN, as a `Date` of no number too, so
  /// every case is played through the rule.
  static let layersOverlayInstant = Runner(id: "geo.layers.overlay-instant", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let pinned = try input.optionalString(at: "pinned").map(GeoTimeFixtures.instant)
    return .value(
      GeoControlFixtures.millisecondsOf(
        overlayInstant(pinned: pinned, now: GeoTimeFixtures.reading(try input.number(at: "nowMs"))))
    )
  }

  /// layersTileTimestamp answers the sources the case's `catalogue` asks again for its `instant`,
  /// where its `overlay` is selected, each as `{source, tiles}`. The catalogue holds each category
  /// and overlay the case writes, its capabilities and its sources as written, and a placeholder in
  /// every member the rule does not read. The parameter is held to the one the rule writes.
  static let layersTileTimestamp = Runner(id: "geo.layers.tile-timestamp", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:], values: ["parameter": .string(GeoTimeFixtures.parameter())])
    let input = fixtureCase.input
    guard let written = input["catalogue"] else {
      throw FixtureError(description: "the case names no `catalogue`")
    }
    let sources = timestampedSources(
      try GeoTimeFixtures.catalogue(written), overlay: try input.optionalString(at: "overlay"),
      at: GeoTimeFixtures.instant(try input.string(at: "instant")))
    return .value(
      .array(
        sources.map { source in
          .object([
            OrderedJSON.Member(key: "source", value: .string(source.sourceId)),
            OrderedJSON.Member(key: "tiles", value: GeoFixtures.texts(source.tiles)),
          ])
        }))
  }

  /// layersTimeWindow answers the track laid out around the case's `nowMs`: its start, its two
  /// stops, the instant of each of its `stops` and the stop of each of its `instants`, null placed
  /// as no pin. The two constants are held to what the rule answers: the hours before the reading
  /// as the stop that stands for it, and the hours after as the stops past it.
  static let layersTimeWindow = Runner(id: "geo.layers.time-window", table: .public) {
    fixture, fixtureCase in
    let input = fixtureCase.input
    let window = timeSliderWindow(now: GeoTimeFixtures.reading(try input.number(at: "nowMs")))
    try fixture.holdConstants([
      "pastHours": Double(window.nowValue),
      "futureHours": Double(window.maxValue - window.nowValue),
    ])
    var stops: [OrderedJSON] = []
    for stop in try input.numbers(at: "stops") {
      guard let value = Int(exactly: stop) else {
        throw FixtureError(description: "the stop \(stop) is no whole number")
      }
      stops.append(GeoControlFixtures.millisecondsOf(window.date(at: value)))
    }
    var values: [OrderedJSON] = []
    for written in try input.array(at: "instants") {
      let instant = written.isNull ? nil : GeoTimeFixtures.instant(written.stringValue ?? "")
      values.append(.number(Double(window.value(at: instant))))
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "instantsAt", value: .array(stops)),
        OrderedJSON.Member(key: "maxValue", value: .number(Double(window.maxValue))),
        OrderedJSON.Member(key: "nowValue", value: .number(Double(window.nowValue))),
        OrderedJSON.Member(key: "startMs", value: GeoControlFixtures.millisecondsOf(window.start)),
        OrderedJSON.Member(key: "valuesOf", value: .array(values)),
      ]))
  }

  /// layersTimeSlider answers what a slider draws and commits over the track the case's `nowMs`
  /// lays out, as `LayersPanel` draws it: its thumb at the stop the track places the `pinned`
  /// instant at, its fill from the stop of the reading, its ticks, the word it is held under on a
  /// track of no instant, and what a release on the stop `release` commits. The two constants are
  /// held to what the rule answers: the stops of a day as the distance between two ticks, and each
  /// labelled day as the days from the stop of the reading to a tick carrying a word.
  static let layersTimeSlider = Runner(id: "geo.layers.time-slider", table: .public) {
    fixture, fixtureCase in
    let input = fixtureCase.input
    let window = timeSliderWindow(now: GeoTimeFixtures.reading(try input.number(at: "nowMs")))
    let ticks = timeSliderTicks(window)
    guard ticks.count > 1 else { throw FixtureError(description: "the track holds one tick") }
    let dayStops = ticks[1].value - ticks[0].value
    try fixture.holdConstants(
      ["dayStops": Double(dayStops)],
      values: [
        "labelledDays": .array(
          ticks.compactMap { tick in
            tick.word.map { word in
              .object([
                OrderedJSON.Member(
                  key: "days", value: .number(Double((tick.value - window.nowValue) / dayStops))),
                OrderedJSON.Member(key: "word", value: .string(word)),
              ])
            }
          })
      ])
    let pinned = try input.optionalString(at: "pinned").map(GeoTimeFixtures.instant)
    let released = timeSliderRelease(window, at: try input.integer(at: "release"))
    return .value(
      .object([
        OrderedJSON.Member(key: "fillFrom", value: .number(Double(window.nowValue))),
        OrderedJSON.Member(
          key: "held", value: window.start == nil ? .string("layers.timeUnavailable") : .null),
        OrderedJSON.Member(
          key: "released",
          value: released.map { release in
            .object([
              OrderedJSON.Member(key: "pin", value: GeoControlFixtures.millisecondsOf(release.pin))
            ])
          } ?? .null),
        OrderedJSON.Member(
          key: "ticks",
          value: .array(
            ticks.map { tick in
              .object([
                OrderedJSON.Member(key: "value", value: .number(Double(tick.value))),
                OrderedJSON.Member(key: "word", value: tick.word.map { .string($0) } ?? .null),
              ])
            })),
        OrderedJSON.Member(key: "value", value: .number(Double(window.value(at: pinned)))),
      ]))
  }

  /// layersTimeReadout answers what the thumb reads at each of the case's `values` over the track
  /// its `nowMs` lays out: the instant, in milliseconds, and the offset's word and count.
  static let layersTimeReadout = Runner(id: "geo.layers.time-readout", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let window = timeSliderWindow(now: GeoTimeFixtures.reading(try input.number(at: "nowMs")))
    var readouts: [OrderedJSON] = []
    for written in try input.numbers(at: "values") {
      guard let value = Int(exactly: written) else {
        throw FixtureError(description: "the stop \(written) is no whole number")
      }
      let readout = timeSliderReadout(window, at: value)
      readouts.append(
        .object([
          OrderedJSON.Member(
            key: "instant", value: GeoControlFixtures.millisecondsOf(readout.instant)),
          OrderedJSON.Member(
            key: "offset",
            value: .object([
              OrderedJSON.Member(
                key: "count", value: readout.count.map { .number(Double($0)) } ?? .null),
              OrderedJSON.Member(key: "word", value: .string(readout.word)),
            ])),
        ]))
    }
    return .value(.array(readouts))
  }
}

/// GeoTimeFixtures reads what the time's fixtures write into the values Geo takes.
enum GeoTimeFixtures {
  /// reading is the clock's reading `milliseconds` from the epoch, NaN for a clock that reads no
  /// instant, as a `Date`, which holds both.
  static func reading(_ milliseconds: Double) -> Date {
    Date(timeIntervalSince1970: milliseconds / 1000)
  }

  /// instant is the instant an RFC 3339 text names, read as the wire's decoder reads one, or a
  /// `Date` of no number where it names none, which the rules read as none.
  static func instant(_ text: String) -> Date {
    parseTimestamp(text) ?? Date(timeIntervalSince1970: .nan)
  }

  /// parameter is the name of the query parameter `timestampedSources(_:overlay:at:)` stamps an
  /// address with, read back off an address it stamps.
  static func parameter() -> String {
    var overlay = GeoTileFixtures.overlay("stamped", id: "stamped")
    overlay.capabilities.server.timestamp = true
    overlay.sources = [
      TileSchema.TileSource(
        id: "stamped", layers: [], tiles: ["https://tiles.test/{z}/{x}/{y}"], type: .vector,
        zoom_max: 14, zoom_min: 0)
    ]
    let catalogue = GeoTileFixtures.layers([
      GeoTileFixtures.category("conditions", children: [overlay])
    ])
    let stamped =
      timestampedSources(catalogue, overlay: "stamped", at: Date(timeIntervalSince1970: 0)).first?
      .tiles.first ?? ""
    let query = stamped.split(separator: "?", maxSplits: 1).last ?? ""
    return String(query.split(separator: "=", maxSplits: 1).first ?? "")
  }

  /// catalogue builds the layers catalogue a stamp fixture writes: each category by its `slug`,
  /// each overlay by its `slug`, its `capabilities` and its `sources`, each its `id` and its
  /// `tiles`, every other member a placeholder.
  static func catalogue(_ written: OrderedJSON) throws(FixtureError) -> TileSchema.Layers {
    var categories: [TileSchema.CategoryOverlays] = []
    for category in try written.array(at: "overlays") {
      var children: [TileSchema.Overlay] = []
      for child in try category.array(at: "children") {
        let slug = try child.string(at: "slug")
        guard let capabilities = child["capabilities"] else {
          throw FixtureError(description: "the overlay `\(slug)` states no `capabilities`")
        }
        var overlay = GeoTileFixtures.overlay(slug, id: slug)
        overlay.capabilities = TileSchema.OverlayCapabilities(
          client: TileSchema.OverlaySupportedCapabilities(
            timestamp: try (capabilities["client"] ?? .null).flag(at: "timestamp")),
          server: TileSchema.OverlaySupportedCapabilities(
            timestamp: try (capabilities["server"] ?? .null).flag(at: "timestamp")))
        var sources: [TileSchema.TileSource] = []
        for source in try child.array(at: "sources") {
          sources.append(
            TileSchema.TileSource(
              id: try source.string(at: "id"), layers: [],
              tiles: try GeoFixtures.textList(source, at: "tiles"), type: .vector, zoom_max: 14,
              zoom_min: 0))
        }
        overlay.sources = sources
        children.append(overlay)
      }
      categories.append(
        GeoTileFixtures.category(try category.string(at: "slug"), children: children))
    }
    return GeoTileFixtures.layers(categories)
  }
}
