// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Response metadata returned when a write is refused because a soft lock is held
  /// on the entity it would change. Carries the identifier of the member holding
  /// that lock. On a collaboration signal it is the all-zero UUID when the entity
  /// is unlocked and the user the session token names lacks the lock a draft
  /// requires; the other writes carry this metadata only when a member holds the
  /// lock.
  ///
  /// Every write that participates in an editing session answers with this
  /// shape: the segment, segment-group and waypoint mutations, the itinerary
  /// publication, the zone update, the zone publication, and the collaboration
  /// signals themselves. A client therefore has one branch for "somebody is
  /// editing this" rather than one per endpoint. The two publications, of an
  /// itinerary and of a zone, are the writes a lock of the caller's own also
  /// refuses: publishing needs every lock on the resource released, so there the
  /// holder can be the caller.
  public struct ResponseMetadataLockConflict: Sendable, Hashable, Codable {
    /// The member holding the lock, so a client can name who is editing rather
    /// than only report that somebody is; on a publication, possibly the
    /// caller. On a collaboration signal, the all-zero UUID when the entity is
    /// unlocked and the user the session token names lacks the lock a draft
    /// requires.
    public var holder: RestSchema.ConflictMetadata

    /// Creates a `ResponseMetadataLockConflict` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      holder: RestSchema.ConflictMetadata,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.holder = holder
      configure(&self)
    }

    /// Reads a `ResponseMetadataLockConflict` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.holder = try container.decode(RestSchema.ConflictMetadata.self, forKey: "holder")
    }

    /// Writes a `ResponseMetadataLockConflict` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.holder, forKey: "holder")
    }
  }
}
