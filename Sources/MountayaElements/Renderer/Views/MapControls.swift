#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// MapControls is a map's floating control stack, laid over the map in one of its corners, top
  /// right unless the app names another. From the top it reads: the zoom pair; the layers,
  /// points-of-interest and preferences toggles as one group; the app's own controls; geolocate;
  /// the compass.
  ///
  /// Each flag has a fixed default, the set a new organization's embed shows, and a flag the app
  /// states, true or false, stands: the zoom, the compass, the layers toggle and the preferences
  /// toggle show unless the app turns them off, and the locate control, the points-of-interest
  /// toggle and the layers panel's time are offered only where the app turns them on. Nothing is
  /// read from the map's organization, so what the stack shows is read off the app's code.
  ///
  /// ```swift
  /// MapView(map)
  ///   .overlay {
  ///     MapControls(map, geolocate: true) {
  ///       DownloadControl { exporting = true }
  ///     }
  ///   }
  /// ```
  ///
  /// Each control drives the map unless a handler of the app's stands in for its default, which a
  /// stack composed of `ZoomControl`, `CompassControl`, `GeolocateControl` and `PanelControl` takes;
  /// an action control, `DownloadControl` or `DirectionsControl`, drives only its handler.
  /// `.disabled(true)` shuts every control under it.
  ///
  /// A toggle opens its panel in place of any other, so one panel is open at a time, the app's own
  /// panel controls among its controls included. The stack holds which one is open, unless the app
  /// hands `openPanel` to hold it itself. The layers toggle opens a `LayersPanel` over a selection
  /// the stack holds for the map, offering the time where the app says it does, `offersTime`, and
  /// showing the pictures it hands, `thumbnail`, the points-of-interest toggle a `POIPanel` of the map's concepts,
  /// and the preferences toggle a `PreferencesPanel` over `unitPreferences`, or, where the app hands
  /// none, over a set the stack holds itself, in the scope's language, which nothing outside the
  /// panel reads. A language pressed relabels the map either way.
  ///
  /// Its words and its glyphs are the scope's (`mountayaScope(_:)`) and its colours the tokens'
  /// (`mountayaTokens(_:)`), read under the colour scheme in force. The preferences panel's own set
  /// starts at the SDK's default units in the scope's language. A panel opens over the map it is
  /// laid over, beside its toggle and level with it, toward the inside of the map's safe area, and
  /// lays out as the embed's does from where it stands (`geo.panels.layout`); a tap on the map
  /// closes it.
  /// `strings` replaces a word of its controls and its panels where it names the word's path,
  /// `controls.zoomIn`, in every control and panel of its own and in none of the app's.
  ///
  /// The stack and its panels keep to the map's safe area, the inset the operating system reports
  /// and no value of the app's layout, and clear of the Mountaya watermark's frame, from the map's
  /// first drawing until its organization answers white label, so nothing moves as the mark lands
  /// (`sdk/SPEC.md` §15): a stack in any corner stands as far from the frame as from the safe area's
  /// edges, moved by the smallest move that clears it, so one in the top-left corner starts below
  /// the frame, and a panel that would lay over the frame moves below it, never to its right, the
  /// map's edge cutting a panel no place inside the map clears the frame for. The
  /// safe area and the frame are the map's own, read off the view that draws it wherever the stack
  /// is laid, over the map or over a larger space around it. A stack over a map no view draws yet,
  /// or no more, keeps to the safe area of the space it is laid in, as its window reports it, and
  /// holds the frame from that safe area's top-left corner as the map's read holds it
  /// (`isWatermarkKeptClear`), so nothing moves as the map appears; a stack given no map holds it
  /// as a waiting read does. The corners are the ones the reader sees, and the mark stands top
  /// left, in a layout that runs right to left too.
  public struct MapControls<Content: View>: View {
    private let map: MapEngine?
    private let zoom: Bool
    private let compass: Bool
    private let geolocate: Bool
    private let layers: Bool
    private let pois: Bool
    private let preferences: Bool
    private let offersTime: Bool
    private let corner: MapCorner
    private let openPanel: Binding<MapPanel?>?
    private let unitPreferences: Binding<UnitPreferences>?
    private let thumbnail: ((LayersPanelChoice, String) -> Image?)?
    private let strings: [String: String]?
    private let content: Content

    @State private var ownOpenPanel: MapPanel?
    @State private var ownPreferences: UnitPreferences?
    @State private var selection = LayersSelectionEngine()
    @ViewScope private var scope: ElementsScope

    /// Creates the stack over `map`, showing the controls each flag turns on, each at its fixed
    /// default where the app states none, and the app's own `content` among them, in `corner`; the
    /// panel open held in `openPanel` where the app hands it, the preferences panel editing
    /// `unitPreferences` where the app hands them, the layers panel offering the time where
    /// `offersTime` says so and showing the pictures `thumbnail` hands, as `LayersPanel` takes them,
    /// and the words of its own controls and panels replaced by `strings` where it names theirs.
    public init(
      _ map: MapEngine?, zoom: Bool = true, compass: Bool = true, geolocate: Bool = false,
      layers: Bool = true, pois: Bool = false, preferences: Bool = true,
      corner: MapCorner = .topRight, openPanel: Binding<MapPanel?>? = nil,
      unitPreferences: Binding<UnitPreferences>? = nil, offersTime: Bool = false,
      thumbnail: ((LayersPanelChoice, String) -> Image?)? = nil, strings: [String: String]? = nil,
      @ViewBuilder content: () -> Content
    ) {
      self.map = map
      self.zoom = zoom
      self.compass = compass
      self.geolocate = geolocate
      self.layers = layers
      self.pois = pois
      self.preferences = preferences
      self.offersTime = offersTime
      self.corner = corner
      self.openPanel = openPanel
      self.unitPreferences = unitPreferences
      self.thumbnail = thumbnail
      self.strings = strings
      self.content = content()
      _scope = ViewScope(strings: strings)
    }

    /// body is the stack, in its corner of the space it is laid in, and the panel open over that
    /// space (`StackPlacement`).
    public var body: some View {
      let slots = ControlSlot.stack(
        zoom: zoom, layers: layers, pois: pois, preferences: preferences, geolocate: geolocate,
        compass: compass)
      let open = openPanel ?? $ownOpenPanel
      VStack(alignment: .center, spacing: 8) {
        ForEach(slots, id: \.self) { slot in
          switch slot {
          case .zoom:
            ZoomControl(map: map, strings: strings)
          case .panels(let panels):
            ControlChip {
              ForEach(panels, id: \.self) { panel in
                panelControl(panel)
              }
            }
          case .content:
            content
          case .geolocate:
            GeolocateControl(map: map, strings: strings)
          case .compass:
            CompassControl(map: map, strings: strings)
          }
        }
      }
      .environment(\.mountayaOpenPanel, open)
      .modifier(StackPlacement(map: map, corner: corner, open: open.wrappedValue))
      .task(id: ShownMap(map: map.map(ObjectIdentifier.init), hasLayers: layers)) {
        // The selection reads the catalogue only where the layers toggle stands to read it for.
        if layers {
          selection.configure(map: map)
        }
      }
      .task(id: map.map(ObjectIdentifier.init)) {
        // A tap on the map closes the panel open, as a tap outside a popover does.
        guard let map else { return }
        for await event in map.events() {
          if case .tap = event, open.wrappedValue != nil {
            open.wrappedValue = nil
          }
        }
      }
    }

    /// panelControl is the toggle of the panel `panel` names, on the group's chip.
    @ViewBuilder
    private func panelControl(_ panel: MapPanel) -> some View {
      switch panel {
      case .layers:
        PanelControl(
          .layers, label: scope.word("controls.layers"), glyph: "layers",
          help: scope.word("tooltips.layers.description"), isChipped: false
        ) {
          layersPanel(over: selection)
        }
      case .pois:
        PanelControl(
          .pois, label: scope.word("controls.pois"), glyph: "pin",
          help: scope.word("tooltips.pois.description"), isChipped: false
        ) {
          POIPanel(map: map, strings: strings)
        }
      case .preferences:
        PanelControl(
          .preferences, label: scope.word("controls.preferences"), glyph: "preferences",
          help: scope.word("tooltips.preferences.description"), isChipped: false
        ) {
          PreferencesPanel(preferences: unitSet, map: map, strings: strings)
        }
      default:
        EmptyView()
      }
    }

    /// layersPanel is the panel the layers toggle opens over `selection`: offering the time where
    /// the app says it does, `offersTime`, showing the pictures it hands, `thumbnail`, and speaking
    /// the stack's `strings`.
    func layersPanel(over selection: LayersSelectionEngine) -> LayersPanel {
      LayersPanel(
        selection: selection, offersTime: offersTime, thumbnail: thumbnail, strings: strings)
    }

    /// unitSet is the set the preferences panel edits: the app's where it hands one, else the
    /// stack's own, which starts at the SDK's default units in the scope's language.
    private var unitSet: Binding<UnitPreferences> {
      if let unitPreferences { return unitPreferences }
      let language = scope.language.rawValue
      return Binding(
        get: { ownPreferences ?? UnitPreferences(language: language) },
        set: { ownPreferences = $0 })
    }
  }

  /// StackPlacement lays a control stack, the content it modifies, in `corner` of the space it is
  /// laid in, and draws the panel its toggles open over that space, as `MapControls` lays them
  /// (`sdk/SPEC.md` §15): the stack and its panel keep to the safe area and clear of the
  /// watermark's frame, the map's own where a view draws `map`, else the space's own and the frame
  /// the map's read holds, or a waiting read where no map is given
  /// (`keptClear(of:holdsFrame:space:safeArea:)`), and the panel is cut by the map's edge, the
  /// space's own where no view draws the map (`mapRect(_:in:)`). The stack's controls read the
  /// reader's direction, and the stack and its panel are placed by the corners the reader sees, so
  /// what lays them out runs from the left edge whatever it is. It holds where the space stands,
  /// its safe area, the stack's size and the panel's height, so the stack, generic over the app's
  /// controls, holds none of them; `open` is the panel open, whose change lays the next out anew.
  struct StackPlacement: ViewModifier {
    let map: MapEngine?
    let corner: MapCorner
    let open: MapPanel?

    @Environment(\.layoutDirection) private var direction
    /// space is where the stack's space stands, the map it is laid over, in global coordinates,
    /// which its panels lay out over and the map's safe area and the watermark's frame are read
    /// into.
    @State private var space = CGRect.zero
    /// spaceSafeArea is how far inside the edges of the stack's space the part of it the device
    /// leaves visible stands, as its window reports it, none while it is in no window: the safe
    /// area the stack keeps to where no view draws its map.
    @State private var spaceSafeArea = PixelPadding(0)
    /// stackSize is the size the stack's controls take, which tells whether it reaches over the
    /// watermark's frame, zero before it was laid out.
    @State private var stackSize = CGSize.zero
    /// panelHeight is how tall the panel open was laid out last, nil before it was.
    @State private var panelHeight: CGFloat?

    func body(content: Content) -> some View {
      let kept = Self.keptClear(
        of: Self.shown(map), holdsFrame: Self.holdsFrame(map), space: space,
        safeArea: spaceSafeArea)
      let inset = Self.stackPadding(
        corner: corner, space: space.size, room: kept.room, stack: stackSize, clearOf: kept.frame)
      let edge = Self.mapRect(map?.shownMap, in: space)
      let direction = self.direction
      content
        .environment(\.layoutDirection, direction)
        .onGeometryChange(for: CGSize.self) { proxy in
          proxy.size
        } action: { size in
          stackSize = size
        }
        .padding(
          EdgeInsets(
            top: inset.top, leading: inset.left, bottom: inset.bottom, trailing: inset.right)
        )
        .frame(
          maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment(in: .leftToRight)
        )
        .overlayPreferenceValue(OpenPanelPreference.self, alignment: .topLeading) { shown in
          if let shown {
            GeometryReader { proxy in
              panel(
                shown, toggle: proxy[shown.toggle], within: kept.room, clearOf: kept.frame,
                direction: direction)
            }
            // The map's edge cuts a panel that no place inside the map clears the frame for.
            .clipShape(Path(edge))
          }
        }
        .background(alignment: .topLeading) {
          WindowProbe(moved: space) { placed in
            spaceSafeArea = placed?.safeArea ?? PixelPadding(0)
          }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          space = frame
        }
        .environment(\.layoutDirection, .leftToRight)
        .onChange(of: open) {
          panelHeight = nil
        }
    }

    /// shown is what a stack reads of `map` where a view draws it: its safe area and the frame its
    /// read holds clear, each in global coordinates, the frame nil once its organization answers
    /// white label; or nil for no map, or one no view draws (`sdk/SPEC.md` §15).
    static func shown(_ map: MapEngine?) -> (safeArea: ScreenRect, frame: ScreenRect?)? {
      guard let map, let safeArea = map.safeAreaFrame else { return nil }
      return (safeArea, map.watermarkKeptClearFrame)
    }

    /// mapRect is the rect whose edges cut a stack's panels, from the corner of the stack's space,
    /// which stands at `space` in global coordinates: the map's own where a view draws it, `shown`
    /// where that view laid it out, wherever the stack is laid, over the map or over a larger space
    /// around it; and the space itself where none does (`sdk/SPEC.md` §15).
    static func mapRect(_ shown: ScreenRect?, in space: CGRect) -> CGRect {
      guard let shown else { return CGRect(origin: .zero, size: space.size) }
      return MeasuredMapView.cgRect(shown).offsetBy(dx: -space.minX, dy: -space.minY)
    }

    /// holdsFrame is whether a stack over `map` keeps clear of the watermark's frame: as the map's
    /// read stands, whether a view draws the map or none does yet, so nothing moves as the map
    /// appears, and as a waiting read holds it where no map is given, since the stack then knows no
    /// read that could release it (`isWatermarkKeptClear`, `sdk/SPEC.md` §15).
    static func holdsFrame(_ map: MapEngine?) -> Bool {
      isWatermarkKeptClear(map?.organizationRead ?? .waiting)
    }

    /// keptClear answers the part of a stack's space the stack and its panels keep to, `room`, and
    /// the watermark's frame there, which nothing of the stack lays over, `frame`, both from the
    /// space's top-left corner, the space standing at `space` in global coordinates
    /// (`sdk/SPEC.md` §15). Where a view draws its map, `map`, they are the map's own, its safe area
    /// met with the space and the frame its read holds clear, read in global coordinates wherever
    /// the stack is laid, over the map or over a larger space around it, and never measured from the
    /// stack's own box. Where none does, they are the space's own: its safe area, `safeArea` inside
    /// its edges as its window reports it, and the frame from that safe area's top-left corner where
    /// `holdsFrame` says the read holds it (`holdsFrame(_:)`).
    static func keptClear(
      of map: (safeArea: ScreenRect, frame: ScreenRect?)?, holdsFrame: Bool, space: CGRect,
      safeArea: PixelPadding
    ) -> (room: CGRect, frame: CGRect?) {
      let whole = CGRect(origin: .zero, size: space.size)
      guard let map else {
        let room = safeAreaBounds(
          safeArea, width: Double(space.width), height: Double(space.height))
        let frame = holdsFrame ? MeasuredMapView.cgRect(watermarkFrame(safeArea: safeArea)) : nil
        return (MeasuredMapView.cgRect(room), frame)
      }
      let covered = whole.intersection(
        MeasuredMapView.cgRect(map.safeArea).offsetBy(dx: -space.minX, dy: -space.minY))
      return (
        covered.isNull ? whole : covered,
        map.frame.map {
          MeasuredMapView.cgRect($0).offsetBy(dx: -space.minX, dy: -space.minY)
        }
      )
    }

    /// cornerInset is how far a stack stands in from its corner of the safe area, and from the
    /// watermark's frame.
    static var cornerInset: CGFloat { 10 }

    /// stackPadding is how far in from the edges of a space of `space`'s size a stack of `stack`'s
    /// size stands in `corner`, on the two edges that meet there, each as the reader sees it, left and
    /// right whatever way the text runs: `cornerInset` inside `room`, the part of the space the safe
    /// area covers, and moved clear of the watermark's `frame`, grown by `cornerInset`, by the
    /// smallest move that keeps it inside the room (`clearOfWatermark`), whichever corner it sits
    /// in. A stack not laid out yet, of no size, stands in its corner, and so does one in a space too
    /// small to hold the inset.
    static func stackPadding(
      corner: MapCorner, space: CGSize, room: CGRect, stack: CGSize, clearOf frame: CGRect?
    ) -> PixelPadding {
      let inner = room.insetBy(dx: cornerInset, dy: cornerInset)
      guard !inner.isNull else { return PixelPadding(Double(cornerInset)) }
      let isLeft = corner == .topLeft || corner == .bottomLeft
      let isTop = corner == .topLeft || corner == .topRight
      var laid = CGRect(
        x: isLeft ? inner.minX : inner.maxX - stack.width,
        y: isTop ? inner.minY : inner.maxY - stack.height, width: stack.width, height: stack.height)
      if stack != .zero, let frame {
        let kept = clearOfWatermark(
          MeasuredMapView.screenRect(laid),
          frame: MeasuredMapView.screenRect(frame.insetBy(dx: -cornerInset, dy: -cornerInset)),
          within: MeasuredMapView.screenRect(inner))
        laid = CGRect(x: kept.x, y: kept.y, width: kept.width, height: kept.height)
      }
      return PixelPadding(
        top: isTop ? Double(laid.minY) : 0, right: isLeft ? 0 : Double(space.width - laid.maxX),
        bottom: isTop ? 0 : Double(space.height - laid.maxY), left: isLeft ? Double(laid.minX) : 0)
    }

    /// panelFrame is where the panel a toggle standing at `toggle` opens, in a space whose part the
    /// safe area covers is `room`, the panel `height` tall where it was laid out, and kept clear of
    /// the watermark's `frame` by moving below it, never to its right (`panelPlacement`): its
    /// top-left corner and its width, and the most it is tall as its height.
    static func panelFrame(
      beside toggle: CGRect, within room: CGRect, height: CGFloat?, clearOf frame: CGRect?
    ) -> CGRect {
      let placed = panelPlacement(
        beside: MeasuredMapView.screenRect(toggle), within: MeasuredMapView.screenRect(room),
        panelHeight: height.map(Double.init), clearOf: frame.map(MeasuredMapView.screenRect))
      return CGRect(x: placed.x, y: placed.y, width: placed.width, height: placed.layout.maxHeight)
    }

    /// panel draws the panel open beside its toggle, which stands at `toggle` in the stack's space,
    /// inside `room`, the part of it the safe area covers, laid out from where it stands and kept
    /// clear of the watermark's `frame` (`panelPlacement`), its content in the reader's
    /// `direction`.
    private func panel(
      _ shown: OpenPanelPreference.Open, toggle: CGRect, within room: CGRect,
      clearOf frame: CGRect?, direction: LayoutDirection
    ) -> some View {
      let placed = panelPlacement(
        beside: MeasuredMapView.screenRect(toggle), within: MeasuredMapView.screenRect(room),
        panelHeight: panelHeight.map(Double.init), clearOf: frame.map(MeasuredMapView.screenRect))
      return shown.content
        .environment(\.panelLayout, placed.layout)
        .environment(\.panelWidth, placed.width)
        .environment(\.layoutDirection, direction)
        .fixedSize()
        .onGeometryChange(for: CGFloat.self) { proxy in
          proxy.size.height
        } action: { height in
          panelHeight = height
        }
        .offset(x: placed.x, y: placed.y)
        .id(shown.panel)
    }
  }

  /// ShownMap is what the stack's layers selection follows: the map shown, and whether the layers
  /// toggle stands.
  private struct ShownMap: Hashable {
    let map: ObjectIdentifier?
    let hasLayers: Bool
  }

  extension MapControls where Content == EmptyView {
    /// Creates the stack over `map`, showing the controls each flag turns on, each at its fixed
    /// default where the app states none, and none of the app's own, in `corner`; the panel open
    /// held in `openPanel` where the app hands it, the preferences panel editing `unitPreferences`
    /// where the app hands them, the layers panel offering the time where `offersTime` says so and
    /// showing the pictures `thumbnail` hands, and the words of its controls and panels replaced by
    /// `strings` where it names theirs.
    public init(
      _ map: MapEngine?, zoom: Bool = true, compass: Bool = true, geolocate: Bool = false,
      layers: Bool = true, pois: Bool = false, preferences: Bool = true,
      corner: MapCorner = .topRight, openPanel: Binding<MapPanel?>? = nil,
      unitPreferences: Binding<UnitPreferences>? = nil, offersTime: Bool = false,
      thumbnail: ((LayersPanelChoice, String) -> Image?)? = nil, strings: [String: String]? = nil
    ) {
      self.init(
        map, zoom: zoom, compass: compass, geolocate: geolocate, layers: layers, pois: pois,
        preferences: preferences, corner: corner, openPanel: openPanel,
        unitPreferences: unitPreferences, offersTime: offersTime, thumbnail: thumbnail,
        strings: strings
      ) {
        EmptyView()
      }
    }
  }
#endif
