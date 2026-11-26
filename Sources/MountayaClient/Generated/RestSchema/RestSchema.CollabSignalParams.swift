// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for a collaboration signal sent into an itinerary's real-time
  /// session. The concrete shape is selected by the `type` discriminator: a
  /// selection, a cursor, a lock acquire/release, or a draft update/clear. A user
  /// id inside the body is never trusted: the user the session token names is
  /// stamped onto every broadcast.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum CollabSignalParams: Sendable, Hashable, Codable {
    /// `selection`.
    case CollabSelectionSignal(RestSchema.CollabSelectionSignal)
    /// `cursor`.
    case CollabCursorSignal(RestSchema.CollabCursorSignal)
    /// `lock.acquire`.
    case CollabLockAcquireSignal(RestSchema.CollabLockAcquireSignal)
    /// `lock.release`.
    case CollabLockReleaseSignal(RestSchema.CollabLockReleaseSignal)
    /// `draft.update`.
    case CollabDraftUpdateSignal(RestSchema.CollabDraftUpdateSignal)
    /// `draft.clear`.
    case CollabDraftClearSignal(RestSchema.CollabDraftClearSignal)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `type` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "type") {
      case "selection":
        self = .CollabSelectionSignal(try RestSchema.CollabSelectionSignal(from: decoder))
      case "cursor":
        self = .CollabCursorSignal(try RestSchema.CollabCursorSignal(from: decoder))
      case "lock.acquire":
        self = .CollabLockAcquireSignal(try RestSchema.CollabLockAcquireSignal(from: decoder))
      case "lock.release":
        self = .CollabLockReleaseSignal(try RestSchema.CollabLockReleaseSignal(from: decoder))
      case "draft.update":
        self = .CollabDraftUpdateSignal(try RestSchema.CollabDraftUpdateSignal(from: decoder))
      case "draft.clear":
        self = .CollabDraftClearSignal(try RestSchema.CollabDraftClearSignal(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .CollabSelectionSignal(let member):
        try member.encode(to: encoder)
      case .CollabCursorSignal(let member):
        try member.encode(to: encoder)
      case .CollabLockAcquireSignal(let member):
        try member.encode(to: encoder)
      case .CollabLockReleaseSignal(let member):
        try member.encode(to: encoder)
      case .CollabDraftUpdateSignal(let member):
        try member.encode(to: encoder)
      case .CollabDraftClearSignal(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
