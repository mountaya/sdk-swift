#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import SwiftUI

  /// TouchTarget pads what it modifies to the platform's touch target, at least 44 points each way,
  /// centred in it, and takes a press anywhere in that span: a 32-point chip, a clear button or a
  /// retry keeps the look it is drawn with and is pressed as easily as a control.
  ///
  /// It lays the padding out, transparent, so a view under it is not covered by another's span, and
  /// it is applied to a button's label, whose shape is what the button takes a press in.
  struct TouchTarget: ViewModifier {
    /// side is the least a touch target spans each way, in points, the platform's guidelines'.
    static var side: CGFloat { 44 }

    func body(content: Content) -> some View {
      content
        .frame(minWidth: Self.side, minHeight: Self.side)
        .contentShape(Rectangle())
    }
  }

  extension View {
    /// touchTarget pads this view to the platform's touch target, at least 44 points each way, and
    /// takes a press anywhere in it (`TouchTarget`).
    func touchTarget() -> some View {
      modifier(TouchTarget())
    }
  }
#endif
