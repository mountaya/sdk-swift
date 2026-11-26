import MountayaClient
import MountayaGeo

/// ScriptedMapSurface draws a map engine's state nowhere, in place of the MapLibre map `MapView`
/// draws it on, so a test reads what the engine does with no renderer: it answers what a renderer
/// would from what the test states, records what the engine asks of it, and plays what happens on a
/// canvas, a gesture, a frame, a failed request, a tile or a style loaded, which the engine tells
/// as `MapView`'s renderer has it tell them.
///
/// ```swift
/// let map = MapEngine(client: mountaya)
/// let surface = ScriptedMapSurface(drawing: map)
/// surface.rendered = [QueriedFeature(properties: ["segment_id": "climb"], geometry: line, layer: "route")]
/// map.addLayer(MapLayer(id: "route", type: .line, source: "trail", rank: 50))
/// surface.tap(at: [120, 80], position: [6.86, 45.83])
/// ```
///
/// Its canvas measures in points and its projection, unless the test states one, reads a position
/// as its point, a longitude an x and a latitude a y. A fit lands where `cameraForBounds` frames the
/// box on its canvas, facing north and keeping the pitch the engine holds. The engine holds the
/// surface it is drawn on weakly, so the test keeps it. It is bound to the main actor, as the engine
/// is.
@MainActor
public final class ScriptedMapSurface: MapSurface {
  /// Move is a camera move the engine handed the surface: the members it states, and how it moves.
  public struct Move: Sendable, Equatable {
    /// target is the members the move states.
    public let target: CameraTarget
    /// motion is how the camera moves there.
    public let motion: CameraMotion

    /// Creates the move to the members `target` states, by `motion`, which a test compares the
    /// moves recorded with.
    public init(target: CameraTarget, motion: CameraMotion) {
      self.target = target
      self.motion = motion
    }
  }

  /// Frame is a box the engine asked the surface to frame, in canonical form, and the fit it framed
  /// it with.
  public struct Frame: Sendable, Equatable {
    /// bounds is the box, `[west, south, east, north]`.
    public let bounds: [Double]
    /// fit is the fit the box was framed with.
    public let fit: CameraFit

    /// Creates the frame of `bounds` with `fit`, which a test compares the frames recorded with.
    public init(bounds: [Double], fit: CameraFit) {
      self.bounds = bounds
      self.fit = fit
    }

    /// Two frames are equal where they frame the same box, each number the same, with one fit.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumbers(lhs.bounds, rhs.bounds) && lhs.fit == rhs.fit
    }
  }

  /// BaseSource is a source of the base map's style as a renderer reports it: the credit it states,
  /// its TileJSON's where the style states none, as MapLibre Native reads a source named by its
  /// TileJSON's address, and whether a layer draws it at the camera's zoom.
  public struct BaseSource: Sendable, Hashable {
    /// attribution is the credit the source states, or nil where it states none.
    public var attribution: String?
    /// isDrawn is whether a layer of the style draws the source at the camera's zoom.
    public var isDrawn: Bool

    /// Creates a source of the base map's style crediting `attribution`, drawn where `isDrawn`.
    public init(attribution: String?, isDrawn: Bool) {
      self.attribution = attribution
      self.isDrawn = isDrawn
    }
  }

  /// Label is a symbol layer of the base map the surface draws: its id and its label as its style
  /// wrote it, a `text-field`.
  public struct Label: Sendable, Equatable {
    /// id is the symbol layer's id.
    public let id: String
    /// textField is the label as the style wrote it.
    public let textField: JSONValue

    /// Creates the symbol layer `id` labelled `textField`.
    public init(id: String, textField: JSONValue) {
      self.id = id
      self.textField = textField
    }

    /// Two labels are equal where their ids and their labels are the same.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.id, rhs.id) && sameJson(lhs.textField, rhs.textField)
    }
  }

  /// zoomLimits is the renderer's own zoom limits the surface plays: the floor no window reaches
  /// under, and the ceiling a window released goes back to.
  public let zoomLimits: ZoomBounds
  /// canvas is the size the map is drawn at, `[width, height]` in points.
  public var canvas: [Double]
  /// projection is the projection the map is drawn through, a position read as its point unless
  /// the test states another.
  public var projection: ScreenProjection
  /// rendered is every feature the surface draws under any point, topmost first, of which a query
  /// answers those its layers drew.
  public var rendered: [QueriedFeature] = []
  /// liveLayers is the id of every layer the live style holds, or nil for every layer the engine
  /// draws.
  public var liveLayers: [String]?
  /// heldSources is the id of every source the live style holds, or nil for every source the
  /// engine holds.
  public var heldSources: [String]?
  /// baseLabels is every symbol layer of the base map, bottom to top, under the map's own.
  public var baseLabels: [Label] = []
  /// baseSources is every source of the base map's style the surface reports, in the order a
  /// renderer reads them, which the map credits beside its own (`map.style.attribution`): none by
  /// default.
  public var baseSources: [BaseSource] = []

  /// moves is every camera move the engine handed the surface, in order.
  public private(set) var moves: [Move] = []
  /// frames is every box the engine asked the surface to frame, in order.
  public private(set) var frames: [Frame] = []
  /// queries is the layers each point query asked the surface about, in order.
  public private(set) var queries: [[String]] = []
  /// relabelled is the id of every symbol layer the engine gave a label of its own language, in
  /// order; a label put back as its style wrote it is not among them.
  public private(set) var relabelled: [String] = []

  private weak var engine: MapEngine?

  /// Creates a surface drawing `engine`, on a canvas of `canvas`, `[width, height]` in points, with
  /// the zoom limits of the renderer it plays, MapLibre Native's unless the test states another's.
  public init(
    drawing engine: MapEngine, canvas: [Double] = [800, 600],
    zoomLimits: ZoomBounds = ZoomBounds(minZoom: 0, maxZoom: 25.5)
  ) {
    self.engine = engine
    self.canvas = canvas
    self.zoomLimits = zoomLimits
    self.projection = ScreenProjection(point: { $0 }, position: { $0 })
    engine.attach(self)
  }

  // MARK: - What happens on the canvas

  /// tap plays a tap at `point` of the canvas, where the renderer read `position`.
  public func tap(at point: [Double], position: [Double]) {
    engine?.tapped(at: point, position: position)
  }

  /// longTap plays a long press, or a secondary click, at `point` of the canvas, where the renderer
  /// read `position`.
  public func longTap(at point: [Double], position: [Double]) {
    engine?.longTapped(at: point, position: position)
  }

  /// hover plays a hovering pointer moving to `point` of the canvas, where the renderer read
  /// `position`.
  public func hover(at point: [Double], position: [Double]) {
    engine?.pointerMoved(to: point, position: position)
  }

  /// drawFrame plays the next frame the map draws.
  public func drawFrame() {
    engine?.frameDrawn()
  }

  /// leave plays a hovering pointer leaving the canvas at `point`, where the renderer read
  /// `position`.
  public func leave(at point: [Double], position: [Double]) {
    engine?.pointerLeft(at: point, position: position)
  }

  /// failRequest plays a request the renderer made for itself failing: to `url`, carrying `status`
  /// where an answer carried one, for a tile of `source` where it was a tile's. `superseded` says
  /// the request left under a credential the client no longer sends as the answer arrives, a
  /// session token since replaced or minted after it left under the key alone, or a visitor's
  /// cookie since changed, which `MapView`'s renderer reads off the headers each request left with.
  /// `cause` is what a read of the client's credential threw, for a request that never left for
  /// want of one: whatever `status` it would have met, it fails as a failure carrying `cause`.
  public func failRequest(
    url: String?, status: Int?, source: String?, superseded: Bool = false,
    cause: (any Error)? = nil
  ) {
    engine?.requestFailed(
      url: url, status: status, source: source, superseded: superseded, cause: cause)
  }

  /// loadTile plays a tile of `source` loading.
  public func loadTile(of source: String) {
    engine?.tileLoaded(source: source)
  }

  /// loadStyle plays a style loading, the base map the engine asked for last, its labels being
  /// `baseLabels` as it loads.
  public func loadStyle() {
    guard let engine else { return }
    engine.styleLoaded(engine.state.style, terrain: engine.state.terrain)
  }

  /// failStyle plays the document of the base map the engine asked for last not arriving, which
  /// gives the map back the base map shown.
  public func failStyle() {
    guard let engine else { return }
    engine.styleFailed(engine.state.style)
  }

  // MARK: - What the engine asks

  func move(to target: CameraTarget, by motion: CameraMotion) {
    moves.append(Move(target: target, motion: motion))
  }

  func frame(_ bounds: [Double], with fit: CameraFit, within window: ZoomBounds) -> CameraPose? {
    frames.append(Frame(bounds: bounds, fit: fit))
    guard
      let viewport = cameraForBounds(
        bounds, canvas: canvas, padding: fit.padding ?? PixelPadding(0), maxZoom: fit.maxZoom,
        window: window)
    else { return nil }
    return CameraPose(
      center: viewport.center, zoom: viewport.zoom, pitch: engine?.state.camera.pitch ?? 0,
      bearing: 0)
  }

  func holdsLayer(_ id: String) -> Bool {
    if let liveLayers {
      return liveLayers.contains { sameText($0, id) }
    }
    return engine?.state.layers.contains { sameText($0.id, id) } ?? false
  }

  func holdsSource(_ id: String) -> Bool {
    if let heldSources {
      return heldSources.contains { sameText($0, id) }
    }
    return engine?.state.sources.contains { sameText($0.id, id) } ?? false
  }

  func renderedFeatures(at point: [Double], in layers: [String]) -> [QueriedFeature] {
    queries.append(layers)
    return rendered.filter { feature in layers.contains { sameText($0, feature.layer) } }
  }

  var symbolLabels: [SymbolLabel] {
    let base = baseLabels.map { SymbolLabel(id: $0.id, textField: $0.textField) }
    let own = (engine?.state.layers ?? []).compactMap { layer -> SymbolLabel? in
      guard sameText(layer.type, .symbol), let label = layer.layout["text-field"]
      else { return nil }
      return SymbolLabel(id: layer.id, textField: label)
    }
    return base + own
  }

  func relabel(_ id: String, to label: JSONValue?) {
    if label != nil {
      relabelled.append(id)
    }
  }

  var creditedBaseSources: [CreditedSource] {
    baseSources.map { CreditedSource(attribution: $0.attribution, isDrawn: $0.isDrawn) }
  }

  /// mapMoved reads nothing again: a scripted surface stands in no window.
  func mapMoved() {}
}
