#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// FocusRing draws the ring a control carries while it holds the keyboard's focus around what it
  /// modifies: 2 points wide in the `focus-ring` token under the scheme in force, inside the frame
  /// it is drawn around, so a chip that clips what it holds keeps the ring too (`sdk/SPEC.md` §7).
  ///
  /// The focus is the one the platform's focus system moves, which a hardware keyboard or Full
  /// Keyboard Access moves from control to control, read off the button around what it modifies;
  /// a touch or a pointer presses a control without focusing it, so a press leaves no ring behind
  /// it. The token is a colour of its own, which a consumer's accent does not move, standing at
  /// least 3 to 1 against the panel in both schemes, as WCAG's success criterion 1.4.11 asks of a
  /// focus indicator.
  struct FocusRing: ViewModifier {
    /// width is the ring's width, in points.
    static var width: CGFloat { 2 }

    /// cornerRadius is the radius of the ring's corners, the control's own.
    var cornerRadius: CGFloat = 4
    /// stated is a focus a test states in place of the platform's, nil reading the platform's.
    var stated: Bool?

    @Environment(\.isFocused) private var isFocused
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
      content.overlay {
        if stated ?? isFocused {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
              tokenColor(tokens.focusRing, in: themeScheme(colorScheme)), lineWidth: Self.width
            )
            .allowsHitTesting(false)
        }
      }
    }
  }

  extension View {
    /// focusRing draws the focus ring around this view while the button around it holds the
    /// keyboard's focus, its corners of `cornerRadius` (`FocusRing`).
    func focusRing(cornerRadius: CGFloat = 4) -> some View {
      modifier(FocusRing(cornerRadius: cornerRadius))
    }
  }
#endif
