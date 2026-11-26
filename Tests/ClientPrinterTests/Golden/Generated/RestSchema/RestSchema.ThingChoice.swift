// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// ThingChoice is a value the contract writes inline as one of several types, with nothing naming
  /// which.
  ///
  /// It is read by trying each member in the contract's order, the first that reads winning, and a
  /// value none reads decodes as `unknown`, holding what arrived. A member the contract adds is a
  /// case of the build made after it, so a `switch` over it outside this module ends in `@unknown
  /// default`.
  @nonexhaustive
  public enum ThingChoice: Sendable, Hashable, Codable {
    /// The value, read as a `String`.
    case string(String)
    /// The value, read as a `Int`.
    case integer(Int)
    /// unknown is a value none of the members reads, holding what arrived.
    case unknown(JSONValue)

    /// Reads the first member the value is.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let value = try? container.decode(String.self) {
        self = .string(value)
      } else if let value = try? container.decode(Int.self) {
        self = .integer(value)
      } else {
        self = .unknown(try container.decode(JSONValue.self))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .string(let value):
        try container.encode(value)
      case .integer(let value):
        try container.encode(value)
      case .unknown(let value):
        try container.encode(value)
      }
    }
  }
}
