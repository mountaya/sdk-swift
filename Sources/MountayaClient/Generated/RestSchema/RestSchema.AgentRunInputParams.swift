// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for an input signal sent into a running agent run. The concrete
  /// shape is selected by the `type` discriminator: a follow-up user message, a
  /// client tool result, a confirmation decision, a request that the run finish, or
  /// a replacement of the run's client-tool manifest.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum AgentRunInputParams: Sendable, Hashable, Codable {
    /// `user-message`.
    case AgentUserMessageInput(RestSchema.AgentUserMessageInput)
    /// `tool-result`.
    case AgentToolResultInput(RestSchema.AgentToolResultInput)
    /// `confirm`.
    case AgentConfirmInput(RestSchema.AgentConfirmInput)
    /// `close`.
    case AgentCloseInput(RestSchema.AgentCloseInput)
    /// `manifest-update`.
    case AgentManifestUpdateInput(RestSchema.AgentManifestUpdateInput)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `type` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "type") {
      case "user-message":
        self = .AgentUserMessageInput(try RestSchema.AgentUserMessageInput(from: decoder))
      case "tool-result":
        self = .AgentToolResultInput(try RestSchema.AgentToolResultInput(from: decoder))
      case "confirm":
        self = .AgentConfirmInput(try RestSchema.AgentConfirmInput(from: decoder))
      case "close":
        self = .AgentCloseInput(try RestSchema.AgentCloseInput(from: decoder))
      case "manifest-update":
        self = .AgentManifestUpdateInput(try RestSchema.AgentManifestUpdateInput(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .AgentUserMessageInput(let member):
        try member.encode(to: encoder)
      case .AgentToolResultInput(let member):
        try member.encode(to: encoder)
      case .AgentConfirmInput(let member):
        try member.encode(to: encoder)
      case .AgentCloseInput(let member):
        try member.encode(to: encoder)
      case .AgentManifestUpdateInput(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
