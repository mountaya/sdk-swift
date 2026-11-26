// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One provider's entry in the AI provider catalog: the provider id, a display
  /// label, the model ids selectable for it, the default among them, and the
  /// credential fields it requires. The catalog is the same for every caller and
  /// drives the configuration picker.
  public struct AiProviderCatalog: Sendable, Hashable, Codable {
    /// Stable identifier of the provider, and the value `postOrganizationAiProviderConfig`
    /// takes.
    public var provider: AdminSchema.AiProvider
    /// The provider's name as a person reads it. For display only; branch on
    /// `provider`.
    public var label: String
    /// The allow-list of model ids selectable for this provider.
    public var models: [String]
    /// The model id a fresh configuration seeds to: the one the picker preselects
    /// and the co-pilot falls back to. Always one of models.
    public var default_model: String
    /// The credential inputs this provider requires, in display order.
    public var credential_fields: [AdminSchema.AiCredentialField]

    /// Creates a `AiProviderCatalog` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      provider: AdminSchema.AiProvider,
      label: String,
      models: [String],
      default_model: String,
      credential_fields: [AdminSchema.AiCredentialField],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.provider = provider
      self.label = label
      self.models = models
      self.default_model = default_model
      self.credential_fields = credential_fields
      configure(&self)
    }

    /// Reads a `AiProviderCatalog` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.provider = try container.decode(AdminSchema.AiProvider.self, forKey: "provider")
      self.label = try container.decode(String.self, forKey: "label")
      self.models = try container.decode([String].self, forKey: "models")
      self.default_model = try container.decode(String.self, forKey: "default_model")
      self.credential_fields = try container.decode(
        [AdminSchema.AiCredentialField].self, forKey: "credential_fields")
    }

    /// Writes a `AiProviderCatalog` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.provider, forKey: "provider")
      try container.encode(self.label, forKey: "label")
      try container.encode(self.models, forKey: "models")
      try container.encode(self.default_model, forKey: "default_model")
      try container.encode(self.credential_fields, forKey: "credential_fields")
    }
  }
}
