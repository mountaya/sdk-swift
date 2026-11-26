// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
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
    /// The object once the change was made.
    public var object: Object
    /// The fields of `data.object` the change moved, each with the value it held before.
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
