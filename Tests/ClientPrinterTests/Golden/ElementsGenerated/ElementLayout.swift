// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/tokens.json`, model digest
// c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and printed
// again (SPEC.md section 3).

/// ElementLayout is every measure the elements are laid out by, as the contract's tokens table's
/// `layout` group names them, each spelled in camel case: a length in logical pixels, the unit an
/// iOS point is, and a count of columns where its name ends in `columns`. They read alike in both
/// schemes, and every other size is each platform's own.
package enum ElementLayout {
  /// panelLayerCardColumns is the measure `panel-layer-card-columns`, a count of columns.
  package static let panelLayerCardColumns = 3
  /// panelWidth is the measure `panel-width`, in logical pixels.
  package static let panelWidth: Double = 340
  /// watermarkInset is the measure `watermark-inset`, in logical pixels.
  package static let watermarkInset: Double = -4

  /// measures is each measure by the name the table gives it.
  package static let measures: [String: Double] = [
    "panel-layer-card-columns": 3,
    "panel-width": 340,
    "watermark-inset": -4,
  ]
}
