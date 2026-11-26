// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The masked read view of an organization's AI provider configuration for the
  /// studio co-pilot. It never contains the credential: it carries the provider,
  /// the model, the base URL override if one is set, and a non-sensitive hint
  /// (the last four characters of the key) so an admin can recognize which key is
  /// in place. An organization with none configured reads `null` rather than this
  /// object, and cannot start an agent run.
  public struct AiProviderConfig: Sendable, Hashable, Codable {
    /// The configured provider. It cannot be changed in place: delete the
    /// configuration and create one to switch providers.
    public var provider: AdminSchema.AiProvider
    /// The configured model id, one of the provider's models in the catalog
    /// `getAiProviders` returns.
    public var model: String
    /// The provider API base URL override, an absolute `https` URL, or null
    /// when completions go to the provider's default endpoint.
    public var base_url: URI?
    /// A non-sensitive fragment of the configured credential, the last four
    /// characters of the provider key, shown so an admin can recognize the key
    /// without revealing it. Empty for a key shorter than 12 characters, of which
    /// four would be too large a part.
    public var credential_hint: String
    /// The version of the configuration, the one the `ETag` of a read of it
    /// carries, opaque and compared whole. Send it as `If-Match` to make
    /// `patchOrganizationAiProviderConfig` or
    /// `deleteOrganizationAiProviderConfig` conditional.
    public var etag: String

    /// Creates a `AiProviderConfig` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      provider: AdminSchema.AiProvider,
      model: String,
      base_url: URI?,
      credential_hint: String,
      etag: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.provider = provider
      self.model = model
      self.base_url = base_url
      self.credential_hint = credential_hint
      self.etag = etag
      configure(&self)
    }

    /// Reads a `AiProviderConfig` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.provider = try container.decode(AdminSchema.AiProvider.self, forKey: "provider")
      self.model = try container.decode(String.self, forKey: "model")
      self.base_url = try container.decodeIfPresent(URI.self, forKey: "base_url")
      self.credential_hint = try container.decode(String.self, forKey: "credential_hint")
      self.etag = try container.decode(String.self, forKey: "etag")
    }

    /// Writes a `AiProviderConfig` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.provider, forKey: "provider")
      try container.encode(self.model, forKey: "model")
      try container.encodeNullable(self.base_url, forKey: "base_url")
      try container.encode(self.credential_hint, forKey: "credential_hint")
      try container.encode(self.etag, forKey: "etag")
    }
  }
}
