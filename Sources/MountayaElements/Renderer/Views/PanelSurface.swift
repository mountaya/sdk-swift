#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// PanelSurface is the surface a control's panel is drawn on: its ground `panel-bg`, its text
  /// `panel-fg` and its edge `panel-border`, each under the scheme in force, under a title row
  /// naming it where it is given one, its sections top to bottom.
  ///
  /// In a control stack it lays out as the embed's panel does (`geo.panels.layout`): 340 points
  /// wide, or the width its corner leaves on a map no wider than 576, its sections scrolling under
  /// its title row once they are laid out taller than the map's height less its top inset allows.
  /// Outside a stack it is at least 240 points wide and its sections scroll past `maxHeight`, or
  /// past the height it is offered where that is less, so a panel holding many rows never grows
  /// past the screen. A surface whose content scrolls on its own, `scrolls` false, holds it as it
  /// is.
  struct PanelSurface<Content: View>: View {
    /// maxHeight is the tallest a panel outside a stack is drawn before its sections scroll, in
    /// points.
    static var maxHeight: CGFloat { 420 }

    /// titleHeight is the height the title row takes from the panel's.
    static var titleHeight: CGFloat { 44 }

    var title: String? = nil
    var scrolls = true
    @ViewBuilder let content: () -> Content

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.panelLayout) private var layout
    @Environment(\.panelWidth) private var width
    /// isTall is whether the sections were last laid out taller than the panel holds.
    @State private var isTall = false

    /// cap is the tallest the sections are drawn before they scroll.
    private var cap: CGFloat {
      let height = layout.map { CGFloat($0.maxHeight) } ?? Self.maxHeight
      return max(height - (title == nil ? 0 : Self.titleHeight), 0)
    }

    var body: some View {
      let scheme = themeScheme(colorScheme)
      let shape = RoundedRectangle(cornerRadius: 8)
      VStack(alignment: .leading, spacing: 0) {
        if let title {
          Text(verbatim: title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, 12)
            .frame(minHeight: Self.titleHeight, alignment: .leading)
          Divider()
        }
        held
      }
      .frame(width: width.map { CGFloat($0) }, alignment: .leading)
      .frame(minWidth: width == nil ? 240 : nil, alignment: .leading)
      .foregroundStyle(tokenColor(tokens.panelFg, in: scheme))
      .background(tokenColor(tokens.panelBg, in: scheme), in: shape)
      .clipShape(shape)
      .overlay(shape.strokeBorder(tokenColor(tokens.panelBorder, in: scheme)))
    }

    /// The sections, held within the panel's height: as high as they are while they fit, and
    /// scrolling once they are laid out taller.
    @ViewBuilder private var held: some View {
      if scrolls && isTall {
        ScrollView(.vertical) {
          measured
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: cap)
      } else {
        measured
      }
    }

    /// The sections, read for whether they are taller than the panel holds.
    private var measured: some View {
      let tall = $isTall
      let cap = cap
      return sections.onGeometryChange(for: Bool.self) { proxy in
        proxy.size.height > cap
      } action: { isTaller in
        tall.wrappedValue = isTaller
      }
    }

    /// The sections top to bottom, inside the panel's padding.
    private var sections: some View {
      VStack(alignment: .leading, spacing: 12) {
        content()
      }
      .padding(12)
    }
  }

  /// PanelHeading heads a section of a panel, in the `dimmed` token under the scheme in force, and
  /// is read by assistive technologies as a heading.
  struct PanelHeading: View {
    let text: String

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      Text(verbatim: text)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(tokenColor(tokens.dimmed, in: themeScheme(colorScheme)))
        .accessibilityAddTraits(.isHeader)
    }
  }

  /// PanelRow is one row of a panel: its label, and beside it what the row shows, a tick, a lock or
  /// a glyph, pressed as a whole, the platform's touch target high, and read by assistive
  /// technologies as selected while it is checked.
  struct PanelRow<Accessory: View>: View {
    let label: String
    let isChecked: Bool
    let action: () -> Void
    @ViewBuilder let accessory: () -> Accessory

    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("PanelRow " + label)
      Button(action: action) {
        HStack(spacing: 8) {
          Text(verbatim: label)
          Spacer(minLength: 8)
          accessory()
        }
        .frame(minHeight: ControlButton<EmptyView>.side)
        .contentShape(Rectangle())
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
      .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
  }

  /// PanelToggleEntry is one toggle row of a points-of-interest panel, a concept, a group or the row
  /// over them all, each on or off by itself. It shows its label, the glyph it names and its tick
  /// while it is on, and presses through the panel as it is now
  /// (`panelTogglePress`), handing it its id. It holds values alone and reads neither the scope nor
  /// the tokens, whose glyphs `PanelRowMarks` draws, so SwiftUI draws an entry again only where what
  /// it shows changes: a panel drawn again for a sibling's press or its host's own redraw redraws no
  /// row it did not change (`panel-rows` in the contract's `sdk/hot-paths.yaml`).
  ///
  /// SwiftUI compares a view it holds with the one drawn anew byte by byte, the padding between two
  /// fields included, so the fields are laid out with none: the eight-byte ones first, then the
  /// environment's nine, then the flag's one. A field added out of that order makes the entry
  /// unequal to itself at random, which the budget test of the panel's rows reads as a redraw.
  struct PanelToggleEntry: View {
    let label: String
    let glyph: String?
    /// id is the row's id, nil for the row over them all.
    let id: String?

    @Environment(\.panelTogglePress) private var press

    let isOn: Bool

    var body: some View {
      PanelRow(label: label, isChecked: isOn, action: { press?.press(id) }) {
        PanelRowMarks(glyph: glyph, note: nil, isOn: isOn)
      }
    }
  }

  /// PanelRowMarks is what a panel's row shows beside its label: its note, a layers panel's word for
  /// a locked entry, the glyph the row names, and its tick while it is on, each glyph of the scope's
  /// control set.
  struct PanelRowMarks: View {
    let glyph: String?
    let note: String?
    let isOn: Bool

    @Environment(\.sharedScope) private var scope

    var body: some View {
      HStack(spacing: 4) {
        if let note {
          Text(verbatim: note).font(.caption)
        }
        if let glyph {
          Glyph(glyph, in: scope.controlGlyphs, size: 14, ink: .foreground)
        }
        if isOn {
          Glyph("check", in: scope.controlGlyphs, size: 14, ink: .foreground)
        }
      }
    }
  }
#endif
