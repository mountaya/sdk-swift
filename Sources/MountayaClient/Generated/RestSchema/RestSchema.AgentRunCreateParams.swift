// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for starting a new agent run. They are read once, when the run is
  /// created, and the run keeps them for its whole life: the `id` of the
  /// `AgentRun` returned addresses that run on every later call. A start is made
  /// at most once per `Idempotency-Key`, which is how a retried start resolves to
  /// the run the first one began.
  public struct AgentRunCreateParams: Sendable, Hashable, Codable {
    /// The user's first message that opens the conversation. It is trimmed before
    /// it is validated, so a message of only whitespace is rejected: it would
    /// otherwise start a run and spend a provider turn on nothing. The upper
    /// bound exists because this message is kept for the run's whole life and
    /// replayed on every continuation.
    public var message: String
    /// The organization the run belongs to, which owns the resource the co-pilot
    /// is opened on. It must be the key's organization. The user the session
    /// token names must hold a write role in it, and its AI provider configuration is
    /// what drives the model.
    public var organization_id: String
    /// Which prompt profile to seed the run with. The agent serves several
    /// surfaces and each has to be told which tools it actually holds, so this is
    /// chosen at creation and fixed for the life of the run. Omitted, it is
    /// `studio`.
    public var profile: RestSchema.AgentRunProfile?
    /// The browser's contextual client-tool schemas for this run. Merged with the
    /// server tools into the schema list handed to the model; a client tool may
    /// not shadow a server tool.
    ///
    /// The bound sits above the whole agent-visible client registry, so no routed
    /// set a caller can legitimately build is refused. It exists because the
    /// manifest is kept for the run's whole life and replayed on every
    /// continuation: an unbounded array here grows without limit for as long as
    /// the run lasts. Over the bound is a validation error, never a truncation.
    public var client_tools: [RestSchema.AgentClientToolManifest]?
    /// Names of the server tools the routed surfaces permit for this run.
    /// Omitted, the model sees every server tool; present, the schema list handed
    /// to the model carries only the named ones. Names that are not server tools
    /// are ignored, so the caller may pass its whole routed tool set. Advisory
    /// over what the model can SEE, exactly like the client manifest; execution
    /// authorization is unchanged.
    ///
    /// It carries the routed name set verbatim rather than the server tools
    /// alone, each name in the client tool name's form, at most 64 characters.
    ///
    /// Under a publishable key a run calls no server tool: what a server tool
    /// reads and computes is the Data API's, which the key's own `data` scope
    /// answers for. A non-empty list is then a `400` naming `server_tools`.
    public var server_tools: [String]?
    /// The caller's point-in-time studio snapshot, captured once by the browser
    /// at run start (active itinerary, current selection, enabled overlays,
    /// viewport, unit/locale preferences, and the available-overlay catalog). Its
    /// inner shape is not typed here (the client that builds it owns that), and
    /// it is passed through as sent with one exception: the overlay list at
    /// `catalog.overlays` is dropped, since the model can list overlays itself.
    /// It is surfaced to the model as a read-only system message seeding the
    /// transcript, so the run starts knowing the current UI state. It is never
    /// re-read mid-run. At most 32 top-level fields and 32 KiB as sent; over
    /// either is a `400` naming `context`.
    public var context: [String: JSONValue]?

    /// Creates a `AgentRunCreateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      message: String,
      organization_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.message = message
      self.organization_id = organization_id
      self.profile = nil
      self.client_tools = nil
      self.server_tools = nil
      self.context = nil
      configure(&self)
    }

    /// Reads a `AgentRunCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.message = try container.decode(String.self, forKey: "message")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.profile = try container.decodeIfPresent(
        RestSchema.AgentRunProfile.self, forKey: "profile")
      self.client_tools = try container.decodeIfPresent(
        [RestSchema.AgentClientToolManifest].self, forKey: "client_tools")
      self.server_tools = try container.decodeIfPresent([String].self, forKey: "server_tools")
      self.context = try container.decodeIfPresent([String: JSONValue].self, forKey: "context")
    }

    /// Writes a `AgentRunCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.message, forKey: "message")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encodeIfPresent(self.profile, forKey: "profile")
      try container.encodeIfPresent(self.client_tools, forKey: "client_tools")
      try container.encodeIfPresent(self.server_tools, forKey: "server_tools")
      try container.encodeIfPresent(self.context, forKey: "context")
    }
  }
}
