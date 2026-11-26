// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Explicit user feedback on one assistant message in an agent run: the thumb the
  /// user pressed.
  ///
  /// It carries no message content, only which message was rated and how, matching
  /// the metadata-only contract of the rest of the agent telemetry.
  public struct AgentRunFeedbackParams: Sendable, Hashable, Codable {
    /// The thumb being recorded against the assistant message named by
    /// `message_index`.
    public var rating: RestSchema.AgentRunFeedbackRating
    /// Zero-based index of the rated assistant message within the run's
    /// conversation. A run carries several answers, and a rating on the third is
    /// not a verdict on the first.
    ///
    /// Bounded at both ends: an index outside 0-65535 is rejected rather than
    /// accepted and applied to a different answer than the one rated.
    public var message_index: Int

    /// Creates a `AgentRunFeedbackParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      rating: RestSchema.AgentRunFeedbackRating,
      message_index: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.rating = rating
      self.message_index = message_index
      configure(&self)
    }

    /// Reads a `AgentRunFeedbackParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.rating = try container.decode(RestSchema.AgentRunFeedbackRating.self, forKey: "rating")
      self.message_index = try container.decode(Int.self, forKey: "message_index")
    }

    /// Writes a `AgentRunFeedbackParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.rating, forKey: "rating")
      try container.encode(self.message_index, forKey: "message_index")
    }
  }
}
