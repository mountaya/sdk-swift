#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// ControlButton is one button of a map's controls: a square the platform's touch target across,
  /// its face drawn in the elements' tokens under the scheme in force, named to assistive
  /// technologies by its label and described by its help, which a pointer hovering over it shows.
  ///
  /// Its face is drawn in `control-fg`, in `accent` while what it asked for is out, and in
  /// `control-fg-disabled` while it is disabled, by its own flag or any around it; its ground is
  /// the chip's around it, `control-bg-hover` while a pointer hovers over it or its panel is open;
  /// and it carries the focus ring while it holds the keyboard's focus.
  struct ControlButton<Face: View>: View {
    /// side is the button's side, the touch target the platform's guidelines name, in points.
    static var side: CGFloat { 44 }

    let label: String
    let help: String
    var isBusy = false
    var isHeld = false
    let action: () -> Void
    @ViewBuilder let face: () -> Face

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.renderProbe) private var probe
    @State private var isHovered = false

    var body: some View {
      let _ = probe?.report("ControlButton " + label)
      let scheme = themeScheme(colorScheme)
      Button(action: action) {
        face()
          .frame(width: Self.side, height: Self.side)
          .foregroundStyle(
            tokenColor(
              tokens.value[keyPath: Self.faceToken(isEnabled: isEnabled, isBusy: isBusy)],
              in: scheme)
          )
          .background {
            if let ground = Self.groundToken(isHovered: isHovered, isHeld: isHeld) {
              tokenColor(tokens.value[keyPath: ground], in: scheme)
            }
          }
          .contentShape(Rectangle())
      }
      .buttonStyle(ElementButtonStyle())
      .focusEffectDisabled()
      .onHover { isHovered = $0 }
      .help(Text(verbatim: help))
      .accessibilityLabel(Text(verbatim: label))
      .accessibilityHint(Text(verbatim: help))
      .accessibilityAddTraits(isHeld ? .isSelected : [])
    }

    /// faceToken is the token a control's face is drawn in: disabled, busy, or neither.
    static func faceToken(isEnabled: Bool, isBusy: Bool)
      -> KeyPath<ElementTokens, ThemeToken<HexColor>>
    {
      if !isEnabled { return \.controlFgDisabled }
      return isBusy ? \.accent : \.controlFg
    }

    /// groundToken is the token a control's ground is drawn in where it draws one of its own: while
    /// a pointer hovers over it or its panel is open, and none otherwise, the chip's showing.
    static func groundToken(isHovered: Bool, isHeld: Bool)
      -> KeyPath<ElementTokens, ThemeToken<HexColor>>?
    {
      isHovered || isHeld ? \.controlBgHover : nil
    }
  }

  /// ElementButtonStyle draws a button of the elements as its label draws it, in the tokens the
  /// label reads, and no look of the platform's over it: a disabled control is drawn in its own
  /// disabled colour, never dimmed again, and a pressed one is drawn as it stands. While the button
  /// holds the keyboard's focus its label carries the focus ring, `FocusRing`, around it where
  /// `ringsLabel` says so, and a label that draws a chip inside a touch target wider than it puts
  /// the ring on the chip itself, `focusRing(cornerRadius:)`. A button drawn in it turns the
  /// platform's own focus effect off, so the ring is the one focus indicator it shows.
  struct ElementButtonStyle: ButtonStyle {
    var ringsLabel = true

    func makeBody(configuration: Configuration) -> some View {
      configuration.label.modifier(FocusRing(stated: ringsLabel ? nil : false))
    }
  }
#endif
