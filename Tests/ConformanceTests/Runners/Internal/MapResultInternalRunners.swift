import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

@testable import MountayaElements

extension InternalRunners {
  /// mapAnalysisLayers answers the layers a Data API result of the case's kind draws through, from
  /// the source `sourceId`, at its kind's rank, through the internal rule the engine applies, the
  /// map's paint the shipped one with the case's patch folded on as a consumer restyles a copy. The
  /// palette, the properties a feature is stamped with and each kind's rank are held to the rule's
  /// own.
  static let mapAnalysisLayers = Runner(id: "map.analysis.layers", table: .internal) {
    fixture, fixtureCase in
    func number(_ value: Double) -> OrderedJSON { .number(value) }
    try fixture.holdConstants(
      [:],
      values: [
        "palette": .object([
          OrderedJSON.Member(key: "directionsLine", value: .string(directionsLineColor)),
          OrderedJSON.Member(key: "isochroneFillOpacity", value: number(isochroneFillOpacity)),
          OrderedJSON.Member(
            key: "isochroneOutline",
            value: .object([
              OrderedJSON.Member(key: "color", value: .string(isochroneOutlineColor)),
              OrderedJSON.Member(key: "width", value: number(isochroneOutlineWidth)),
            ])),
          OrderedJSON.Member(
            key: "matrixLine",
            value: .object([
              OrderedJSON.Member(key: "color", value: .string(matrixLineColor)),
              OrderedJSON.Member(key: "opacity", value: number(matrixLineOpacity)),
            ])),
          OrderedJSON.Member(
            key: "resultPoint",
            value: .object([
              OrderedJSON.Member(key: "radius", value: number(resultPointRadius)),
              OrderedJSON.Member(key: "strokeColor", value: .string(resultPointStrokeColor)),
              OrderedJSON.Member(key: "strokeWidth", value: number(resultPointStrokeWidth)),
            ])),
        ]),
        "properties": .object([
          OrderedJSON.Member(key: "color", value: .string(featureColorProperty)),
          OrderedJSON.Member(key: "kind", value: .string(featureKindProperty)),
          OrderedJSON.Member(key: "width", value: .string(featureWidthProperty)),
        ]),
        "ranks": .object(
          AnalysisKind.allCases.map { kind in
            OrderedJSON.Member(
              key: kind.rawValue,
              value: number(
                Double(
                  analysisLayers(kind, sourceId: "s", paint: .standard).first?.rank ?? -1)))
          }),
      ])
    let input = fixtureCase.input
    guard let kind = AnalysisKind(rawValue: try input.string(at: "kind")) else {
      throw FixtureError(description: "no kind is called `\(input["kind"] ?? .null)`")
    }
    let paint = try MapPaintFixtures.folded(input["paint"])
    let layers = analysisLayers(kind, sourceId: try input.string(at: "sourceId"), paint: paint)
    guard Set(layers.map(\.rank)).count == 1, let rank = layers.first?.rank else {
      throw FixtureError(description: "the kind's layers draw at more than one rank")
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "layers", value: .array(layers.map(MapFixtures.styleLayer))),
        OrderedJSON.Member(key: "rank", value: .number(Double(rank))),
      ]))
  }

  /// mapAnalysisRequests answers how the queries of a drawn result are cancelled and answered,
  /// played over an exchange that holds every query sending its full document until a step answers
  /// it, and fails one as cancelled the moment its task is cancelled. `add` is `addIsochrones(_:fit:)`
  /// of `input`, `edit` `editIsochrones(_:patch:fit:)` with the case's patch, `answer` lets the query
  /// `query` answer, `remove` is `removeAnalysis(_:)` and `clear` the kind's clear. Every call runs
  /// in a task preferring the main queue, and each step settles before the next. A call is
  /// `cancelled` where it threw `CancellationError`.
  static let mapAnalysisRequests = Runner(id: "map.analysis.requests", table: .internal) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapResultRequests.play(try fixtureCase.input.array(at: "steps"))
  }

  /// mapGeometryLayers answers how a geometry slot draws, through the internal rule the engine
  /// applies, in the case's colour or the slot's own, in the map's paint with the case's patch
  /// folded on: its source, its band and its layers. Each slot's source, band and own colour, and
  /// the circle a highlighted point is drawn as, are held to the rule's own, and the engine is held
  /// to draw the same layers for a point.
  static let mapGeometryLayers = Runner(id: "map.geometry.layers", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "point": .object([
          OrderedJSON.Member(key: "radius", value: .number(resultPointRadius)),
          OrderedJSON.Member(key: "strokeWidth", value: .number(resultPointStrokeWidth)),
        ]),
        "slots": .object(
          GeometrySlot.allCases.map { slot in
            OrderedJSON.Member(
              key: slot.rawValue,
              value: .object([
                OrderedJSON.Member(key: "color", value: .string(slot.color)),
                OrderedJSON.Member(key: "rank", value: .number(Double(slot.rank))),
                OrderedJSON.Member(key: "sourceId", value: .string(slot.sourceId)),
              ]))
          }),
      ])
    let input = fixtureCase.input
    guard let slot = GeometrySlot(rawValue: try input.string(at: "slot")) else {
      throw FixtureError(description: "no slot is called `\(input["slot"] ?? .null)`")
    }
    let paint = try MapPaintFixtures.folded(input["paint"])
    let color = try input.optionalString(at: "color")
    let layers = geometrySlotLayers(slot, color: color ?? slot.color, paint: paint)
    try await MainActor.run { () throws in
      let map = MapEngine(
        client: try MapFixtures.client(), paint: paint, geolocation: InertGeolocation())
      map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: slot, color: color)
      guard map.state.layers == layers else {
        throw FixtureError(description: "the map drew other layers: \(map.state.layers.map(\.id))")
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "layers", value: .array(layers.map(MapFixtures.styleLayer))),
        OrderedJSON.Member(key: "rank", value: .number(Double(slot.rank))),
        OrderedJSON.Member(key: "sourceId", value: .string(slot.sourceId)),
      ]))
  }

  /// mapMarkerPin answers the pin a marker given no view of its own is drawn as, through the
  /// internal rule the renderer draws, over a glyph set holding the case's `heldGlyphs` and no
  /// other. The pin's sizes and colours are held to the rule's own.
  static let mapMarkerPin = Runner(id: "map.marker.pin", table: .internal) { fixture, fixtureCase in
    try fixture.holdConstants(
      [
        "diameter": markerPinDiameter,
        "dotSize": markerPinDotSize,
        "glyphSize": markerPinGlyphSize,
        "ringWidth": markerPinRingWidth,
      ],
      values: ["markColor": .string(markerPinMarkColor)],
      inputs: ["heldGlyphs"])
    let held = try GeoFixtures.textList(fixture.constants ?? .null, at: "heldGlyphs")
    guard
      let set = GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(
          held.map { ($0, #"<path d="M0 0h1"/>"#) }, uniquingKeysWith: { a, _ in a })
      )
    else {
      throw FixtureError(description: "the held glyphs make no set")
    }
    let input = fixtureCase.input
    let pin = describeMarkerPin(
      color: try input.optionalString(at: "color"), glyph: try input.optionalString(at: "glyph"),
      in: set)
    let centre: OrderedJSON =
      switch pin.centre {
      case .glyph(let glyph, let size, let color):
        .object([
          OrderedJSON.Member(key: "color", value: .string(color)),
          OrderedJSON.Member(key: "glyph", value: .string(glyph)),
          OrderedJSON.Member(key: "size", value: .number(size)),
        ])
      case .dot(let size, let color):
        .object([
          OrderedJSON.Member(key: "color", value: .string(color)),
          OrderedJSON.Member(key: "dot", value: .number(size)),
        ])
      }
    return .value(
      .object([
        OrderedJSON.Member(key: "centre", value: centre),
        OrderedJSON.Member(key: "diameter", value: .number(pin.diameter)),
        OrderedJSON.Member(key: "fill", value: pin.fill.map { .string($0) } ?? .null),
        OrderedJSON.Member(
          key: "ring",
          value: .object([
            OrderedJSON.Member(key: "color", value: .string(pin.ringColor)),
            OrderedJSON.Member(key: "width", value: .number(pin.ringWidth)),
          ])),
      ]))
  }
}

/// MapResultRequests plays `map.analysis.requests`'s steps on the main actor, every call in a task
/// preferring the main queue.
@MainActor
enum MapResultRequests {
  /// play plays the steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func play(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let exchange = MapFixtures.Queries(holding: true)
    let map = MapEngine(
      client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
    let calls = MapResultScripts.Outcomes()
    let named = Named()
    /// progress is what the script reads to know a step has come to rest: each call's outcome, the
    /// queries sent, held and withdrawn, and the results drawn under a name.
    func progress() -> [OrderedJSON] {
      [
        GeoFixtures.texts(calls.values), exchange.progress,
        .array(named.ids.map { .string("\($0.name)=\($0.id)") }),
      ]
    }
    func track(_ call: @escaping @MainActor @Sendable () async throws -> Void) {
      let index = calls.values.count
      calls.values.append("waiting")
      _ = MainQueue.run {
        do {
          try await call()
          calls.values[index] = "answered"
        } catch is CancellationError {
          calls.values[index] = "cancelled"
        } catch {
          calls.values[index] = "failed"
        }
      }
    }
    for step in steps {
      switch try step.string(at: "step") {
      case "add":
        let name = try step.string(at: "name")
        let input = try GeoFixtures.decoded(
          DataSchema.IsochronesInput.self, from: step["input"] ?? .null)
        track {
          let handle = try await map.addIsochrones(input)
          named.ids.append((name, handle.id))
        }
      case "edit":
        let name = try step.string(at: "name")
        let stated = step["patch"]?.members ?? []
        let id = named.ids.last { $0.name == name }?.id ?? "analysis:none:0"
        let patch = try MapResultScripts.patched(stated, of: DataSchema.IsochronesInput.self)
        track { _ = try await map.editIsochrones(id, patch: patch) }
      case "answer":
        exchange.answer(try step.integer(at: "query"))
      case "remove":
        let name = try step.string(at: "name")
        map.removeAnalysis(named.ids.last { $0.name == name }?.id ?? "analysis:none:0")
      case "clear":
        try MapResultScripts.clear(try step.string(at: "kind"), on: map)
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      await MainQueue.settle { progress() }
    }
    let outcomes = calls.values
    let sent = exchange.queries.map(\.written)
    let cancelled = exchange.queries.indices.filter { exchange.queries[$0].cancelled }
    let drawn = try MapResultScripts.marks(named.ids, on: map)
    exchange.release()
    await MainQueue.settle { progress() }
    map.close()
    return .value(
      .object([
        OrderedJSON.Member(key: "calls", value: GeoFixtures.texts(outcomes)),
        OrderedJSON.Member(
          key: "cancelled", value: .array(cancelled.map { .number(Double($0)) })),
        OrderedJSON.Member(key: "drawn", value: drawn),
        OrderedJSON.Member(key: "sent", value: .array(sent)),
      ]))
  }

  /// Named is the id each result was drawn under, by the name it was added under.
  @MainActor
  final class Named {
    var ids: [(name: String, id: String)] = []
  }
}
