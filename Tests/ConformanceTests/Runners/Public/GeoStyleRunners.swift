import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// styleSegmentColors answers the colour at the case's `index`, over its own `palette` where it
  /// names one, or the `count` colours a batch with the case's `reserved` ones takes. A whole index
  /// within an `Int` reads through the whole-position overload and any other number through the one
  /// that takes any number. The default colour and the lively palette are held to the ones Geo
  /// publishes.
  static let styleSegmentColors = Runner(id: "geo.style.segment-colors", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "defaultSegmentColor": .string(defaultSegmentColor),
        "livelyPalette": GeoFixtures.texts(livelyPalette),
      ])
    let input = fixtureCase.input
    let palette = input["palette"] == nil ? nil : try GeoFixtures.textList(input, at: "palette")
    if let count = try input.optionalInteger(at: "count") {
      let reserved = try GeoFixtures.textList(input, at: "reserved")
      return .value(
        GeoFixtures.texts(
          palette.map { assignDistinctColors(count, reserved: reserved, palette: $0) }
            ?? assignDistinctColors(count, reserved: reserved)))
    }
    let index = try input.number(at: "index")
    let color: String
    switch (Int(exactly: index), palette) {
    case (let whole?, let palette?): color = segmentColorAt(whole, palette: palette)
    case (let whole?, nil): color = segmentColorAt(whole)
    case (nil, let palette?): color = segmentColorAt(index, palette: palette)
    case (nil, nil): color = segmentColorAt(index)
    }
    return .value(.string(color))
  }

  /// styleLabelLanguage answers the language a map labels in for the case's `tag`, or for no tag.
  /// The fallback is held to the language no tag reads, and the languages to the ones Geo labels in.
  static let styleLabelLanguage = Runner(id: "geo.style.label-language", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "fallback": .string(labelLanguage(nil).rawValue),
        "languages": GeoFixtures.texts(labelLanguages.map(\.rawValue)),
      ])
    return .value(.string(labelLanguage(try fixtureCase.input.optionalString(at: "tag")).rawValue))
  }

  /// styleLabelRelabel answers the `text-field` a symbol layer whose label is the case's
  /// `textField` takes to label in its `language`, as JSON writes it, or null where the layer is
  /// left as it is. The label is handed to Geo as the client's `JSONValue`.
  static let styleLabelRelabel = Runner(id: "geo.style.label-relabel", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let written = relabelTextField(
      input["textField"].map(GeoFixtures.json),
      language: RestSchema.Language(rawValue: try input.string(at: "language")))
    return .value(written.map(GeoFixtures.ordered) ?? .null)
  }
}
