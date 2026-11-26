// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's Map Publishing settings as a webhook event carries them: whose they
  /// are, and their version. `getOrganizationSettings` reads the settings themselves.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct OrganizationSettingsEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.settings`: the family of the
    /// event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.settings`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "organization.settings"
    }
    /// Identifier of the organization the settings belong to.
    public var organization_id: String
    /// The settings's version once this change was made. It climbs with every change a
    /// read of the settings shows, so of two events about one settings the one carrying
    /// the higher `version` is the later state: events are not delivered in order.
    public var version: Int64

    /// Creates a `OrganizationSettingsEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      organization_id: String,
      version: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = organization_id
      self.version = version
      configure(&self)
    }

    /// Reads a `OrganizationSettingsEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.version = try container.decode(Int64.self, forKey: "version")
    }

    /// Writes a `OrganizationSettingsEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.version, forKey: "version")
    }
  }
}
