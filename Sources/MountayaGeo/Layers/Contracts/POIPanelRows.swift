/// POIPanelRows is what a points-of-interest picker offers (`geo.layers.poi-rows`): its rows, in
/// order, and whether its master row, which turns the whole overlay on and off, is on.
public struct POIPanelRows: Sendable, Hashable {
  /// rows is the picker's rows, in order. None where nothing is drawn, and the picker then shows
  /// nothing.
  public var rows: [POIPanelRow]
  /// isAnyVisible is whether the master row is on: while any row is.
  public var isAnyVisible: Bool

  /// Creates what a picker offers: `rows`, its master row on where `isAnyVisible` says so.
  public init(rows: [POIPanelRow], isAnyVisible: Bool) {
    self.rows = rows
    self.isAnyVisible = isAnyVisible
  }
}
