// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A single credential input a provider requires, as advertised by the AI
  /// provider catalog. It is non-sensitive metadata describing the field to collect
  /// (its key and a display label); it never carries a value.
  public struct AiCredentialField: Sendable, Hashable, Codable {
    /// The stable credential map key to submit under
    /// AiProviderConfigParams.credential (for example "api_key"). A snake_case
    /// slug, bounded the way every other key on this surface is.
    public var key: String
    /// A human-readable field name for a configuration form.
    public var label: String

    /// Creates a `AiCredentialField` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      key: String,
      label: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.key = key
      self.label = label
      configure(&self)
    }

    /// Reads a `AiCredentialField` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.key = try container.decode(String.self, forKey: "key")
      self.label = try container.decode(String.self, forKey: "label")
    }

    /// Writes a `AiCredentialField` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.key, forKey: "key")
      try container.encode(self.label, forKey: "label")
    }
  }
}
