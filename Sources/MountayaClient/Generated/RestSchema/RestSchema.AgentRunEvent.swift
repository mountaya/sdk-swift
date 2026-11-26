// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One decoded frame off an agent run's event stream: the `data:` JSON of a
  /// Server-Sent Events record, with the record's `event:` type repeated as the
  /// `type` discriminator so the frame is self-describing once decoded.
  ///
  /// It is the single source of the stream's vocabulary. The event kinds live in
  /// AgentRunEventType, the run's terminal reason in AgentRunReason, and the
  /// per-call abandon reason in AgentToolAbandonedReason, so none of the three can
  /// drift from the others or from prose.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum AgentRunEvent: Sendable, Hashable, Codable {
    /// `message-delta`.
    case AgentMessageDeltaEvent(RestSchema.AgentMessageDeltaEvent)
    /// `message`.
    case AgentMessageEvent(RestSchema.AgentMessageEvent)
    /// `tool-call`.
    case AgentToolCallEvent(RestSchema.AgentToolCallEvent)
    /// `tool-result`.
    case AgentToolResultEvent(RestSchema.AgentToolResultEvent)
    /// `confirm-required`.
    case AgentConfirmRequiredEvent(RestSchema.AgentConfirmRequiredEvent)
    /// `tool-abandoned`.
    case AgentToolAbandonedEvent(RestSchema.AgentToolAbandonedEvent)
    /// `checks-unmet`.
    case AgentChecksUnmetEvent(RestSchema.AgentChecksUnmetEvent)
    /// `awaiting-input`.
    case AgentAwaitingInputEvent(RestSchema.AgentAwaitingInputEvent)
    /// `budget-exhausted`.
    case AgentBudgetExhaustedEvent(RestSchema.AgentBudgetExhaustedEvent)
    /// `error`.
    case AgentErrorEvent(RestSchema.AgentErrorEvent)
    /// `done`.
    case AgentDoneEvent(RestSchema.AgentDoneEvent)
    /// `reconnect`.
    case AgentReconnectEvent(RestSchema.AgentReconnectEvent)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `type` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "type") {
      case "message-delta":
        self = .AgentMessageDeltaEvent(try RestSchema.AgentMessageDeltaEvent(from: decoder))
      case "message":
        self = .AgentMessageEvent(try RestSchema.AgentMessageEvent(from: decoder))
      case "tool-call":
        self = .AgentToolCallEvent(try RestSchema.AgentToolCallEvent(from: decoder))
      case "tool-result":
        self = .AgentToolResultEvent(try RestSchema.AgentToolResultEvent(from: decoder))
      case "confirm-required":
        self = .AgentConfirmRequiredEvent(try RestSchema.AgentConfirmRequiredEvent(from: decoder))
      case "tool-abandoned":
        self = .AgentToolAbandonedEvent(try RestSchema.AgentToolAbandonedEvent(from: decoder))
      case "checks-unmet":
        self = .AgentChecksUnmetEvent(try RestSchema.AgentChecksUnmetEvent(from: decoder))
      case "awaiting-input":
        self = .AgentAwaitingInputEvent(try RestSchema.AgentAwaitingInputEvent(from: decoder))
      case "budget-exhausted":
        self = .AgentBudgetExhaustedEvent(try RestSchema.AgentBudgetExhaustedEvent(from: decoder))
      case "error":
        self = .AgentErrorEvent(try RestSchema.AgentErrorEvent(from: decoder))
      case "done":
        self = .AgentDoneEvent(try RestSchema.AgentDoneEvent(from: decoder))
      case "reconnect":
        self = .AgentReconnectEvent(try RestSchema.AgentReconnectEvent(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .AgentMessageDeltaEvent(let member):
        try member.encode(to: encoder)
      case .AgentMessageEvent(let member):
        try member.encode(to: encoder)
      case .AgentToolCallEvent(let member):
        try member.encode(to: encoder)
      case .AgentToolResultEvent(let member):
        try member.encode(to: encoder)
      case .AgentConfirmRequiredEvent(let member):
        try member.encode(to: encoder)
      case .AgentToolAbandonedEvent(let member):
        try member.encode(to: encoder)
      case .AgentChecksUnmetEvent(let member):
        try member.encode(to: encoder)
      case .AgentAwaitingInputEvent(let member):
        try member.encode(to: encoder)
      case .AgentBudgetExhaustedEvent(let member):
        try member.encode(to: encoder)
      case .AgentErrorEvent(let member):
        try member.encode(to: encoder)
      case .AgentDoneEvent(let member):
        try member.encode(to: encoder)
      case .AgentReconnectEvent(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
