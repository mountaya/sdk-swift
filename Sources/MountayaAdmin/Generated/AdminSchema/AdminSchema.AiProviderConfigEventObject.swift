// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's AI provider configuration as a webhook event carries it: the
  /// provider, the model, and the hint of the credential, which is never carried.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct AiProviderConfigEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.ai_provider_config`: the family
    /// of the event types that carry it, and what tells the members of
    /// `WebhookEventObject` apart.
    ///
    /// It is always `organization.ai_provider_config`, the discriminator value naming this member
    /// of its union.
    public var object: String {
      "organization.ai_provider_config"
    }
    /// Identifier of the organization the configuration belongs to.
    public var organization_id: String
    /// The provider agent runs are routed through.
    public var provider: AdminSchema.AiProvider
    /// The provider's model agent runs use.
    public var model: String
    /// The last four characters of the stored credential, as
    /// `getOrganizationAiProviderConfig` shows them, and empty for a credential shorter
    /// than 12 characters, of which four would be too large a part.
    public var credential_hint: String
    /// The configuration's version once this change was made. It climbs with every change
    /// a read of the configuration shows, so of two events about one configuration the
    /// one carrying the higher `version` is the later state: events are not delivered in
    /// order. A delete is the configuration's last version change:
    /// `organization.ai_provider_config.deleted` carries a version past every one the
    /// configuration held, and below the one a configuration created afterwards starts
    /// at, so an event that arrives after the delete is never mistaken for the later
    /// state.
    public var version: Int64

    /// Creates a `AiProviderConfigEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      organization_id: String,
      provider: AdminSchema.AiProvider,
      model: String,
      credential_hint: String,
      version: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = organization_id
      self.provider = provider
      self.model = model
      self.credential_hint = credential_hint
      self.version = version
      configure(&self)
    }

    /// Reads a `AiProviderConfigEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.provider = try container.decode(AdminSchema.AiProvider.self, forKey: "provider")
      self.model = try container.decode(String.self, forKey: "model")
      self.credential_hint = try container.decode(String.self, forKey: "credential_hint")
      self.version = try container.decode(Int64.self, forKey: "version")
    }

    /// Writes a `AiProviderConfigEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.provider, forKey: "provider")
      try container.encode(self.model, forKey: "model")
      try container.encode(self.credential_hint, forKey: "credential_hint")
      try container.encode(self.version, forKey: "version")
    }
  }
}
