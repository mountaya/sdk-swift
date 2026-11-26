// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The visual theme an embed renders with, part of an organization's Map
  /// Publishing settings. It carries colors, and it is an object rather than a
  /// color scale hoisted onto the settings so that a typographic or spacing
  /// dimension is an added property rather than a reshaped one.
  public struct EmbeddedStudioTheme: Sendable, Hashable, Codable {
    /// The color scale an embed renders with.
    public var colors: RestSchema.EmbeddedStudioThemeColors

    /// Creates a `EmbeddedStudioTheme` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      colors: RestSchema.EmbeddedStudioThemeColors,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.colors = colors
      configure(&self)
    }

    /// Reads a `EmbeddedStudioTheme` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.colors = try container.decode(
        RestSchema.EmbeddedStudioThemeColors.self, forKey: "colors")
    }

    /// Writes a `EmbeddedStudioTheme` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.colors, forKey: "colors")
    }
  }
}
