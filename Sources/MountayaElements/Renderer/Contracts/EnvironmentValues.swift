#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  extension EnvironmentValues {
    /// mountayaClock is the clock the elements under it read the time through: a `LayersPanel`'s
    /// time section lays its track out around its reading each time it is drawn
    /// (`geo.layers.time-window`), so the window follows the clock with no timer of its own. It is
    /// the system's wall clock where no view states another; a host that pins or replays time
    /// states its own, and the window, the thumb's readout and a release's pin move with it.
    ///
    /// ```swift
    /// LayersPanel(selection: layers, offersTime: true)
    ///   .environment(\.mountayaClock, replayClock)
    /// ```
    public var mountayaClock: any WallClock {
      get { self[ClockKey.self] }
      set { self[ClockKey.self] = newValue }
    }

    /// mountayaScope is the elements scope every element under it reads
    /// (`geo.i18n.nested-scope`): the language its words are in, the locale its figures are
    /// written in, the words themselves, and the glyph sets its controls and its markers draw
    /// with. It is `ElementsScope.standard` where no view states one, and `mountayaScope(_:)`
    /// nests a scope in the one around a view.
    public var mountayaScope: ElementsScope {
      get { self[ScopeKey.self].value }
      set { self[ScopeKey.self] = SharedScope(newValue) }
    }

    /// sharedScope is `mountayaScope` held by one reference, which the views of the elements read
    /// their scope through (`SharedScope`).
    var sharedScope: SharedScope {
      self[ScopeKey.self]
    }

    /// mountayaTokens is the design tokens every element under it is drawn with, read under the
    /// scheme it is drawn in (`geo.style.theme-tokens`), the map's markers among them. It is
    /// `ElementTokens.standard` where no view states others, and `mountayaTokens(_:)` states them.
    public var mountayaTokens: ElementTokens {
      get { self[TokensKey.self].value }
      set { self[TokensKey.self] = SharedTokens(newValue) }
    }

    /// sharedTokens is `mountayaTokens` held by one reference, which the views of the elements read
    /// their tokens through (`SharedTokens`).
    var sharedTokens: SharedTokens {
      self[TokensKey.self]
    }

    /// mountayaOpenPanel is the panel open in the control stack around a view, which every panel
    /// control under it opens in place of any other, or nil outside a stack.
    var mountayaOpenPanel: Binding<MapPanel?>? {
      get { self[OpenPanelKey.self] }
      set { self[OpenPanelKey.self] = newValue }
    }

    /// renderProbe is the probe the views under it report their evaluations to, which a test
    /// installs and nothing else does: nil in an app.
    var renderProbe: RenderProbe? {
      get { self[RenderProbeKey.self] }
      set { self[RenderProbeKey.self] = newValue }
    }

    /// panelTogglePress is what the toggle rows of the panel around a view press through, a row's
    /// id, nil for the row over them all: the points-of-interest panel's rows, and the layers
    /// panel's switches, each its enrichment's slug; nil outside one. A row reaches it here rather than holding it, since
    /// SwiftUI draws again a view holding a reference whenever its parent draws, and a value in the
    /// environment is read again only where it changes.
    var panelTogglePress: PanelPress<String?>? {
      get { self[PanelTogglePressKey.self] }
      set { self[PanelTogglePressKey.self] = newValue }
    }

    /// panelLayout is how the panels a control stack opens lay out over its map
    /// (`geo.panels.layout`), which `MapControls` states from the map's size and the inset of its
    /// toggles, and nil outside a stack, where a panel lays out as on a wide map.
    var panelLayout: PanelLayout? {
      get { self[PanelLayoutKey.self] }
      set { self[PanelLayoutKey.self] = newValue }
    }

    /// panelWidth is the width a panel of the stack around a view is drawn at: the layout's own,
    /// or the width its corner leaves on a narrow map; nil outside a stack.
    var panelWidth: Double? {
      get { self[PanelWidthKey.self] }
      set { self[PanelWidthKey.self] = newValue }
    }

    /// layersPanelPress is what the cards of the layers panel around a view press through, what a
    /// card's press asks for, or nil outside one, reached here as `panelTogglePress` is.
    var layersPanelPress: PanelPress<LayersPanelPress>? {
      get { self[LayersPanelPressKey.self] }
      set { self[LayersPanelPressKey.self] = newValue }
    }
  }

  extension View {
    /// mountayaScope nests an elements scope stating `statement` in the one around this view
    /// (`scopeOf(_:stating:)`): every element under it reads the settings the statement states, and
    /// every other one from the scope around it. A view's own words, `words`, localise that view
    /// alone.
    ///
    /// ```swift
    /// ZoomControl(map: map)
    ///   .mountayaScope(ElementsScopeStatement(words: .bySection(["controls": ["zoomIn": "Plus"]])))
    /// ```
    public func mountayaScope(_ statement: ElementsScopeStatement) -> some View {
      modifier(ScopeStatement(statement: statement))
    }

    /// mountayaTokens draws every element under this view with `tokens`, each read under the
    /// scheme it is drawn in: a token a consumer sets whole stands in both schemes, and one the
    /// table states reads its dark value under the dark scheme (`geo.style.theme-tokens`).
    ///
    /// ```swift
    /// var tokens = ElementTokens.standard
    /// tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
    /// MapView(map).mountayaTokens(tokens)
    /// ```
    public func mountayaTokens(_ tokens: ElementTokens) -> some View {
      environment(\.mountayaTokens, tokens)
    }
  }

  /// ClockKey holds the clock of a view's environment, the system's wall clock unless a view states
  /// another.
  private struct ClockKey: EnvironmentKey {
    static let defaultValue: any WallClock = SystemWallClock()
  }

  /// ScopeKey holds the elements scope of a view's environment, by reference.
  private struct ScopeKey: EnvironmentKey {
    static let defaultValue = SharedScope.standard
  }

  /// TokensKey holds the design tokens of a view's environment, by reference.
  private struct TokensKey: EnvironmentKey {
    static let defaultValue = SharedTokens.standard
  }

  /// OpenPanelKey holds the panel open in the control stack around a view.
  private struct OpenPanelKey: EnvironmentKey {
    static var defaultValue: Binding<MapPanel?>? { nil }
  }

  /// RenderProbeKey holds the probe the views under it report to, none unless a test installs one.
  private struct RenderProbeKey: EnvironmentKey {
    static var defaultValue: RenderProbe? { nil }
  }

  /// PanelTogglePressKey holds the press of the toggle rows of the panel around a view.
  private struct PanelTogglePressKey: EnvironmentKey {
    static var defaultValue: PanelPress<String?>? { nil }
  }

  /// PanelLayoutKey holds how the panels of the stack around a view lay out, none outside one.
  private struct PanelLayoutKey: EnvironmentKey {
    static var defaultValue: PanelLayout? { nil }
  }

  /// PanelWidthKey holds the width the panels of the stack around a view are drawn at.
  private struct PanelWidthKey: EnvironmentKey {
    static var defaultValue: Double? { nil }
  }

  /// LayersPanelPressKey holds the press of the layers panel around a view.
  private struct LayersPanelPressKey: EnvironmentKey {
    static var defaultValue: PanelPress<LayersPanelPress>? { nil }
  }

  /// ScopeStatement nests a scope stating `statement` in the one around the view it modifies.
  private struct ScopeStatement: ViewModifier {
    let statement: ElementsScopeStatement
    @Environment(\.sharedScope) private var outer

    func body(content: Content) -> some View {
      content.environment(\.mountayaScope, scopeOf(outer.value, stating: statement))
    }
  }
#endif
