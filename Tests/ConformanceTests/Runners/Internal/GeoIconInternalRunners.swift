import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// iconsGlyphFallback answers what stands where a glyph the case's set, holding its `held`
  /// glyphs and no other, cannot draw would be, by the case's `surface`: a place's glyph through
  /// `placeGlyph(_:in:)`, a badge's glyph where the set draws it and otherwise the text
  /// `badgeFallback(_:on:)` writes, and a control's glyph where the set draws it and nothing
  /// otherwise, which no rule of Geo's states: a control draws a glyph it holds, as the SwiftUI
  /// `Glyph` view does. The fallback pin is held to the one Geo publishes. The rules are the
  /// views' own, which a consumer only observes, so they are reached as internals.
  static let iconsGlyphFallback = Runner(id: "geo.icons.glyph-fallback", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([:], values: ["fallbackGlyph": .string(waypointFallbackGlyph)])
    let input = fixtureCase.input
    let set = try GeoIconFixtures.set(holding: GeoFixtures.textList(input, at: "held"))
    func glyph(_ name: String?) -> OrderedJSON {
      name.map { .object([OrderedJSON.Member(key: "glyph", value: .string($0))]) } ?? .null
    }
    let surfaces: [String: BadgeSurface] = [
      "badge-cell": .cell, "badge-stack": .stack, "badge-labelled": .labelled,
    ]
    let surface = try input.string(at: "surface")
    switch surface {
    case "place":
      return .value(glyph(placeGlyph(try input.optionalString(at: "glyph"), in: set)))
    case "control":
      let name = try input.string(at: "glyph")
      return .value(glyph(set.markup[name] == nil ? nil : name))
    default:
      guard let badge = surfaces[surface] else {
        throw FixtureError(description: "`\(surface)` is no surface a glyph stands on")
      }
      let name = amenityGlyph(RestSchema.WaypointAmenity(rawValue: try input.string(at: "amenity")))
      if set.markup[name] != nil {
        return .value(glyph(name))
      }
      return .value(
        badgeFallback(try input.string(at: "name"), on: badge).map {
          .object([OrderedJSON.Member(key: "text", value: .string($0))])
        } ?? .null)
    }
  }
}
