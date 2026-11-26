// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/tokens.json`, model digest
// f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and printed
// again (SPEC.md section 3).

/// ElementLayout is every measure the elements are laid out by, as the contract's tokens table's
/// `layout` group names them, each spelled in camel case: a length in logical pixels, the unit an
/// iOS point is, and a count of columns where its name ends in `columns`. They read alike in both
/// schemes, and every other size is each platform's own.
package enum ElementLayout {
  /// panelLayerCardColumns is the measure `panel-layer-card-columns`, a count of columns.
  package static let panelLayerCardColumns = 3
  /// panelLayerCardHeight is the measure `panel-layer-card-height`, in logical pixels.
  package static let panelLayerCardHeight: Double = 77
  /// panelLayerCardWidth is the measure `panel-layer-card-width`, in logical pixels.
  package static let panelLayerCardWidth: Double = 98
  /// panelNarrowBottomInset is the measure `panel-narrow-bottom-inset`, in logical pixels.
  package static let panelNarrowBottomInset: Double = 16
  /// panelNarrowMapWidth is the measure `panel-narrow-map-width`, in logical pixels.
  package static let panelNarrowMapWidth: Double = 576
  /// panelPictureHeight is the measure `panel-picture-height`, in logical pixels.
  package static let panelPictureHeight: Double = 52
  /// panelPictureHeightNarrow is the measure `panel-picture-height-narrow`, in logical pixels.
  package static let panelPictureHeightNarrow: Double = 40
  /// panelPreferenceCardColumns is the measure `panel-preference-card-columns`, a count of columns.
  package static let panelPreferenceCardColumns = 2
  /// panelPreferenceCardHeight is the measure `panel-preference-card-height`, in logical pixels.
  package static let panelPreferenceCardHeight: Double = 57
  /// panelPreferenceCardWidth is the measure `panel-preference-card-width`, in logical pixels.
  package static let panelPreferenceCardWidth: Double = 152
  /// panelWidth is the measure `panel-width`, in logical pixels.
  package static let panelWidth: Double = 340
  /// readoutWidth is the measure `readout-width`, in logical pixels.
  package static let readoutWidth: Double = 288
  /// watermarkInset is the measure `watermark-inset`, in logical pixels.
  package static let watermarkInset: Double = -4
  /// watermarkWidth is the measure `watermark-width`, in logical pixels.
  package static let watermarkWidth: Double = 180

  /// measures is each measure by the name the table gives it.
  package static let measures: [String: Double] = [
    "panel-layer-card-columns": 3,
    "panel-layer-card-height": 77,
    "panel-layer-card-width": 98,
    "panel-narrow-bottom-inset": 16,
    "panel-narrow-map-width": 576,
    "panel-picture-height": 52,
    "panel-picture-height-narrow": 40,
    "panel-preference-card-columns": 2,
    "panel-preference-card-height": 57,
    "panel-preference-card-width": 152,
    "panel-width": 340,
    "readout-width": 288,
    "watermark-inset": -4,
    "watermark-width": 180,
  ]
}
