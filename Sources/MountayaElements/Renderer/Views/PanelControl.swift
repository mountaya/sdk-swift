#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  public import SwiftUI

  /// PanelControl is a control that opens a panel of its own beside it, floating over the map, and
  /// closes it again: the layers, points-of-interest and preferences toggles of `MapControls`, or a
  /// panel of the app's own.
  ///
  /// In a control stack, it opens its panel in place of any other the stack holds open, so one
  /// panel is open at a time, the stack's own and the app's alike, and the stack draws it over the
  /// map beside the toggle, level with it and toward the inside of the map, laid out from where it
  /// stands (`geo.panels.layout`). Anywhere else it holds its own, and draws it beside its chip the
  /// same way, toward the inside of the safe area of the window it stands in, as its window reports
  /// it, and clear of the Mountaya watermark's frame a waiting read holds from that safe area's
  /// top-left corner, below the frame and never to its right (`sdk/SPEC.md` §15), since a control
  /// out of any stack knows no map whose read could release it; while it stands in no window, it
  /// draws the panel under its chip. Its button is held while the panel is open, and read so by
  /// assistive technologies. Its label names it, and its help, which a pointer hovering over it
  /// shows, describes it. `.disabled(true)` disables it.
  ///
  /// ```swift
  /// MapControls(map, zoom: true) {
  ///   PanelControl("filters", label: "Filters", glyph: "controls") {
  ///     Text("Only open huts")
  ///   }
  /// }
  /// ```
  public struct PanelControl<Content: View>: View {
    private let panel: MapPanel
    private let label: String
    private let glyph: String
    private let help: String
    private let content: Content
    /// isChipped is whether the control stands on a chip of its own, where it stands alone, or on
    /// the chip of a group it stands in.
    private let isChipped: Bool

    @Environment(\.mountayaOpenPanel) private var stack
    @Environment(\.sharedScope) private var scope
    @State private var isOpenAlone = false

    /// Creates the control of `panel`, labelled `label`, drawing the glyph `glyph` of the scope's
    /// control set and described by `help`, which opens a panel showing `content`.
    public init(
      _ panel: MapPanel, label: String, glyph: String, help: String = "",
      @ViewBuilder content: () -> Content
    ) {
      self.init(panel, label: label, glyph: glyph, help: help, isChipped: true, content: content)
    }

    /// Creates the control of `panel`, on a chip of its own where `isChipped` says so.
    init(
      _ panel: MapPanel, label: String, glyph: String, help: String, isChipped: Bool,
      @ViewBuilder content: () -> Content
    ) {
      self.panel = panel
      self.label = label
      self.glyph = glyph
      self.help = help
      self.isChipped = isChipped
      self.content = content()
    }

    /// body is the control's glyph, on a chip where it stands alone, its panel told to the stack
    /// around it while open, or drawn beside its chip where no stack stands around it
    /// (`AlonePanel`).
    public var body: some View {
      let isOpen = Self.isOpen(panel, in: stack, alone: isOpenAlone)
      if isChipped {
        ControlChip { toggleButton(isOpen: isOpen) }
          .modifier(
            AlonePanel(
              isAlone: stack == nil, panel: isOpen && stack == nil ? AnyView(content) : nil))
      } else {
        toggleButton(isOpen: isOpen)
      }
    }

    /// toggleButton is the control's button, which tells the stack around it where it stands and
    /// what its panel shows while it is open.
    private func toggleButton(isOpen: Bool) -> some View {
      ControlButton(label: label, help: help, isHeld: isOpen, action: toggle) {
        Glyph(glyph, in: scope.controlGlyphs, size: 20, ink: .foreground)
      }
      .anchorPreference(key: OpenPanelPreference.self, value: .bounds) { bounds in
        isOpen && stack != nil
          ? OpenPanelPreference.Open(panel: panel, toggle: bounds, content: AnyView(content)) : nil
      }
    }

    /// toggle opens the panel, in place of any other the stack holds open, or closes it.
    func toggle() {
      if let stack {
        Self.toggle(panel, in: stack)
      } else {
        isOpenAlone.toggle()
      }
    }

    /// isOpen is whether `panel` is open: the one the stack holds open, or, out of any stack, the
    /// control's own word.
    static func isOpen(_ panel: MapPanel, in stack: Binding<MapPanel?>?, alone: Bool) -> Bool {
      guard let stack else { return alone }
      return stack.wrappedValue == panel
    }

    /// toggle opens `panel` in `stack`, in place of any other, or closes it where it is the one
    /// open.
    static func toggle(_ panel: MapPanel, in stack: Binding<MapPanel?>) {
      stack.wrappedValue = stack.wrappedValue == panel ? nil : panel
    }
  }

  /// AlonePanel draws the panel a `PanelControl` out of any stack opens, `panel` while it is open,
  /// beside the control it modifies, toward the inside of the safe area of the window the control
  /// stands in, as its window reports it, level with it, laid out from where it stands and clear of
  /// the Mountaya watermark's frame a waiting read holds from that safe area's top-left corner,
  /// below the frame and never to its right (`frame(in:height:)`, `sdk/SPEC.md` §15), its content in
  /// the reader's direction; while the control stands in no window, it draws the panel under it. It
  /// reads the control's window only where the control stands alone, `isAlone`, and holds where it
  /// stands and how tall the panel was laid out, so the control, generic over its content, holds
  /// neither.
  struct AlonePanel: ViewModifier {
    let isAlone: Bool
    let panel: AnyView?

    @Environment(\.layoutDirection) private var direction
    /// window is where the control stands in its window, nil while it stands in no window.
    @State private var window: WindowPlacement?
    /// moved is where the control stands in SwiftUI's global space, which tells its window's reader
    /// of a move with no layout of its own.
    @State private var moved = CGRect.zero
    /// height is how tall the panel was laid out last, nil before it was.
    @State private var height: CGFloat?

    func body(content: Content) -> some View {
      content
        .overlay {
          if let panel {
            // The panel is placed by the window's own coordinates, which run from its left edge
            // whatever the reader's direction.
            Color.clear
              .allowsHitTesting(false)
              .overlay(alignment: .topLeading) { placed(panel) }
              .environment(\.layoutDirection, .leftToRight)
          }
        }
        .background {
          if isAlone {
            // The probe marks the control's top-left corner, which the window's coordinates read.
            Color.clear
              .overlay(alignment: .topLeading) {
                WindowProbe(moved: moved) { placed in
                  window = placed
                }
              }
              .environment(\.layoutDirection, .leftToRight)
          }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
          proxy.frame(in: .global)
        } action: { frame in
          if isAlone { moved = frame }
        }
        .onChange(of: panel == nil) {
          height = nil
        }
    }

    /// placed is `panel` where `frame(in:height:)` places it, from the control's top-left corner,
    /// or under the control while it stands in no window.
    @ViewBuilder
    private func placed(_ panel: AnyView) -> some View {
      if let window {
        let placed = Self.frame(in: window, height: height)
        panel
          .environment(\.panelLayout, placed.layout)
          .environment(\.panelWidth, placed.width)
          .environment(\.layoutDirection, direction)
          .fixedSize()
          .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
          } action: { laid in
            height = laid
          }
          .offset(x: placed.x - window.view.x, y: placed.y - window.view.y)
      } else {
        panel
          .environment(\.layoutDirection, direction)
          .fixedSize()
          .offset(y: ControlButton<EmptyView>.side + CGFloat(panelGap))
      }
    }

    /// frame is where the panel of a control out of any stack opens, the control standing in its
    /// window as `window` says and the panel `height` tall where it was laid out, in the window's
    /// coordinates (`sdk/SPEC.md` §15): beside the control, toward the inside of the part of the
    /// window the device leaves visible, and clear of the frame a waiting read holds from that
    /// part's top-left corner, below it and never to its right (`panelPlacement`), since a control
    /// out of any stack knows no map whose read could release it.
    static func frame(in window: WindowPlacement, height: CGFloat?) -> PanelPlacement {
      let visible = window.visible
      let corner = PixelPadding(top: visible.y, right: 0, bottom: 0, left: visible.x)
      let frame = isWatermarkKeptClear(.waiting) ? watermarkFrame(safeArea: corner) : nil
      return panelPlacement(
        beside: window.view, within: visible, panelHeight: height.map(Double.init), clearOf: frame)
    }
  }
#endif
