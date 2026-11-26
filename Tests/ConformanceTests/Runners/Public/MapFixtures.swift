import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

/// MapFixtures builds what the map fixtures write into the engine's own values, and writes the
/// engine's answers back as the fixtures expect them, every value through the published surface.
enum MapFixtures {
  /// client is a client for a map, which no case reaches the network through: its exchange, where
  /// none is given, answers nothing at all, and its every other seam is the harness's own.
  static func client(
    credential: Credential = .publishable(
      key: "pk_conformance", sessionToken: "sess_conformance"),
    baseUrls: BaseURLs = .standard, retry: RetryPolicy = .standard,
    exchange: (any HTTPExchange)? = nil
  ) throws -> Mountaya {
    try HeldSeams.client(
      credential: credential, baseUrls: baseUrls, retry: retry,
      exchange: exchange ?? Recording(answer: .failing))
  }

  /// kind is the contract's spelling of the kind of a map engine's refusal.
  static func kind(_ error: MapError) -> String {
    switch error.kind {
    case .positionRefused: "position-refused"
    case .numberRefused: "number-refused"
    case .zoomBoundsRefused: "window-refused"
    case .fixRefused: "fix-refused"
    case .closed: "closed"
    case .layerNotFound, .markerNotFound, .terrainNotFound, .overlayNotFound, .analysisNotFound:
      "not-found"
    case .maxBoundsRefused: "bounds-refused"
    case .typeRefused: "type-refused"
    case .kindMismatch: "kind-mismatch"
    case .noInput: "no-input"
    @unknown default: "\(error.kind)"
    }
  }

  /// refusedPose is the answer of a camera move refused as `kind`.
  static func refusedPose(_ kind: String) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "pose", value: .null),
      OrderedJSON.Member(key: "refused", value: .string(kind)),
    ])
  }

  /// target writes the members a camera move states, and no other.
  static func target(_ target: CameraTarget) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if let bearing = target.bearing {
      members.append(OrderedJSON.Member(key: "bearing", value: .number(bearing)))
    }
    if let center = target.center {
      members.append(OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(center)))
    }
    if let pitch = target.pitch {
      members.append(OrderedJSON.Member(key: "pitch", value: .number(pitch)))
    }
    if let zoom = target.zoom {
      members.append(OrderedJSON.Member(key: "zoom", value: .number(zoom)))
    }
    return .object(members)
  }

  /// camera writes a camera, `{ bearing, center, pitch, zoom }`.
  static func camera(_ pose: CameraPose) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "bearing", value: .number(pose.bearing)),
      OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(pose.center)),
      OrderedJSON.Member(key: "pitch", value: .number(pose.pitch)),
      OrderedJSON.Member(key: "zoom", value: .number(pose.zoom)),
    ])
  }

  /// FitReading is a drawing call's `fit` as a Swift caller can hand it: none, a `CameraFit`, or
  /// a value no `CameraFit` holds, refused by the type before any call as the kind named.
  enum FitReading {
    case read(CameraFit?)
    case refused(String)
  }

  /// readFit reads a drawing call's `fit`: left out or `false` is none, `true` a fit stating
  /// nothing, options a fit of the members they state, each `unstated` member left nil.
  static func readFit(_ written: OrderedJSON?, unstated: Set<String>) -> FitReading {
    guard let written else { return .read(nil) }
    if let flag = written.boolValue {
      return .read(flag ? CameraFit() : nil)
    }
    guard written.members != nil else { return .refused("kind-mismatch") }
    var fit = CameraFit()
    if let padding = written["padding"], !unstated.contains("padding") {
      if let all = padding.numberValue {
        fit.padding = PixelPadding(all)
      } else if padding.members != nil,
        let top = padding["top"]?.numberValue, let right = padding["right"]?.numberValue,
        let bottom = padding["bottom"]?.numberValue, let left = padding["left"]?.numberValue
      {
        fit.padding = PixelPadding(top: top, right: right, bottom: bottom, left: left)
      } else {
        return .refused("number-refused")
      }
    }
    if let maxZoom = written["maxZoom"], !unstated.contains("maxZoom") {
      guard let number = maxZoom.numberValue else { return .refused("number-refused") }
      fit.maxZoom = number
    }
    if let duration = written["duration"], !unstated.contains("duration") {
      guard let milliseconds = duration.numberValue, milliseconds.isFinite else {
        return .refused("number-refused")
      }
      fit.duration = .milliseconds(milliseconds)
    }
    return .read(fit)
  }

  /// fitOptions writes the members a fit states: its padding as one number where the case wrote
  /// one, else per edge, and its duration in milliseconds.
  static func fitOptions(_ fit: CameraFit, paddingAsOne: Bool) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if let duration = fit.duration {
      members.append(OrderedJSON.Member(key: "duration", value: .milliseconds(duration)))
    }
    if let maxZoom = fit.maxZoom {
      members.append(OrderedJSON.Member(key: "maxZoom", value: .number(maxZoom)))
    }
    if let padding = fit.padding {
      let value: OrderedJSON =
        paddingAsOne
        ? .number(padding.top)
        : .object([
          OrderedJSON.Member(key: "bottom", value: .number(padding.bottom)),
          OrderedJSON.Member(key: "left", value: .number(padding.left)),
          OrderedJSON.Member(key: "right", value: .number(padding.right)),
          OrderedJSON.Member(key: "top", value: .number(padding.top)),
        ])
      members.append(OrderedJSON.Member(key: "padding", value: value))
    }
    return .object(members)
  }

  /// fitAnswer is the answer of a drawing call handed a fit.
  static func fitAnswer(drawn: Bool, fit: OrderedJSON?, refused: String?) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "drawn", value: .bool(drawn)),
      OrderedJSON.Member(key: "fit", value: fit ?? .null),
      OrderedJSON.Member(key: "refused", value: refused.map { .string($0) } ?? .null),
    ])
  }

  /// collection is a collection's specification, stating the box it is framed on, with one source
  /// of one layer.
  static let collection = TileSchema.TileSpecification(
    sources: [
      TileSchema.TileSource(
        id: "collection",
        layers: [
          TileSchema.TileLayer(
            id: "collection-lines", key: "lines", layout: nil, paint: nil,
            source_layer: "itinerary_lines", type: .line, zoom_max: 22, zoom_min: 0)
        ],
        tiles: ["https://tiles.test/v1/collections/c/{z}/{x}/{y}"],
        type: .vector, zoom_max: 14, zoom_min: 0)
    ],
    configure: { $0.bbox = [6.8, 45.8, 6.95, 45.9] })

  /// limit reads a zoom limit a call states: left out is kept, null released, a number moved to,
  /// and anything else nil, a limit no `ZoomLimit` holds.
  static func limit(_ written: OrderedJSON?) -> ZoomLimit? {
    guard let written else { return .kept }
    if written.isNull { return .released }
    return written.numberValue.map { .zoom($0) }
  }

  /// feature reads a feature a renderer found, as the fixtures write one, into the feature a query
  /// answers for it.
  static func feature(_ written: OrderedJSON) throws(FixtureError) -> QueriedFeature {
    var id: QueriedFeature.ID?
    if let number = written["id"]?.numberValue {
      id = .number(number)
    } else if let text = written["id"]?.stringValue {
      id = .string(text)
    }
    let properties: [String: JSONValue] =
      written["properties"].map { $0.isNull } ?? true
      ? [:] : try GeoFixtures.jsonObject(written["properties"] ?? .null, naming: "properties")
    guard let geometry = written["geometry"] else {
      throw FixtureError(description: "a feature states no geometry")
    }
    return QueriedFeature(
      id: id, properties: properties, geometry: try GeoFixtures.geometry(geometry),
      layer: try written.string(at: "layer"),
      sourceLayer: try written.optionalString(at: "sourceLayer"))
  }

  /// features reads the features a renderer found under the key `key`, topmost first.
  static func features(_ input: OrderedJSON, at key: String) throws(FixtureError)
    -> [QueriedFeature]
  {
    var found: [QueriedFeature] = []
    for written in input[key] == nil ? [] : try input.array(at: key) {
      found.append(try feature(written))
    }
    return found
  }

  /// answer writes a feature a query answers as the fixtures expect one: a GeoJSON feature, with
  /// its id where it has one, the layer that drew it and its source layer where it has one.
  static func answer(_ feature: QueriedFeature) throws -> OrderedJSON {
    var members: [OrderedJSON.Member] = [
      OrderedJSON.Member(key: "geometry", value: try geometry(feature.geometry))
    ]
    switch feature.id {
    case .number(let number)?: members.append(OrderedJSON.Member(key: "id", value: .number(number)))
    case .string(let text)?: members.append(OrderedJSON.Member(key: "id", value: .string(text)))
    case nil: break
    }
    members.append(OrderedJSON.Member(key: "layer", value: .string(feature.layer)))
    members.append(
      OrderedJSON.Member(key: "properties", value: GeoFixtures.ordered(.object(feature.properties)))
    )
    if let sourceLayer = feature.sourceLayer {
      members.append(OrderedJSON.Member(key: "sourceLayer", value: .string(sourceLayer)))
    }
    members.append(OrderedJSON.Member(key: "type", value: .string("Feature")))
    return .object(members)
  }

  /// geometry writes a GeoJSON geometry through the client's own encoder.
  private static func geometry(_ geometry: GeoJSONGeometry) throws -> OrderedJSON {
    let written = try JSONEncoder().encode(geometry)
    return try OrderedJSON.parse(String(decoding: written, as: UTF8.self))
  }

  /// place places each layer the case names at its rank, as a map places its own.
  @MainActor
  static func place(_ input: OrderedJSON, on map: MapEngine) throws(FixtureError) {
    for layer in try input.array(at: "placed") {
      map.addLayer(
        MapLayer(
          id: try layer.string(at: "id"), type: .line, source: "placed",
          rank: try layer.integer(at: "rank")))
    }
  }

  /// Fix is a geolocation answering one fix, which records whether it was asked.
  @MainActor
  final class Fix: Geolocation {
    let answer: GeolocationFix
    private(set) var asked = false

    init(answer: GeolocationFix) {
      self.answer = answer
    }

    func locate() async -> GeolocationFix {
      asked = true
      return answer
    }

    func permission() async -> GeolocationPermission {
      .granted
    }
  }

  /// Recording is an exchange that records every request and answers each as it is told: a
  /// Data API query that sends no document first asked for it, as the persisted-query protocol
  /// does, then answered with `data`; any other request with `status` alone, or failing with no
  /// answer at all.
  /// Unreachable is a request that never reached an answer.
  struct Unreachable: Error {}

  actor Recording: HTTPExchange {
    /// Answer is how a request is answered.
    enum Answer: Sendable {
      /// data answers a Data API query with its result, under the operation's name.
      case data(operation: String, result: OrderedJSON)
      /// status answers with a status and an empty error envelope.
      case status(Int)
      /// failing answers nothing, the connection failing.
      case failing
    }

    let answer: Answer
    private(set) var sent: [ExchangeRequest] = []

    init(answer: Answer) {
      self.answer = answer
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      switch answer {
      case .failing:
        throw Unreachable()
      case .status(let status):
        return ExchangeResponse(
          status: status, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(
            Data(#"{"errors": [{"code": "FORBIDDEN", "message": "refused"}]}"#.utf8)))
      case .data(let operation, let result):
        let body = try request.body.map {
          try OrderedJSON.parse(String(decoding: $0, as: UTF8.self))
        }
        let text: String
        if body?["query"] == nil {
          text =
            #"{"errors": [{"message": "PersistedQueryNotFound", "extensions": {"code": "PERSISTED_QUERY_NOT_FOUND"}}]}"#
        } else {
          let data = OrderedJSON.object([
            OrderedJSON.Member(
              key: "data",
              value: .object([OrderedJSON.Member(key: operation, value: result)]))
          ])
          text = data.serialized()
        }
        return ExchangeResponse(
          status: 200, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(Data(text.utf8)))
      }
    }
  }
}
