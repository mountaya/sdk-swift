#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import CoreLocation
  import Foundation
  internal import MapLibre
  import MountayaClient
  import MountayaGeo
  internal import UIKit

  /// MapRenderer draws a map engine's state on MapLibre's own map, and is the surface the engine
  /// asks what only a renderer knows and tells what happens on the map.
  ///
  /// It draws every state the engine reports: the base map's style, the camera, and each source and
  /// layer above the base map in the order the one layer registry ranks them (`geo.layers.order`),
  /// every one above the base map's own layers. A layer is MapLibre's style layer of its type, each
  /// property set under the name MapLibre gives the style property and read as the style document
  /// reads it, so a patch the engine merged is the property the map draws. MapLibre refuses a value
  /// its style does not take as it refuses one in a style document, by raising. The engine relabels
  /// the base map's labels through it, never a layer of the map's own (`map.style.label-scope`).
  ///
  /// It moves MapLibre's camera as the engine hands it a move, at once, along an ease or a flight,
  /// frames a box on its own canvas as `cameraForBounds` fits one (`geo.camera.fit`), and holds the
  /// camera to the state's pan lock and zoom range. It answers a point query from MapLibre's
  /// rendered features, layer by layer, topmost first, and projects through MapLibre's projection.
  ///
  /// It shows each marker as its pin (`map.marker.pin`), its glyph drawn from the engine's glyph
  /// set, and the waypoint being placed, as MapLibre's own annotations above every layer, with no
  /// callout of MapLibre's: the label of the marker a tap fell on is written to `callout`, which the
  /// view draws over the watermark, and each move of the camera while one shows. It tells
  /// the engine of each tap and long press, of a hovering pointer and each frame drawn while one
  /// waits, of a request of the map's own that failed, of a tile loaded, of a style loaded and of
  /// one that did not arrive, of a move of the camera the reader begins, and of the camera at rest
  /// after the reader moved it, and the engine hears the map's safe area as it changes, which the
  /// watermark is measured from; it hands `onTap`
  /// each tap the engine tells, and `onCameraChange` each camera at rest, whoever moved it. A style
  /// refused access is told as that refusal alone, never also as one that did not arrive, and one
  /// refused a credential the client no longer sends is asked for again instead, once an ask.
  ///
  /// It answers an image the style names and does not hold with the marker sprite the id names,
  /// drawn from the engine's glyph set (`map.icons.missing-image`), so an itinerary's waypoints and
  /// a map's points of interest show their pins on a map no editor draws, and with the stripe
  /// pattern of a restricted stretch's kind (`map.icons.stripe-pattern`), which the stripes beside
  /// an itinerary's line paint (`map.road-access.layers`). Its credit button lists what the engine
  /// credits, Mountaya first (`map.style.attribution`).
  ///
  /// It shows its map in the process's request hook for as long as it lives, so the map's own
  /// requests carry its engine's client's credential and language, and the failures of those it
  /// claims reach the engine. MapLibre's map is made showing nothing and asked for its style only
  /// once the hook shows the map and knows the style as its own, so the style's first request
  /// carries the credential and its failure is kept for the renderer to find. It shows none of MapLibre's own compass, `MapControls`' standing in
  /// for it, and keeps MapLibre's credit button at the bottom right. It is bound to the main actor,
  /// where MapLibre's map lives.
  @MainActor
  final class MapRenderer: NSObject {
    /// mapView is MapLibre's own map, which the view hosts and the ready callback hands over.
    let mapView: MLNMapView

    let engine: MapEngine
    private let onReady: ((MLNMapView) -> Void)?
    /// onTap is told each tap the engine tells, which the view hands on as SwiftUI redraws it.
    var onTap: ((MapTap) -> Void)?
    /// onCameraChange is told where the camera came to rest after each move.
    var onCameraChange: ((CameraPose) -> Void)?
    /// callout is the label of the marker tapped last, which the view draws over the watermark.
    let callout: MarkerCallout
    private var isReady = false
    /// annotations is every marker shown and the pin of the waypoint being placed, as drawn.
    private var annotations: [MLNPointAnnotation] = []
    /// pinImages is each marker pin drawn, by the look it is drawn for, so a look is drawn once
    /// and every marker of it is shown through that one image.
    private var pinImages: [PinLook: UIImage] = [:]
    /// pinsDrawn is how many marker pins the renderer has drawn, one for each look it showed,
    /// which a test counts.
    private(set) var pinsDrawn = 0
    /// probe is told of each source the renderer sends MapLibre, `source <id>`, and of each time
    /// it reads its claims anew, `claims`, where a test installs one; nil in an app.
    var probe: RenderProbe?
    /// unlocked is the pan lock MapLibre's map holds before one is set, which lifting a lock
    /// restores.
    private var unlocked = MLNCoordinateBounds(
      sw: CLLocationCoordinate2D(latitude: -90, longitude: -180),
      ne: CLLocationCoordinate2D(latitude: 90, longitude: 180))
    /// holding is true from a change of the camera's limits to the move MapLibre makes to keep
    /// the camera within them, which the engine is told of.
    private var holding = false
    /// drawn is the state last drawn, nil before the first.
    private(set) var drawn: MapState?
    /// heldClaims is `claims` as last read, until a state drawn changes the sources or the style
    /// they are read from, nil before.
    private var heldClaims: [String]?
    /// camera is the camera last drawn, moved to or reported, which a state holding it does not
    /// move again.
    private var camera: CameraPose?
    /// isStyleLoaded is true while the style MapLibre holds is loaded and takes sources and layers.
    private var isStyleLoaded = false
    /// isStyleAskedAgain is true once the style asked for last was asked for again, after a
    /// refusal of a credential the client no longer sends, which it is once an ask.
    private var isStyleAskedAgain = false
    private var sources: [String: (source: MLNSource, value: MapSource)] = [:]
    private var layers: [String: (layer: MLNStyleLayer, value: MapLayer)] = [:]
    /// writtenLabels is the label of each symbol layer of the style, as its style wrote it.
    private var writtenLabels: [String: NSExpression] = [:]
    /// following ends the tasks drawing the engine's states and handing on its taps once the
    /// renderer is let go.
    private var following: [Following] = []
    /// frames ticks once a frame while a hovering pointer waits on the next frame.
    private var frames: CADisplayLink?
    /// accent is the colour a marker naming none is drawn in, and the ring of the waypoint being
    /// placed: the elements' `accent` token as the host's tokens state it, read under the scheme in
    /// force (`geo.style.theme-tokens`), which the view hands over as SwiftUI draws it. A new one
    /// draws the pins it shows again: the look of the markers naming no colour, once, and the ring
    /// of the waypoint being placed.
    var accent = themeTokenValue(ElementTokens.standard.accent, in: .light) {
      didSet {
        guard oldValue != accent, drawn != nil else { return }
        restyle()
      }
    }

    /// Creates a renderer drawing `engine`'s state, which calls `onReady` with MapLibre's map once
    /// its first style is loaded, `onTap` with each tap the engine tells and `onCameraChange` with
    /// each camera at rest, and writes the label of the marker tapped last to `callout`.
    init(
      engine: MapEngine, onReady: ((MLNMapView) -> Void)?, onTap: ((MapTap) -> Void)? = nil,
      onCameraChange: ((CameraPose) -> Void)? = nil, callout: MarkerCallout = MarkerCallout()
    ) {
      self.engine = engine
      self.onReady = onReady
      self.onTap = onTap
      self.onCameraChange = onCameraChange
      self.callout = callout
      // MapLibre asks for a style as it is handed one, so its map shows nothing until the hook shows
      // it: the first state drawn asks for the style.
      let measured = MeasuredMapView(frame: .zero, styleJSON: Self.blankStyle)
      mapView = measured
      super.init()
      // The watermark is measured from the map's safe area, which the map tells as it changes, and
      // the engine hears after the layout that measured it, so no view is drawn again inside it.
      measured.onSafeArea = { [weak engine] safeArea in
        guard let engine else { return }
        Task { @MainActor [weak engine] in engine?.safeAreaShown(safeArea) }
      }
      MapRequestHook.shared.install(
        client: engine.client, transform: engine.transformRequest, renderer: self)
      mapView.delegate = self
      // MapLibre's compass shows on a rotated map, beside the one `MapControls` draws.
      mapView.showsCompassView = false
      unlocked = mapView.maximumScreenBounds
      let tap = UITapGestureRecognizer(target: self, action: #selector(recognized(_:)))
      // A double tap zooms, and is no tap of the reader's.
      for case let other as UITapGestureRecognizer in mapView.gestureRecognizers ?? []
      where other.numberOfTapsRequired > 1 {
        tap.require(toFail: other)
      }
      mapView.addGestureRecognizer(tap)
      mapView.addGestureRecognizer(
        UILongPressGestureRecognizer(target: self, action: #selector(pressed(_:))))
      mapView.addGestureRecognizer(
        UIHoverGestureRecognizer(target: self, action: #selector(hovered(_:))))
      mapView.attributionButton.removeTarget(nil, action: nil, for: .allEvents)
      mapView.attributionButton.addTarget(
        self, action: #selector(showCredits), for: .touchUpInside)
      engine.attach(self)
      draw(engine.state)
      let states = engine.subscribe()
      let events = engine.events()
      following = [
        Following(
          Task { [weak self] in
            for await state in states {
              guard let self else { return }
              self.draw(state)
            }
          }),
        Following(
          Task { [weak self] in
            for await event in events {
              guard let self else { return }
              if case .tap(let tap) = event {
                self.label(tap.marker)
                self.onTap?(tap)
              }
            }
          }),
      ]
    }

    /// label shows the label of the marker of id `id` a tap fell on, where it holds one, and takes
    /// the label shown off where the tap fell on no marker or on one with none.
    func label(_ id: String?) {
      let marker = id.flatMap { id in drawn?.markers.last { sameText($0.id, id) } }
      callout.show(marker?.label == nil ? nil : marker?.id)
    }

    /// ask asks MapLibre's map for `style`, or shows nothing where it is nil, once the request hook
    /// knows it as this map's style.
    private func ask(_ style: URL?) {
      MapRequestHook.shared.askedStyle(style, by: self)
      if let style {
        mapView.styleURL = style
      } else {
        mapView.styleJSON = Self.blankStyle
      }
    }

    /// blankStyle is the style a map shows before it is given a base map: nothing at all, which
    /// MapLibre fetches nothing for.
    static let blankStyle = #"{"version":8,"sources":{},"layers":[]}"#

    /// zoomLimits is MapLibre Native's own: it draws nothing under 0, and builds a map with a
    /// ceiling of 25.5.
    static let zoomLimits = ZoomBounds(minZoom: 0, maxZoom: 25.5)

    /// easeDuration is how long an ease takes where it states no duration, MapLibre GL JS's own.
    static let easeDuration: TimeInterval = 0.5

    /// draw draws `state`, each part that differs from the state drawn before.
    func draw(_ state: MapState) {
      let before = drawn
      drawn = state
      if before?.sources != state.sources || before?.style != state.style {
        heldClaims = nil
      }
      if before == nil || before?.style != state.style {
        if before != nil {
          isStyleLoaded = false
          isStyleAskedAgain = false
          sources = [:]
          layers = [:]
          writtenLabels = [:]
        }
        // The map was made showing nothing, which a first state with no base map keeps.
        if before != nil || state.style != nil {
          ask(state.style)
        }
      }
      let limited = hold(state, after: before)
      if camera != state.camera {
        move(to: state.camera)
      }
      // The first draw sets the limits the map opens with, and the camera with them; a later
      // change of limits may move the camera the state holds, now or as MapLibre next moves it.
      if limited, before != nil {
        holding = true
        reportHeldCamera(state.camera)
      }
      if before?.markers != state.markers || before?.waypointEdit != state.waypointEdit {
        annotate(state)
      }
      guard isStyleLoaded, let style = mapView.style else { return }
      reconcile(state, on: style)
    }

    /// move moves the camera to `pose`, at once.
    private func move(to pose: CameraPose) {
      camera = pose
      // A camera the app sets is the one to show, whatever move the limits had pending.
      holding = false
      guard pose.center.count > 1 else { return }
      // MapLibre's camera holds its eye's altitude, so a tilt changes the zoom it shows: the tilt
      // is set first, and the center, the zoom and the bearing over it.
      let pitched = mapView.camera
      pitched.pitch = pose.pitch
      mapView.setCamera(pitched, animated: false)
      mapView.setCenter(
        CLLocationCoordinate2D(latitude: pose.center[1], longitude: pose.center[0]),
        zoomLevel: pose.zoom, direction: pose.bearing, animated: false)
    }

    /// pose is where MapLibre's camera stands now.
    private var pose: CameraPose {
      let center = mapView.centerCoordinate
      return CameraPose(
        center: [center.longitude, center.latitude], zoom: mapView.zoomLevel,
        pitch: Double(mapView.camera.pitch), bearing: mapView.direction)
    }

    // MARK: - Sources and layers

    /// reconcile brings the map's own sources and layers to the state's: each one taken off,
    /// added or changed, and every layer in the registry's order above the base map's.
    private func reconcile(_ state: MapState, on style: MLNStyle) {
      // A source that is gone, or serves another kind of tiles, is taken off with every layer
      // drawing from it; GeoJSON the app holds is given its new features in place.
      var replaced: Set<String> = []
      for (id, held) in sources {
        let wanted = state.sources.first { sameText($0.id, id) }
        if let wanted, wanted == held.value {
          continue
        }
        if let wanted, case .geoJson(let features) = wanted.kind,
          case .geoJson = held.value.kind, let shapes = held.source as? MLNShapeSource
        {
          shapes.shape = shape(features)
          probe?.report("source " + id)
          sources[id] = (shapes, wanted)
          continue
        }
        replaced.insert(id)
      }
      for (id, held) in layers
      where replaced.contains(held.value.source)
        || !state.layers.contains(where: { sameText($0.id, id) })
      {
        style.removeLayer(held.layer)
        layers[id] = nil
      }
      for id in replaced {
        if let held = sources[id] {
          style.removeSource(held.source)
        }
        sources[id] = nil
      }
      for source in state.sources where sources[source.id] == nil {
        guard let made = makeSource(source) else { continue }
        style.addSource(made)
        probe?.report("source " + source.id)
        sources[source.id] = (made, source)
      }

      // A layer whose type, source or source layer moved is made again; any other change is set
      // property by property on the layer drawn.
      for layer in state.layers {
        if let held = layers[layer.id], sameShape(held.value, layer) {
          if held.value != layer {
            set(layer, on: held.layer, was: held.value)
            layers[layer.id] = (held.layer, layer)
          }
          continue
        }
        if let held = layers[layer.id] {
          style.removeLayer(held.layer)
          layers[layer.id] = nil
        }
        guard sources[layer.source] != nil, let made = makeLayer(layer) else { continue }
        set(layer, on: made, was: nil)
        layers[layer.id] = (made, layer)
      }

      // The map's own layers draw above the base map's, in the registry's order: where the order
      // on the map is another, they are taken off and added again in it.
      let order = state.layers.compactMap { layers[$0.id]?.layer }
      let onMap = style.layers.filter { layer in layers[layer.identifier] != nil }
      guard !onMap.elementsEqual(order, by: { $0 === $1 }) else { return }
      for layer in onMap {
        style.removeLayer(layer)
      }
      for layer in order {
        style.addLayer(layer)
      }
    }

    /// sameShape tells whether two layers are drawn by the same style layer: of one type, from one
    /// source and source layer.
    private func sameShape(_ a: MapLayer, _ b: MapLayer) -> Bool {
      sameText(a.type, b.type) && sameText(a.source, b.source)
        && sameText(a.sourceLayer, b.sourceLayer)
    }

    /// makeSource is MapLibre's source for `source`, or nil for one it cannot hold.
    private func makeSource(_ source: MapSource) -> MLNSource? {
      var options: [MLNTileSourceOption: Any] = [:]
      if let attribution = source.attribution {
        options[.attributionHTMLString] = attribution
      }
      switch source.kind {
      case .vector(let tiles, let zoom):
        options[.minimumZoomLevel] = NSNumber(value: zoom.minZoom)
        options[.maximumZoomLevel] = NSNumber(value: zoom.maxZoom)
        return MLNVectorTileSource(identifier: source.id, tileURLTemplates: tiles, options: options)
      case .raster(let tiles, let tileSize, let zoom):
        options[.minimumZoomLevel] = NSNumber(value: zoom.minZoom)
        options[.maximumZoomLevel] = NSNumber(value: zoom.maxZoom)
        // A size the specification does not state is MapLibre's own, 512, as it is GL JS's.
        if let tileSize {
          options[.tileSize] = NSNumber(value: tileSize)
        }
        return MLNRasterTileSource(identifier: source.id, tileURLTemplates: tiles, options: options)
      case .rasterDem(let tiles, let tileSize, let zoom):
        options[.minimumZoomLevel] = NSNumber(value: zoom.minZoom)
        options[.maximumZoomLevel] = NSNumber(value: zoom.maxZoom)
        if let tileSize {
          options[.tileSize] = NSNumber(value: tileSize)
        }
        return MLNRasterDEMSource(identifier: source.id, tileURLTemplates: tiles, options: options)
      case .geoJson(let features):
        return MLNShapeSource(identifier: source.id, shape: shape(features), options: nil)
      }
    }

    /// shape is GeoJSON features as MapLibre reads them, a GeometryCollection's laid out as the
    /// geometries it holds (`mapLibreFeatures`), none where they cannot be written as JSON, a
    /// coordinate that is no number among them.
    private func shape(_ features: GeoJSONFeatureCollection) -> MLNShape? {
      let collection = FeatureCollection(
        features: mapLibreFeatures(features.features).map(Feature.init))
      guard let data = try? JSONEncoder().encode(collection) else { return nil }
      return try? MLNShape(data: data, encoding: String.Encoding.utf8.rawValue)
    }

    /// makeLayer is MapLibre's style layer of `layer`'s type, drawing from its source, or nil
    /// for a type it does not draw.
    private func makeLayer(_ layer: MapLayer) -> MLNStyleLayer? {
      guard let source = sources[layer.source]?.source else { return nil }
      let made: MLNStyleLayer
      switch layer.type.rawValue {
      case "line": made = MLNLineStyleLayer(identifier: layer.id, source: source)
      case "fill": made = MLNFillStyleLayer(identifier: layer.id, source: source)
      case "circle": made = MLNCircleStyleLayer(identifier: layer.id, source: source)
      case "symbol": made = MLNSymbolStyleLayer(identifier: layer.id, source: source)
      case "raster": made = MLNRasterStyleLayer(identifier: layer.id, source: source)
      case "hillshade": made = MLNHillshadeStyleLayer(identifier: layer.id, source: source)
      case "fill-extrusion": made = MLNFillExtrusionStyleLayer(identifier: layer.id, source: source)
      case "heatmap": made = MLNHeatmapStyleLayer(identifier: layer.id, source: source)
      default: return nil
      }
      if let vector = made as? MLNVectorStyleLayer, let sourceLayer = layer.sourceLayer {
        vector.sourceLayerIdentifier = sourceLayer
      }
      return made
    }

    /// set sets every property of `layer` on MapLibre's style layer, and resets one `was` held
    /// that `layer` no longer states. A label is set as the layer states it: the map's label
    /// language relabels the base map alone (`map.style.label-scope`).
    private func set(_ layer: MapLayer, on drawn: MLNStyleLayer, was: MapLayer?) {
      let properties = layer.paint.merging(layer.layout) { paint, _ in paint }
      var stated = Set<String>()
      if let was {
        stated.formUnion(was.paint.keys)
        stated.formUnion(was.layout.keys)
      }
      for name in stated where properties[name] == nil {
        setProperty(name, to: .null, on: drawn)
      }
      for (name, value) in properties {
        setProperty(name, to: value, on: drawn)
      }
      if let vector = drawn as? MLNVectorStyleLayer {
        vector.predicate = layer.filter.map { NSPredicate(mglJSONObject: foundationObject($0)) }
      }
      drawn.minimumZoomLevel = Float(layer.zoom?.minZoom ?? 0)
      drawn.maximumZoomLevel = Float(layer.zoom?.maxZoom ?? 24)
    }

    /// setProperty sets the style property of name `name` to `value` on MapLibre's layer, under the
    /// name MapLibre gives it, JSON's `null` resetting it to the style's default. A property the
    /// layer's type does not hold is set nowhere.
    private func setProperty(_ name: String, to value: JSONValue, on layer: MLNStyleLayer) {
      if name == "visibility" {
        if case .string(let visibility) = value {
          layer.isVisible = !sameText(visibility, "none")
        } else {
          layer.isVisible = true
        }
        return
      }
      let key = styleKey(name)
      guard
        layer.responds(
          to: NSSelectorFromString("set\(key.prefix(1).uppercased())\(key.dropFirst()):"))
      else {
        return
      }
      if case .null = value {
        layer.setValue(nil, forKey: key)
      } else {
        layer.setValue(
          NSExpression(mglJSONObject: foundationObject(styleValue(value, of: name))), forKey: key)
      }
    }
  }

  extension MapRenderer: @MainActor MLNMapViewDelegate {
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
      isStyleLoaded = true
      if let state = drawn {
        reconcile(state, on: style)
      }
      // MapLibre drops a style's load as another is asked of it, so the style loaded, from its
      // cache or not, is the one drawn last, which the engine may have been asked past since: it is
      // credited as itself, never as the base map asked for after it.
      engine.styleLoaded(drawn?.style, terrain: drawn?.terrain)
      if !isReady {
        isReady = true
        onReady?(mapView)
      }
    }

    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: any Error) {
      let style = drawn?.style
      // The hook heard the style's answer before MapLibre told it failed, and told it.
      let answer = style.flatMap { MapRequestHook.shared.styleAnswer(at: $0) }
      // A style refused under a credential the client no longer sends, a refusal its engine told
      // nobody, is asked for again under the one it sends now, once an ask.
      if answer == .dropped, !engine.isClosed, !isStyleAskedAgain {
        isStyleAskedAgain = true
        mapView.reloadStyle(nil)
        return
      }
      // A style the hook told is told once, a refusal of access as that refusal, or to nobody,
      // and never also as a failure (`map.events.access-refused`), and a failure with its status,
      // or none where it reached no answer; one the hook told nothing of arrived and MapLibre could
      // not read it, which is told here.
      if answer == nil {
        engine.requestFailed(url: style?.absoluteString ?? "", status: nil, source: nil)
      }
      // The base map drawn did not arrive: where it is still the one asked for last, the map goes
      // back to the one shown, and draws its content on it again as that style loads.
      engine.styleFailed(style)
    }

    /// Hears a move of the camera beginning: one the reader makes, a pan, a pinch, a turn or a
    /// tilt, closes the readout as it begins (`map.readout.open`); one the app or a control asked
    /// for closed it as it was asked.
    func mapView(
      _ mapView: MLNMapView, regionWillChangeWith reason: MLNCameraChangeReason, animated: Bool
    ) {
      guard !engine.isClosed, !reason.contains(.programmatic), reason != [] else { return }
      engine.readerMoveBegan()
    }

    /// Hears the camera moving, which moves the label shown with its marker.
    func mapViewRegionIsChanging(_ mapView: MLNMapView) {
      callout.cameraMoved()
    }

    func mapView(
      _ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool
    ) {
      callout.cameraMoved()
      guard !engine.isClosed else { return }
      let moved = pose
      if !reason.contains(.programmatic), reason != [] {
        holding = false
        camera = moved
        engine.cameraMoved(to: moved)
      } else if holding {
        reportHeldCamera(drawn?.camera ?? moved)
        holding = false
      }
      onCameraChange?(moved)
    }

    func mapView(_ mapView: MLNMapView, viewFor annotation: any MLNAnnotation) -> MLNAnnotationView?
    {
      switch annotation {
      case let marker as MarkerAnnotation: return MarkerPinView(pinImage(of: marker))
      case is DraftAnnotation: return DraftPinView(accent: accent)
      default: return nil
      }
    }

    /// Answers that no annotation shows MapLibre's callout: a marker's label is the view's, drawn
    /// over the watermark, where a callout inside MapLibre's view would stand under it.
    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: any MLNAnnotation)
      -> Bool
    {
      false
    }

    /// Answers an image the style names and the map does not hold: where the id names a marker
    /// sprite, `section-icon-` or `poi-icon-` then a glyph of the engine's set, a hyphen and six
    /// hexadecimal digits, the sprite of that glyph on a disc of that colour, which MapLibre adds to
    /// the style under the id, and nothing for any other id, which MapLibre leaves missing
    /// (`map.icons.missing-image`).
    func mapView(_ mapView: MLNMapView, didFailToLoadImage imageName: String) -> UIImage? {
      missingImage(imageName)
    }

    /// Hears a tile of a source loading, which ends that source's refusal of access, on a thread
    /// of MapLibre's own (`map.events.access-standing`).
    nonisolated func mapView(
      _ mapView: MLNMapView, tileDidTriggerAction operation: MLNTileOperation, x: Int, y: Int,
      z: Int, wrap: Int, overscaledZ: Int, sourceID: String
    ) {
      guard operation == .endParse else { return }
      MapRequestHook.shared.tileParsed(source: sourceID, by: self)
    }
  }

  // MARK: - Images

  extension MapRenderer {
    /// missingImage is the image the map draws for an id its style names and does not hold: the
    /// stripe pattern of the restricted stretch's kind the id names (`map.icons.stripe-pattern`),
    /// the marker sprite the id names, drawn from the engine's glyph set
    /// (`map.icons.missing-image`, `map.icons.marker-sprite`), or nil where it names neither, a kind
    /// the vocabulary does not hold or a glyph the set cannot draw.
    func missingImage(_ id: String) -> UIImage? {
      if let kind = readRoadAccessStripeImageId(id) {
        return stripePatternImage(roadAccessStripePattern(kind))
      }
      let set = engine.glyphs
      guard let named = readMarkerImageId(id, in: set),
        let sprite = describeMarkerSprite(named.glyph, color: named.color, in: set),
        let figures = glyphFigures(named.glyph, in: set)
      else { return nil }
      return markerSpriteImage(sprite, figures: figures)
    }

    /// pinImage is the pin `marker` is shown as, its glyph drawn from the engine's glyph set, on the
    /// accent where it names no colour (`map.marker.pin`): drawn the first time its look is shown,
    /// and the one drawn then every later time, for this marker and every other of its look.
    func pinImage(of marker: MarkerAnnotation) -> UIImage {
      let set = engine.glyphs
      let pin = describeMarkerPin(color: marker.color, glyph: marker.glyph, in: set)
      let look = PinLook(pin: pin, accent: pin.fill == nil ? accent : nil)
      if let drawn = pinImages[look] {
        return drawn
      }
      let image = markerPinImage(pin, accent: accent, in: set)
      pinImages[look] = image
      pinsDrawn += 1
      return image
    }
  }

  // MARK: - The surface the engine asks

  extension MapRenderer: MapSurface {
    var zoomLimits: ZoomBounds { Self.zoomLimits }

    func move(to target: CameraTarget, by motion: CameraMotion) {
      // The engine holds where the move lands, so the state that holds it moves nothing again.
      camera = engine.state.camera
      holding = false
      let landing = target.applied(to: pose)
      guard landing.center.count > 1 else { return }
      switch motion {
      case .jump:
        jump(to: landing)
      case .ease(let duration):
        mapView.setCamera(
          mapCamera(landing),
          withDuration: duration.map(Self.seconds) ?? Self.easeDuration,
          animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
      case .fly:
        mapView.fly(to: mapCamera(landing), completionHandler: nil)
      }
    }

    func frame(_ bounds: [Double], with fit: CameraFit, within window: ZoomBounds) -> CameraPose? {
      let size = mapView.bounds.size
      guard
        let viewport = cameraForBounds(
          bounds, canvas: [Double(size.width), Double(size.height)],
          padding: fit.padding ?? PixelPadding(0), maxZoom: fit.maxZoom, window: window)
      else { return nil }
      let framed = CameraPose(
        center: viewport.center, zoom: viewport.zoom, pitch: Double(mapView.camera.pitch),
        bearing: 0)
      camera = framed
      holding = false
      mapView.setCamera(
        mapCamera(framed), withDuration: fit.duration.map(Self.seconds) ?? Self.easeDuration,
        animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
      return framed
    }

    func holdsLayer(_ id: String) -> Bool {
      mapView.style?.layer(withIdentifier: id) != nil
    }

    func holdsSource(_ id: String) -> Bool {
      mapView.style?.source(withIdentifier: id) != nil
    }

    func renderedFeatures(at point: [Double], in layers: [String]) -> [QueriedFeature] {
      guard point.count > 1, let style = mapView.style else { return [] }
      let at = CGPoint(x: point[0], y: point[1])
      // MapLibre answers a feature with no layer, so each layer is asked alone, the topmost first,
      // which keeps the features of a layer drawn above another before that other's.
      let asked = style.layers.reversed().filter { layer in
        layers.contains { sameText($0, layer.identifier) }
      }
      return asked.flatMap { layer in
        mapView.visibleFeatures(at: at, styleLayerIdentifiers: [layer.identifier]).compactMap {
          queriedFeature($0, layer: layer)
        }
      }
    }

    var symbolLabels: [SymbolLabel] {
      guard let style = mapView.style else { return [] }
      return style.layers.compactMap { layer in
        guard let symbol = layer as? MLNSymbolStyleLayer else { return nil }
        guard let written = writtenLabels[symbol.identifier] ?? symbol.text else { return nil }
        writtenLabels[symbol.identifier] = written
        guard let label = jsonValue(written.mgl_jsonExpressionObject) else { return nil }
        return SymbolLabel(id: symbol.identifier, textField: label)
      }
    }

    func relabel(_ id: String, to label: JSONValue?) {
      guard let symbol = mapView.style?.layer(withIdentifier: id) as? MLNSymbolStyleLayer else {
        return
      }
      if let label {
        symbol.text = NSExpression(mglJSONObject: foundationObject(label))
      } else if let written = writtenLabels[id] {
        symbol.text = written
      }
    }

    var creditedBaseSources: [CreditedSource] {
      guard let style = mapView.style else { return [] }
      let zoom = mapView.zoomLevel
      // A style's sources keep no order MapLibre publishes, so each is read in the order the first
      // layer drawing it is drawn, bottom to top.
      var order: [String] = []
      var drawnSources: Set<String> = []
      for case let layer as MLNForegroundStyleLayer in style.layers {
        guard let source = layer.sourceIdentifier, self.layers[layer.identifier] == nil else {
          continue
        }
        if !order.contains(source) {
          order.append(source)
        }
        if layer.isVisible, zoom >= Double(layer.minimumZoomLevel),
          zoom < Double(layer.maximumZoomLevel)
        {
          drawnSources.insert(source)
        }
      }
      return order.compactMap { id in
        guard self.sources[id] == nil,
          let source = style.source(withIdentifier: id) as? MLNTileSource
        else { return nil }
        return CreditedSource(
          attribution: source.attributionHTMLString, isDrawn: drawnSources.contains(id))
      }
    }

    func mapMoved() {
      // A move with no layout of the map's own reaches none of its view's methods, so the view
      // measures its safe area again once the drawing under way ends.
      (mapView as? MeasuredMapView)?.measureLater()
    }

    /// jump moves MapLibre's camera to `pose` at once. MapLibre's camera holds its eye's altitude,
    /// so a tilt changes the zoom it shows: the tilt is set first, and the center, the zoom and the
    /// bearing over it.
    private func jump(to pose: CameraPose) {
      let pitched = mapView.camera
      pitched.pitch = pose.pitch
      mapView.setCamera(pitched, animated: false)
      mapView.setCenter(
        CLLocationCoordinate2D(latitude: pose.center[1], longitude: pose.center[0]),
        zoomLevel: pose.zoom, direction: pose.bearing, animated: false)
    }

    /// mapCamera is MapLibre's camera looking at `pose` from the altitude its zoom stands for on
    /// this view.
    private func mapCamera(_ pose: CameraPose) -> MLNMapCamera {
      let center = CLLocationCoordinate2D(latitude: pose.center[1], longitude: pose.center[0])
      return MLNMapCamera(
        lookingAtCenter: center,
        altitude: MLNAltitudeForZoomLevel(
          pose.zoom, CGFloat(pose.pitch), center.latitude, mapView.bounds.size),
        pitch: CGFloat(pose.pitch), heading: pose.bearing)
    }

    /// queriedFeature is a feature MapLibre found, as a query answers it, drawn by `layer`, or nil
    /// for one whose geometry it cannot write.
    private func queriedFeature(_ feature: any MLNFeature, layer: MLNStyleLayer) -> QueriedFeature?
    {
      guard
        let written = feature.geoJSONDictionary()["geometry"],
        JSONSerialization.isValidJSONObject(written),
        let data = try? JSONSerialization.data(withJSONObject: written),
        let geometry = try? JSONDecoder().decode(GeoJSONGeometry.self, from: data)
      else { return nil }
      var id: QueriedFeature.ID?
      switch feature.identifier {
      case let number as NSNumber where CFGetTypeID(number) != CFBooleanGetTypeID():
        id = .number(number.doubleValue)
      case let text as String:
        id = .string(text)
      default:
        id = nil
      }
      var properties: [String: JSONValue] = [:]
      for (name, value) in feature.attributes {
        if let read = jsonValue(value) {
          properties[name] = read
        }
      }
      return QueriedFeature(
        id: id, properties: properties, geometry: geometry, layer: layer.identifier,
        sourceLayer: (layer as? MLNVectorStyleLayer)?.sourceLayerIdentifier)
    }

    private static func seconds(_ duration: Duration) -> TimeInterval {
      let (seconds, attoseconds) = duration.components
      return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
  }

  // MARK: - What happens on the map

  extension MapRenderer {
    /// projection is MapLibre's projection of the map as it is drawn, from a position to the point
    /// of the view it is drawn at and back, which an edit's magnet measures in (`map.edit.snap`).
    var projection: ScreenProjection {
      let mapView = mapView
      return ScreenProjection(
        point: { position in
          let coordinate = CLLocationCoordinate2D(
            latitude: position.count > 1 ? position[1] : 0, longitude: position.first ?? 0)
          let point = mapView.convert(coordinate, toPointTo: mapView)
          return [Double(point.x), Double(point.y)]
        },
        position: { point in
          let drawn = CGPoint(x: point.first ?? 0, y: point.count > 1 ? point[1] : 0)
          let coordinate = mapView.convert(drawn, toCoordinateFrom: mapView)
          return [coordinate.longitude, coordinate.latitude]
        })
    }

    /// snapped places a point the pointer holds at `position` as an edit's magnet places it, on the
    /// nearest point of `lines` as the map draws them where it lies within the magnet's radius on
    /// the screen, and under the pointer otherwise (`map.edit.snap`).
    func snapped(_ position: [Double], onto lines: [[[Double]]]) -> EditSnap {
      snapToActiveSegments(position, segments: lines, projection: projection)
    }

    @objc private func recognized(_ recognizer: UITapGestureRecognizer) {
      guard recognizer.state == .ended else { return }
      tapped(at: recognizer.location(in: mapView))
    }

    @objc private func pressed(_ recognizer: UILongPressGestureRecognizer) {
      guard recognizer.state == .began else { return }
      pressed(at: recognizer.location(in: mapView))
    }

    /// hovered tells the engine of a pointer hovering at a point of the view, and of its leaving.
    /// A pointer hovers without pressing alone, a trackpad's, a mouse's or a pencil's over the
    /// screen; a finger never does, so a touch screen tells no hover.
    @objc private func hovered(_ recognizer: UIHoverGestureRecognizer) {
      let point = recognizer.location(in: mapView)
      switch recognizer.state {
      case .began, .changed: hovered(at: point)
      case .ended, .cancelled, .failed: left(at: point)
      default: break
      }
    }

    /// tapped tells the engine of a tap at `point` of the view, which places the waypoint being
    /// edited or is told as a tap, and as the features it landed on.
    func tapped(at point: CGPoint) {
      engine.tapped(at: [Double(point.x), Double(point.y)], position: position(at: point))
    }

    /// pressed tells the engine of a long press at `point` of the view, which is told as a long tap
    /// where no edit takes it.
    func pressed(at point: CGPoint) {
      engine.longTapped(at: [Double(point.x), Double(point.y)], position: position(at: point))
    }

    /// hovered tells the engine a hovering pointer moved to `point` of the view, which the next
    /// frame tells with the features of an itinerary under it.
    func hovered(at point: CGPoint) {
      engine.pointerMoved(to: [Double(point.x), Double(point.y)], position: position(at: point))
      awaitFrame()
    }

    /// left tells the engine a hovering pointer left the view at `point`.
    func left(at point: CGPoint) {
      engine.pointerLeft(at: [Double(point.x), Double(point.y)], position: position(at: point))
    }

    /// frameDrawn tells the engine a frame was drawn while a hovering pointer waits on one, and
    /// stops counting frames once none waits.
    @objc func frameDrawn() {
      engine.frameDrawn()
      if engine.hovering == nil {
        frames?.invalidate()
        frames = nil
      }
    }

    /// claims is the beginnings of the addresses this map's requests are made at, by which the
    /// request hook tells it a failed answer: each tile template of its own sources up to its first
    /// `{`, and its style's directory, the style's address before any query up to and including its
    /// last `/`, which holds what a Mountaya terrain's style names, its tiles, sprites and glyphs.
    /// They are read once for the sources and the style drawn, and read again, `claims` told to the
    /// probe, once a state drawn changes either.
    var claims: [String] {
      if let heldClaims {
        return heldClaims
      }
      probe?.report("claims")
      var prefixes = (drawn?.sources ?? []).flatMap(tileTemplates).map {
        String($0.prefix { $0 != "{" })
      }
      if let style = drawn?.style, let directory = Self.directory(of: style) {
        prefixes.append(directory)
      }
      let claims = prefixes.filter { !$0.isEmpty }
      heldClaims = claims
      return claims
    }

    /// directory is the directory `url` lies in: its address before any query or fragment, up to
    /// and including the last `/` after its host, or nil where its path holds none.
    static func directory(of url: URL) -> String? {
      let address = url.absoluteString.prefix { $0 != "?" && $0 != "#" }
      guard let host = address.range(of: "://")?.upperBound,
        let slash = address[host...].lastIndex(of: "/")
      else { return nil }
      return String(address[...slash])
    }

    /// failed tells the engine one of the map's own requests failed, to `url` with `status`, from
    /// the source of the map's own whose tiles it was where its address is one of theirs, the
    /// request having left under a credential the client no longer sends where `superseded` is
    /// true, and never having left where `cause`, what the read of its credential threw, is given.
    func failed(url: URL, status: Int?, superseded: Bool, cause: (any Error)? = nil) {
      let address = url.absoluteString
      let source = drawn?.sources.first { source in
        tileTemplates(of: source).contains { template in
          let prefix = template.prefix { $0 != "{" }
          return !prefix.isEmpty && address.hasPrefix(prefix)
        }
      }
      engine.requestFailed(
        url: address, status: status, source: source?.id, superseded: superseded, cause: cause)
    }

    /// position is the place MapLibre reads at `point` of the view, its longitude as it reads it.
    private func position(at point: CGPoint) -> [Double] {
      let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
      return [coordinate.longitude, coordinate.latitude]
    }

    /// awaitFrame counts the frames MapLibre's view draws until the engine is told the next one.
    private func awaitFrame() {
      guard frames == nil else { return }
      let link = CADisplayLink(target: self, selector: #selector(frameDrawn))
      link.add(to: .main, forMode: .common)
      frames = link
    }

    @objc private func showCredits() {
      var responder: UIResponder? = mapView
      while let next = responder?.next, !(next is UIViewController) {
        responder = next
      }
      guard let presenter = responder?.next as? UIViewController else { return }
      presenter.present(
        creditSheet(engine.credits) { url in UIApplication.shared.open(url) }, animated: true)
    }

    private func tileTemplates(of source: MapSource) -> [String] {
      switch source.kind {
      case .vector(let tiles, _), .raster(let tiles, _, _), .rasterDem(let tiles, _, _): tiles
      case .geoJson: []
      }
    }
  }

  // MARK: - Markers and the camera's limits

  extension MapRenderer {
    /// annotate shows the state's markers, the last one on top, and the pin of the waypoint being
    /// placed above them, in one change to what was shown before: a marker shown already is kept,
    /// moved to where it stands now and given its label, a marker whose look changed shows the pin
    /// of its new look, and only a marker the state adds is added and only one it drops removed.
    /// Where the markers kept change their order, every one is shown again, so the last is on top.
    func annotate(_ state: MapState) {
      var shown: [String: MarkerAnnotation] = [:]
      var draft: DraftAnnotation?
      for annotation in annotations {
        if let marker = annotation as? MarkerAnnotation {
          shown[marker.id] = marker
        } else if let pin = annotation as? DraftAnnotation {
          draft = pin
        }
      }
      let wanted = Set(state.markers.map(\.id))
      let keptBefore = annotations.compactMap { ($0 as? MarkerAnnotation)?.id }
        .filter { wanted.contains($0) }
      let keptAfter = state.markers.map(\.id).filter { shown[$0] != nil }
      guard keptBefore == keptAfter else {
        mapView.removeAnnotations(annotations)
        annotations = state.markers.map(MarkerAnnotation.init)
        if let position = state.waypointEdit?.position, position.count > 1 {
          annotations.append(DraftAnnotation(position))
        }
        mapView.addAnnotations(annotations)
        return
      }
      var next: [MLNPointAnnotation] = []
      var added: [MLNPointAnnotation] = []
      for marker in state.markers {
        guard let annotation = shown.removeValue(forKey: marker.id) else {
          let annotation = MarkerAnnotation(marker)
          added.append(annotation)
          next.append(annotation)
          continue
        }
        annotation.show(marker)
        if annotation.color != marker.color || annotation.glyph != marker.glyph {
          annotation.color = marker.color
          annotation.glyph = marker.glyph
          (mapView.view(for: annotation) as? MarkerPinView)?.image = pinImage(of: annotation)
        }
        next.append(annotation)
      }
      var removed: [MLNPointAnnotation] = Array(shown.values)
      if let position = state.waypointEdit?.position, position.count > 1 {
        if let draft, sameNumbers(draft.position, position) {
          next.append(draft)
        } else {
          if let draft {
            removed.append(draft)
          }
          let placed = DraftAnnotation(position)
          added.append(placed)
          next.append(placed)
        }
      } else if let draft {
        removed.append(draft)
      }
      mapView.removeAnnotations(removed)
      mapView.addAnnotations(added)
      annotations = next
    }

    /// restyle shows the pins of a new accent: the look of the markers naming no colour drawn once
    /// in it and set on each such marker's view, and the waypoint being placed shown again with its
    /// ring in it.
    func restyle() {
      for case let marker as MarkerAnnotation in annotations where marker.color == nil {
        (mapView.view(for: marker) as? MarkerPinView)?.image = pinImage(of: marker)
      }
      guard let draft = annotations.lazy.compactMap({ $0 as? DraftAnnotation }).first else {
        return
      }
      let placed = DraftAnnotation(draft.position)
      annotations = annotations.map { $0 === draft ? placed : $0 }
      mapView.removeAnnotation(draft)
      mapView.addAnnotation(placed)
    }

    /// hold hands MapLibre's map the state's pan lock and zoom range where they changed, and
    /// answers whether they did.
    private func hold(_ state: MapState, after before: MapState?) -> Bool {
      var changed = false
      if before == nil || before?.zoomBounds != state.zoomBounds {
        changed = true
        // MapLibre Native draws no zoom under 0 and none past 25.5, and refuses a floor above its
        // ceiling, so the ceiling is set first where the floor rises past the one held.
        let floor = Swift.max(state.zoomBounds.minZoom, 0)
        let ceiling = Swift.min(Swift.max(state.zoomBounds.maxZoom, floor), 25.5)
        if floor > mapView.maximumZoomLevel {
          mapView.maximumZoomLevel = ceiling
          mapView.minimumZoomLevel = floor
        } else {
          mapView.minimumZoomLevel = floor
          mapView.maximumZoomLevel = ceiling
        }
      }
      if before == nil ? state.maxBounds != nil : !sameLock(before?.maxBounds, state.maxBounds) {
        changed = true
        if let lock = state.maxBounds, lock.count == 4 {
          let bounds = MLNCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: lock[1], longitude: lock[0]),
            ne: CLLocationCoordinate2D(latitude: lock[3], longitude: lock[2]))
          // MapLibre iOS moves the camera into a lock before it holds the screen within one, so the
          // first lock a map is given holds the camera's center alone until the camera next moves,
          // and the view shows up to half its size past the lock. Handed over again, the lock holds
          // what the view shows at once, as every later one does.
          mapView.maximumScreenBounds = bounds
          mapView.maximumScreenBounds = bounds
        } else {
          mapView.maximumScreenBounds = unlocked
        }
      }
      return changed
    }

    /// reportHeldCamera tells the engine where MapLibre holds the camera, where its limits moved it
    /// from `wanted`, so the state is the map as it is shown. It tells nothing where the engine no
    /// longer holds `wanted`: a camera the app set since is the one to show, and the renderer moves
    /// to it as it draws the state that holds it.
    private func reportHeldCamera(_ wanted: CameraPose) {
      // A map not yet laid out holds no camera worth reading.
      guard mapView.bounds.width > 0, mapView.bounds.height > 0 else { return }
      // The engine's states reach the renderer through a stream, so the engine may already hold a
      // camera the app set after the state drawn; held over it, the report would undo it.
      guard engine.state.camera == wanted else { return }
      let shown = pose
      let tolerance = 1e-7
      guard shown.center.count > 1, wanted.center.count > 1 else { return }
      let moved =
        abs(shown.center[0] - wanted.center[0]) > tolerance
        || abs(shown.center[1] - wanted.center[1]) > tolerance
        || abs(shown.zoom - wanted.zoom) > tolerance
      guard moved else { return }
      holding = false
      camera = shown
      engine.cameraMoved(to: shown)
    }

    private func sameLock(_ a: [Double]?, _ b: [Double]?) -> Bool {
      switch (a, b) {
      case (nil, nil): return true
      case (let a?, let b?): return sameNumbers(a, b)
      default: return false
      }
    }
  }

  /// MarkerAnnotation is a marker as MapLibre shows it: at its position, its label held as its
  /// title, which assistive technologies read, and drawn by the view beside it once a tap falls on
  /// it. A position's altitude, its third number, is left out: a marker stands flat on the map. It
  /// is made and read on the main actor by the renderer alone; MapLibre's annotation class can be
  /// neither isolated nor Sendable.
  final class MarkerAnnotation: MLNPointAnnotation {
    /// id is the marker's id.
    let id: String
    /// color is the marker's color, or nil for the map's accent.
    var color: String?
    /// glyph is the glyph the marker's pin carries, or nil for a dot.
    var glyph: String?

    init(_ marker: MapMarker) {
      id = marker.id
      color = marker.color
      glyph = marker.glyph
      super.init()
      show(marker)
    }

    required init?(coder: NSCoder) {
      nil
    }

    /// show moves the annotation to where `marker` stands and gives it the marker's label, each
    /// set only where it changed, so MapLibre moves only a marker that moved.
    func show(_ marker: MapMarker) {
      let moved = CLLocationCoordinate2D(
        latitude: marker.position[1], longitude: marker.position[0])
      if coordinate.latitude != moved.latitude || coordinate.longitude != moved.longitude {
        coordinate = moved
      }
      if title != marker.label {
        title = marker.label
      }
    }
  }

  /// DraftAnnotation is the pin of the waypoint being placed. It is made and read on the main actor
  /// by the renderer alone; MapLibre's annotation class can be neither isolated nor Sendable.
  final class DraftAnnotation: MLNPointAnnotation {
    /// position is where the waypoint being placed stands, as the state gave it.
    let position: [Double]

    init(_ position: [Double]) {
      self.position = position
      super.init()
      coordinate = CLLocationCoordinate2D(latitude: position[1], longitude: position[0])
    }

    required init?(coder: NSCoder) {
      nil
    }
  }

  /// PinLook is what a marker's pin looks like: the pin its marker describes, and the accent it is
  /// drawn on where it names no colour of its own, nil where it names one.
  struct PinLook: Hashable {
    let pin: MarkerPin
    let accent: HexColor?
  }

  /// MarkerPinView is how a marker is shown: its pin, centred on its position, over a soft shadow
  /// that lifts it off the map, as the web map's pin is (`map.marker.pin`). An image of a look that
  /// changed is shown in place of the one before. It is bound to the main actor, as every UIKit
  /// view is.
  final class MarkerPinView: MLNAnnotationView {
    /// image is the pin as drawn.
    var image: UIImage {
      didSet { show(image) }
    }

    init(_ image: UIImage) {
      self.image = image
      super.init(reuseIdentifier: nil)
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOpacity = 0.35
      layer.shadowOffset = CGSize(width: 0, height: 1)
      layer.shadowRadius = 2
      show(image)
    }

    required init?(coder: NSCoder) {
      nil
    }

    /// show draws `image` as the view, at its size, over a shadow of its disc.
    private func show(_ image: UIImage) {
      frame = CGRect(origin: frame.origin, size: image.size)
      layer.contents = image.cgImage
      layer.contentsScale = image.scale
      layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }
  }

  /// DraftPinView is how the waypoint being placed is shown: a white disc ringed in the accent. It
  /// is bound to the main actor, as every UIKit view is.
  final class DraftPinView: MLNAnnotationView {
    init(accent: HexColor) {
      super.init(reuseIdentifier: nil)
      frame = CGRect(x: 0, y: 0, width: 24, height: 24)
      layer.cornerRadius = 12
      layer.borderWidth = 4
      backgroundColor = .white
      layer.borderColor = (uiColor(accent.hex, opacity: accent.opacity) ?? .systemBlue).cgColor
    }

    required init?(coder: NSCoder) {
      nil
    }
  }

  /// Following is a task following one of an engine's streams, cancelled once the renderer holding
  /// it is let go, which ends the task's stream. It is Sendable: it holds one constant, the task.
  private final class Following: Sendable {
    let task: Task<Void, Never>

    init(_ task: Task<Void, Never>) {
      self.task = task
    }

    deinit {
      task.cancel()
    }
  }

  /// styleKeys is the name MapLibre gives each style property whose name is not its style name
  /// written in camel case, the same across the range this package takes.
  private let styleKeys: [String: String] = [
    "circle-pitch-scale": "circleScaleAlignment",
    "circle-translate": "circleTranslation",
    "circle-translate-anchor": "circleTranslationAnchor",
    "fill-antialias": "fillAntialiased",
    "fill-extrusion-translate": "fillExtrusionTranslation",
    "fill-extrusion-translate-anchor": "fillExtrusionTranslationAnchor",
    "fill-extrusion-vertical-gradient": "fillExtrusionHasVerticalGradient",
    "fill-translate": "fillTranslation",
    "fill-translate-anchor": "fillTranslationAnchor",
    "icon-allow-overlap": "iconAllowsOverlap",
    "icon-ignore-placement": "iconIgnoresPlacement",
    "icon-image": "iconImageName",
    "icon-keep-upright": "keepsIconUpright",
    "icon-rotate": "iconRotation",
    "icon-size": "iconScale",
    "icon-translate": "iconTranslation",
    "icon-translate-anchor": "iconTranslationAnchor",
    "line-dasharray": "lineDashPattern",
    "line-translate": "lineTranslation",
    "line-translate-anchor": "lineTranslationAnchor",
    "raster-brightness-max": "maximumRasterBrightness",
    "raster-brightness-min": "minimumRasterBrightness",
    "raster-hue-rotate": "rasterHueRotation",
    "raster-resampling": "rasterResamplingMode",
    "symbol-avoid-edges": "symbolAvoidsEdges",
    "text-allow-overlap": "textAllowsOverlap",
    "text-field": "text",
    "text-font": "textFontNames",
    "text-ignore-placement": "textIgnoresPlacement",
    "text-justify": "textJustification",
    "text-keep-upright": "keepsTextUpright",
    "text-max-angle": "maximumTextAngle",
    "text-max-width": "maximumTextWidth",
    "text-rotate": "textRotation",
    "text-size": "textFontSize",
    "text-translate": "textTranslation",
    "text-translate-anchor": "textTranslationAnchor",
    "text-writing-mode": "textWritingModes",
  ]

  /// styleKey is the name MapLibre gives a style property: its own where it has one, and the style
  /// name in camel case otherwise, `line-color` read as `lineColor`.
  private func styleKey(_ name: String) -> String {
    if let key = styleKeys[name] {
      return key
    }
    var key = ""
    var raise = false
    for character in name {
      if character == "-" {
        raise = true
      } else {
        key += raise ? character.uppercased() : String(character)
        raise = false
      }
    }
    return key
  }

  /// literalArrays are the style properties a list of words is a value of, never an expression.
  private let literalArrays: Set<String> = [
    "text-font", "text-variable-anchor", "text-writing-mode",
  ]

  /// styleValue is a property's value as MapLibre reads an expression of it: a color written as a
  /// string handed to MapLibre's own style parser, which reads it as a style document's color,
  /// and a list that is a value rather than an expression held as a literal. Every other value is
  /// the expression it is.
  ///
  /// MapLibre takes a constant color as a platform color alone, and casts a string to one through
  /// no conversion it supports, so a color written as a string is the one argument of a
  /// `coalesce`, which its parser reads as the style document's color it is.
  private func styleValue(_ value: JSONValue, of name: String) -> JSONValue {
    switch value {
    case .string where name.hasSuffix("-color"):
      return .array([.string("coalesce"), value])
    case .array(let elements):
      guard let first = elements.first else { return .array([.string("literal"), value]) }
      if case .string = first {
        let words = elements.allSatisfy { element in
          if case .string = element { return true }
          return false
        }
        return literalArrays.contains(name) && words ? .array([.string("literal"), value]) : value
      }
      return .array([.string("literal"), value])
    default:
      return value
    }
  }

  /// foundationObject is a JSON value as Foundation's JSON objects write it, which MapLibre reads.
  private func foundationObject(_ value: JSONValue) -> Any {
    switch value {
    case .null: NSNull()
    case .bool(let flag): NSNumber(value: flag)
    case .number(let number): NSNumber(value: number)
    case .string(let text): text
    case .array(let elements): elements.map(foundationObject)
    case .object(let members): members.mapValues(foundationObject)
    }
  }

  /// jsonValue is a Foundation JSON object as a JSON value, or nil for one that is no JSON.
  private func jsonValue(_ object: Any) -> JSONValue? {
    switch object {
    case is NSNull:
      return .null
    case let number as NSNumber:
      return CFGetTypeID(number) == CFBooleanGetTypeID()
        ? .bool(number.boolValue) : .number(number.doubleValue)
    case let text as String:
      return .string(text)
    case let elements as [Any]:
      var values: [JSONValue] = []
      for element in elements {
        guard let value = jsonValue(element) else { return nil }
        values.append(value)
      }
      return .array(values)
    case let members as [String: Any]:
      var values: [String: JSONValue] = [:]
      for (name, member) in members {
        guard let value = jsonValue(member) else { return nil }
        values[name] = value
      }
      return .object(values)
    default:
      return nil
    }
  }

  /// FeatureCollection is GeoJSON features as RFC 7946 writes them, for MapLibre to read.
  private struct FeatureCollection: Encodable {
    let type = "FeatureCollection"
    let features: [Feature]
  }

  /// Feature is one GeoJSON feature as RFC 7946 writes it, a geometry of none written as `null`.
  private struct Feature: Encodable {
    let type = "Feature"
    let geometry: GeoJSONGeometry?
    let properties: [String: JSONValue]

    init(_ feature: GeoJSONFeature) {
      geometry = feature.geometry
      properties = feature.properties
    }

    enum CodingKeys: String, CodingKey {
      case type, geometry, properties
    }

    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(type, forKey: .type)
      try container.encode(geometry, forKey: .geometry)
      try container.encode(properties, forKey: .properties)
    }
  }
#endif
