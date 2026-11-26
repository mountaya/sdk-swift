// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A new organization. The name is required. The website is optional and does
  /// one thing: its host seeds the embed domain allowlist, so a new
  /// organization's keys work from its own site from the start. Omit it and the
  /// allowlist starts empty: no page but Mountaya's own can call the API with the
  /// organization's keys from a browser, and no site but Mountaya's own can frame
  /// its hosted embed, until it is set: by `patchOrganizationSettings` on a
  /// self-serve organization, and by Mountaya, as the agreement states, once an
  /// agreement covers it.
  /// `agreement_requested` says which way
  /// the organization is meant to be covered, by an agreement with Mountaya or by
  /// the card it saves for the Data API.
  public struct OrganizationCreateParams: Sendable, Hashable, Codable {
    /// Display name of the organization: 2 to 30 characters as sent, and still
    /// at least 2 once leading and trailing whitespace is trimmed, which is the
    /// form it is stored in. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// The organization's website as a full URL, scheme included. Its host
    /// seeds the embed domain allowlist, which is why the scheme is required
    /// rather than merely conventional: a bare host, or a scheme that is not
    /// http or https, would land in the allowlist and silently deny every
    /// embed. An empty string is accepted and seeds nothing. A host longer than
    /// the 253 characters a domain name may run to is a `400` at `website`, the
    /// limit every entry of the allowlist is held to.
    ///
    /// Set once, at creation. `patchOrganization` takes the name alone, so there is
    /// no operation in this contract that changes the website afterwards.
    ///
    /// The ceiling is the conventional URL one rather than the 500 a waypoint's
    /// link carries. A waypoint link is one of many on a place a person
    /// authored; this is one address per organization.
    public var website: URI?
    /// Whether the organization is meant to be covered by an agreement with
    /// Mountaya rather than by a card. True records that choice, which
    /// `awaiting_agreement` on the organization then reports until an agreement
    /// is set, and the organization holds no product until that agreement
    /// grants the ones it names. It grants nothing itself and opens nothing.
    /// Omitted or false, the organization is self-serve: it holds no product
    /// until its first card opens the metered Data API subscription.
    public var agreement_requested: Bool?

    /// Creates a `OrganizationCreateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.website = nil
      self.agreement_requested = nil
      configure(&self)
    }

    /// Reads a `OrganizationCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.website = try container.decodeWiredIfPresent(URI.self, forKey: "website")
      self.agreement_requested = try container.decodeIfPresent(
        Bool.self, forKey: "agreement_requested")
    }

    /// Writes a `OrganizationCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encodeWiredIfPresent(self.website, forKey: "website")
      try container.encodeIfPresent(self.agreement_requested, forKey: "agreement_requested")
    }
  }
}
