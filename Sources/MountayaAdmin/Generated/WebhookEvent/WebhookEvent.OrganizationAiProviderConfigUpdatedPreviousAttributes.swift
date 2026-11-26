// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// OrganizationAiProviderConfigUpdatedPreviousAttributes is the former value of each field a
  /// `organization.ai_provider_config.updated` event's change moved, as its
  /// `data.previous_attributes` carries them, each typed as
  /// `AdminSchema.AiProviderConfigEventObject` types it: a field the change did not move is nil.
  public struct OrganizationAiProviderConfigUpdatedPreviousAttributes: Sendable, Hashable, Codable {
    /// The provider's model agent runs use.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var model: String?
    /// The last four characters of the stored credential, as
    /// `getOrganizationAiProviderConfig` shows them, and empty for a credential shorter
    /// than 12 characters, of which four would be too large a part.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var credential_hint: String?

    /// Creates a `OrganizationAiProviderConfigUpdatedPreviousAttributes` from the properties the
    /// contract requires, the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.model = nil
      self.credential_hint = nil
      configure(&self)
    }

    /// Reads a `OrganizationAiProviderConfigUpdatedPreviousAttributes` from the JSON object the
    /// contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.model = try container.decodeIfPresent(String.self, forKey: "model")
      self.credential_hint = try container.decodeIfPresent(String.self, forKey: "credential_hint")
    }

    /// Writes a `OrganizationAiProviderConfigUpdatedPreviousAttributes` as the JSON object the
    /// contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.model, forKey: "model")
      try container.encodeIfPresent(self.credential_hint, forKey: "credential_hint")
    }
  }
}
