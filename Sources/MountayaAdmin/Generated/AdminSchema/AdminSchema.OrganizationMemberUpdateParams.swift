// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change to one member's role. The role is the whole of what a membership
  /// carries that a caller can change. `owner` cannot be granted here and the
  /// owner's own role cannot be changed: ownership moves only in Mountaya's web
  /// application. Only the owner grants `admin` or takes it away, and only
  /// there: under a key, granting `admin` or changing the role of a member who
  /// holds it is a `403`, the owner's own session included.
  public struct OrganizationMemberUpdateParams: Sendable, Hashable, Codable {
    /// The role the member holds after the change. `owner` is not among the
    /// values: it is never granted here.
    public var role: AdminSchema.AssignableOrganizationRole

    /// Creates a `OrganizationMemberUpdateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      role: AdminSchema.AssignableOrganizationRole,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.role = role
      configure(&self)
    }

    /// Reads a `OrganizationMemberUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.role = try container.decode(AdminSchema.AssignableOrganizationRole.self, forKey: "role")
    }

    /// Writes a `OrganizationMemberUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.role, forKey: "role")
    }
  }
}
