/// layersPanelPress is what a press on `row` of a layers picker's section making `choice` asks
/// for (`geo.layers.picker-rows`): the report of the entry where the row shows its lock, which
/// selects nothing, and otherwise the command of the row's choice with its slug, which the layers
/// selection carries out (`LayersSelectionEngine`).
public func layersPanelPress(_ choice: LayersPanelChoice, row: LayersPanelRow)
  -> LayersPanelPress
{
  row.mark == .lock ? .locked(row.slug) : .command(choice, slug: row.slug)
}
