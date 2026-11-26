// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The answer a write sent with an `Idempotency-Key` was given the first time,
  /// at `extensions.metadata` of the `409` coded `IDEMPOTENCY_ANSWER_UNAVAILABLE`
  /// that a repeat of the key gets when that answer cannot be replayed. That
  /// happens for one of three reasons: the answer was too large to keep whole,
  /// the request failed with a `5xx` after its write was made, or the answer
  /// carried a credential shown only once, which is never kept. Whichever it
  /// is, the write was made: this says how it was answered and where the
  /// resource it made or changed is, so a client reads it again rather than
  /// sending the write once more, and revokes a credential it cannot be shown
  /// again rather than creating a second one beside it.
  public struct ResponseMetadataIdempotentAnswer: Sendable, Hashable, Codable {
    /// The HTTP status the first request was answered with: a `2xx` whose
    /// answer carried a credential shown only once, an answer below `500`
    /// other than a `429` that was too large to keep whole, or the `5xx` a
    /// request was answered with after its write was made, such as a `504`
    /// when its time budget ran out once the write had been made.
    public var status: Int
    /// The path of what the write created, relative to this host: the
    /// `Location` its `201` carried, or, for a create whose operation says
    /// so, the path of what it made when the request failed with a `5xx`
    /// once that was made. Absent on every other answer, which names nothing
    /// the write created.
    public var location: String?
    /// The `ETag` that answer carried, the version of the resource it returned,
    /// to send as `If-Match` on the next write once the resource is read again.
    /// Absent where the answer carried none, as a `5xx` never does.
    public var etag: String?

    /// Creates a `ResponseMetadataIdempotentAnswer` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      status: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.status = status
      self.location = nil
      self.etag = nil
      configure(&self)
    }

    /// Reads a `ResponseMetadataIdempotentAnswer` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.status = try container.decode(Int.self, forKey: "status")
      self.location = try container.decodeIfPresent(String.self, forKey: "location")
      self.etag = try container.decodeIfPresent(String.self, forKey: "etag")
    }

    /// Writes a `ResponseMetadataIdempotentAnswer` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.status, forKey: "status")
      try container.encodeIfPresent(self.location, forKey: "location")
      try container.encodeIfPresent(self.etag, forKey: "etag")
    }
  }
}
