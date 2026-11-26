// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A partial update to the settings that shape an organization's embeds:
  /// the default props, the map theme, and the safety rules. Every group is
  /// optional: only the groups present in the request are replaced; the rest are
  /// preserved. The organization's limits, its per-minute rate limits and monthly
  /// allowances among them, are deliberately absent: they are set by its
  /// agreement rather than by a caller, so no operation in this contract writes
  /// them.
  ///
  /// Three safety rules are set by Mountaya rather than by the caller:
  /// `safety_rules.with_overlays` and `safety_rules.with_overlays_control` on
  /// every organization, and `safety_rules.domains` on an organization covered
  /// by an agreement. A `safety_rules` group carries them as every group carries
  /// all its fields, and must carry them as they stand: a request that changes
  /// any of them is a `403` naming that field, and nothing in the request is
  /// applied.
  public struct OrganizationSettingsPatchParams: Sendable, Hashable, Codable {
    /// What an embed starts with when it names nothing itself. Sent whole: the
    /// object REPLACES the stored one rather than merging into it, and every
    /// field in it is required, so a group that leaves one out is a 400 rather
    /// than a partial change.
    public var default_props: RestSchema.EmbeddedStudioDefaultProps?
    /// The organization's colors and typography for an embed. Sent whole: the
    /// object REPLACES the stored one rather than merging into it, and every
    /// field in it is required.
    public var theme: RestSchema.EmbeddedStudioTheme?
    /// The ceilings an embed cannot raise. Sent whole: the object REPLACES the
    /// stored one rather than merging into it, and every rule in it is required,
    /// `require_session_token` included, so a group that leaves one out is a 400
    /// rather than a change that drops it. `with_overlays`,
    /// `with_overlays_control`, and `domains` on an organization covered by an
    /// agreement, are sent as they stand, since Mountaya sets them: changing any
    /// of them is a `403`.
    public var safety_rules: RestSchema.EmbeddedStudioSafetyRules?

    /// Creates a `OrganizationSettingsPatchParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.default_props = nil
      self.theme = nil
      self.safety_rules = nil
      configure(&self)
    }

    /// Reads a `OrganizationSettingsPatchParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.default_props = try container.decodeIfPresent(
        RestSchema.EmbeddedStudioDefaultProps.self, forKey: "default_props")
      self.theme = try container.decodeIfPresent(
        RestSchema.EmbeddedStudioTheme.self, forKey: "theme")
      self.safety_rules = try container.decodeIfPresent(
        RestSchema.EmbeddedStudioSafetyRules.self, forKey: "safety_rules")
    }

    /// Writes a `OrganizationSettingsPatchParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.default_props, forKey: "default_props")
      try container.encodeIfPresent(self.theme, forKey: "theme")
      try container.encodeIfPresent(self.safety_rules, forKey: "safety_rules")
    }
  }
}
