// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Theme colors applied by an embed's map: the 10-stop UI color scale.
  public struct EmbeddedStudioThemeColors: Sendable, Hashable, Codable {
    /// The 10-stop UI color scale, ordered lightest to darkest. Exactly 10
    /// entries: a shorter or longer array is rejected rather than padded.
    ///
    /// Six-digit form only, and case-insensitive: a scale is stored and returned
    /// in the case it was written in rather than normalized, so compare these
    /// case-insensitively. `segments_color`, which is a color rather than a
    /// scale, is the one that is lowercased on the way in.
    public var ui: [String]

    /// Creates a `EmbeddedStudioThemeColors` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      ui: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.ui = ui
      configure(&self)
    }

    /// Reads a `EmbeddedStudioThemeColors` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.ui = try container.decode([String].self, forKey: "ui")
    }

    /// Writes a `EmbeddedStudioThemeColors` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.ui, forKey: "ui")
    }
  }
}
