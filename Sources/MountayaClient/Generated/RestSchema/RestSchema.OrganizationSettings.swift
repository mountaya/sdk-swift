// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The settings that shape an organization's embeds, its Map Publishing
  /// settings, in three independent groups: the default props an embed starts
  /// from, the safety rules constraining what an embed may do, and the map theme.
  /// Each group is replaced whole rather than merged, so a partial update carries
  /// the complete group it changes.
  public struct OrganizationSettings: Sendable, Hashable, Codable {
    /// The version of the settings, the one the `ETag` of a read of them
    /// carries, opaque and compared whole. Send it as `If-Match` to make
    /// `patchOrganizationSettings` conditional. The settings are versioned
    /// apart from the organization's own fields, so a settings edit never
    /// refuses a rename made at the same moment, nor the other way round.
    public var etag: String
    /// What an embed starts with when it names nothing itself: language, units,
    /// theme and the rest. An embed may override any of these per instance.
    public var default_props: RestSchema.EmbeddedStudioDefaultProps
    /// The ceilings an embed cannot raise, whatever it asks for. Unlike
    /// `default_props`, these are enforced rather than defaulted: an embed that
    /// requests a zoom outside the allowed window is refused, not clamped
    /// silently by the client.
    public var safety_rules: RestSchema.EmbeddedStudioSafetyRules
    /// The organization's colors and typography for an embed. Always present:
    /// unset fields carry their neutral value rather than being absent, so a
    /// renderer reads every one of them unconditionally.
    public var theme: RestSchema.EmbeddedStudioTheme

    /// Creates a `OrganizationSettings` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      etag: String,
      default_props: RestSchema.EmbeddedStudioDefaultProps,
      safety_rules: RestSchema.EmbeddedStudioSafetyRules,
      theme: RestSchema.EmbeddedStudioTheme,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.etag = etag
      self.default_props = default_props
      self.safety_rules = safety_rules
      self.theme = theme
      configure(&self)
    }

    /// Reads a `OrganizationSettings` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.etag = try container.decode(String.self, forKey: "etag")
      self.default_props = try container.decode(
        RestSchema.EmbeddedStudioDefaultProps.self, forKey: "default_props")
      self.safety_rules = try container.decode(
        RestSchema.EmbeddedStudioSafetyRules.self, forKey: "safety_rules")
      self.theme = try container.decode(RestSchema.EmbeddedStudioTheme.self, forKey: "theme")
    }

    /// Writes a `OrganizationSettings` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.default_props, forKey: "default_props")
      try container.encode(self.safety_rules, forKey: "safety_rules")
      try container.encode(self.theme, forKey: "theme")
    }
  }
}
