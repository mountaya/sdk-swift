// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

/// APIErrorCode is the code an error carries, on the error and on each of its entries: the one
/// vocabulary of every surface, the union of the Map Studio API's and the Tile API's
/// `ErrorExtensionsCode` and the Data API's `ErrorCode`.
///
/// A program branches on it, never on an entry's `message`, which is written for a person and free
/// to change.
///
/// The set is open: a value this build has never seen decodes as itself rather than failing the
/// response, and a value the contract adds is one more static member.
public struct APIErrorCode: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
  ExpressibleByStringLiteral
{
  /// `BAD_REQUEST`, as the wire spells it, which the Map Studio API and the Data API declare.
  public static let badRequest: Self = "BAD_REQUEST"
  /// `LIMIT_REACHED`, as the wire spells it, which the Map Studio API declares.
  public static let limitReached: Self = "LIMIT_REACHED"
  /// `NOT_FOUND`, as the wire spells it, which the Map Studio API, the Tile API and the Data API
  /// declare.
  public static let notFound: Self = "NOT_FOUND"
  /// `TILE_GONE`, as the wire spells it, which the Tile API declares.
  public static let tileGone: Self = "TILE_GONE"
  /// `GRAPHQL_PARSE_FAILED`, as the wire spells it, which the Data API declares.
  public static let graphqlParseFailed: Self = "GRAPHQL_PARSE_FAILED"

  /// rawValue is the value as the wire spells it.
  public let rawValue: String

  /// Creates a value from its wire spelling, which may be one this build has never seen.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a value from a string literal, which is its wire spelling.
  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  /// codingKey is the value as an object's key, where the contract keys a map by it.
  public var codingKey: any CodingKey {
    WireKey(stringValue: rawValue)
  }

  /// Creates a value from an object's key.
  public init?<Key: CodingKey>(codingKey: Key) {
    self.rawValue = codingKey.stringValue
  }

  /// Reads the value from its wire spelling.
  public init(from decoder: any Decoder) throws {
    self.rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Writes the value as the wire spells it.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
