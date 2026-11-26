// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// PayloadData is what an event of a type this build knows says about its object: the object as
  /// the type carries it, and the former value of each field its change moved.
  public struct PayloadData<
    Object: Codable & Hashable & Sendable, PreviousAttributes: Codable & Hashable & Sendable
  >: Sendable, Hashable, Codable {
    /// The object once the change was made, as lean as its kind allows: identifiers and
    /// bounded figures, never geometry, a file or a credential. For a type ending in
    /// `deleted`, `revoked`, `removed` or `detached`, the object as it was, its `status`
    /// and every other member included. Where the object carries a `version`, a delete
    /// is its last version change: the `deleted` event carries a version past the last
    /// the object held, so a receiver that applies an event only when its `version` is
    /// newer applies the delete too, and never an event that arrives after it. Its
    /// `object` names its kind, which is the family of the event's type.
    public var object: Object
    /// The fields of `data.object` the change moved, each with the value it held before.
    /// Present on the types whose entry in `webhooks` says so, such as
    /// `organization.member.updated`, which carries the member's former `role`. A field
    /// that did not move is not in it.
    ///
    /// It is always nil where `PreviousAttributes` is `Never`, a type whose change moves no field:
    /// a `previous_attributes` such an event carries is not read, as a key this build does not know
    /// is not.
    public var previous_attributes: PreviousAttributes?

    /// Creates a `PayloadData` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      object: Object,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.object = object
      self.previous_attributes = nil
      configure(&self)
    }

    /// Reads a `PayloadData` from the JSON object the contract describes, its `previous_attributes`
    /// left unread where `PreviousAttributes` is `Never`.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.object = try container.decode(Object.self, forKey: "object")
      if PreviousAttributes.self == Never.self {
        self.previous_attributes = nil
      } else {
        self.previous_attributes = try container.decodeIfPresent(
          PreviousAttributes.self, forKey: "previous_attributes")
      }
    }

    /// Writes a `PayloadData` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encodeIfPresent(self.previous_attributes, forKey: "previous_attributes")
    }
  }
}
