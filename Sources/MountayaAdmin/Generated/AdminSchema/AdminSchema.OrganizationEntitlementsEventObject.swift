// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What an organization holds, as a webhook event carries it: its capabilities and the
  /// studio features its agreement grants.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct OrganizationEntitlementsEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.entitlements`: the family of the
    /// event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.entitlements`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "organization.entitlements"
    }
    /// Identifier of the organization.
    public var organization_id: String
    /// The capabilities the organization holds once this change was made.
    public var capabilities: [AdminSchema.Capability]
    /// The studio features the organization's agreement grants once this change was made.
    public var studio_entitlements: [RestSchema.StudioEntitlement]

    /// Creates a `OrganizationEntitlementsEventObject` from the properties the contract requires,
    /// the optional ones being set in `configure`.
    public init(
      organization_id: String,
      capabilities: [AdminSchema.Capability],
      studio_entitlements: [RestSchema.StudioEntitlement],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = organization_id
      self.capabilities = capabilities
      self.studio_entitlements = studio_entitlements
      configure(&self)
    }

    /// Reads a `OrganizationEntitlementsEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.capabilities = try container.decode(
        [AdminSchema.Capability].self, forKey: "capabilities")
      self.studio_entitlements = try container.decode(
        [RestSchema.StudioEntitlement].self, forKey: "studio_entitlements")
    }

    /// Writes a `OrganizationEntitlementsEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.capabilities, forKey: "capabilities")
      try container.encode(self.studio_entitlements, forKey: "studio_entitlements")
    }
  }
}
