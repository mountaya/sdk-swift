// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Machine-readable failure code the browser's tool bus emits alongside `error`
  /// when a client tool did not succeed. It lets the model branch on the KIND of
  /// failure without parsing a human-readable message, which is what makes a
  /// recovery hint actionable.
  ///
  /// This is the closed client-tool vocabulary: a client tool reports a failure
  /// using one of these codes and no other.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AgentToolErrorCode: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The person the tool works for stopped it before it finished, such as a recording they
    /// canceled. Nothing failed, so the call is not repeated unless they ask again.
    public static let canceled: Self = "canceled"
    /// The caller's capability set does not grant this tool, so it was never dispatched.
    public static let capabilityDenied: Self = "capability-denied"
    /// Another collaborator holds the lock on the entity this tool would change.
    public static let collabLocked: Self = "collab-locked"
    /// The user was asked to confirm a destructive action and declined.
    public static let confirmationDenied: Self = "confirmation-denied"
    /// The user was asked to confirm a destructive action and the window elapsed with no answer.
    /// Distinct from `confirmation-denied`: nobody refused, so re-asking is reasonable where
    /// re-asking after a refusal is not.
    public static let confirmationTimeout: Self = "confirmation-timeout"
    /// The change conflicts with the resource's current state.
    public static let conflict: Self = "conflict"
    /// A verb that only applies to a persisted itinerary was asked for while an import or
    /// suggestion draft owns the editor. Distinct from `edit-in-progress`, which is a geometry
    /// session being armed: this one says the thing on screen is a proposal, and a proposal has
    /// nothing to publish, copy, or re-shape server-side.
    public static let draftOpen: Self = "draft-open"
    /// An edit is already in progress on this surface and must be settled first.
    public static let editInProgress: Self = "edit-in-progress"
    /// The caller may not act on this resource.
    public static let forbidden: Self = "forbidden"
    /// The tool failed for a reason with no more specific code; the message carries no internal
    /// detail.
    public static let `internal`: Self = "internal"
    /// The arguments did not satisfy the tool's schema; the error restates the accepted shape.
    public static let invalidInput: Self = "invalid-input"
    /// A ceiling of the account or of the organization's agreement was reached, such as the
    /// itineraries a personal space keeps, the seats, published itineraries or published zones an
    /// agreement allows, or a spent daily bound or monthly allowance more than a minute from
    /// lifting, which happens when the next day begins in UTC or the organization's next billing
    /// period begins, at the instant the error states. Nothing sent again changes a ceiling, so the
    /// call is not retried.
    public static let limitReached: Self = "limit-reached"
    /// The named resource does not exist or is not visible to the caller.
    public static let notFound: Self = "not-found"
    /// The caller exceeded its per-minute limit on requests, which lifts within the minute, so the
    /// call may be retried shortly. A spent monthly allowance is `limit-reached`, except in the
    /// last minute of a billing period, when it too lifts within the minute and is this.
    public static let rateLimited: Self = "rate-limited"
    /// The request outlived the budget its route runs under and was abandoned. Distinct from
    /// `rate-limited`: nothing is throttling the caller, so retrying the same call unchanged fails
    /// the same way. The work itself has to get smaller.
    public static let timeout: Self = "timeout"
    /// What the tool needs is not available where it runs, such as a position the device does not
    /// give. Distinct from `internal`: nothing broke, and the same call fails the same way until
    /// the device or the page offers it, so the model says so rather than retrying.
    public static let unavailable: Self = "unavailable"
    /// No tool is registered under the name the model used.
    public static let unknownTool: Self = "unknown-tool"
    /// The caller's organization does not hold what the call needs, a product its agreement does
    /// not grant or, for the Data API, a payment method on file. Every `402` is this: a ceiling is
    /// a `429`, and `limit-reached`.
    public static let upgradeRequired: Self = "upgrade-required"

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
