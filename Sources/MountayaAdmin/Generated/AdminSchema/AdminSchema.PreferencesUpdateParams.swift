// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The preferences to change. Every field is optional and each one is
  /// independent: send only what is changing, and the rest is left as it is.
  ///
  /// There is nothing to clear. A preference always has a value, so there is no
  /// null and no empty string here; omitting a field is the only way to leave it
  /// alone, and sending one is the only way to change it. A value outside a
  /// field's closed set is a 400 naming that field, the empty string included,
  /// which is not a member of any of the six.
  public struct PreferencesUpdateParams: Sendable, Hashable, Codable {
    /// The language user-facing content is written in. Optional and not
    /// nullable: omit it to keep the current language.
    public var language: RestSchema.Language?
    /// The color theme the interface is painted in. Optional and not nullable:
    /// omit it to keep the current theme.
    public var theme: RestSchema.Theme?
    /// The measurement system distances, elevations and lengths are shown in.
    /// Optional and not nullable: omit it to keep the current system.
    public var length: RestSchema.UnitLength?
    /// The form a travel rate is shown in, time over distance or distance over
    /// time. Optional and not nullable: omit it to keep the current form.
    public var pace: RestSchema.UnitPace?
    /// The unit a gradient is shown in. Optional and not nullable: omit it to
    /// keep the current unit.
    public var slope: RestSchema.UnitSlope?
    /// The unit a temperature is shown in. Optional and not nullable: omit it to
    /// keep the current unit.
    public var temperature: RestSchema.UnitTemperature?

    /// Creates a `PreferencesUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.language = nil
      self.theme = nil
      self.length = nil
      self.pace = nil
      self.slope = nil
      self.temperature = nil
      configure(&self)
    }

    /// Reads a `PreferencesUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.language = try container.decodeIfPresent(RestSchema.Language.self, forKey: "language")
      self.theme = try container.decodeIfPresent(RestSchema.Theme.self, forKey: "theme")
      self.length = try container.decodeIfPresent(RestSchema.UnitLength.self, forKey: "length")
      self.pace = try container.decodeIfPresent(RestSchema.UnitPace.self, forKey: "pace")
      self.slope = try container.decodeIfPresent(RestSchema.UnitSlope.self, forKey: "slope")
      self.temperature = try container.decodeIfPresent(
        RestSchema.UnitTemperature.self, forKey: "temperature")
    }

    /// Writes a `PreferencesUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.theme, forKey: "theme")
      try container.encodeIfPresent(self.length, forKey: "length")
      try container.encodeIfPresent(self.pace, forKey: "pace")
      try container.encodeIfPresent(self.slope, forKey: "slope")
      try container.encodeIfPresent(self.temperature, forKey: "temperature")
    }
  }
}
