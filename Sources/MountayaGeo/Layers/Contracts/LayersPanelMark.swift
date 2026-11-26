/// LayersPanelMark is what a row of a layers picker shows beside its label
/// (`geo.layers.picker-rows`), its raw value the contract's spelling.
public enum LayersPanelMark: String, Sendable, Hashable, CaseIterable {
  /// lock is an entry out of the viewer's reach, shown whether or not the selection holds it.
  case lock
  /// tick is an entry the selection holds.
  case tick
}
