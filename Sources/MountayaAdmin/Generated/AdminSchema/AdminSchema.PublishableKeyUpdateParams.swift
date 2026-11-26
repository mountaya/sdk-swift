// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change to a publishable key. Both fields are optional; an omitted field
  /// keeps its current value. `scopes` is replaced whole rather than merged, so a
  /// request that sends it lists every scope the key is to keep, and a scope left
  /// out is removed. An empty `scopes` list is a 400, and none is added to the
  /// ones listed.
  public struct PublishableKeyUpdateParams: Sendable, Hashable, Codable {
    /// Display name of the publishable key. Omit to keep the current value.
    /// When sent, it is 2 to 30 characters as sent, and still at least 2 once
    /// leading and trailing whitespace is trimmed, which is the form it is
    /// stored in. A name is one line: a tab, a line break or a line separator
    /// between two of its characters is a `400`, and one at either end is trimmed
    /// with the whitespace there.
    public var name: String?
    /// The scopes the key carries from now on, each at most once, replacing the
    /// list it held. Omit to keep the current scopes. A key carries at least
    /// one: an empty list is a `400` naming `scopes`. A scope the key does not
    /// already carry is granted only while the organization holds its product,
    /// so one it does not hold is a `402` naming its position in the list; a
    /// scope the key already carries is kept whatever has become of its product.
    /// `management` is carried alone: a list naming it beside another scope is
    /// a `400` naming the position of each scope beside it. `studio-embedded`
    /// is carried with `tiles` and `data`: a list naming it without one of
    /// them is a `400` naming `scopes`, once per missing scope, whatever the
    /// key carries now.
    public var scopes: [AdminSchema.PublishableKeyScope]?

    /// Creates a `PublishableKeyUpdateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.scopes = nil
      configure(&self)
    }

    /// Reads a `PublishableKeyUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.scopes = try container.decodeIfPresent(
        [AdminSchema.PublishableKeyScope].self, forKey: "scopes")
    }

    /// Writes a `PublishableKeyUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.scopes, forKey: "scopes")
    }
  }
}
