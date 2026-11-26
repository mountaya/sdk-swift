// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The publishable key to resolve an organization from. It is the key itself
  /// rather than an identifier, because the caller is an embed host that has been
  /// handed a key and nothing else: if it knew the organization id it would read
  /// `getOrganization` instead.
  public struct OrganizationLookupParams: Sendable, Hashable, Codable {
    /// The publishable key to resolve. It is sent in the BODY rather than in the
    /// `X-API-Key` header, and that is the whole shape of this operation: the key
    /// is the subject of the question, not the credential answering it.
    ///
    /// A key that does not exist, one that has been revoked, one that carries
    /// neither the `publishing` scope nor the `studio-embedded` scope that
    /// includes it, and one whose organization has been canceled all answer
    /// 404 alike, so this cannot be used to sort real keys from invented ones.
    public var publishable_key: String

    /// Creates a `OrganizationLookupParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      publishable_key: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.publishable_key = publishable_key
      configure(&self)
    }

    /// Reads a `OrganizationLookupParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.publishable_key = try container.decode(String.self, forKey: "publishable_key")
    }

    /// Writes a `OrganizationLookupParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.publishable_key, forKey: "publishable_key")
    }
  }
}
