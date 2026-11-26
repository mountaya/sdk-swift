#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import SwiftUI

  /// OpenPanelPreference carries the panel open in a control stack up to the stack, which draws it
  /// over the map beside its toggle (`geo.panels.layout`): which panel it is, where its toggle
  /// stands and what it shows. One panel is open at a time, so the stack reads the first one told.
  struct OpenPanelPreference: PreferenceKey {
    /// Open is the panel open: its name, its toggle's bounds and its content.
    struct Open {
      let panel: MapPanel
      let toggle: Anchor<CGRect>
      let content: AnyView
    }

    static var defaultValue: Open? { nil }

    static func reduce(value: inout Open?, nextValue: () -> Open?) {
      value = value ?? nextValue()
    }
  }
#endif
