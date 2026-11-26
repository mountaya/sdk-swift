// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change to an organization's AI provider configuration, merged into what is
  /// stored: a field left out keeps its value. The provider is not among the
  /// fields: delete the configuration and create one to switch providers. Only
  /// owners and admins may submit it.
  public struct AiProviderConfigUpdateParams: Sendable, Hashable, Codable {
    /// The model id to use, one of the provider's models in the catalog
    /// `getAiProviders` returns. Optional and not nullable: omit it to keep the
    /// current model.
    public var model: String?
    /// A provider API base URL override, held to the rules
    /// `AiProviderConfigCreateParams` states for it. Omit it to keep the
    /// current one, and send null to clear it, which routes completions to the
    /// provider's default endpoint again.
    ///
    /// Requests to this endpoint carry the stored credential, so moving them to
    /// a new host is a change only someone holding that credential may make: a
    /// URL other than the one stored must come with `credential` in the same
    /// request, and without it the update is a `400` with one entry at
    /// `["credential"]` and nothing is changed. Null, which sends completions
    /// back to the provider's own endpoint, and the URL already stored need no
    /// credential.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var base_url: URI??
    /// A new provider credential, which REPLACES the stored one whole: every
    /// field the catalog names for the configured provider is sent, each
    /// non-empty, as on a create. Optional and not nullable: omit it to keep
    /// the stored credential, so the model can be changed without sending the
    /// key again. A `base_url` changed to a new URL is the exception, and
    /// requires it. Write-only: never returned by any operation.
    ///
    /// At most eight fields, each named in snake_case and holding at most 4096
    /// characters.
    ///
    /// A request sends it, and the server never answers it.
    public var credential: [String: String]?

    /// Creates a `AiProviderConfigUpdateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.model = nil
      self.base_url = nil
      self.credential = nil
      configure(&self)
    }

    /// Reads a `AiProviderConfigUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.model = try container.decodeIfPresent(String.self, forKey: "model")
      self.base_url = try container.decodeWiredMerge(URI.self, forKey: "base_url")
      self.credential = try container.decodeIfPresent([String: String].self, forKey: "credential")
    }

    /// Writes a `AiProviderConfigUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.model, forKey: "model")
      try container.encodeWiredMerge(self.base_url, forKey: "base_url")
      try container.encodeIfPresent(self.credential, forKey: "credential")
    }
  }
}
