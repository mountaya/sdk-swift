/// LayersPanelChoice is the choice a section of a layers picker makes (`geo.layers.picker-rows`),
/// its raw value the contract's spelling: one base map among the catalogue's terrains, each
/// enrichment on or off by itself, one classic overlay among every classic category's at once, or
/// the instant the time pins.
public enum LayersPanelChoice: String, Sendable, Hashable, CaseIterable {
  /// terrain is one base map among the catalogue's terrains.
  case terrain
  /// overlay is one classic overlay among those of every classic category.
  case overlay
  /// enrichment is each enrichment of a category whose overlays stack, on or off by itself.
  case enrichment
  /// time is the instant a time slider pins, a section of no row (`geo.layers.time-slider`).
  case time
}
