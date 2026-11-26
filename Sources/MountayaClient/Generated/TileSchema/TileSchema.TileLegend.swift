// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Legend describing how to read a layer's symbology: the localized title, the
  /// measurement unit, and the ordered color steps. Used to render a map legend UI;
  /// not consumed by the map style itself.
  public struct TileLegend: Sendable, Hashable, Codable {
    /// How the legend is laid out: `row` draws the steps below as an ordered row
    /// of color swatches, and `compass` as a compass dial, for a directional
    /// overlay such as aspect/slope.
    public var kind: TileSchema.TileLegendKind?
    /// The legend's title and step labels per language. A language absent here is
    /// null rather than missing, which is the case to fall back from.
    public var locales: TileSchema.Locales
    /// Ordered color stops mapping a value (or bucket) to the color the layer
    /// paints for it, from low to high. Drives a graduated or categorical legend.
    public var steps: [TileSchema.TileLegendStep]?
    /// The unit the step values are measured in, for the suffix a legend prints
    /// beside each one. Absent when the steps are categories rather than
    /// quantities.
    public var unit: TileSchema.UnitLegend?

    /// Creates a `TileLegend` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      locales: TileSchema.Locales,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.kind = nil
      self.locales = locales
      self.steps = nil
      self.unit = nil
      configure(&self)
    }

    /// Reads a `TileLegend` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.kind = try container.decodeIfPresent(TileSchema.TileLegendKind.self, forKey: "kind")
      self.locales = try container.decode(TileSchema.Locales.self, forKey: "locales")
      self.steps = try container.decodeIfPresent([TileSchema.TileLegendStep].self, forKey: "steps")
      self.unit = try container.decodeIfPresent(TileSchema.UnitLegend.self, forKey: "unit")
    }

    /// Writes a `TileLegend` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.kind, forKey: "kind")
      try container.encode(self.locales, forKey: "locales")
      try container.encodeIfPresent(self.steps, forKey: "steps")
      try container.encodeIfPresent(self.unit, forKey: "unit")
    }
  }
}
