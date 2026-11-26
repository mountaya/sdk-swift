// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The status class a request was counted under, and the dimension availability
  /// is read from. It is derived from the terminal error a request produced rather
  /// than from its status line: a Data API query whose field fails is transported
  /// as `200` with an `errors` array, and it is classified here from that entry's
  /// `extensions.code`, so a failure upstream of the answer reads `5xx` on both
  /// surfaces. Availability is `2xx / (2xx + 5xx)`; `4xx` is excluded, because a
  /// malformed request is not an outage. A request whose caller went away before
  /// its answer began is counted under no class, however long it had waited: a
  /// request too slow is the server's to fail, at its own time budget, as the
  /// `504` counted `5xx`.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct UsageStatusClass: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The request succeeded. It is what a monthly allowance counts on the counted surfaces (`api`
    /// and `mcp` on the Data API, `api` and `embedding` on the Tile API), and on the Data API what
    /// a self-serve organization is invoiced for.
    public static let class2xx: Self = "2xx"
    /// The request was refused for a reason the caller owns: invalid input, a key outside its
    /// scope, an exhausted allowance, or a missing payment method. Not counted against
    /// availability.
    public static let class4xx: Self = "4xx"
    /// The request failed inside Mountaya or inside something Mountaya depends on. Counted against
    /// availability.
    public static let class5xx: Self = "5xx"

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
}
