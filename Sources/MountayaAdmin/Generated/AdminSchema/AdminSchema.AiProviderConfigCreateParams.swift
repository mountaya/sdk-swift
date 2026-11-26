// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's AI provider configuration for the studio co-pilot, created
  /// when it has none. The credential is write-only: it is accepted here, encrypted
  /// at rest, and never returned by any operation. Only owners and admins may
  /// submit it.
  public struct AiProviderConfigCreateParams: Sendable, Hashable, Codable {
    /// The AI provider to use. It cannot be changed afterwards: delete the
    /// configuration and create one to switch providers.
    public var provider: AdminSchema.AiProvider
    /// The model id to use. It must be one of the provider's models in the
    /// catalog `getAiProviders` returns, which is what decides whether a value
    /// is accepted; the ceiling below is the envelope bound, not the
    /// vocabulary.
    public var model: String
    /// A provider API base URL override, for routing completions through a
    /// gateway of the organization's own. Optional and not nullable: omit it to
    /// use the provider's default endpoint.
    ///
    /// Must be an absolute `https` URL on a public host, with no credentials in
    /// the URL and no query or fragment. Requests to this endpoint carry the
    /// configured provider credential, so plaintext `http`, loopback and private
    /// addresses, and internal-only names are all refused.
    public var base_url: URI?
    /// The provider credential as a set of named fields. Each provider declares
    /// the fields it requires in the catalog `getAiProviders` returns; read
    /// them from there rather than assuming a shape. Every field the catalog
    /// names is sent, each non-empty, or the missing ones are a `400`; a field
    /// the catalog does not name is a `400` naming it. Write-only: never
    /// returned by any operation; a read answers with `credential_hint`
    /// instead.
    ///
    /// At most eight fields, each named in snake_case and holding at most 4096
    /// characters.
    ///
    /// A request sends it, and the server never answers it.
    public var credential: [String: String]

    /// Creates a `AiProviderConfigCreateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      provider: AdminSchema.AiProvider,
      model: String,
      credential: [String: String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.provider = provider
      self.model = model
      self.base_url = nil
      self.credential = credential
      configure(&self)
    }

    /// Reads a `AiProviderConfigCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.provider = try container.decode(AdminSchema.AiProvider.self, forKey: "provider")
      self.model = try container.decode(String.self, forKey: "model")
      self.base_url = try container.decodeWiredIfPresent(URI.self, forKey: "base_url")
      self.credential = try container.decode([String: String].self, forKey: "credential")
    }

    /// Writes a `AiProviderConfigCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.provider, forKey: "provider")
      try container.encode(self.model, forKey: "model")
      try container.encodeWiredIfPresent(self.base_url, forKey: "base_url")
      try container.encode(self.credential, forKey: "credential")
    }
  }
}
