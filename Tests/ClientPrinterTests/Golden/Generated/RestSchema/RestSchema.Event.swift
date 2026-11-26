// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Something that happened to a thing.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum Event: Sendable, Hashable, Codable {
    /// `started`.
    case EventStarted(RestSchema.EventStarted)
    /// `stopped`.
    case EventStopped(RestSchema.EventStopped)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `type` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "type") {
      case "started":
        self = .EventStarted(try RestSchema.EventStarted(from: decoder))
      case "stopped":
        self = .EventStopped(try RestSchema.EventStopped(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .EventStarted(let member):
        try member.encode(to: encoder)
      case .EventStopped(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
