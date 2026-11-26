// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A user's own display preferences: the language they read in, the theme they
  /// see, and the four units every figure this API returns is rendered in. They
  /// belong to the PERSON rather than to an organization, so they follow the user
  /// across every organization they are a member of.
  ///
  /// They shape rendering only. Nothing here changes what an operation returns: a
  /// distance comes back in meters whichever length unit is set, and a client
  /// formats it. The organization's own defaults, which seed what an embed shows a
  /// visitor who has no preferences of their own, are in `OrganizationSettings`.
  public struct Preferences: Sendable, Hashable, Codable {
    /// The language user-facing content is written in.
    public var language: RestSchema.Language
    /// The color theme the interface is painted in.
    public var theme: RestSchema.Theme
    /// The measurement system distances, elevations and lengths are shown in.
    public var length: RestSchema.UnitLength
    /// The form a travel rate is shown in, time over distance or distance over
    /// time.
    public var pace: RestSchema.UnitPace
    /// The unit a gradient is shown in.
    public var slope: RestSchema.UnitSlope
    /// The unit a temperature is shown in.
    public var temperature: RestSchema.UnitTemperature

    /// Creates a `Preferences` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      language: RestSchema.Language,
      theme: RestSchema.Theme,
      length: RestSchema.UnitLength,
      pace: RestSchema.UnitPace,
      slope: RestSchema.UnitSlope,
      temperature: RestSchema.UnitTemperature,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.language = language
      self.theme = theme
      self.length = length
      self.pace = pace
      self.slope = slope
      self.temperature = temperature
      configure(&self)
    }

    /// Reads a `Preferences` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.language = try container.decode(RestSchema.Language.self, forKey: "language")
      self.theme = try container.decode(RestSchema.Theme.self, forKey: "theme")
      self.length = try container.decode(RestSchema.UnitLength.self, forKey: "length")
      self.pace = try container.decode(RestSchema.UnitPace.self, forKey: "pace")
      self.slope = try container.decode(RestSchema.UnitSlope.self, forKey: "slope")
      self.temperature = try container.decode(
        RestSchema.UnitTemperature.self, forKey: "temperature")
    }

    /// Writes a `Preferences` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.language, forKey: "language")
      try container.encode(self.theme, forKey: "theme")
      try container.encode(self.length, forKey: "length")
      try container.encode(self.pace, forKey: "pace")
      try container.encode(self.slope, forKey: "slope")
      try container.encode(self.temperature, forKey: "temperature")
    }
  }
}
