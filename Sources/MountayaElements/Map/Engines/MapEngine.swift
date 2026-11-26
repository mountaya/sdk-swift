import Foundation
import MountayaClient
import MountayaGeo
import Observation

/// MapEngine holds a map's state: the base map, the camera and the pan lock and zoom range it is
/// held to, the language the labels speak, every source and layer drawn above the base map, the
/// markers shown above them, the waypoint being placed, and whether a refusal of access stands,
/// which `MapView` renders and a consumer who draws a map of their own reads as `state`.
///
/// It takes the app's `Mountaya`, never a client of its own: the map reads the Tile API's
/// catalogue and the content it draws by id through it, and the renderer sends its own requests for
/// tiles, styles, sprites and glyphs with its credential and its language
/// (`Mountaya.mapRequestHeaders(for:)`). A map given no label language labels in the client's, the
/// one it sends as `Accept-Language`, before the device's (`geo.style.label-language`).
///
/// ```swift
/// let map = MapEngine(client: mountaya)
/// try await map.setTerrain()
/// try await map.setItinerary(itineraryId, fit: CameraFit(padding: PixelPadding(48)))
/// try await map.setZones(true)
/// ```
///
/// It holds content in slots, each drawing its latest request (`map.slots.latest-request`): the
/// itinerary and the collection drawn by id, the itineraries and zones switched on, the classic
/// overlay and the enrichments the catalogue names, the classic overlay the server stamps drawn for
/// the instant pinned, `setInstant(_:)` (`map.overlays.instant`), and a specification an app draws
/// under a name of its own. Every layer goes through the one layer registry, which ranks it by
/// `geo.layers.order`, keeps the caller's word on its visibility by its id
/// (`map.layers.visibility`), and is drawn again on every base map a switch brings in
/// (`map.basemap.replay`). Beside each itinerary line it draws the route's restricted stretches,
/// shown until the app hides them (`map.road-access.layers`), and above everything else the result
/// a reader picked from a search, `setSearchHighlight(_:accent:)` (`map.search.result-highlight`).
/// A layer is changed by a patch
/// (`map.engine.patch`): a member it states replaces the one held, JSON's `null`, `false`, `0` and
/// the empty string included, and a member it leaves `nil` leaves the one held as it is.
///
/// The camera moves by `jump(to:)`, `ease(to:)` and `fly(to:)`, each taking the members a
/// `CameraTarget` states and keeping the rest (`map.camera.pose`), frames a box by
/// `fitBounds(_:with:)`, a fit this SDK computes rather than asks of its renderer
/// (`geo.camera.fit`), steps by `zoomIn()`, `zoomOut()` and `resetNorth()`
/// (`map.camera.control-moves`), and locates the device by `locate()` (`map.camera.locate`). A
/// point query, `features(at:)` and its siblings, asks only about the layers the map placed
/// (`map.query.layers`), and what happens on the map is told by `events()`: a tap, a long press,
/// the features a tap lands on and a hovering pointer is over, a refusal of access and its end, and
/// a failed request.
///
/// A waypoint is placed by an edit, `beginWaypointEdit(_:at:)` to `endWaypointEdit()`: each tap
/// on the map places it, `placeWaypoint(at:through:)`, and where it falls within 40 pixels of
/// one of the active segments the edit's magnet places it on the segment (`map.edit.snap`).
///
/// Its marker sprites, the images a waypoint's and a point of interest's symbol layers name, are
/// drawn from `glyphs`, the bundled marker set unless the app hands in a set of its own: where a
/// style names `section-icon-` or `poi-icon-` then a glyph, a hyphen and six hexadecimal digits,
/// the map draws that glyph in white on a disc of that colour (`map.icons.missing-image`).
///
/// It reads its organization once it is first drawn, `loadOrganization()`, through a read every map
/// whose client holds the same publishable key and sends to the same Map Studio API origin shares
/// (`map.organization.read`): the answer decides whether the map draws the Mountaya watermark,
/// which no host can take off (`geo.organization.watermark`), and nothing else the map draws. A
/// right-click or a long press opens a readout of the point, unless the host turned it off, which
/// reads the terrain off the elevation tiles there, and a camera move or a tap closes it
/// (`map.readout.open`).
///
/// It is bound to the main actor, as every engine is, and `Observable`, so a SwiftUI view that
/// reads `state` is drawn again when it changes. Each command has its effect before it returns,
/// and reports a state only where it differs from the one held. A closed map is inert
/// (`map.engine.closed`).
@MainActor
@Observable
public final class MapEngine {
  /// state is what the map shows.
  public var state: MapState { held }

  /// held is the state the engine holds, which an observer of `state` is told of.
  private var held: MapState

  /// client is the app's client, whose credential and language the renderer's own requests
  /// carry.
  @ObservationIgnored let client: Mountaya
  /// transformRequest is the app's own hook for the renderer's requests, called before a client's
  /// credential is attached, for every map's while this map is the one shown last to name one.
  @ObservationIgnored let transformRequest: (@Sendable (MapRequest) -> MapRequest)?
  /// glyphs is the glyph set the map's marker sprites are drawn from.
  @ObservationIgnored public let glyphs: GlyphSet
  /// paint is how the map paints what it draws above its base map: the itinerary stroke the
  /// lines it draws from data take, and the rank each tile source layer draws at
  /// (`geo.style.map-paint`).
  @ObservationIgnored public let paint: MapPaint
  /// geolocation is where a locate's fix comes from.
  @ObservationIgnored let geolocation: any Geolocation
  /// surface is what draws the map, which the engine asks what only a renderer knows.
  @ObservationIgnored weak var surface: (any MapSurface)?
  /// registry is the one layer registry, which ranks every layer the map draws.
  @ObservationIgnored private var registry = MapLayerRegistry()
  /// isClosed is whether the map is closed, after which it is inert.
  @ObservationIgnored private(set) var isClosed = false
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers: [Int: AsyncStream<MapState>.Continuation] = [:]
  /// listeners is every stream `events()` returned that has not ended, by its number.
  @ObservationIgnored private var listeners: [Int: AsyncStream<MapEvent>.Continuation] = [:]
  @ObservationIgnored private var nextSubscriber = 0
  /// standing is the refusals of access that stand.
  @ObservationIgnored private var standing = StandingRefusals()
  /// hovering is where a hovering pointer last moved, waiting on the next frame.
  @ObservationIgnored private(set) var hovering: (point: [Double], position: [Double])?
  /// relabelled is the id of every symbol layer of the base map whose label the engine rewrote.
  @ObservationIgnored private var relabelled: [String] = []
  /// reducesMotion is whether a camera move a control starts lands at once rather than travelling
  /// there: a zoom step and a compass reset, a located fix framed, and the ease into an overlay's
  /// zooms. `MapView` and the controls state it from SwiftUI's `accessibilityReduceMotion`, so a
  /// reader who asked the device for reduced motion is never carried across the map; a move the
  /// app makes itself travels as it asks.
  @ObservationIgnored var reducesMotion = false

  /// slots is the requests made of the map's slots, which a load that lands late draws nothing by.
  @ObservationIgnored private let slots = SlotRequests()
  /// contents is what each slot draws, in the order each slot was first asked for.
  private var contents: [MapContent] = []
  /// hiddenLayerIds is the id of every layer the app hid, kept by its id before the layer is drawn,
  /// across a base-map switch and through a redraw of the content holding it.
  private var hiddenLayerIds: [String] = []
  /// isAccessRestrictionsVisible is whether the map shows the restricted stretches of the
  /// itineraries it draws: the stripes over each stretch of a route that follows a way restricting
  /// who may pass, and the warning icon of its kind. They are shown until the app hides them.
  public private(set) var isAccessRestrictionsVisible = true

  /// layersManifest is the layers catalogue the map holds, read for the studio scope it names, or
  /// nil before a read lands and once the scope moved (`map.layers.manifest`). It never reads:
  /// `loadLayers()` does.
  public private(set) var layersManifest: TileSchema.Layers?
  /// layersOrganization is the studio scope the catalogue is read for, or nil for none.
  @ObservationIgnored private var layersOrganization: String?
  /// manifestRead is the number of the catalogue read out for the scope named, or nil for none.
  @ObservationIgnored private var manifestRead: Int?
  /// manifestReads is how many catalogue reads the map sent.
  @ObservationIgnored private var manifestReads = 0
  /// manifestWaiters is every load waiting on a catalogue read another load sent.
  @ObservationIgnored private var manifestWaiters:
    [CheckedContinuation<TileSchema.Layers, any Error>] = []

  /// instant is the instant pinned last, which the map draws the classic overlay the server stamps
  /// for, or nil for none pinned, where it draws the manifest's own addresses
  /// (`map.overlays.instant`). Observation tells no view of it: a view showing the pin reads the
  /// layers selection's, `LayersSelection.instant`, which it does.
  public var instant: Date? { pinned.map { Date(timeIntervalSinceReferenceDate: $0) } }
  /// pinned is the instant pinned last, in seconds from the reference date as a `Date` holds it, or
  /// nil for none: Foundation keeps the layout of its `Date` to itself, and an engine holding one
  /// reads every member after it at an offset found at run time.
  @ObservationIgnored private var pinned: Double?
  /// classicDrawn is the classic overlay the map draws, with the catalogue it was found in, which a
  /// pin stamps, or nil for none.
  @ObservationIgnored private var classicDrawn:
    (catalogue: TileSchema.Layers, overlay: TileSchema.Overlay)?

  /// terrainVariantAsked is the variant the app asked for last, light until it asks for dark.
  @ObservationIgnored private var terrainVariantAsked: TileSchema.TerrainVariant
  /// baseMapRequests is how many base maps the app asked for, of which the latest is shown.
  @ObservationIgnored private var baseMapRequests = 0
  /// terrainReading is the terrain a `setTerrain(_:)` still reading the catalogue asks for.
  @ObservationIgnored private var terrainReading: TerrainAsk?
  /// terrainLastAsked is the terrain asked for last that the catalogue did not refuse.
  @ObservationIgnored private var terrainLastAsked: TerrainAsk?
  /// shownStyle and shownTerrain are the base map the renderer last loaded, which a base map that
  /// does not arrive gives the map back to.
  @ObservationIgnored private var shownStyle: URL?
  @ObservationIgnored private var shownTerrain: String?
  /// givenBack is the base map a style that did not arrive gave back, until it loads again: its load
  /// answers nothing (`map.events.access-standing`).
  @ObservationIgnored private var givenBack: (style: URL?, terrain: String?)?

  /// analyses is every Data API result the map draws, by the id it is drawn under.
  @ObservationIgnored private var analyses: [(id: String, held: HeldAnalysis)] = []
  /// queryAborts is the abort of each query out for a result, by the result's id.
  @ObservationIgnored private var queryAborts: [(id: String, abort: QueryAbort)] = []
  /// analysisCount is how many results the map was asked to add, which numbers their ids.
  @ObservationIgnored private var analysisCount = 0
  /// geometrySlots is what each geometry slot written holds.
  private var geometrySlots: [(slot: GeometrySlot, held: SlotGeometry)] = []

  /// organization is the organization the map read, its client's publishable key's, or nil
  /// before a read answers, after one fails, and for a client holding no publishable key
  /// (`map.organization.read`). It never reads: `loadOrganization()` does.
  public private(set) var organization: RestSchema.Organization?
  /// organizationRead is where the map's read of its organization stands, in the five states its
  /// watermark is drawn by (`map.organization.read`, `geo.organization.watermark`): waiting from
  /// the map's making until its first read answers, timed out once that read has gone one attempt's
  /// time budget with no answer, answered with whether the organization holds white label, and once
  /// a read failed, failed until a later read answers, so a read asked again never takes the mark
  /// off while it waits; no key from the making of a map whose client holds no publishable key. A
  /// host reads it to keep its own interface clear of the mark until the read answers white label,
  /// as the map's own controls, panels, readout and marker label do: `isWatermarkKeptClear(_:)`
  /// answers whether the frame is held, and `watermarkClearance` how far below the safe area's top
  /// it ends.
  public private(set) var organizationRead: OrganizationRead

  /// isWatermarked is whether the map draws the Mountaya watermark as its read stands: once the
  /// read answered no white label, failed or went one attempt's budget with no answer, or for a
  /// client holding no publishable key.
  var isWatermarked: Bool {
    watermarkOf(organizationRead, language: .en) != nil
  }
  /// shownMap is where the view drawing the map laid it out last, in the view hierarchy's global
  /// coordinates, or nil while no view draws it, before the first view laid it out and once the
  /// view drawing it went. A control stack laid over the map reads where the watermark
  /// stands through it, to keep clear of it, and where the map's edge cuts its panels, and keeps
  /// to its own space while it is nil (`sdk/SPEC.md` §15).
  private(set) var shownMap: ScreenRect?
  /// safeArea is how far inside the map's edges its safe area stands, the part of it the device
  /// leaves visible, as the view drawing it measured it last, as it was laid out and as it moved in
  /// its window with no layout of its own: the watermark is measured from the safe area's top-left
  /// corner, so a map drawn full bleed shows it (`sdk/SPEC.md` §15).
  private(set) var safeArea = PixelPadding(0)

  /// shown records where the view drawing the map laid it out, `map` in global coordinates, where
  /// that changed, and hands the surface drawing it the move, laid out again or moved in its window
  /// with no layout of its own, so it measures the map's safe area again (`MapSurface.mapMoved()`).
  func shown(at map: ScreenRect) {
    guard shownMap != map else { return }
    shownMap = map
    surface?.mapMoved()
  }

  /// unshown records that `surface`, the renderer of a view that goes, draws the map no more, as
  /// `MapView` tells it as SwiftUI lets the view go, so a control stack over the map keeps to its
  /// own space until a view draws it again (`sdk/SPEC.md` §15): the map is drawn by no view only
  /// while `surface` is still the one it is drawn on, never where another view drew it since.
  func unshown(by surface: any MapSurface) {
    guard self.surface === surface else { return }
    shownMap = nil
  }

  /// safeAreaShown records how far inside the map's edges its safe area stands, `safeArea`, where
  /// that changed.
  func safeAreaShown(_ safeArea: PixelPadding) {
    guard self.safeArea != safeArea else { return }
    self.safeArea = safeArea
  }

  /// watermarkKeptClearFrame is the frame nothing of the map's own lays over: where the mark stands,
  /// or will once its read answers, in global coordinates, or nil where no view draws the map or
  /// its read no longer holds it, an answer of white label (`isWatermarkKeptClear`).
  var watermarkKeptClearFrame: ScreenRect? {
    guard let shownMap, isWatermarkKeptClear(organizationRead) else { return nil }
    return watermarkFrame(safeArea: safeArea).offset(dx: shownMap.x, dy: shownMap.y)
  }

  /// safeAreaFrame is the map's safe area, the part of it the device leaves visible, in global
  /// coordinates, which every part of the map's own interface keeps to, or nil while no view draws
  /// the map (`sdk/SPEC.md` §15).
  var safeAreaFrame: ScreenRect? {
    guard let shownMap else { return nil }
    return safeAreaBounds(safeArea, width: shownMap.width, height: shownMap.height)
      .offset(dx: shownMap.x, dy: shownMap.y)
  }
  /// organizations is the reads the map shares with every map of the process, the process's own
  /// unless a test hands the engine others.
  @ObservationIgnored var organizations: OrganizationReads
  /// organizationWaiters is every load waiting on the map's read of its organization.
  @ObservationIgnored private var organizationWaiters:
    [CheckedContinuation<RestSchema.Organization?, any Error>] = []
  /// isReadingOrganization is whether the map waits on a read of its organization.
  @ObservationIgnored private var isReadingOrganization = false
  /// organizationDeadline waits one attempt's time budget from the map's first read of its
  /// organization, after which the map draws its watermark whatever the read still waits on.
  @ObservationIgnored private var organizationDeadline: Task<Void, Never>?

  /// readout is the readout open on the map, or nil (`map.readout.open`).
  private(set) var readout: MapReadout?
  /// isReadoutOn is whether a right-click or a long press opens a readout, which `MapView` states
  /// from its `readout` argument, on unless the host turns it off.
  @ObservationIgnored var isReadoutOn = true
  /// readoutsOpened is how many readouts the map opened, which numbers them.
  @ObservationIgnored private var readoutsOpened = 0
  /// readoutReads is the read of the terrain for the readout open, its tile reads under it, which
  /// closing or replacing the readout cancels.
  @ObservationIgnored private var readoutReads: Task<Void, Never>?
  /// elevation is how the map reads the terrain its readout states.
  @ObservationIgnored let elevation = ElevationReads()

  /// Creates an engine holding a map of `style` seen from `camera`, labelled in `labelLanguage`,
  /// and drawing nothing above its base map.
  ///
  /// `client` is the app's own. `style` is a base map's style document of the app's own, nil until
  /// `setTerrain(_:)` or `setStyle(_:)` chooses one. `terrainVariant` is the variant every terrain
  /// of the catalogue is drawn in until `setTerrainVariant(_:)` asks for another, light unless the
  /// app names dark. `labelLanguage`, where given, is read as a label language is, by the languages
  /// the base map's tiles carry. `paint` is how the map paints what it draws, `MapPaint.standard`
  /// unless the app restyles a copy of it: the itinerary stroke and the band each tile source layer
  /// draws at. `glyphs` is the set the map's marker sprites and its markers' pins are drawn from, a
  /// licensed set of the app's own, alone or chained over the bundled one, in place of
  /// `GlyphSet.marker`. `geolocation` is where `locate()` asks for the device's position, the
  /// platform's location services unless the app hands in its own or `InertGeolocation`.
  /// `transformRequest` is the app's own hook for every request the renderer makes for itself,
  /// handed each as a `MapRequest` and called first: the URL it answers is the one a client's
  /// credential is claimed by, and a header it sets stands over the client's. MapLibre's hook is
  /// the process's, so while several maps are shown, the hook of the one shown last to name one is
  /// handed every map's requests.
  public init(
    client: Mountaya,
    style: URL? = nil,
    terrainVariant: TileSchema.TerrainVariant = .light,
    camera: CameraPose = CameraPose(center: [0, 0], zoom: 0, pitch: 0, bearing: 0),
    labelLanguage: RestSchema.Language? = nil,
    paint: MapPaint = .standard,
    glyphs: GlyphSet = .marker,
    geolocation: any Geolocation = DeviceGeolocation(),
    transformRequest: (@Sendable (MapRequest) -> MapRequest)? = nil
  ) {
    self.client = client
    self.paint = paint
    self.glyphs = glyphs
    self.geolocation = geolocation
    self.transformRequest = transformRequest
    self.terrainVariantAsked = terrainVariant
    self.organizations = .shared
    self.organizationRead = client.publishableKey == nil ? .noKey : .waiting
    self.shownStyle = style
    self.held = MapState(
      style: style,
      terrainVariant: terrainVariant,
      camera: camera,
      labelLanguage: Self.labelLanguage(given: labelLanguage, client: client)
    )
  }

  deinit {
    // An engine let go of ends its streams, so no reader waits on a state that never comes.
    for continuation in subscribers.values {
      continuation.finish()
    }
    for continuation in listeners.values {
      continuation.finish()
    }
  }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order, for as long as the stream is held. It ends at `close()`.
  public func subscribe() -> AsyncStream<MapState> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: MapState.self, bufferingPolicy: .unbounded)
    continuation.yield(held)
    if isClosed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    subscribers[number] = continuation
    return stream
  }

  /// events returns a stream that yields every event the map tells from now on, in order, for as
  /// long as the stream is held: each tap and long press no edit took, the features a tap lands on
  /// and those a hovering pointer is over, each refusal of access and the end of the last one
  /// standing, and each failure of one of the map's own requests. It ends at `close()`, after which
  /// nothing is told.
  public func events() -> AsyncStream<MapEvent> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: MapEvent.self, bufferingPolicy: .unbounded)
    if isClosed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    listeners[number] = continuation
    return stream
  }

  // MARK: - The base map

  /// setStyle shows the base map of a style document of the app's own at `style`, or none, in
  /// place of any terrain of the catalogue. Everything the map draws above its base map is drawn
  /// again on it, each layer at its rank and a hidden one hidden, a layer added with `addLayer(_:)`
  /// included (`map.basemap.replay`). A document that does not arrive leaves the base map shown and
  /// its content as they were.
  public func setStyle(_ style: URL?) {
    guard !isClosed else { return }
    baseMapRequests += 1
    terrainReading = nil
    terrainLastAsked = nil
    report { state in
      state.style = style
      state.terrain = nil
      state.terrainVariant = terrainVariantAsked
    }
  }

  /// setTerrain shows a terrain of the Tile API's catalogue as the base map
  /// (`map.basemap.terrain`): the one of slug `slug`, as the catalogue spells it, or the first it
  /// lists where `slug` is nil, in the variant asked for last, light until `setTerrainVariant(_:)`
  /// asks for dark. It reads the catalogue through `loadLayers()`, once for the studio scope the map
  /// names, and every layer the map draws is drawn again on the base map it brings in.
  ///
  /// The latest base map asked for wins: a `setTerrain(_:)` or a `setStyle(_:)` asked for while
  /// this one reads the catalogue is the one shown, and this one returns without switching.
  /// `state.terrain` names the terrain from the moment the catalogue names it, and a document that
  /// does not arrive gives the map back the base map still shown.
  ///
  /// A catalogue read the API refuses access, a 401, a 402 or a 403, is told as `accessRefused` at
  /// the catalogue's address and stands until the next style loads; one failing for any other
  /// reason is told as a `failure` (`map.events.access-refused`). Either way it throws what the
  /// client throws, and a `MapError` of kind `terrainNotFound` where the catalogue lists no such
  /// terrain, or none at all; the base map is then left as it was. A closed map reads nothing.
  public func setTerrain(_ slug: String? = nil) async throws {
    guard !isClosed else { return }
    baseMapRequests += 1
    let request = baseMapRequests
    let asked = TerrainAsk(request: request, slug: slug)
    terrainReading = asked
    terrainLastAsked = asked
    let catalogue: TileSchema.Layers
    do {
      catalogue = try await loadLayers()
    } catch {
      // A read the map gave up on, or one a later base map superseded, is told to nobody.
      if request == baseMapRequests, !(error is CancellationError), !(error is MapError) {
        terrainReading = nil
        var status: Int?
        if case .api(let refusal)? = error as? MountayaError {
          status = refusal.status
        }
        requestFailed(
          url: layersManifestAddress(client.baseUrls.tiles.absoluteString), status: status,
          source: nil)
      } else if request == baseMapRequests {
        terrainReading = nil
      }
      throw error
    }
    if request == baseMapRequests { terrainReading = nil }
    // The variant asked for while the catalogue was read is the one drawn.
    guard let found = baseMapOf(catalogue.terrains, slug: slug, variant: terrainVariantAsked)
    else {
      // A refused slug is never the terrain a later variant asks for again.
      if terrainLastAsked?.request == request { terrainLastAsked = nil }
      throw MapError(kind: .terrainNotFound, name: slug ?? "")
    }
    guard request == baseMapRequests, !isClosed else { return }
    report { state in
      state.style = found.style
      state.terrain = found.terrain.slug
      state.terrainVariant =
        terrainVariantOfStyle(found.terrain, style: found.style)
        ?? terrainVariantAsked
    }
  }

  /// setTerrainVariant draws the catalogue's terrains in `variant`, light or dark, the app's word
  /// apart from any colour scheme around the map, from here on (`map.basemap.terrain`). The terrain
  /// the map shows or is switching to, or, on a map that shows none because the one asked for last
  /// did not arrive, that one, is asked for again in it through `setTerrain(_:)`; a terrain whose two
  /// variants are one document, and the variant already drawn, ask the renderer for nothing. Under a
  /// style of the app's own, and before any terrain, nothing is switched, and the next terrain is
  /// drawn in `variant`. It throws what `setTerrain(_:)` throws for the terrain asked for again,
  /// and the variant stands either way.
  public func setTerrainVariant(_ variant: TileSchema.TerrainVariant) async throws {
    guard !isClosed else { return }
    terrainVariantAsked = variant
    let again: TerrainAsk?
    if let reading = terrainReading {
      again = reading
    } else if let shown = held.terrain {
      again = TerrainAsk(request: baseMapRequests, slug: shown)
    } else if held.style == nil {
      again = terrainLastAsked
    } else {
      again = nil
    }
    guard let again else {
      report { $0.terrainVariant = variant }
      return
    }
    try await setTerrain(again.slug)
  }

  // MARK: - The layers catalogue

  /// loadLayers answers the layers catalogue, `getTileLayers`, read through the client for the
  /// studio scope `setLayersOrganization(_:)` names, and held: every terrain, overlay and enrichment
  /// the credential draws (`map.layers.manifest`). `setTerrain(_:)`, `setOverlay(_:)` and
  /// `addEnrichment(_:)` resolve their slugs through it, so a map that switches base maps reads it
  /// once.
  ///
  /// It is read once for the scope and shared by every load until the scope moves: a load made
  /// while a read is out waits on that read. Each read that lands is told as `layersChange`. A read
  /// that fails is kept by nobody, so the next load reads again, and every load waiting on it throws
  /// what it failed with. A read that lands, or fails, after the scope moved is another scope's: it
  /// is kept by nobody and told to nobody, and every load waiting on it is answered the current
  /// scope's catalogue instead, read again where no read is out for it. Every read runs in the task
  /// of a load waiting on it. A closed map reads nothing more: it answers the catalogue it held, and
  /// throws a `MapError` of kind `closed` where it held none.
  @discardableResult
  public func loadLayers() async throws -> TileSchema.Layers {
    if let held = layersManifest { return held }
    guard !isClosed else { throw MapError(kind: .closed, name: "loadLayers") }
    if manifestRead != nil {
      return try await withCheckedThrowingContinuation { manifestWaiters.append($0) }
    }
    return try await readLayers()
  }

  /// setLayersOrganization names the studio scope the layers catalogue is read for: an
  /// organization, sent as `organization_id`, or nil, or the empty text, for the read that names
  /// none (`map.layers.manifest`). Moving the scope drops the catalogue held, which `layersManifest`
  /// then reads as nil and `layersChange` tells, and a read still out for the scope before is
  /// another scope's as it lands. Naming the scope the map already reads for changes nothing.
  ///
  /// What the map already draws stays drawn: an overlay, the itineraries and the zones keep the
  /// tile addresses of the scope they were read in, so an app redraws what it still wants once the
  /// new catalogue lands.
  public func setLayersOrganization(_ organizationId: String?) {
    guard !isClosed else { return }
    let named = organizationId.flatMap { $0.isEmpty ? nil : $0 }
    guard !sameText(named, layersOrganization) else { return }
    layersOrganization = named
    manifestRead = nil
    guard layersManifest != nil else { return }
    layersManifest = nil
    tell(.layersChange(nil))
  }

  // MARK: - The camera

  /// jump moves the camera to `target` at once: the members it states, every other kept where the
  /// camera has it, the zoom held within the zoom range (`map.camera.pose`).
  ///
  /// It throws a `MapError` of kind `positionRefused` where the centre is not two finite numbers,
  /// the latitude from -90 to 90, and of kind `numberRefused` where the zoom, the bearing or the
  /// pitch is not a finite number; nothing moves.
  public func jump(to target: CameraTarget) throws(MapError) {
    try move(to: target, by: .jump)
  }

  /// ease moves the camera to `target` along a straight ease, the default for a move the app makes,
  /// as `jump(to:)` reads it and refuses what it refuses.
  public func ease(to target: CameraTarget) throws(MapError) {
    try move(to: target, by: .ease())
  }

  /// fly moves the camera to `target` along the curved flight that pulls out and back in, as
  /// `jump(to:)` reads it and refuses what it refuses.
  public func fly(to target: CameraTarget) throws(MapError) {
    try move(to: target, by: .fly)
  }

  /// fitBounds moves the camera to frame `bounds`, `[west, south, east, north]` in degrees, with
  /// the padding, the ceiling and the duration `fit` states (`map.camera.fit-options`): facing
  /// north at the highest zoom at which the box fits the canvas less its padding, within the zoom
  /// range and under the fit's ceiling, keeping its pitch (`geo.camera.fit`).
  ///
  /// The box is read as `normalizeBoundingBox(_:)` writes it, so one drawn from its east corner is
  /// framed the right way round and one across the antimeridian, its east edge past 180, is framed
  /// across it. The fit is computed on the canvas the map is drawn on, so a map no view draws
  /// frames nothing.
  ///
  /// It throws a `MapError` of kind `numberRefused` where the fit states a padding or a duration
  /// that is not a finite number from 0 up, or a ceiling that is not a finite number, and of kind
  /// `positionRefused` where the box is not four finite numbers; nothing moves.
  public func fitBounds(_ bounds: [Double], with fit: CameraFit = CameraFit()) throws(MapError) {
    guard !isClosed else { return }
    let read = try readCameraFit(fit)
    let box = normalizeBoundingBox(bounds)
    guard box.allSatisfy(\.isFinite) else {
      throw MapError(kind: .positionRefused, name: "\(bounds)")
    }
    frame(box, with: read)
  }

  /// zoomIn eases the camera one zoom in from the zoom it stands at, unrounded and held within the
  /// zoom range, its centre, bearing and pitch kept (`map.camera.control-moves`), and moves it there
  /// at once where the reader asked for reduced motion.
  public func zoomIn() {
    controlMove(.zoomIn)
  }

  /// zoomOut eases the camera one zoom out from the zoom it stands at, unrounded and held within
  /// the zoom range, its centre, bearing and pitch kept (`map.camera.control-moves`), and moves it
  /// there at once where the reader asked for reduced motion.
  public func zoomOut() {
    controlMove(.zoomOut)
  }

  /// resetNorth eases the camera back to facing north and looking straight down, its bearing and
  /// its pitch turned to 0, its centre and zoom kept, which is what a compass means by reset
  /// (`map.camera.control-moves`), and turns it there at once where the reader asked for reduced
  /// motion.
  public func resetNorth() {
    controlMove(.resetNorth)
  }

  /// easeIntoZoomRange eases the camera into `window`, the zooms a specification paints across
  /// (`paintZoomRange(_:)`): a camera below it moves up to its floor and one above it down to its
  /// ceiling, the nearer edge, and one inside it, or before a window no move satisfies, stays
  /// (`geo.camera.zoom-into-range`). A layer outside its window paints nothing and reports nothing,
  /// so a switch that turns one on from too far out would otherwise read as a dead control. Where
  /// the reader asked for reduced motion, the camera lands there at once.
  public func easeIntoZoomRange(_ window: ZoomBounds) {
    guard !isClosed, let zoom = zoomIntoRange(held.camera.zoom, window: window) else { return }
    try? move(
      to: CameraTarget(zoom: zoom), by: reducesMotion ? .jump : .ease(duration: Self.zoomEase))
  }

  /// locate asks the device for its position, one fix, through the map's geolocation, and frames
  /// it: the camera fits the box its accuracy spans (`accuracyBounds(_:radiusMeters:)`) at
  /// `locateMaxZoom` at most, so a coarse fix frames the area it may be anywhere in and a precise one
  /// a street, at once where the reader asked for reduced motion. A fix that states no accuracy, or
  /// one that is no finite number from 0 up, is framed on its position alone. It answers the
  /// position, `[longitude, latitude]` (`map.camera.locate`).
  ///
  /// It throws a `MapError` of kind `fixRefused` where the geolocation answers no fix, naming its
  /// reason, and nothing moves; and of kind `closed` on a closed map, which asks the device nothing,
  /// since asking may prompt its reader and nothing would follow. A fix that arrives once the map
  /// has closed frames nothing, a closed map being inert, and its position is still answered.
  @discardableResult
  public func locate() async throws(MapError) -> [Double] {
    guard !isClosed else { throw MapError(kind: .closed, name: "locate") }
    switch await geolocation.locate() {
    case .refused(let reason):
      throw MapError(kind: .fixRefused(reason), name: "locate")
    case .located(let position, let accuracyMeters):
      let radius = accuracyMeters.isFinite && accuracyMeters > 0 ? accuracyMeters : 0
      let box = normalizeBoundingBox(accuracyBounds(position, radiusMeters: radius))
      if box.allSatisfy(\.isFinite) {
        frame(box, with: CameraFit(maxZoom: locateMaxZoom, duration: reducesMotion ? .zero : nil))
      }
      return position
    }
  }

  /// isLocationRefused reads, through the map's geolocation and without asking anyone, whether the
  /// standing permission refuses a fix: true where it answers `denied`, the reader's refusal, the
  /// platform's restriction or a reader allowing only an approximate fix, and false where it is
  /// granted, never asked for, or cannot be known. A locate control says location is blocked on
  /// this word alone (`geo.controls.geolocate-state`), and a closed map still answers it.
  public func isLocationRefused() async -> Bool {
    await geolocation.permission() == .denied
  }

  /// terrain is the slug of the catalogue terrain the base map is, as `state.terrain` holds it, or
  /// nil under a style of the app's own and before any terrain: the terrain a layers selection
  /// states once the catalogue lands (`geo.layers.selection`).
  public var terrain: String? { held.terrain }

  /// setMaxBounds holds the camera within a pan lock, `[west, south, east, north]` in degrees, or
  /// lifts the lock where `bounds` is nil.
  ///
  /// The lock is read as a box is: each axis ordered low to high, so a west edge greater than the
  /// east one is a box drawn from its east corner, and one crossing the antimeridian is written
  /// with its east edge past 180; each latitude held within the latitudes a map draws; and a box a
  /// turn or more wide is the whole world a hair under a turn, which a renderer measures a width
  /// in (`maxBoundsLongitudes(west:east:)`). The renderer then keeps what the view shows within
  /// it, so the view zooms out no farther than the zoom at which it fits within the lock.
  ///
  /// It throws a `MapError` of kind `maxBoundsRefused` where the lock so read encloses no area
  /// (`refusesMaxBounds(_:)`), and the map is left as it was.
  public func setMaxBounds(_ bounds: [Double]?) throws(MapError) {
    guard !isClosed else { return }
    guard let bounds else {
      report { $0.maxBounds = nil }
      return
    }
    var lock = normalizeBoundingBox(bounds)
    if lock[2] - lock[0] >= 360 {
      let longitudes = maxBoundsLongitudes(west: lock[0], east: lock[2])
      lock[0] = longitudes[0]
      lock[2] = longitudes[1]
    }
    guard !refusesMaxBounds(lock) else {
      throw MapError(kind: .maxBoundsRefused, name: "\(bounds)")
    }
    report { $0.maxBounds = lock }
  }

  /// setZoomBounds moves the zoom range the camera is held to, each limit as `min` and `max` state
  /// it (`map.camera.zoom-window`): a limit left `.kept` stays where the map holds it, one
  /// `.released` goes back to the renderer's own, MapLibre Native's floor of 0 and ceiling of 25.5,
  /// and one given a zoom moves to it. A range of one zoom holds the camera at it, and a camera
  /// outside the range is brought to its nearest end.
  ///
  /// ```swift
  /// try map.setZoomBounds(min: 8, max: 12)
  /// try map.setZoomBounds(max: .released)
  /// ```
  ///
  /// A call that moves the range reports one state; one that leaves it as it is reports none. It
  /// throws, with nothing applied, a `MapError` of kind `numberRefused` where a limit is not a
  /// finite number, and of kind `zoomBoundsRefused` where the least zoom lies under the
  /// renderer's floor, or above the greatest, the one stated beside it or the one held where it is
  /// stated alone, or where a greatest zoom stated alone lies under the least one held.
  public func setZoomBounds(min: ZoomLimit = .kept, max: ZoomLimit = .kept) throws(MapError) {
    guard !isClosed else { return }
    let window = try zoomWindowAfter(
      held.zoomBounds, min: min, max: max, renderer: rendererZoomLimits)
    report { state in
      state.zoomBounds = window
      state.camera = Self.held(state.camera, within: window)
    }
  }

  // MARK: - Labels and credits

  /// setLabelLanguage labels the map in `language`, read as a label language is, or, where it is
  /// nil, in the client's language, then the device's. It relabels the base map's labels alone,
  /// never a layer the map placed, and again on every base map a switch brings in
  /// (`map.style.label-scope`).
  public func setLabelLanguage(_ language: RestSchema.Language?) {
    guard !isClosed else { return }
    let resolved = Self.labelLanguage(given: language, client: client)
    report { $0.labelLanguage = resolved }
    relabelBaseMap()
  }

  /// credits is what the map credits (`map.style.attribution`): Mountaya, always and first, then
  /// each source it draws by the credit that source states, the base map's in the order its
  /// renderer reads them and then the map's own in the order they were added, each credit once by
  /// its exact text and a blank one left out. A credit is markup, which a renderer shows as it
  /// shows its own.
  public var credits: [String] {
    let zoom = held.camera.zoom
    let own = held.sources.map { source in
      CreditedSource(
        attribution: source.attribution,
        isDrawn: held.layers.contains { layer in
          sameText(layer.source, source.id) && Self.draws(layer, at: zoom)
        })
    }
    return mapCredits((surface?.creditedBaseSources ?? []) + own)
  }

  // MARK: - Sources and layers

  /// addSource adds a source the map's layers may draw from, replacing the one of its id.
  public func addSource(_ source: MapSource) {
    report { state in
      if let place = state.sources.firstIndex(where: { sameText($0.id, source.id) }) {
        state.sources[place] = source
      } else {
        state.sources.append(source)
      }
    }
  }

  /// removeSource takes off the source of id `id` and every layer drawing from it. A source the
  /// map does not hold is nothing to take off.
  public func removeSource(_ id: String) {
    guard !isClosed else { return }
    registry.removeLayers(drawingFrom: id)
    let layers = registry.layers
    report { state in
      state.sources.removeAll { sameText($0.id, id) }
      state.layers = layers
    }
  }

  /// addLayer draws `layer` at its rank, through the one layer registry
  /// (`map.layers.rank-insertion`): beneath the lowest layer of a greater rank and above every
  /// other, so layers of one rank stack in the order they were placed. A layer added again under an
  /// id in use at the rank it holds keeps its place, and one added at another rank moves to the top
  /// of its new band. A layer the app hid by its id is drawn hidden.
  ///
  /// The map holds it as it holds every layer, so it is drawn again on every base map a switch
  /// brings in, until `removeLayer(_:)` takes it off.
  public func addLayer(_ layer: MapLayer) {
    guard !isClosed else { return }
    var placed = layer
    if isHidden(layer.id) {
      placed.layout["visibility"] = "none"
    }
    registry.add(placed)
    let layers = registry.layers
    report { $0.layers = layers }
  }

  /// editLayer merges a patch onto the layer drawn under `id`, in its place (`map.engine.patch`).
  ///
  /// A member `paint` or `layout` states replaces the one held, or is added where none was, and
  /// JSON's `null`, `false`, `0` and the empty string are values, a paint property set to `null`
  /// going back to the style's default. A member written as `nil` is unstated, which is what a
  /// caller forwards where it may not have a value: it leaves the member held as it is.
  ///
  /// ```swift
  /// try map.editLayer("route", paint: ["line-color": "#228be6", "line-opacity": nil])
  /// ```
  ///
  /// It throws a `MapError` of kind `layerNotFound` where no layer is drawn under `id`, and does
  /// nothing once the engine is closed.
  public func editLayer(
    _ id: String, paint: [String: JSONValue?] = [:], layout: [String: JSONValue?] = [:]
  ) throws(MapError) {
    guard !isClosed else { return }
    guard var layer = registry.layer(id) else {
      throw MapError(kind: .layerNotFound, name: id)
    }
    layer.paint.merge(statedMembers(paint)) { _, stated in stated }
    layer.layout.merge(statedMembers(layout)) { _, stated in stated }
    _ = registry.replace(id, with: layer)
    let layers = registry.layers
    report { $0.layers = layers }
  }

  /// removeLayer takes off the layer drawn under `id`, and forgets whether the app hid it. A layer
  /// the map does not draw is nothing to take off.
  public func removeLayer(_ id: String) {
    guard !isClosed else { return }
    hiddenLayerIds.removeAll { sameText($0, id) }
    guard registry.remove(id) else { return }
    let layers = registry.layers
    report { $0.layers = layers }
  }

  // MARK: - Content

  /// setItinerary draws the itinerary of id `id`, its specification read through the client,
  /// `getItinerarySpecification`, in place of the itinerary drawn before, and answers whether it
  /// drew (`map.slots.latest-request`).
  ///
  /// The latest call draws, whatever order the reads answer in: a read that answers after a later
  /// call for the itinerary, or after `clearItinerary()`, draws nothing, and the call answers
  /// false. A call is withdrawn by cancelling its task: withdrawn before it drew, it throws
  /// `CancellationError` and gives the itinerary back to the call it superseded, which draws as its
  /// own read answers; withdrawn once it drew, it changes nothing. A call a later one superseded
  /// waits for that one to draw, end or be withdrawn before it answers.
  ///
  /// Where `fit` is given, the itinerary's geometry is read beside it, `getItinerary`, and the
  /// camera frames the box its segments span as `fitBounds(_:with:)` frames one, once the call drew
  /// and never for a call that drew nothing (`geo.camera.content-bounds`). The fit is read before
  /// anything is read or drawn: it throws a `MapError` of kind `numberRefused` where it states a
  /// padding or a duration that is not a finite number from 0 up, or a ceiling that is not a finite
  /// number (`map.camera.fit-options`). It throws what the client throws, and a `MapError` of kind
  /// `typeRefused` where the specification holds a source of a type the contract does not declare,
  /// nothing of it drawn. A closed map reads and draws nothing, and answers false.
  @discardableResult
  public func setItinerary(_ id: String, fit: CameraFit? = nil) async throws -> Bool {
    guard !isClosed else { return false }
    let framing = try fit.map { fit throws(MapError) in try readCameraFit(fit) }
    let client = client
    let loaded = try await load(.itinerary) {
      guard framing != nil else {
        return SlotLoad(
          specification: try await client.tiles.getItinerarySpecification(itinerary_id: id).data)
      }
      async let specification = client.tiles.getItinerarySpecification(itinerary_id: id)
      async let itinerary = client.studio.itineraries.getItinerary(itinerary_id: id)
      let (read, spanned) = try await (specification, itinerary)
      return SlotLoad(
        specification: read.data, bounds: itineraryBounds(spanned.data.segments))
    }
    guard let loaded else { return false }
    if let framing, let bounds = loaded.bounds {
      frame(normalizeBoundingBox(bounds), with: framing)
    }
    return true
  }

  /// clearItinerary takes off the itinerary drawn, and a read still out for one draws nothing.
  public func clearItinerary() {
    unmount(.itinerary)
  }

  /// setCollection draws the collection of id `id`, every itinerary and zone it holds, its
  /// specification read through the client, `getCollectionSpecification`, in place of the
  /// collection drawn before, and answers whether it drew, as `setItinerary(_:fit:)` reads, draws,
  /// is withdrawn and refuses (`map.slots.latest-request`).
  ///
  /// Where `fit` is given, the camera frames the box the specification states, `bbox`, the extent
  /// of the itineraries its tiles draw (`specificationBounds(_:)`), once the call drew; a
  /// specification stating no box frames nothing (`geo.camera.content-bounds`).
  @discardableResult
  public func setCollection(_ id: String, fit: CameraFit? = nil) async throws -> Bool {
    guard !isClosed else { return false }
    let framing = try fit.map { fit throws(MapError) in try readCameraFit(fit) }
    let client = client
    let loaded = try await load(.collection) {
      let specification = try await client.tiles.getCollectionSpecification(collection_id: id).data
      return SlotLoad(specification: specification, bounds: specificationBounds(specification.bbox))
    }
    guard let loaded else { return false }
    if let framing, let bounds = loaded.bounds {
      frame(normalizeBoundingBox(bounds), with: framing)
    }
    return true
  }

  /// clearCollection takes off the collection drawn, and a read still out for one draws nothing.
  public func clearCollection() {
    unmount(.collection)
  }

  /// setItineraries switches on or off the itineraries of the credential's scope, their
  /// specification read through the client, `getItinerariesSpecification`
  /// (`map.slots.latest-request`). Switched on while they are drawn, it reads nothing; switched off,
  /// a read still out draws nothing. It throws what the client throws.
  public func setItineraries(_ shown: Bool) async throws {
    let client = client
    try await toggle(.itineraries, on: shown) {
      try await client.tiles.getItinerariesSpecification().data
    }
  }

  /// setZones switches on or off the zones of the credential's scope, their specification read
  /// through the client, `getZonesSpecification`, as `setItineraries(_:)` switches the itineraries.
  public func setZones(_ shown: Bool) async throws {
    let client = client
    try await toggle(.zones, on: shown) {
      try await client.tiles.getZonesSpecification().data
    }
  }

  /// setSpecification draws a specification the app already holds, under a name of its own, in
  /// place of what that name drew before: each of its sources, and each of their layers at the rank
  /// its source layer declares, in the order it lists them (`map.specification.style`). A layer the
  /// app hid by its id is drawn hidden. The name is the app's, apart from every slot the map draws
  /// for itself, and a specification drawn again under it keeps the place its concepts are named in
  /// (`map.layers.keys`).
  ///
  /// It throws a `MapError` of kind `typeRefused` where a source is of a type the contract does not
  /// declare, and nothing of the specification is drawn.
  public func setSpecification(
    _ specification: TileSchema.TileSpecification, named name: String
  ) throws(MapError) {
    guard !isClosed else { return }
    // The latest request for the name, so a read of the app's own that lands late draws nothing.
    _ = slots.take(.specification(name))
    try mount(specification, in: .specification(name))
  }

  /// removeSpecification takes off the specification drawn under `name`, and forgets whether the
  /// app hid any of its layers. A name holding nothing is nothing to take off.
  public func removeSpecification(named name: String) {
    unmount(.specification(name))
  }

  /// clearSpecifications takes off every specification drawn under a name of the app's own,
  /// leaving every slot the map draws for itself.
  public func clearSpecifications() {
    for name in specifications {
      unmount(.specification(name))
    }
  }

  /// specifications is the name of every specification drawn under a name of the app's own, in
  /// the order each was first drawn.
  public var specifications: [String] {
    contents.compactMap { content in
      if case .specification(let name) = content.slot { name } else { nil }
    }
  }

  /// setOverlay draws the classic overlay of slug `slug`, as the layers catalogue lists it, in place
  /// of the one drawn before, and eases the camera into the zooms it paints across
  /// (`map.overlays.composition`). Classic overlays repaint one ground, so a map draws one at a
  /// time; enrichments stack, through `addEnrichment(_:)`.
  ///
  /// It reads the catalogue through `loadLayers()`, and throws what that throws. It throws a
  /// `MapError` of kind `kindMismatch` where the catalogue holds the slug as an enrichment, and of
  /// kind `overlayNotFound` where it holds it under neither kind, the overlay drawn left as it was.
  /// A later call, or `clearOverlay()`, made while the catalogue is read has this one draw nothing.
  ///
  /// An overlay the server stamps, its `capabilities.server.timestamp` true, is drawn for the
  /// instant pinned, `setInstant(_:)`, each address of its sources stamped
  /// (`timestampedSources(_:overlay:at:)`), and from the manifest's own addresses with none pinned
  /// (`map.overlays.instant`).
  public func setOverlay(_ slug: String) async throws {
    guard !isClosed, let found = try await overlay(slug, kind: .classic, in: .overlay) else {
      return
    }
    try draw(found.overlay, in: .overlay, from: found.catalogue)
  }

  /// clearOverlay takes off the classic overlay drawn. The instant pinned stays, and an overlay
  /// drawn later is drawn for it.
  public func clearOverlay() {
    unmount(.overlay)
  }

  /// setInstant pins `instant`, the instant the map draws the classic overlay the server stamps
  /// for, or pins none where it is nil, so it draws the manifest's own addresses, which the Tile API
  /// answers for the moment each tile arrives (`map.overlays.instant`). A `Date` that names no
  /// instant, of no number or past the 8.64e15 milliseconds every SDK holds a time to, pins none.
  ///
  /// The classic overlay drawn is asked again at once, each address of its sources stamped as
  /// `timestampedSources(_:overlay:at:)` stamps it, without being drawn anew: its layers stand
  /// where they stood, and its sources' tiles are swapped in place, the renderer replacing a source
  /// whose addresses MapLibre fixes as it builds one. An overlay drawn later is drawn for the pin,
  /// a base-map switch keeps the addresses asked for, and a pin outlives the overlay it was asked
  /// for. An enrichment, and a classic overlay the server does not stamp, are never stamped, and a
  /// stamped tile refused is told as any of the map's own requests is, at the address it was asked
  /// at (`map.events.access-refused`).
  ///
  /// ```swift
  /// map.setInstant(Date(timeIntervalSinceNow: 6 * 3600))
  /// ```
  public func setInstant(_ instant: Date?) {
    guard !isClosed else { return }
    pinned = nil
    if let instant, namesInstant(instant) {
      pinned = instant.timeIntervalSinceReferenceDate
    }
    guard let drawn = classicDrawn else { return }
    // Each source is put in place of the one of its id, its layers untouched; the overlay was
    // drawn, so each is of a type the map draws.
    for source in askedSources(of: drawn.overlay, in: drawn.catalogue) {
      if let asked = try? MapSource(source) {
        addSource(asked)
      }
    }
  }

  /// addEnrichment draws the enrichment of slug `slug`, as the layers catalogue lists it, on top of
  /// whatever is drawn, and eases the camera into the zooms it paints across
  /// (`map.overlays.composition`). Enrichments stack, each under its own slug in the order first
  /// added, so one added again keeps its place.
  ///
  /// It reads the catalogue through `loadLayers()`, and throws what that throws. It throws a
  /// `MapError` of kind `kindMismatch` where the catalogue holds the slug as a classic overlay, and
  /// of kind `overlayNotFound` where it holds it under neither kind, what is drawn left as it was.
  public func addEnrichment(_ slug: String) async throws {
    guard !isClosed,
      let found = try await overlay(slug, kind: .enrichment, in: .enrichment(slug))
    else { return }
    try draw(found.overlay, in: .enrichment(found.overlay.slug), from: found.catalogue)
  }

  /// removeEnrichment takes off the enrichment of slug `slug`, and one still being found in the
  /// catalogue draws nothing. A slug not drawn is nothing to take off.
  public func removeEnrichment(_ slug: String) {
    unmount(.enrichment(slug))
  }

  /// clearEnrichments takes off every enrichment, those still being found in the catalogue
  /// included.
  public func clearEnrichments() {
    var cleared = slots.requestedSlots()
    for content in contents where !cleared.contains(content.slot) {
      cleared.append(content.slot)
    }
    for slot in cleared {
      if case .enrichment = slot {
        unmount(slot)
      }
    }
  }

  /// enrichments is the slug of every enrichment drawn, in the order each was first added.
  public var enrichments: [String] {
    contents.compactMap { content in
      if case .enrichment(let slug) = content.slot { slug } else { nil }
    }
  }

  // MARK: - Visibility

  /// setLayerVisibility shows or hides the layer of id `id`, the app's word kept by that id
  /// (`map.layers.visibility`): before the layer is drawn, so it is born hidden, across a base-map
  /// switch, and through a redraw of the content holding it, until that content is cleared, which
  /// forgets it. A layer hidden keeps its place and its tiles, so showing it again fetches nothing.
  public func setLayerVisibility(_ id: String, visible: Bool) {
    guard !isClosed else { return }
    writeVisibility(id, visible: visible)
    let layers = registry.layers
    report { $0.layers = layers }
  }

  /// isLayerVisible tells whether the app's word on the layer of id `id` is shown, which it is
  /// until the app hides it: the app's intent, the same before the layer is drawn and through a
  /// base-map switch (`map.layers.visibility`).
  public func isLayerVisible(_ id: String) -> Bool {
    !isHidden(id)
  }

  /// drawnLayerKeys answers the concepts the map draws, named by the layers catalogue's keys
  /// (`map.layers.keys`): each listed once, in the order its content was first asked for and its
  /// layers listed, and narrowed, where `rank` names a band, to those with a layer drawn at that
  /// rank. A layer of no named concept, the empty key on the wire, names none.
  public func drawnLayerKeys(rank: Int? = nil) -> [String] {
    var keys: [String] = []
    for content in contents {
      for id in content.layerIds {
        guard let layer = registry.layer(id), let key = layer.key,
          rank == nil || layer.rank == rank, !keys.contains(where: { sameText($0, key) })
        else { continue }
        keys.append(key)
      }
    }
    return keys
  }

  /// layerIds answers the id of every drawn layer carrying the concept `key`, in the order its
  /// content was first asked for and its layers listed, none for a key nothing draws
  /// (`map.layers.keys`).
  public func layerIds(forKey key: String) -> [String] {
    var ids: [String] = []
    for content in contents {
      for id in content.layerIds {
        guard let layer = registry.layer(id), sameText(layer.key, key),
          !ids.contains(where: { sameText($0, id) })
        else { continue }
        ids.append(id)
      }
    }
    return ids
  }

  /// setKeyVisibility shows or hides every layer drawing the concept `key`, as
  /// `setLayerVisibility(_:visible:)` shows or hides one.
  public func setKeyVisibility(_ key: String, visible: Bool) {
    guard !isClosed else { return }
    for id in layerIds(forKey: key) {
      writeVisibility(id, visible: visible)
    }
    let layers = registry.layers
    report { $0.layers = layers }
  }

  /// isKeyVisible tells whether the concept `key` is shown: while none of its layers is hidden, so
  /// a key that draws nothing reads as shown (`map.layers.keys`).
  public func isKeyVisible(_ key: String) -> Bool {
    layerIds(forKey: key).allSatisfy { !isHidden($0) }
  }

  /// setAccessRestrictionsVisibility shows or hides the restricted stretches of every itinerary
  /// the map draws, from here on and across a base-map switch (`map.road-access.layers`). Their
  /// layers stay drawn while hidden, so showing them again fetches nothing, and a stretch layer the
  /// app hid by its id stays hidden either way.
  public func setAccessRestrictionsVisibility(_ visible: Bool) {
    guard !isClosed, visible != isAccessRestrictionsVisible else { return }
    isAccessRestrictionsVisible = visible
    for content in contents {
      for id in content.restrictionLayerIds {
        guard var layer = registry.layer(id) else { continue }
        layer.layout["visibility"] = visible && !isHidden(id) ? "visible" : "none"
        _ = registry.replace(id, with: layer)
      }
    }
    let layers = registry.layers
    report { $0.layers = layers }
  }

  // MARK: - Point queries

  /// features answers the features the map drew at `point` of the canvas, `[x, y]` in points from
  /// its top left corner, topmost first: those of the layers it placed, in every band, never the
  /// base map's, each as a `QueriedFeature` once for each layer that drew it (`map.query.layers`,
  /// `map.query.feature-shape`). A map no view draws, or a closed one, answers none.
  public func features(at point: [Double]) -> [QueriedFeature] {
    query(.features, at: point)
  }

  /// pois answers the points of interest the map drew at `point`, as `features(at:)` answers them.
  public func pois(at point: [Double]) -> [QueriedFeature] {
    query(.pois, at: point)
  }

  /// zones answers the zones the map drew at `point`, as `features(at:)` answers them.
  public func zones(at point: [Double]) -> [QueriedFeature] {
    query(.zones, at: point)
  }

  /// itineraries answers an itinerary's routed lines and waypoints the map drew at `point`, as
  /// `features(at:)` answers them.
  public func itineraries(at point: [Double]) -> [QueriedFeature] {
    query(.itineraries, at: point)
  }

  /// project answers the point of the canvas `position`, `[longitude, latitude]`, is drawn at,
  /// `[x, y]` in points from its top left corner. A map no view draws, or a closed one, has no
  /// projection, and answers `[NaN, NaN]`.
  public func project(_ position: [Double]) -> [Double] {
    guard !isClosed, let surface else { return [.nan, .nan] }
    return surface.projection.point(position)
  }

  /// unproject answers the position, `[longitude, latitude]`, drawn at `point` of the canvas. A map
  /// no view draws, or a closed one, has no projection, and answers `[NaN, NaN]`.
  public func unproject(_ point: [Double]) -> [Double] {
    guard !isClosed, let surface else { return [.nan, .nan] }
    return surface.projection.position(point)
  }

  /// elevation answers the ground's elevation at `position`, `[longitude, latitude]`, in meters:
  /// the Data API's terrain sample there, asked for its elevation alone, and nil where the answer
  /// holds no sample or the sample states none, 0 being an elevation (`map.query.elevation-at`). It
  /// is never read off the drawn terrain, a shaded image that is no height field, and a closed map
  /// still answers it, since it reads through the client. It throws what the client throws.
  public func elevation(at position: [Double]) async throws -> Double? {
    let answer = try await client.data.terrainSamples(
      input: DataSchema.TerrainSamplesInput(locations: [position]),
      select: ["samples": ["elevation": true]])
    return answer.samples?.first?.elevation
  }

  // MARK: - Markers

  /// addMarker pins `marker` above everything the map draws, on top of every other, in place of the
  /// marker pinned under its id where one is (`map.marker.lifecycle`). Its position is a longitude
  /// and a latitude, and an altitude after them, which a marker drawn flat on the map ignores.
  ///
  /// It throws a `MapError` of kind `positionRefused` where the position's first two numbers are
  /// not finite, its latitude lies outside -90 to 90, or it holds fewer than two numbers or more
  /// than three, and whatever is pinned is left as it was.
  public func addMarker(_ marker: MapMarker) throws(MapError) {
    guard !isClosed else { return }
    var shown = marker
    shown.position = try Self.place(marker.position, for: marker.id)
    report { state in
      state.markers.removeAll { sameText($0.id, shown.id) }
      state.markers.append(shown)
    }
  }

  /// editMarker changes the marker pinned under `id`, which keeps its place among the others: each
  /// member given replaces the one held, and each left nil leaves it as it is
  /// (`map.marker.lifecycle`). A color, a glyph or a label is taken off by adding the marker again
  /// without it.
  ///
  /// It throws a `MapError` of kind `markerNotFound` where no marker is pinned under `id`, and of
  /// kind `positionRefused` where `position` is refused as `addMarker(_:)` refuses one; the map is
  /// then left as it was.
  public func editMarker(
    _ id: String, position: [Double]? = nil, color: String? = nil, glyph: String? = nil,
    label: String? = nil
  ) throws(MapError) {
    guard !isClosed else { return }
    guard let place = held.markers.firstIndex(where: { sameText($0.id, id) }) else {
      throw MapError(kind: .markerNotFound, name: id)
    }
    var marker = held.markers[place]
    if let position { marker.position = try Self.place(position, for: id) }
    if let color { marker.color = color }
    if let glyph { marker.glyph = glyph }
    if let label { marker.label = label }
    report { $0.markers[place] = marker }
  }

  /// removeMarker takes off the marker pinned under `id`. A marker the map does not pin is nothing
  /// to take off.
  public func removeMarker(_ id: String) {
    report { $0.markers.removeAll { sameText($0.id, id) } }
  }

  /// clearMarkers takes off every marker.
  public func clearMarkers() {
    report { $0.markers = [] }
  }

  // MARK: - Geometry slots

  /// setGeometry draws `geometry` in `slot`, the preview, the highlight or the emphasis, in
  /// `color`, the slot's own where it is nil, or takes the slot down where `geometry` is nil
  /// (`map.geometry.slots`). Writing one slot never clears another. Each slot draws from a source of
  /// its own as the itinerary's cased line in the map's paint, the highlight adding a circle for a
  /// point, at its band: the highlight above every content band, the preview and the emphasis just
  /// above the itinerary lines (`map.geometry.layers`).
  public func setGeometry(_ geometry: GeoJSONGeometry?, in slot: GeometrySlot, color: String? = nil)
  {
    write(SlotGeometry(geometry: geometry, color: color ?? slot.color), in: slot)
  }

  /// editGeometry changes what `slot` holds: `geometry` where it is given, and `color` where it is
  /// given, keeping the one it does not name (`map.geometry.slots`).
  public func editGeometry(
    in slot: GeometrySlot, geometry: GeoJSONGeometry? = nil, color: String? = nil
  ) {
    var held = self.geometry(in: slot)
    if let geometry { held.geometry = geometry }
    if let color { held.color = color }
    write(held, in: slot)
  }

  /// clearGeometry takes `slot` down, and gives it back its own colour (`map.geometry.slots`).
  public func clearGeometry(in slot: GeometrySlot) {
    write(SlotGeometry(geometry: nil, color: slot.color), in: slot)
  }

  /// geometry answers what `slot` holds: its geometry, nil where it draws none, and its colour.
  public func geometry(in slot: GeometrySlot) -> SlotGeometry {
    geometrySlots.first { $0.slot == slot }?.held ?? SlotGeometry(geometry: nil, color: slot.color)
  }

  // MARK: - The search highlight

  /// setSearchHighlight draws `highlight`, the result a reader picked from a search, above
  /// everything else on the map in `accent`, in place of the one drawn before, or takes it down at
  /// once where it is nil (`map.search.result-highlight`); `pickTarget(_:)` answers what a pick
  /// marks.
  ///
  /// A place is the point-of-interest pin carrying a point, or the map pin where the map's glyph set
  /// holds no point; a point of interest is its category's own pin in its category's colour, the
  /// pin the tiles draw it with; and a way is its line, haloed and cased, with its two ends, else
  /// its extent washed and outlined dashed, across the antimeridian where it crosses it, else a pin
  /// at its anchor. It draws from a source of its own at the chrome band, apart from the geometry
  /// slots, so lighting a feature leaves the picked result where it is, and is drawn again on every
  /// base map a switch brings in. `accent` is the elements' `accent` token as the host's tokens read
  /// it under the colour scheme in force, which `SearchControl` hands; the standard light one where
  /// a caller hands none. A closed map draws nothing.
  public func setSearchHighlight(
    _ highlight: SearchHighlight?,
    accent: HexColor = themeTokenValue(ElementTokens.standard.accent, in: .light)
  ) {
    guard !isClosed else { return }
    guard let highlight else {
      unmount(.searchHighlight)
      return
    }
    let drawn = searchHighlightLayers(
      highlight, accent: accent,
      hasPointGlyph: glyphs.markup[searchHighlightPlaceGlyph] != nil)
    mountGeoJson(
      drawn.features, source: searchHighlightSourceId, layers: drawn.layers,
      in: .searchHighlight)
  }

  // MARK: - Data API results

  /// addDirections draws routed directions, asking the client for them, `directions`, under an id
  /// of their own, and answers the id and the result (`map.analysis.slots`). Results of one kind
  /// accumulate, each removed alone by `removeAnalysis(_:)`. Where `fit` is given, the camera then
  /// frames what the result draws.
  ///
  /// A `clearDirections()` or a `removeAnalysis(_:)` made while the query is out cancels it, and the
  /// call throws `CancellationError` (`map.analysis.requests`). It throws a `MapError` of kind
  /// `numberRefused` for a fit `fitBounds(_:with:)` refuses, before anything is asked, and what the
  /// client throws.
  @discardableResult
  public func addDirections(_ input: DataSchema.DirectionsInput, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.DirectionsResult>
  {
    try await addAnalysis(
      .directions, input: input, answered: nil, chosen: 0, fit: fit,
      query: Self.directions(client), features: Self.directionsFeatures)
  }

  /// addDirections draws directions the app already holds, asking nothing, as the input form draws
  /// its answer.
  @discardableResult
  public func addDirections(_ result: DataSchema.DirectionsResult, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.DirectionsResult>
  {
    try await addAnalysis(
      .directions, input: DataSchema.DirectionsInput?.none, answered: result, chosen: 0, fit: fit,
      query: Self.directions(client), features: Self.directionsFeatures)
  }

  /// editDirections asks again for the directions drawn under `id`, with `patch` applied to the
  /// input they were asked with, and redraws them, answering the new result (`map.analysis.edit`).
  /// With no patch it redraws the result held under the draw options it states, asking nothing.
  ///
  /// It throws a `MapError` of kind `analysisNotFound` where nothing is drawn under `id`, of kind
  /// `kindMismatch` where a result of another kind is, and of kind `noInput` where a patch is given
  /// for a result drawn from one handed over; the result stays as it is drawn. A later edit, a
  /// removal or a clear made while the query is out cancels it, the call throwing
  /// `CancellationError`.
  @discardableResult
  public func editDirections(
    _ id: String, patch: ((inout DataSchema.DirectionsInput) -> Void)? = nil, fit: CameraFit? = nil
  ) async throws -> DataSchema.DirectionsResult {
    try await editAnalysis(
      .directions, id: id, patch: patch, chosen: nil, fit: fit, query: Self.directions(client),
      features: Self.directionsFeatures)
  }

  /// clearDirections takes off every directions result, and cancels every query of one still out.
  public func clearDirections() {
    clearAnalyses(.directions)
  }

  /// addSuggestions draws suggested itineraries, asking the client for them, `suggestions`: the one
  /// at `chosen` solid, the rest dashed alternatives, as `addDirections(_:fit:)` draws and answers.
  @discardableResult
  public func addSuggestions(
    _ input: DataSchema.SuggestionsInput, chosen: Int = 0, fit: CameraFit? = nil
  ) async throws -> AnalysisHandle<DataSchema.SuggestionsResult> {
    try await addAnalysis(
      .suggestions, input: input, answered: nil, chosen: chosen, fit: fit,
      query: Self.suggestions(client), features: Self.suggestionFeatures)
  }

  /// addSuggestions draws suggested itineraries the app already holds, asking nothing.
  @discardableResult
  public func addSuggestions(
    _ result: DataSchema.SuggestionsResult, chosen: Int = 0, fit: CameraFit? = nil
  ) async throws -> AnalysisHandle<DataSchema.SuggestionsResult> {
    try await addAnalysis(
      .suggestions, input: DataSchema.SuggestionsInput?.none, answered: result, chosen: chosen,
      fit: fit, query: Self.suggestions(client), features: Self.suggestionFeatures)
  }

  /// editSuggestions asks again for the suggestions drawn under `id` with `patch` applied to their
  /// input, as `editDirections(_:patch:fit:)` does; with no patch it redraws the result held, the
  /// candidate at `chosen` solid where it is given, asking nothing, since a seeded query asked again
  /// would answer other itineraries than the one the reader picked.
  @discardableResult
  public func editSuggestions(
    _ id: String, patch: ((inout DataSchema.SuggestionsInput) -> Void)? = nil, chosen: Int? = nil,
    fit: CameraFit? = nil
  ) async throws -> DataSchema.SuggestionsResult {
    try await editAnalysis(
      .suggestions, id: id, patch: patch, chosen: chosen, fit: fit, query: Self.suggestions(client),
      features: Self.suggestionFeatures)
  }

  /// clearSuggestions takes off every suggestion set, and cancels every query of one still out.
  public func clearSuggestions() {
    clearAnalyses(.suggestions)
  }

  /// addIsochrones draws the areas reached within each range of an origin, asking the client for
  /// them, `isochrones`, as `addDirections(_:fit:)` draws and answers.
  @discardableResult
  public func addIsochrones(_ input: DataSchema.IsochronesInput, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.IsochronesResult>
  {
    try await addAnalysis(
      .isochrones, input: input, answered: nil, chosen: 0, fit: fit,
      query: Self.isochrones(client), features: Self.isochroneFeatures)
  }

  /// addIsochrones draws isochrones the app already holds, asking nothing.
  @discardableResult
  public func addIsochrones(_ result: DataSchema.IsochronesResult, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.IsochronesResult>
  {
    try await addAnalysis(
      .isochrones, input: DataSchema.IsochronesInput?.none, answered: result, chosen: 0, fit: fit,
      query: Self.isochrones(client), features: Self.isochroneFeatures)
  }

  /// editIsochrones asks again for the isochrones drawn under `id` with `patch` applied to their
  /// input, as `editDirections(_:patch:fit:)` does.
  @discardableResult
  public func editIsochrones(
    _ id: String, patch: ((inout DataSchema.IsochronesInput) -> Void)? = nil, fit: CameraFit? = nil
  ) async throws -> DataSchema.IsochronesResult {
    try await editAnalysis(
      .isochrones, id: id, patch: patch, chosen: nil, fit: fit, query: Self.isochrones(client),
      features: Self.isochroneFeatures)
  }

  /// clearIsochrones takes off every isochrone set, and cancels every query of one still out.
  public func clearIsochrones() {
    clearAnalyses(.isochrones)
  }

  /// addPlaces draws the places a search answers, asking the client for them, `geocode`, each a
  /// point, a place that names no position drawing none, as `addDirections(_:fit:)` draws and
  /// answers.
  @discardableResult
  public func addPlaces(_ input: DataSchema.GeocodeInput, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.GeocodeResult>
  {
    try await addAnalysis(
      .places, input: input, answered: nil, chosen: 0, fit: fit, query: Self.places(client),
      features: Self.placeFeatures)
  }

  /// addPlaces draws places the app already holds, asking nothing.
  @discardableResult
  public func addPlaces(_ result: DataSchema.GeocodeResult, fit: CameraFit? = nil)
    async throws -> AnalysisHandle<DataSchema.GeocodeResult>
  {
    try await addAnalysis(
      .places, input: DataSchema.GeocodeInput?.none, answered: result, chosen: 0, fit: fit,
      query: Self.places(client), features: Self.placeFeatures)
  }

  /// editPlaces asks again for the places drawn under `id` with `patch` applied to their input, as
  /// `editDirections(_:patch:fit:)` does.
  @discardableResult
  public func editPlaces(
    _ id: String, patch: ((inout DataSchema.GeocodeInput) -> Void)? = nil, fit: CameraFit? = nil
  ) async throws -> DataSchema.GeocodeResult {
    try await editAnalysis(
      .places, id: id, patch: patch, chosen: nil, fit: fit, query: Self.places(client),
      features: Self.placeFeatures)
  }

  /// clearPlaces takes off every place search result, and cancels every query of one still out.
  public func clearPlaces() {
    clearAnalyses(.places)
  }

  /// addMatrix draws the costs between the locations of `input` as connectors between them, a
  /// straight line per solved pair weighted by its cost, asking the client for them, `matrix`, or
  /// drawing `answered`, a result the app already holds for that input, asking nothing, as
  /// `addDirections(_:fit:)` draws and answers. A matrix always holds its input, since its
  /// connectors run between the input's locations and a result holds none.
  @discardableResult
  public func addMatrix(
    _ input: DataSchema.MatrixInput, answered: DataSchema.MatrixResult? = nil, fit: CameraFit? = nil
  ) async throws -> AnalysisHandle<DataSchema.MatrixResult> {
    try await addAnalysis(
      .matrix, input: input, answered: answered, chosen: 0, fit: fit, query: Self.matrix(client),
      features: Self.matrixFeatures)
  }

  /// editMatrix asks again for the matrix drawn under `id` with `patch` applied to its input, as
  /// `editDirections(_:patch:fit:)` does.
  @discardableResult
  public func editMatrix(
    _ id: String, patch: ((inout DataSchema.MatrixInput) -> Void)? = nil, fit: CameraFit? = nil
  ) async throws -> DataSchema.MatrixResult {
    try await editAnalysis(
      .matrix, id: id, patch: patch, chosen: nil, fit: fit, query: Self.matrix(client),
      features: Self.matrixFeatures)
  }

  /// clearMatrix takes off every matrix, and cancels every query of one still out.
  public func clearMatrix() {
    clearAnalyses(.matrix)
  }

  /// setPointsOfInterest draws the points of interest a query answers, asking the client for them,
  /// `pois`, in place of the ones drawn before: the map draws one such result at a time, under the
  /// id `poisAnalysisId`. It answers the result, as `addDirections(_:fit:)` draws it.
  @discardableResult
  public func setPointsOfInterest(_ input: DataSchema.PoisInput, fit: CameraFit? = nil)
    async throws -> DataSchema.PoisResult
  {
    try await addAnalysis(
      .pois, id: Self.poisAnalysisId, input: input, answered: nil, chosen: 0, fit: fit,
      query: Self.pois(client), features: Self.poiFeatures
    ).result
  }

  /// setPointsOfInterest draws points of interest the app already holds, asking nothing.
  @discardableResult
  public func setPointsOfInterest(_ result: DataSchema.PoisResult, fit: CameraFit? = nil)
    async throws -> DataSchema.PoisResult
  {
    try await addAnalysis(
      .pois, id: Self.poisAnalysisId, input: DataSchema.PoisInput?.none, answered: result,
      chosen: 0, fit: fit, query: Self.pois(client), features: Self.poiFeatures
    ).result
  }

  /// editPointsOfInterest asks again for the points of interest drawn with `patch` applied to their
  /// input, as `editDirections(_:patch:fit:)` does.
  @discardableResult
  public func editPointsOfInterest(
    patch: ((inout DataSchema.PoisInput) -> Void)? = nil, fit: CameraFit? = nil
  ) async throws -> DataSchema.PoisResult {
    try await editAnalysis(
      .pois, id: Self.poisAnalysisId, patch: patch, chosen: nil, fit: fit, query: Self.pois(client),
      features: Self.poiFeatures)
  }

  /// clearPointsOfInterest takes off the points of interest drawn, and cancels their query while it
  /// is out.
  public func clearPointsOfInterest() {
    removeAnalysis(Self.poisAnalysisId)
  }

  /// removeAnalysis takes off the Data API result drawn under `id`, whatever its kind, and cancels
  /// its query while it is out, the call waiting on it throwing `CancellationError`
  /// (`map.analysis.requests`). An id nothing is drawn under is nothing to take off.
  public func removeAnalysis(_ id: String) {
    guard !isClosed else { return }
    abortQuery(of: id)
    analyses.removeAll { sameText($0.id, id) }
    unmount(.analysis(id))
  }

  /// poisAnalysisId is the id the points of interest a query answers are drawn under.
  public static let poisAnalysisId = "analysis:pois"

  // MARK: - Editing

  /// setActiveSegments sets the lines an edit's magnet places a waypoint on, each a list of
  /// positions, such as the segments of the itinerary being edited; none turns the magnet off. A
  /// waypoint placed before is left where it was.
  public func setActiveSegments(_ lines: [[[Double]]]) {
    report { $0.activeSegments = lines }
  }

  /// beginWaypointEdit begins placing the waypoint `waypointId`, already at `position` or not yet.
  /// An edit of that waypoint already begun goes on as it is; an edit of another is ended, and
  /// this one begins in its place. While it lasts, a tap on the map places the waypoint and a long
  /// press is taken too, each told to nobody.
  ///
  /// It throws a `MapError` of kind `positionRefused` where `position` names no place a map draws,
  /// and the map is left as it was.
  public func beginWaypointEdit(_ waypointId: String, at position: [Double]? = nil)
    throws(MapError)
  {
    guard !isClosed else { return }
    if let editing = held.waypointEdit, sameText(editing.waypointId, waypointId) { return }
    let placed = try position.map { position throws(MapError) in
      try Self.place(position, for: waypointId)
    }
    report { $0.waypointEdit = WaypointEdit(waypointId: waypointId, position: placed) }
  }

  /// placeWaypoint places the waypoint being edited where a tap fell, `position`, its longitude
  /// read within [-180, 180], as `projection` draws the map: on the nearest point of an active
  /// segment where that point is drawn within 40 pixels of the tap, and at the tap otherwise
  /// (`map.edit.snap`). The renderer's projection is read at that moment, so the magnet reads
  /// alike at every zoom. Where no waypoint is being edited, it does nothing.
  ///
  /// It throws a `MapError` of kind `positionRefused` where `position` names no place a map draws,
  /// and the waypoint is left where it was.
  public func placeWaypoint(at position: [Double], through projection: ScreenProjection)
    throws(MapError)
  {
    guard !isClosed, let editing = held.waypointEdit else { return }
    var tapped = try Self.place(position, for: editing.waypointId)
    tapped[0] = wrapLongitude(tapped[0])
    let snap = snapToActiveSegments(
      tapped, segments: held.activeSegments, projection: projection)
    report { state in
      state.waypointEdit = WaypointEdit(
        waypointId: editing.waypointId, position: snap.position, isSnapped: snap.isSnapped)
    }
  }

  /// endWaypointEdit ends the edit of the waypoint being placed, and answers it as it stands, where
  /// it was placed and whether the magnet placed it, or nil where none was being edited.
  @discardableResult
  public func endWaypointEdit() -> WaypointEdit? {
    guard !isClosed, let edit = held.waypointEdit else { return nil }
    report { $0.waypointEdit = nil }
    return edit
  }

  /// close makes the map inert (`map.engine.closed`): every later command does nothing, a drawing
  /// call draws nothing, a point query answers no feature, a projection no number, `locate()` is
  /// refused, its readout closes, and every stream ends, so nothing is told; `state` and `credits`
  /// read as the map ended, and `elevation(at:)`, which reads through the client, still answers.
  /// A load of its organization still waiting is refused, and a later one answers the organization
  /// it held (`map.organization.read`). Closing a closed map does nothing.
  public func close() {
    guard !isClosed else { return }
    isClosed = true
    hovering = nil
    dropReadout()
    organizationDeadline?.cancel()
    organizationDeadline = nil
    let waiters = organizationWaiters
    organizationWaiters = []
    for waiter in waiters {
      waiter.resume(throwing: MapError(kind: .closed, name: "loadOrganization"))
    }
    for continuation in subscribers.values {
      continuation.finish()
    }
    subscribers.removeAll()
    for continuation in listeners.values {
      continuation.finish()
    }
    listeners.removeAll()
  }

  // MARK: - The organization

  /// loadOrganization answers the organization the map's client's publishable key was minted for,
  /// read through `postOrganizationLookup`, the core's operation, the key in the body and no
  /// credential sent, and held as `organization` (`map.organization.read`). The read is made once
  /// per key and Map Studio API origin, and shared by every map whose client holds that key and
  /// sends to that origin, `baseUrls.rest`, for as long as the process lives: a read in flight is
  /// waited on rather than sent again, and an answer is kept. `MapView` asks for it when it first
  /// draws the map, and its watermark follows its answer and nothing else the map draws does. A
  /// read asked again after one failed leaves the watermark drawn while it waits.
  ///
  /// It answers nil for a client holding no publishable key, a share token, a secret key or a seam
  /// of its own, which reads nothing, and never throws for one, a closed map's included, as every
  /// SDK's map answers. A read that fails, one that reaches the transport's own time budget among
  /// them, is kept by nobody: every load waiting on it throws what it failed with, and the next
  /// load reads again. A closed map reads nothing more: it answers the organization it held, and
  /// throws a `MapError` of kind `closed` where its client holds a key and it held none, a load
  /// still waiting as it closes among them.
  @discardableResult
  public func loadOrganization() async throws -> RestSchema.Organization? {
    if let organization { return organization }
    guard client.publishableKey != nil else { return nil }
    guard !isClosed else { throw MapError(kind: .closed, name: "loadOrganization") }
    return try await awaitOrganization()
  }

  /// beginOrganizationRead starts the read of the map's organization, as a map first drawn does,
  /// where none is held or out; its answer lands as `loadOrganization()`'s does.
  func beginOrganizationRead() {
    guard organization == nil, !isClosed, !isReadingOrganization,
      let key = client.publishableKey
    else { return }
    readOrganization(key)
  }

  /// awaitOrganization waits on the map's read of its organization, sending it where none is out.
  private func awaitOrganization() async throws -> RestSchema.Organization? {
    guard let key = client.publishableKey else { return nil }
    return try await withCheckedThrowingContinuation { continuation in
      organizationWaiters.append(continuation)
      readOrganization(key)
    }
  }

  /// readOrganization reads the organization of `key` through the reads every map shares, where
  /// the map waits on none, in a task of its own, so a load given up on gives up no read. Where the
  /// map's read stands is left as it is: waiting before the first answer, and failed after a
  /// failure, which keeps the watermark drawn until a read answers white label.
  private func readOrganization(_ key: String) {
    guard !isReadingOrganization else { return }
    isReadingOrganization = true
    let reads = organizations
    let client = client
    if organizationRead == .waiting, organizationDeadline == nil,
      let budget = client.organizationLookupBudget
    {
      // The first read hides the mark for one attempt's budget at most, on the client's clock.
      organizationDeadline = Task { [weak self] in
        do {
          try await client.wait(for: budget)
        } catch {
          return
        }
        self?.organizationOverdue()
      }
    }
    Task { [weak self] in
      let answer: Result<RestSchema.Organization, any Error>
      do {
        answer = .success(try await reads.read(key, through: client))
      } catch {
        answer = .failure(error)
      }
      self?.organizationAnswered(answer)
    }
  }

  /// organizationOverdue draws the watermark of a map whose first read of its organization has
  /// gone one attempt's time budget with no answer (`geo.organization.watermark`): the read's
  /// further attempts go on, and only an answer saying white label takes the mark off again.
  private func organizationOverdue() {
    organizationDeadline = nil
    guard !isClosed, organizationRead == .waiting else { return }
    organizationRead = .timedOut
  }

  /// organizationAnswered lands the answer of the map's read of its organization: every load
  /// waiting on it is handed it, and the watermark follows it. A closed map lands nothing, its loads
  /// already refused.
  private func organizationAnswered(_ answer: Result<RestSchema.Organization, any Error>) {
    isReadingOrganization = false
    organizationDeadline?.cancel()
    organizationDeadline = nil
    guard !isClosed else { return }
    let waiters = organizationWaiters
    organizationWaiters = []
    switch answer {
    case .success(let read):
      organization = read
      organizationRead = .answered(whiteLabel: read.white_label)
      for waiter in waiters {
        waiter.resume(returning: read)
      }
    case .failure(let error):
      organizationRead = .failed
      for waiter in waiters {
        waiter.resume(throwing: error)
      }
    }
  }

  // MARK: - The readout

  /// openReadout opens the readout at `point` of the canvas, where the renderer read `position`,
  /// in place of one already open, with what the map holds there, unless the readout is off
  /// (`map.readout.open`). At the detail zoom it reads the elevation tiles the point needs, and the
  /// terrain read off them joins it once every one has answered.
  func openReadout(at point: [Double], position: [Double]) {
    guard !isClosed, isReadoutOn else { return }
    dropReadout()
    readoutsOpened += 1
    let number = readoutsOpened
    let zoom = held.camera.zoom
    readout = MapReadout(
      number: number, point: point, facts: readoutFacts(at: point, position: position, zoom: zoom),
      overlayNames: classicDrawn?.overlay.locales)
    guard zoom >= readoutDetailZoom else { return }
    readoutReads = Task { [weak self] in await self?.readTerrain(for: number, at: position) }
  }

  /// closeReadout closes the readout open on the map, as a tap does and a camera move does as it
  /// starts, and cancels the reads of its terrain still out.
  func closeReadout() {
    dropReadout()
  }

  /// readerMoveBegan closes the readout as a move of the camera the reader makes begins, a pan, a
  /// pinch, a turn or a tilt, rather than once it comes to rest (`map.readout.open`); a move the
  /// app or a control asks for closes it as it is asked.
  func readerMoveBegan() {
    guard !isClosed else { return }
    dropReadout()
  }

  /// dropReadout takes the readout open off the map and cancels the reads of its terrain.
  private func dropReadout() {
    readout = nil
    readoutReads?.cancel()
    readoutReads = nil
  }

  /// readTerrain reads the terrain at `position` off the elevation tiles for the readout numbered
  /// `number`, through the client's tile transport: the catalogue's elevation source, then every
  /// tile it needs at once, asked for in the order `elevationTilesAt` answers them, by `x` then `y`.
  /// An answer for a readout since closed or replaced lands nowhere, and a tile that fails, or a
  /// source that cannot be read, leaves the readout without terrain.
  private func readTerrain(for number: Int, at position: [Double]) async {
    guard let catalogue = try? await loadLayers(), readout?.number == number,
      let source = try? await elevation.source(of: catalogue.elevation, through: client),
      readout?.number == number
    else { return }
    let addresses = elevationTilesAt(position, source: source.source)
    // Every tile is asked for at once, each read a child task, so closing the readout cancels them
    // all; each is sent once the one before it has left, so they leave in the order the rule
    // answers them, and each image is decoded off the main actor.
    let elevation = elevation
    let client = client
    let tiles = await withTaskGroup(of: (Int, ElevationTile?).self) { group in
      for (index, address) in addresses.enumerated() {
        let (left, leaving) = AsyncStream<Void>.makeStream()
        group.addTask {
          (
            index,
            await Self.readTile(
              address, of: source, by: elevation, through: client, leaving: leaving)
          )
        }
        for await _ in left {}
      }
      var read: [(Int, ElevationTile)] = []
      for await (index, tile) in group {
        if let tile { read.append((index, tile)) }
      }
      return read.sorted { $0.0 < $1.0 }.map(\.1)
    }
    guard !Task.isCancelled, !isClosed, readout?.number == number else { return }
    readout?.facts.terrain = terrainFromElevationTiles(
      position, source: source.source, tiles: tiles)
  }

  /// readTile reads the elevation tile at `address` of `source` through `elevation` and `client`,
  /// or nil where it fails, and finishes `leaving` once its read has left, or once it ends without
  /// leaving, so the next read is sent after it.
  private static func readTile(
    _ address: ElevationTile, of source: ElevationReads.Source, by elevation: ElevationReads,
    through client: Mountaya, leaving: AsyncStream<Void>.Continuation
  ) async -> ElevationTile? {
    defer { leaving.finish() }
    let tile = try? await elevation.tile(
      address, of: source, through: client, departed: { leaving.finish() })
    return tile ?? nil
  }

  /// readoutFacts is what the map holds at `point` of the canvas, where the renderer read
  /// `position`, at `zoom` (`geo.readout.rows`): the topmost point of interest and zone it draws
  /// there, read through the bands `map.query.layers` asks, and the classic overlay it draws with
  /// the first of its own layers' features there stating a `minValue` or a `maxValue`, never a
  /// feature of another layer. A point of interest's name is its tile's `name` and its category
  /// the OpenMapTiles `subclass`, else its `class`. A zone's are its `name`, `description`,
  /// `level`, `start_at` and `end_at`, the two times JSON numbers of seconds since the epoch
  /// truncated to the whole second, and a time written as a string read as none. The moment the map
  /// shows is the view's to read, on the clock it holds.
  private func readoutFacts(at point: [Double], position: [Double], zoom: Double) -> ReadoutFacts {
    var facts = ReadoutFacts(position: position, zoom: zoom)
    func text(_ value: JSONValue?) -> String {
      if case .string(let text)? = value { return text }
      return ""
    }
    func number(_ value: JSONValue?) -> Double? {
      if case .number(let number)? = value { return number }
      return nil
    }
    // A zone's times are JSON numbers of seconds, truncated to the whole second; a time written
    // as a string, digits or not, is none.
    func seconds(_ value: JSONValue?) -> Double? {
      number(value).flatMap { $0.isFinite ? $0.rounded(.towardZero) : nil }
    }
    if let poi = pois(at: point).first {
      let subclass = text(poi.properties["subclass"])
      facts.poi = ReadoutFacts.POI(
        name: text(poi.properties["name"]),
        category: subclass.unicodeScalars.isEmpty ? text(poi.properties["class"]) : subclass)
    }
    if let zone = zones(at: point).first {
      facts.zone = ReadoutFacts.Zone(
        name: text(zone.properties["name"]), description: text(zone.properties["description"]),
        level: RestSchema.ZoneLevel(rawValue: text(zone.properties["level"])),
        startAt: seconds(zone.properties["start_at"]),
        endAt: seconds(zone.properties["end_at"]))
    }
    // The overlay is named in the label language here; a view names it in its words' language.
    if let drawn = classicDrawn?.overlay {
      facts.overlay = ReadoutFacts.Overlay(
        slug: drawn.slug,
        name: localizedName(
          locales: drawn.locales, slug: drawn.slug, language: held.labelLanguage.rawValue),
        vector: drawn.content_type == .protobuf)
      let layers = Set(drawn.sources.flatMap { $0.layers.map(\.id) })
      let band = features(at: point).first { feature in
        layers.contains(feature.layer)
          && (number(feature.properties["minValue"]) != nil
            || number(feature.properties["maxValue"]) != nil)
      }
      if let band {
        facts.band = (number(band.properties["minValue"]), number(band.properties["maxValue"]))
      }
    }
    return facts
  }

  // MARK: - What a surface tells

  /// attach makes `surface` the one the map is drawn on, which the engine asks what only a
  /// renderer knows and hands its camera moves to.
  func attach(_ surface: any MapSurface) {
    self.surface = surface
  }

  /// cameraMoved records where the renderer's camera came to rest after the reader moved it, so
  /// the state is the map as it is shown.
  func cameraMoved(to camera: CameraPose) {
    report { $0.camera = camera }
  }

  /// tapped reads a tap at `point` of the canvas, where the renderer read `position`: it closes the
  /// readout (`map.readout.open`); while a waypoint is being placed it places it, through the
  /// surface's projection, and is told to nobody; otherwise it is told as a `tap`, and again as a
  /// `featureTap` where it landed on features the map drew (`map.events.pointer`).
  func tapped(at point: [Double], position: [Double]) {
    guard !isClosed else { return }
    dropReadout()
    if held.waypointEdit != nil {
      // A tap that names no place leaves the waypoint where it was.
      if let projection = surface?.projection {
        try? placeWaypoint(at: position, through: projection)
      }
      return
    }
    guard let place = Self.within(position) else { return }
    tell(.tap(MapTap(position: place, point: point, marker: marker(near: point))))
    let found = query(.features, at: point)
    if !found.isEmpty {
      tell(.featureTap(position: place, features: found))
    }
  }

  /// longTapped reads a long press, or a secondary click, at `point` of the canvas, where the
  /// renderer read `position`: it is told as a `longTap` and opens the readout there, and is told
  /// to nobody and opens nothing while a waypoint is being placed, whose edit takes it
  /// (`map.events.pointer`, `map.readout.open`).
  func longTapped(at point: [Double], position: [Double]) {
    guard !isClosed, held.waypointEdit == nil, let place = Self.within(position) else { return }
    tell(.longTap(MapTap(position: place, point: point, marker: marker(near: point))))
    openReadout(at: point, position: place)
  }

  /// pointerMoved records where a hovering pointer moved, `point` of the canvas, where the renderer
  /// read `position`; the next frame tells it (`map.events.feature-hover`).
  func pointerMoved(to point: [Double], position: [Double]) {
    guard !isClosed else { return }
    hovering = (point, position)
  }

  /// frameDrawn tells where a hovering pointer ended the frame, with the features of an itinerary's
  /// line and points under it, topmost first, once a frame at most. Nothing is asked of the
  /// renderer while nobody listens.
  func frameDrawn() {
    guard !isClosed, let pending = hovering else { return }
    hovering = nil
    guard !listeners.isEmpty, let place = Self.within(pending.position) else { return }
    tell(.featureHover(position: place, features: query(.itineraries, at: pending.point)))
  }

  /// pointerLeft tells that a hovering pointer left the canvas at `point`, where the renderer read
  /// `position`, with no feature, dropping a hover still waiting on its frame.
  func pointerLeft(at point: [Double], position: [Double]) {
    guard !isClosed else { return }
    hovering = nil
    guard let place = Self.within(position) else { return }
    tell(.featureHover(position: place, features: []))
  }

  /// requestFailed tells a failure of one of the map's own requests, to `url` where the renderer
  /// reported one, carrying `status` where an answer carried one, from the source `source` where
  /// it was a tile's: a refusal of access, which stands until that source loads a tile or, naming
  /// no source, until the next style loads; or any other failure (`map.events.access-refused`). A
  /// 401 or a 403 of a request that left under a credential the client no longer sends,
  /// `superseded`, is told to nobody and stands for nothing
  /// (`refusesSupersededCredential(_:superseded:)`, `map.events.access-standing`). `cause` is what
  /// a read of the client's credential threw, for a request that never left for want of one: it is
  /// told as a failure carrying it whatever status the request would have met, and stands for
  /// nothing.
  func requestFailed(
    url: String?, status: Int?, source: String?, superseded: Bool = false,
    cause: (any Error)? = nil
  ) {
    guard !isClosed else { return }
    if let cause {
      tell(.failure(url: url ?? "", status: nil, cause: cause))
      return
    }
    guard !refusesSupersededCredential(status, superseded: superseded) else { return }
    guard let refused = accessRefusalStatus(status) else {
      tell(.failure(url: url ?? "", status: status))
      return
    }
    standing =
      accessStandingAfter(
        standing, answer: .refused(source: source), holdsSource: holdsSource
      ).standing
    report { $0.isAccessRequired = true }
    tell(.accessRefused(status: refused, url: url ?? ""))
  }

  /// tileLoaded ends the refusal of access of `source`, and of every source the style no longer
  /// holds (`map.events.access-standing`).
  func tileLoaded(source: String) {
    guard !isClosed else { return }
    answerAccess(.tile(source: source))
  }

  /// styleLoaded relabels the base map a style brought in, `style` of the terrain `terrain`, the
  /// one the surface was asked to draw, and ends every refusal of access naming no source, and
  /// those of the sources the style no longer holds. That base map is the one shown from then on,
  /// whatever the map has been asked for since: a style that loads once a later one is asked for
  /// is credited as itself, the one a later base map that does not arrive gives back.
  ///
  /// A base map given back where the one asked for did not arrive answers nothing as it loads
  /// again: it ends no refusal, the refusal of the style that did not arrive among them, which
  /// stands until a style the map asks for loads (`map.events.access-standing`).
  func styleLoaded(_ style: URL?, terrain: String?) {
    guard !isClosed else { return }
    let isGivenBack = givenBack.map { $0.style == style && sameText($0.terrain, terrain) } ?? false
    givenBack = nil
    shownStyle = style
    shownTerrain = terrain
    relabelled = []
    relabelBaseMap()
    if !isGivenBack {
      answerAccess(.style)
    }
  }

  /// styleFailed gives the map back the base map shown, where the document of `style`, the base
  /// map asked for last, did not arrive, its content drawn on it as it was (`map.basemap.replay`),
  /// which answers nothing as it loads again. The failure of a style a later base map replaced
  /// moves nothing: the later one is drawn next.
  func styleFailed(_ style: URL?) {
    guard !isClosed, style == held.style,
      held.style != shownStyle || !sameText(held.terrain, shownTerrain)
    else {
      return
    }
    let style = shownStyle
    let terrain = shownTerrain
    let variant = drawnVariant(style: style, terrain: terrain)
    givenBack = (style, terrain)
    report { state in
      state.style = style
      state.terrain = terrain
      state.terrainVariant = variant
    }
  }

  // MARK: - Applying the rules

  /// TerrainAsk is a terrain a `setTerrain(_:)` asked for: the base-map request it made, and the
  /// slug, nil for the catalogue's first.
  private struct TerrainAsk {
    let request: Int
    let slug: String?
  }

  /// SlotLoad is what a slot's read answered: the specification it draws, and the box a fit frames
  /// once it drew, where one was read.
  private struct SlotLoad {
    let specification: TileSchema.TileSpecification
    var bounds: [Double]?
  }

  /// load reads what `slot` draws through `read`, as its latest request, and draws it where the
  /// request still owns the slot as the read answers, or regains it once the call that superseded
  /// it settles, answering what it read, or nil where it drew nothing (`map.slots.latest-request`).
  /// A call whose task is cancelled before it drew gives the slot back and throws
  /// `CancellationError`.
  private func load(_ slot: ContentSlot, read: () async throws -> SlotLoad) async throws
    -> SlotLoad?
  {
    // A call withdrawn before it starts reads nothing.
    try Task.checkCancellation()
    let token = slots.claim(slot)
    let loaded: SlotLoad
    do {
      loaded = try await read()
      // An answer that lands all the same, after the call was withdrawn, is withdrawn with it.
      try Task.checkCancellation()
    } catch {
      if Task.isCancelled {
        slots.giveBack(slot, token: token)
      } else {
        slots.settle(token)
      }
      throw error
    }
    if !slots.owns(slot, token: token) {
      guard await slots.regains(slot, token: token) else {
        if Task.isCancelled {
          slots.giveBack(slot, token: token)
          throw CancellationError()
        }
        slots.settle(token)
        return nil
      }
    }
    defer { slots.settle(token) }
    guard !isClosed else { return nil }
    try mount(loaded.specification, in: slot)
    return loaded
  }

  /// toggle draws or clears `slot`, whose content needs no id: switched on while it is drawn it
  /// reads nothing, and a read switched off, or superseded, while it was out draws nothing.
  private func toggle(
    _ slot: ContentSlot, on: Bool, read: () async throws -> TileSchema.TileSpecification
  ) async throws {
    guard !isClosed else { return }
    guard on else {
      unmount(slot)
      return
    }
    guard !contents.contains(where: { $0.slot == slot }) else { return }
    let token = slots.take(slot)
    let specification = try await read()
    guard slots.owns(slot, token: token), !isClosed else { return }
    try mount(specification, in: slot)
  }

  /// overlay finds the overlay of slug `slug` and of `kind` in the layers catalogue, read where the
  /// map holds none, holding `slot` meanwhile as a request a later one supersedes, and answers it
  /// with the catalogue it was found in: nil where a later request for the slot, or a clear, was
  /// made while the catalogue was read. A refusal gives the slot back first, so it depends on the
  /// slug alone.
  private func overlay(_ slug: String, kind: OverlayKind, in slot: ContentSlot) async throws
    -> (catalogue: TileSchema.Layers, overlay: TileSchema.Overlay)?
  {
    if let catalogue = layersManifest {
      return (catalogue, try requireOverlay(slug, kind: kind, in: catalogue))
    }
    let token = slots.claim(slot)
    do {
      let catalogue = try await loadLayers()
      let found = try requireOverlay(slug, kind: kind, in: catalogue)
      defer { slots.settle(token) }
      return slots.owns(slot, token: token) && !isClosed ? (catalogue, found) : nil
    } catch {
      slots.giveBack(slot, token: token)
      throw error
    }
  }

  /// requireOverlay is the overlay of slug `slug` and of `kind` in `catalogue`, refusing a slug the
  /// catalogue holds only as the other kind as `kindMismatch`, and one it does not hold as
  /// `overlayNotFound`.
  private func requireOverlay(
    _ slug: String, kind: OverlayKind, in catalogue: TileSchema.Layers
  ) throws(MapError) -> TileSchema.Overlay {
    if let found = findOverlay(catalogue, slug: slug, kind: kind) {
      return found
    }
    let other: OverlayKind = kind == .classic ? .enrichment : .classic
    if findOverlay(catalogue, slug: slug, kind: other) != nil {
      throw MapError(kind: .kindMismatch, name: slug)
    }
    throw MapError(kind: .overlayNotFound, name: slug)
  }

  /// draw draws `overlay`, found in `catalogue`, as what `slot` holds, taking the slot for good, and
  /// eases the camera into the zooms it paints across, so switching it on from too far out reads as
  /// no dead control. The classic overlay is drawn for the instant pinned, which it is kept to be
  /// stamped for again.
  private func draw(
    _ overlay: TileSchema.Overlay, in slot: ContentSlot, from catalogue: TileSchema.Layers
  ) throws(MapError) {
    _ = slots.take(slot)
    let isClassic = slot == .overlay
    try mount(
      TileSchema.TileSpecification(
        sources: isClassic ? askedSources(of: overlay, in: catalogue) : overlay.sources),
      in: slot)
    if isClassic {
      classicDrawn = (catalogue, overlay)
    }
    if let window = paintZoomRange(overlay.sources) {
      easeIntoZoomRange(window)
    }
  }

  /// askedSources is the sources of the classic overlay `overlay`, found in `catalogue`, as the map
  /// asks for them: each address stamped for the instant pinned where the server stamps the overlay
  /// (`timestampedSources(_:overlay:at:)`), and the manifest's own otherwise.
  private func askedSources(of overlay: TileSchema.Overlay, in catalogue: TileSchema.Layers)
    -> [TileSchema.TileSource]
  {
    guard let pinned else { return overlay.sources }
    let stamped = timestampedSources(
      catalogue, overlay: overlay.slug, at: Date(timeIntervalSinceReferenceDate: pinned))
    guard stamped.count == overlay.sources.count else { return overlay.sources }
    var sources = overlay.sources
    for index in sources.indices {
      sources[index].tiles = stamped[index].tiles
    }
    return sources
  }

  /// mount draws `specification` as what `slot` holds, in place of what it held, which keeps its
  /// place among the map's contents and the app's word on its layers: every source, then every
  /// layer at the rank its source layer declares, a layer the app hid born hidden, then the
  /// restricted stretches of each source that draws an itinerary line. Every source is read before
  /// anything is drawn, so a specification refused for one of them draws none of the others.
  private func mount(
    _ specification: TileSchema.TileSpecification, in slot: ContentSlot
  ) throws(MapError) {
    var sources: [MapSource] = []
    for source in specification.sources {
      sources.append(try MapSource(source))
    }
    let before = contents.firstIndex { $0.slot == slot }.map { contents[$0] }
    if let before {
      for id in before.layerIds + before.restrictionLayerIds {
        registry.remove(id)
      }
    }
    var layerIds: [String] = []
    for source in specification.sources {
      for layer in source.layers {
        var drawn = MapLayer(layer, source: source.id, ranks: layerRanks)
        if isHidden(drawn.id) {
          drawn.layout["visibility"] = "none"
        }
        registry.add(drawn)
        layerIds.append(drawn.id)
      }
    }
    var restrictionLayerIds: [String] = []
    for source in specification.sources {
      for var drawn in roadAccessLayersOf(source, isShown: isAccessRestrictionsVisible) {
        if isHidden(drawn.id) {
          drawn.layout["visibility"] = "none"
        }
        registry.add(drawn)
        restrictionLayerIds.append(drawn.id)
      }
    }
    let content = MapContent(
      slot: slot, sourceIds: sources.map(\.id), layerIds: layerIds,
      restrictionLayerIds: restrictionLayerIds)
    if let index = contents.firstIndex(where: { $0.slot == slot }) {
      contents[index] = content
    } else {
      contents.append(content)
    }
    let gone = (before?.sourceIds ?? []).filter { id in !sources.contains { sameText($0.id, id) } }
    let layers = registry.layers
    report { state in
      state.sources.removeAll { source in gone.contains { sameText($0, source.id) } }
      for source in sources {
        if let place = state.sources.firstIndex(where: { sameText($0.id, source.id) }) {
          state.sources[place] = source
        } else {
          state.sources.append(source)
        }
      }
      state.layers = layers
    }
  }

  /// unmount takes off what `slot` holds, and forgets the app's word on its layers, as the slot is
  /// cleared for good: a read still out for it draws nothing once it lands. A source another slot
  /// still draws stays.
  private func unmount(_ slot: ContentSlot) {
    guard !isClosed else { return }
    slots.release(slot)
    if slot == .overlay {
      classicDrawn = nil
    }
    guard let index = contents.firstIndex(where: { $0.slot == slot }) else { return }
    let content = contents.remove(at: index)
    let ids = content.layerIds + content.restrictionLayerIds
    for id in ids {
      registry.remove(id)
    }
    hiddenLayerIds.removeAll { hidden in ids.contains { sameText($0, hidden) } }
    let kept = contents.flatMap(\.sourceIds)
    let gone = content.sourceIds.filter { id in !kept.contains { sameText($0, id) } }
    let layers = registry.layers
    report { state in
      state.sources.removeAll { source in gone.contains { sameText($0, source.id) } }
      state.layers = layers
    }
  }

  /// writeVisibility records the app's word on the layer of id `id` and writes it onto the layer
  /// where it is drawn, a restricted stretch drawn only while the stretches are shown too.
  private func writeVisibility(_ id: String, visible: Bool) {
    hiddenLayerIds.removeAll { sameText($0, id) }
    if !visible {
      hiddenLayerIds.append(id)
    }
    guard var layer = registry.layer(id) else { return }
    let isStretch = contents.contains { content in
      content.restrictionLayerIds.contains { sameText($0, id) }
    }
    let shown = visible && (!isStretch || isAccessRestrictionsVisible)
    layer.layout["visibility"] = shown ? "visible" : "none"
    _ = registry.replace(id, with: layer)
  }

  /// isHidden tells whether the app hid the layer of id `id`.
  private func isHidden(_ id: String) -> Bool {
    hiddenLayerIds.contains { sameText($0, id) }
  }

  /// layerRanks is the band each tile source layer draws at, the map's paint's, which a tile
  /// specification's layers are ranked by.
  private var layerRanks: [String: Int] {
    paint.layerRanks
  }

  /// readLayers reads the layers catalogue for the studio scope named, in the task of the load
  /// asking, and answers it to that load and every load waiting on the read; a read that lands
  /// after the scope moved is another scope's, and every load waiting on it is answered the
  /// current scope's catalogue instead.
  private func readLayers() async throws -> TileSchema.Layers {
    while true {
      let read = manifestReads
      manifestReads += 1
      manifestRead = read
      let scope = layersOrganization
      let answer: Result<TileSchema.Layers, any Error>
      do {
        let query = TileSchema.GetTileLayersQuery { $0.organization_id = scope }
        answer = .success(try await client.tiles.getTileLayers(query: query).data)
      } catch {
        answer = .failure(error)
      }
      if manifestRead == read {
        manifestRead = nil
        let waiting = manifestWaiters
        manifestWaiters = []
        switch answer {
        case .success(let catalogue):
          layersManifest = catalogue
          tell(.layersChange(catalogue))
          for waiter in waiting {
            waiter.resume(returning: catalogue)
          }
          return catalogue
        case .failure(let error):
          for waiter in waiting {
            waiter.resume(throwing: error)
          }
          throw error
        }
      }
      // The scope moved while this read was out: the current scope's catalogue answers, held,
      // still being read, or read now.
      if let held = layersManifest {
        return held
      }
      if manifestRead != nil {
        return try await withCheckedThrowingContinuation { manifestWaiters.append($0) }
      }
    }
  }

  /// addAnalysis draws a Data API result of `kind` under an id of its own, or `fixed`, the result
  /// `answered` where one is handed over, else the answer of `query` asked with `input`, and
  /// answers the id and the result. The fit is read before anything is asked. A request a removal,
  /// a clear or a later request superseded draws and records nothing, and a closed map still
  /// answers the query, drawing and recording nothing (`map.analysis.slots`,
  /// `map.analysis.requests`).
  private func addAnalysis<Input: Sendable, Answer: Sendable>(
    _ kind: AnalysisKind, id fixed: String? = nil, input: Input?, answered: Answer?, chosen: Int,
    fit: CameraFit?, query: @escaping @Sendable (Input) async throws -> Answer,
    features: (Answer, Input?, Int) -> GeoJSONFeatureCollection
  ) async throws -> AnalysisHandle<Answer> {
    let framing = isClosed ? nil : try fit.map { fit throws(MapError) in try readCameraFit(fit) }
    let id: String
    if let fixed {
      id = fixed
    } else {
      id = "analysis:\(kind.rawValue):\(analysisCount)"
      analysisCount += 1
    }
    let token = isClosed ? nil : slots.take(.analysis(id))
    let answer: Answer
    do {
      if let answered {
        answer = answered
      } else if let input {
        answer = try await runQuery(of: id) { try await query(input) }
      } else {
        throw MapError(kind: .noInput, name: id)
      }
    } catch {
      // A request that draws nothing gives its slot up, unless a result is drawn under the id.
      if let token, slots.owns(.analysis(id), token: token), !isClosed,
        !analyses.contains(where: { sameText($0.id, id) })
      {
        slots.release(.analysis(id))
      }
      throw error
    }
    guard let token, slots.owns(.analysis(id), token: token), !isClosed else {
      return AnalysisHandle(id: id, result: answer)
    }
    hold(HeldAnalysis(kind: kind, input: input, result: answer, chosen: chosen, fit: fit), as: id)
    drawAnalysis(kind, id: id, features: features(answer, input, chosen), fit: framing)
    return AnalysisHandle(id: id, result: answer)
  }

  /// editAnalysis asks again for the result of `kind` drawn under `id`, with `patch` applied to the
  /// input it was asked with, or, with no patch, redraws the result held under the options the
  /// call states merged onto the held ones, asking nothing (`map.analysis.edit`). The options are
  /// read again as an answer lands, so a redraw made while the query was out stands under what the
  /// call itself stated.
  private func editAnalysis<Input: Sendable, Answer: Sendable>(
    _ kind: AnalysisKind, id: String, patch: ((inout Input) -> Void)?, chosen: Int?,
    fit: CameraFit?, query: @escaping @Sendable (Input) async throws -> Answer,
    features: (Answer, Input?, Int) -> GeoJSONFeatureCollection
  ) async throws -> Answer {
    guard let held = analyses.first(where: { sameText($0.id, id) })?.held else {
      throw MapError(kind: .analysisNotFound, name: id)
    }
    guard held.kind == kind, let result = held.result as? Answer else {
      throw MapError(kind: .kindMismatch, name: id)
    }
    _ = isClosed ? nil : try fit.map { fit throws(MapError) in try readCameraFit(fit) }
    let heldInput = held.input as? Input
    guard let patch else {
      guard !isClosed else { return result }
      var restyled = held
      restyled.chosen = chosen ?? held.chosen
      restyled.fit = fit ?? held.fit
      hold(restyled, as: id)
      drawAnalysis(
        kind, id: id, features: features(result, heldInput, restyled.chosen), fit: restyled.fit)
      return result
    }
    guard var input = heldInput else { throw MapError(kind: .noInput, name: id) }
    patch(&input)
    let asked = input
    let token = isClosed ? nil : slots.take(.analysis(id))
    let answer = try await runQuery(of: id) { try await query(asked) }
    guard let token, slots.owns(.analysis(id), token: token), !isClosed,
      let current = analyses.first(where: { sameText($0.id, id) })?.held
    else { return answer }
    let next = HeldAnalysis(
      kind: kind, input: asked, result: answer, chosen: chosen ?? current.chosen,
      fit: fit ?? current.fit)
    hold(next, as: id)
    drawAnalysis(kind, id: id, features: features(answer, asked, next.chosen), fit: next.fit)
    return answer
  }

  /// runQuery runs `query` in the calling task for the result `id`, cancelling the query that
  /// result had out, and throws `CancellationError` where a later run, a removal or a clear cancels
  /// it in turn.
  private func runQuery<Answer: Sendable>(
    of id: String, query: @escaping @Sendable () async throws -> Answer
  ) async throws -> Answer {
    guard !isClosed else { return try await query() }
    abortQuery(of: id)
    let abort = QueryAbort()
    queryAborts.append((id, abort))
    defer { queryAborts.removeAll { $0.abort === abort } }
    return try await abort.race(query)
  }

  /// abortQuery cancels the query out for the result `id`, where one is.
  private func abortQuery(of id: String) {
    for entry in queryAborts where sameText(entry.id, id) {
      entry.abort.pull()
    }
    queryAborts.removeAll { sameText($0.id, id) }
  }

  /// clearAnalyses takes off every result of `kind`, those whose first query is still out
  /// included, and cancels every query of them still out.
  private func clearAnalyses(_ kind: AnalysisKind) {
    guard !isClosed else { return }
    let prefix = "analysis:\(kind.rawValue):".unicodeScalars
    var ids = analyses.filter { $0.held.kind == kind }.map(\.id)
    for case .analysis(let id) in slots.requestedSlots()
    where id.unicodeScalars.starts(with: prefix) && !ids.contains(where: { sameText($0, id) }) {
      ids.append(id)
    }
    for id in ids {
      removeAnalysis(id)
    }
  }

  /// hold records `held` as the result drawn under `id`.
  private func hold(_ held: HeldAnalysis, as id: String) {
    if let index = analyses.firstIndex(where: { sameText($0.id, id) }) {
      analyses[index].held = held
    } else {
      analyses.append((id, held))
    }
  }

  /// drawAnalysis draws `features`, a result of `kind`, from the source `mountaya-` then `id`, at
  /// its kind's rank, and frames what it draws where `fit` is given.
  private func drawAnalysis(
    _ kind: AnalysisKind, id: String, features: GeoJSONFeatureCollection, fit: CameraFit?
  ) {
    let sourceId = "mountaya-\(id)"
    mountGeoJson(
      features, source: sourceId, layers: analysisLayers(kind, sourceId: sourceId, paint: paint),
      in: .analysis(id))
    guard let fit, let framing = try? readCameraFit(fit),
      let bounds = boundsOf(features.features.compactMap(\.geometry))
    else { return }
    let canonical = normalizeBoundingBox(bounds)
    if canonical.allSatisfy(\.isFinite) {
      frame(canonical, with: framing)
    }
  }

  /// write records what a geometry slot holds and draws it, or takes the slot down where it holds
  /// no geometry (`map.geometry.slots`, `map.geometry.layers`).
  private func write(_ held: SlotGeometry, in slot: GeometrySlot) {
    guard !isClosed else { return }
    if let index = geometrySlots.firstIndex(where: { $0.slot == slot }) {
      geometrySlots[index].held = held
    } else {
      geometrySlots.append((slot, held))
    }
    guard let geometry = held.geometry else {
      unmount(.geometry(slot))
      return
    }
    mountGeoJson(
      GeoJSONFeatureCollection(features: [GeoJSONFeature(geometry: geometry, properties: [:])]),
      source: slot.sourceId, layers: geometrySlotLayers(slot, color: held.color, paint: paint),
      in: .geometry(slot))
  }

  /// mountGeoJson draws `features` from the GeoJSON source `sourceId` through `layers`, each at its
  /// rank, as what `slot` holds: a slot drawn already takes the new features in place, and a layer
  /// it no longer lists comes off.
  private func mountGeoJson(
    _ features: GeoJSONFeatureCollection, source sourceId: String, layers: [MapLayer],
    in slot: ContentSlot
  ) {
    if let before = contents.first(where: { $0.slot == slot }) {
      for id in before.layerIds where !layers.contains(where: { sameText($0.id, id) }) {
        registry.remove(id)
      }
    }
    for var layer in layers {
      if isHidden(layer.id) {
        layer.layout["visibility"] = "none"
      }
      registry.add(layer)
    }
    let content = MapContent(
      slot: slot, sourceIds: [sourceId], layerIds: layers.map(\.id), restrictionLayerIds: [])
    if let index = contents.firstIndex(where: { $0.slot == slot }) {
      contents[index] = content
    } else {
      contents.append(content)
    }
    let source = MapSource(id: sourceId, kind: .geoJson(features))
    let drawn = registry.layers
    report { state in
      if let place = state.sources.firstIndex(where: { sameText($0.id, sourceId) }) {
        state.sources[place] = source
      } else {
        state.sources.append(source)
      }
      state.layers = drawn
    }
  }

  /// directions and its siblings are the client's call that answers each kind of result.
  private static func directions(_ client: Mountaya)
    -> @Sendable (DataSchema.DirectionsInput) async throws -> DataSchema.DirectionsResult
  {
    { input in try await client.data.directions(input: input) }
  }

  private static func suggestions(_ client: Mountaya)
    -> @Sendable (DataSchema.SuggestionsInput) async throws -> DataSchema.SuggestionsResult
  {
    { input in try await client.data.suggestions(input: input) }
  }

  private static func isochrones(_ client: Mountaya)
    -> @Sendable (DataSchema.IsochronesInput) async throws -> DataSchema.IsochronesResult
  {
    { input in try await client.data.isochrones(input: input) }
  }

  private static func places(_ client: Mountaya)
    -> @Sendable (DataSchema.GeocodeInput) async throws -> DataSchema.GeocodeResult
  {
    { input in try await client.data.geocode(input: input) }
  }

  private static func matrix(_ client: Mountaya)
    -> @Sendable (DataSchema.MatrixInput) async throws -> DataSchema.MatrixResult
  {
    { input in try await client.data.matrix(input: input) }
  }

  private static func pois(_ client: Mountaya)
    -> @Sendable (DataSchema.PoisInput) async throws -> DataSchema.PoisResult
  {
    { input in try await client.data.pois(input: input) }
  }

  /// directionsFeatures and its siblings are what each kind of result draws
  /// (`geo.layers.data-geojson`): a place, a point of interest and a matrix location that names no
  /// position drawing no feature, each kept feature keeping the index of its datum.
  private static func directionsFeatures(
    _ result: DataSchema.DirectionsResult, _: DataSchema.DirectionsInput?, _: Int
  ) -> GeoJSONFeatureCollection {
    directionsGeoJson(result)
  }

  private static func suggestionFeatures(
    _ result: DataSchema.SuggestionsResult, _: DataSchema.SuggestionsInput?, chosen: Int
  ) -> GeoJSONFeatureCollection {
    suggestionsGeoJson(result, chosen: chosen)
  }

  private static func isochroneFeatures(
    _ result: DataSchema.IsochronesResult, _: DataSchema.IsochronesInput?, _: Int
  ) -> GeoJSONFeatureCollection {
    isochronesGeoJson(result)
  }

  private static func placeFeatures(
    _ result: DataSchema.GeocodeResult, _: DataSchema.GeocodeInput?, _: Int
  ) -> GeoJSONFeatureCollection {
    drawable(placesGeoJson(result))
  }

  private static func poiFeatures(
    _ result: DataSchema.PoisResult, _: DataSchema.PoisInput?, _: Int
  ) -> GeoJSONFeatureCollection {
    drawable(poisGeoJson(result))
  }

  private static func matrixFeatures(
    _ result: DataSchema.MatrixResult, _ input: DataSchema.MatrixInput?, _: Int
  ) -> GeoJSONFeatureCollection {
    guard let input else { return GeoJSONFeatureCollection(features: []) }
    return drawable(matrixGeoJson(input, result: result))
  }

  /// drawable keeps the features that have a geometry to draw.
  private static func drawable(_ collection: GeoJSONFeatureCollection) -> GeoJSONFeatureCollection {
    GeoJSONFeatureCollection(features: collection.features.filter { $0.geometry != nil })
  }

  /// drawnVariant is the variant the map draws terrains in, with the base map at `style` and the
  /// catalogue's terrain `terrain`: the one the document is where the terrain's two variants are
  /// two documents, and the one the app asked for last otherwise.
  private func drawnVariant(style: URL?, terrain: String?) -> TileSchema.TerrainVariant {
    guard let terrain,
      let listed = layersManifest?.terrains.first(where: { sameText($0.slug, terrain) }),
      let variant = terrainVariantOfStyle(listed, style: style)
    else { return terrainVariantAsked }
    return variant
  }

  /// move hands the surface a camera move once it is read, the state holding where it lands.
  private func move(to target: CameraTarget, by motion: CameraMotion) throws(MapError) {
    guard !isClosed else { return }
    let read = try readCameraTarget(target)
    report { state in
      state.camera = Self.held(read.applied(to: state.camera), within: state.zoomBounds)
    }
    surface?.move(to: read, by: motion)
  }

  /// frame fits the camera to `box`, a box in canonical form, on the surface's canvas.
  private func frame(_ box: [Double], with fit: CameraFit) {
    guard !isClosed, let camera = surface?.frame(box, with: fit, within: held.zoomBounds) else {
      return
    }
    report { $0.camera = camera }
  }

  /// controlMove eases the camera as a control asks, to the target `controlMoveTarget` answers,
  /// handing the renderer the members that move so it keeps every other, or moves it there at once
  /// where the reader asked for reduced motion.
  private func controlMove(_ move: ControlMove) {
    guard !isClosed else { return }
    let target = controlMoveTarget(held.camera, window: held.zoomBounds, move: move)
    report { $0.camera = target }
    switch move {
    case .resetNorth:
      surface?.move(
        to: CameraTarget(bearing: 0, pitch: 0),
        by: reducesMotion ? .jump : .ease(duration: Self.northReset))
    case .zoomIn, .zoomOut:
      surface?.move(
        to: CameraTarget(zoom: target.zoom),
        by: reducesMotion ? .jump : .ease(duration: Self.zoomEase))
    }
  }

  /// query asks the surface what a point query reads at `point`, over the layers `queryLayerIds`
  /// names.
  private func query(_ query: PointQuery, at point: [Double]) -> [QueriedFeature] {
    guard !isClosed, let surface else { return [] }
    guard
      let layers = queryLayerIds(
        query, placed: registry.placement, isLive: { surface.holdsLayer($0) })
    else { return [] }
    return surface.renderedFeatures(at: point, in: layers)
  }

  /// marker is the id of the topmost marker drawn within `markerRadius` of `point`, through the
  /// surface's projection, or nil.
  private func marker(near point: [Double]) -> String? {
    guard let projection = surface?.projection, point.count > 1 else { return nil }
    let reach = Self.markerRadius * Self.markerRadius
    return held.markers.last { marker in
      let drawn = projection.point(marker.position)
      guard drawn.count > 1 else { return false }
      let dx = drawn[0] - point[0]
      let dy = drawn[1] - point[1]
      return dx * dx + dy * dy <= reach
    }?.id
  }

  /// relabelBaseMap labels every symbol layer of the base map the surface draws in the state's
  /// language, from the label its style wrote, and puts back a label it rewrote before where the
  /// language leaves it as written; a layer the map placed is never relabelled.
  private func relabelBaseMap() {
    guard let surface else { return }
    let labels = relabelledBaseLabels(
      surface.symbolLabels, isPlaced: { self.registry.layer($0) != nil },
      language: held.labelLanguage)
    for (id, label) in labels {
      if let label {
        surface.relabel(id, to: label)
        if !relabelled.contains(where: { sameText($0, id) }) {
          relabelled.append(id)
        }
      } else if relabelled.contains(where: { sameText($0, id) }) {
        surface.relabel(id, to: nil)
        relabelled.removeAll { sameText($0, id) }
      }
    }
  }

  /// answerAccess hears an answer a refusal of access ends on, and tells the end of the last one.
  private func answerAccess(_ answer: AccessAnswer) {
    // While no refusal stands, a tile or a style that loads answers nothing, and the state already
    // says no refusal stands: a map loading tile after tile reads no state for each.
    guard !standing.isEmpty else { return }
    let (after, restored) = accessStandingAfter(standing, answer: answer, holdsSource: holdsSource)
    standing = after
    report { $0.isAccessRequired = !after.isEmpty }
    if restored {
      tell(.accessRestored)
    }
  }

  /// holdsSource tells whether the surface's style holds the source `id`, which none does without
  /// a surface.
  private func holdsSource(_ id: String) -> Bool {
    surface?.holdsSource(id) ?? false
  }

  /// rendererZoomLimits is the floor and the default ceiling of the renderer that draws the map:
  /// the surface's, else MapLibre Native's, the renderer `MapView` draws on.
  private var rendererZoomLimits: ZoomBounds {
    surface?.zoomLimits ?? Self.nativeZoomLimits
  }

  /// report applies `change` to the state held and tells every stream of the new state, where it
  /// differs from the one held and the engine is not closed.
  private func report(_ change: (inout MapState) -> Void) {
    guard !isClosed else { return }
    var next = held
    change(&next)
    guard next != held else { return }
    // A camera move closes the readout, the app's or a control's as it is asked, and the reader's
    // as it begins, `readerMoveBegan()` (`map.readout.open`).
    if readout != nil, next.camera != held.camera {
      dropReadout()
    }
    held = next
    for number in subscribers.keys.sorted() {
      guard let continuation = subscribers[number] else { continue }
      if case .terminated = continuation.yield(next) {
        subscribers[number] = nil
      }
    }
  }

  /// tell hands `event` to every stream `events()` returned, in order.
  private func tell(_ event: MapEvent) {
    guard !isClosed else { return }
    for number in listeners.keys.sorted() {
      guard let continuation = listeners[number] else { continue }
      if case .terminated = continuation.yield(event) {
        listeners[number] = nil
      }
    }
  }

  /// nativeZoomLimits is MapLibre Native's own zoom limits, which `MapView` draws on: it draws
  /// nothing under 0, and builds a map with a ceiling of 25.5.
  static let nativeZoomLimits = ZoomBounds(minZoom: 0, maxZoom: 25.5)

  /// markerRadius is how far from a marker's point, in the canvas's points, a tap is on it.
  static let markerRadius: Double = 22

  /// zoomEase is how long a zoom control's step eases, the platform's motion and no contract's.
  static let zoomEase: Duration = .milliseconds(250)

  /// northReset is how long a reset of north eases, as MapLibre's own reset takes.
  static let northReset: Duration = .seconds(1)

  /// held is `camera` with its zoom brought within `range`, a zoom that is no number left as it is.
  private static func held(_ camera: CameraPose, within range: ZoomBounds) -> CameraPose {
    var held = camera
    if camera.zoom < range.minZoom { held.zoom = range.minZoom }
    if camera.zoom > range.maxZoom { held.zoom = range.maxZoom }
    return held
  }

  /// within is a position a gesture was read at, its longitude brought within [-180, 180] only
  /// where it lies past that range, or nil where it is not two numbers.
  private static func within(_ position: [Double]) -> [Double]? {
    guard position.count > 1 else { return nil }
    return [wrapLongitudePastRange(position[0]), position[1]]
  }

  /// draws tells whether `layer` draws at `zoom`: within its zoom window, where it has one, and
  /// not hidden.
  private static func draws(_ layer: MapLayer, at zoom: Double) -> Bool {
    if case .string(let visibility)? = layer.layout["visibility"], sameText(visibility, "none") {
      return false
    }
    guard let window = layer.zoom else { return true }
    return zoom >= window.minZoom && zoom < window.maxZoom
  }

  /// place reads a position a marker or a waypoint is placed at as `[longitude, latitude]`, an
  /// altitude after them ignored, and refuses one that names no place a map draws: fewer than two
  /// numbers or more than three, or a longitude or a latitude that is not finite, the latitude from
  /// -90 to 90 (`map.marker.lifecycle`).
  private static func place(_ position: [Double], for id: String) throws(MapError) -> [Double] {
    guard (2...3).contains(position.count), position[0].isFinite, position[1].isFinite,
      (-90...90).contains(position[1])
    else {
      throw MapError(kind: .positionRefused, name: id)
    }
    return [position[0], position[1]]
  }

  /// labelLanguage is the language a map labels in: the one the app named, else the client's,
  /// else the device's, each read as a label language is.
  private static func labelLanguage(given: RestSchema.Language?, client: Mountaya)
    -> RestSchema.Language
  {
    MountayaGeo.labelLanguage(given?.rawValue ?? client.language ?? preferredLanguage())
  }
}

/// A map is what a layers selection drives (`geo.layers.selection`): its catalogue, its terrain,
/// its classic overlay, its enrichments and the instant it draws its stamped overlay for
/// (`geo.layers.selection-instant`), each command throwing where the map refuses it, and
/// what a locate control stands over (`geo.controls.geolocate-state`): the fix `locate()` frames
/// and the standing permission `isLocationRefused()` reads. A selection and a control compare their
/// map by identity, so one handed the map it holds already changes nothing.
extension MapEngine: LayersSelectionTarget, GeolocateControlTarget, CursorMarkerTarget,
  LegEmphasisTarget
{}
