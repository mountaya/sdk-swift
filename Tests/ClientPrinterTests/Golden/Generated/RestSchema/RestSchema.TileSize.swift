// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The contract's `TileSize`.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct TileSize: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByIntegerLiteral
  {
    /// 256, as the wire spells it.
    public static let size256: Self = 256
    /// 512, as the wire spells it.
    public static let size512: Self = 512

    /// rawValue is the value as the wire spells it.
    public let rawValue: Int

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Creates a value from an integer literal, which is its wire spelling.
    public init(integerLiteral value: Int) {
      self.rawValue = value
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(Int.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
