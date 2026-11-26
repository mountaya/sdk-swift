// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A single legend entry pairing a color with the value or bucket it represents.
  public struct TileLegendStep: Sendable, Hashable, Codable {
    /// CSS color the layer paints for this step (e.g. "#1c7ed6"). Matches the
    /// color used in the layer's paint expression.
    ///
    /// Case-insensitive, unlike the colors on an itinerary's segments, waypoints
    /// and segment groups. Those are values a caller wrote, normalized to the
    /// six-digit lowercase form on the
    /// way in; this one is read from the layer's own palette and served in
    /// whatever case that palette is written in. Compare these case-insensitively
    /// rather than by string equality.
    public var color: String
    /// Label for the value or bucket this color represents, such as a threshold
    /// like "20" or a range like "25 - 30". It is the same in every language:
    /// the legend's translated text is in its `locales`.
    public var step: String

    /// Creates a `TileLegendStep` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      color: String,
      step: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.color = color
      self.step = step
      configure(&self)
    }

    /// Reads a `TileLegendStep` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.color = try container.decode(String.self, forKey: "color")
      self.step = try container.decode(String.self, forKey: "step")
    }

    /// Writes a `TileLegendStep` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.color, forKey: "color")
      try container.encode(self.step, forKey: "step")
    }
  }
}
