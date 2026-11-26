// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change to the organization's own identity, merged into what is stored: a
  /// field left out keeps its value. The display name is the whole of what is
  /// settable here: settings and entitlements each have their own surface or none
  /// at all, so a rename cannot carry one of them along by accident. An empty
  /// object changes nothing and is answered with the organization as it stands.
  public struct OrganizationUpdateParams: Sendable, Hashable, Codable {
    /// Display name of the organization: 2 to 30 characters as sent, and still
    /// at least 2 once leading and trailing whitespace is trimmed, which is the
    /// form it is stored in. Optional and not nullable: omit it to keep the
    /// current name. A name is one line: a tab, a line break or a line separator
    /// between two of its characters is a `400`, and one at either end is trimmed
    /// with the whitespace there.
    public var name: String?

    /// Creates a `OrganizationUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      configure(&self)
    }

    /// Reads a `OrganizationUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
    }

    /// Writes a `OrganizationUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
    }
  }
}
