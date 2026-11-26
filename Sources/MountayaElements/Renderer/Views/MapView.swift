#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MapLibre
  public import SwiftUI
  import MountayaClient
  import MountayaGeo

  /// MapView is a map, in SwiftUI over MapLibre Native: it draws the state a `MapEngine` holds,
  /// its base map, its camera, its labels and every source and layer above the base map in the
  /// order the one layer registry ranks them, and tells the engine where the reader moved the
  /// camera to.
  ///
  /// The map's own requests, for its style, its tiles, its sprites and its glyphs, carry the
  /// engine's client's credential and language where they go to the Tile API, and nothing where
  /// they go to any other host. They are MapLibre's, made by its own loader on its own schedule:
  /// none waits for a first session token, none is reported to the client's `onResponse`, and
  /// each is repeated as MapLibre repeats a failed request (SPEC.md section 11).
  ///
  /// ```swift
  /// struct TrailMap: View {
  ///   @State private var map = MapEngine(client: mountaya)
  ///
  ///   var body: some View {
  ///     MapView(map)
  ///       .ignoresSafeArea()
  ///       .task { try? await map.setTerrain() }
  ///   }
  /// }
  /// ```
  ///
  /// Its markers are drawn in the elements' tokens around it, read under the colour scheme in
  /// force: a marker naming no colour, and the waypoint being placed, in the `accent`
  /// (`mountayaTokens(_:)`, `geo.style.theme-tokens`).
  ///
  /// `onReady` is handed MapLibre's own map once its first style is loaded, which is how an app
  /// reaches what this view does not wrap: it is the one place a MapLibre type is published, and
  /// an app that reaches it declares MapLibre too, within the range this package takes.
  ///
  /// `onTap` is handed each tap on the map, the place tapped and the marker it fell on, where it
  /// fell on one, whose label the view then shows beside it, inside the safe area and clear of the
  /// watermark's frame, a tap anywhere else taking the label off; a tap while the engine places a waypoint places it instead, and is told to no handler. `onCameraChange` is handed the camera each time it comes to rest, after the reader
  /// moved it or the app did; the engine's `state` holds the camera the reader moved too.
  ///
  /// ```swift
  /// MapView(map, onTap: { tap in selected = tap.marker }, onCameraChange: { camera = $0 })
  /// ```
  ///
  /// It reads its engine's organization once it is first drawn (`MapEngine.loadOrganization()`),
  /// and again whenever it is handed another engine, and draws the Mountaya watermark in the
  /// top-left corner of its safe area, the part of the map the device leaves visible, so a map drawn
  /// full bleed under `ignoresSafeArea()` shows it below the status bar and beside a notch or a
  /// display cutout, in a layout that runs right to left too, clipped to the map, over its canvas
  /// and its markers and under its popups and panels, each of which keeps clear of it, unless the
  /// organization holds white label (`geo.organization.watermark`): the glyph
  /// table's `watermark` drawing, 180 points wide, linked to Mountaya's site in the scope's
  /// language, which a press opens in the device's browser through the system's own opener. While
  /// the read waits, the mark is held off for one attempt's time budget at most, 35 seconds unless
  /// the client names another, and drawn once it has passed, until an answer says white label.
  /// Nothing the app states takes the mark off or opens its link elsewhere, and the answer serves
  /// the mark alone: the map's units, language, base map and accent are the app's, else the SDK's
  /// own. A snapshot of MapLibre's own map, taken through what `onReady` hands, records its canvas
  /// alone, without the mark.
  ///
  /// A right-click or a long press opens a readout of the point, 288 points wide, its top-left corner
  /// at the point, unless `readout` turns it off (`map.readout.open`): the point of interest, the
  /// classic overlay's band, the terrain read off the elevation tiles, the moment the map shows, live
  /// on the clock of its environment and in the time zone the device keeps, a moment it cannot
  /// write there left out, the coordinates with a copy button, and the zone
  /// (`geo.readout.rows`), in the scope's words and the SDK's default units, flipped left or up to
  /// stay inside the map's safe area and moved clear of the watermark's frame by the smallest move,
  /// the frame held clear from the map's first drawing until its organization answers white label,
  /// and cut by the map's edge where no place inside the safe area clears the frame.
  /// `MapEngine.organizationRead` says where that read stands, and `watermarkClearance` how far below
  /// the safe area's top the frame ends, so the app keeps its own views clear of the mark too. A tap
  /// closes it, and so does a camera move as it starts.
  public struct MapView: View {
    private let engine: MapEngine
    private let readout: Bool
    private let onReady: ((MLNMapView) -> Void)?
    private let onTap: ((MapTap) -> Void)?
    private let onCameraChange: ((CameraPose) -> Void)?
    /// callout is the label of the marker tapped last, which the renderer writes and the view draws
    /// over the watermark.
    @State private var callout = MarkerCallout()

    /// Creates a view drawing `engine`'s map, which opens a readout on a long press unless
    /// `readout` is false, calls `onReady` with MapLibre's own map once its first style is loaded,
    /// `onTap` with each tap no edit takes, and `onCameraChange` with the camera each time it comes
    /// to rest.
    public init(
      _ engine: MapEngine, readout: Bool = true, onReady: ((MLNMapView) -> Void)? = nil,
      onTap: ((MapTap) -> Void)? = nil, onCameraChange: ((CameraPose) -> Void)? = nil
    ) {
      self.engine = engine
      self.readout = readout
      self.onReady = onReady
      self.onTap = onTap
      self.onCameraChange = onCameraChange
    }

    /// body is the map's canvas, and over it the watermark, the label of the marker tapped last and
    /// the readout, in that order from the bottom. The canvas and its chrome are made anew for
    /// another engine, so a view handed one draws it and tells it where it stands, the engine it
    /// drew before being drawn by no view, and the engine shown reads its organization as it appears
    /// and as it takes another's place.
    public var body: some View {
      MapCanvas(
        engine: engine, readout: readout, callout: callout, onReady: onReady, onTap: onTap,
        onCameraChange: onCameraChange
      )
      .id(ObjectIdentifier(engine))
      .overlay(alignment: .topLeading) {
        // A chrome made anew for another engine tells it where the map stands, which the frame
        // left as it was would not.
        MapChrome(engine: engine, callout: callout).id(ObjectIdentifier(engine))
      }
      .task(id: ObjectIdentifier(engine)) {
        callout.show(nil)
        engine.beginOrganizationRead()
      }
    }
  }

  /// MapCanvas is MapLibre's map a `MapView` draws on, which the renderer draws its engine's state
  /// on.
  struct MapCanvas: UIViewRepresentable {
    let engine: MapEngine
    let readout: Bool
    /// callout is the label of the marker tapped last, which the renderer writes.
    let callout: MarkerCallout
    let onReady: ((MLNMapView) -> Void)?
    let onTap: ((MapTap) -> Void)?
    let onCameraChange: ((CameraPose) -> Void)?

    /// makeCoordinator makes the renderer that draws the engine's state for the view's life.
    func makeCoordinator() -> Coordinator {
      Coordinator(
        renderer: MapRenderer(
          engine: engine, onReady: onReady, onTap: onTap, onCameraChange: onCameraChange,
          callout: callout))
    }

    /// makeUIView hands SwiftUI MapLibre's map, which the renderer draws.
    func makeUIView(context: Context) -> MLNMapView {
      context.coordinator.renderer.mapView
    }

    /// updateUIView hands the renderer the handlers SwiftUI drew the view with last, and the accent
    /// the tokens around it read under the colour scheme in force, and tells the engine whether the
    /// reader asked for reduced motion, which lands every move a control starts at once, and
    /// whether a long press opens a readout; the renderer draws every state the engine reports, as
    /// it reports it.
    func updateUIView(_ uiView: MLNMapView, context: Context) {
      let renderer = context.coordinator.renderer
      renderer.onTap = onTap
      renderer.onCameraChange = onCameraChange
      renderer.accent = themeTokenValue(
        context.environment.mountayaTokens.accent,
        in: themeScheme(context.environment.colorScheme))
      engine.reducesMotion = context.environment.accessibilityReduceMotion
      engine.isReadoutOn = readout
    }

    /// dismantleUIView tells the engine its map is drawn by no view as SwiftUI lets the view go,
    /// unless another view draws it since (`MapEngine.unshown(by:)`), so a control stack over it
    /// keeps to its own space.
    static func dismantleUIView(_ uiView: MLNMapView, coordinator: Coordinator) {
      coordinator.renderer.engine.unshown(by: coordinator.renderer)
    }

    /// Coordinator keeps the renderer of one view for as long as SwiftUI keeps the view. It is
    /// bound to the main actor, where SwiftUI makes and keeps it.
    @MainActor
    final class Coordinator {
      let renderer: MapRenderer

      init(renderer: MapRenderer) {
        self.renderer = renderer
      }
    }
  }
#elseif os(iOS) && !targetEnvironment(macCatalyst)
  /// MapView is the map an iOS app shows, which this build of the package leaves out: it is linked
  /// by the package's `Elements` trait, off by default, so an app that shows no map resolves none
  /// of what it needs.
  @available(
    *, unavailable,
    message:
      "MapView needs sdk-swift's Elements trait: depend on the package with traits: [\"Elements\"], or turn the trait on in the Xcode project's package settings."
  )
  public struct MapView: Sendable {}
#else
  /// MapView is the map an iOS app shows, which this platform has none of: the map library under
  /// it ships for iOS alone.
  @available(
    *, unavailable,
    message:
      "MapView draws in an iOS app built with sdk-swift's Elements trait; on this platform, hold the map's state with MapEngine and draw it with the platform's own frameworks."
  )
  public struct MapView: Sendable {}
#endif
