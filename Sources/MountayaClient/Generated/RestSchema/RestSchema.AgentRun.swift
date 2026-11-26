// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An agent run that `postAgentRun` started. The run itself happens after the
  /// answer: its events are read from `getAgentRunEvents`, which opens on the
  /// run's `id`.
  public struct AgentRun: Sendable, Hashable, Codable {
    /// Identifier of the run, the `run_id` `postAgentRunInput`,
    /// `getAgentRunEvents` and `postAgentRunFeedback` take.
    public var id: String
    /// The organization the run belongs to, the one the request named.
    public var organization_id: String
    /// The prompt profile the run was seeded with, fixed for its whole life.
    public var profile: RestSchema.AgentRunProfile
    /// When the run was started.
    public var created_at: Date

    /// Creates a `AgentRun` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      organization_id: String,
      profile: RestSchema.AgentRunProfile,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.profile = profile
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `AgentRun` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.profile = try container.decode(RestSchema.AgentRunProfile.self, forKey: "profile")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `AgentRun` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.profile, forKey: "profile")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
