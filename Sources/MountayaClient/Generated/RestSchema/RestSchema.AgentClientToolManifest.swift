// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Schema of a single browser-executed client tool the agent run may call. The
  /// browser sends one manifest entry per contextual tool it can run on behalf of
  /// the run; they are merged with the server tools into the schema list handed to
  /// the model. A client tool may not shadow a server tool.
  public struct AgentClientToolManifest: Sendable, Hashable, Codable {
    /// Stable namespaced name of the client tool, for example
    /// `studio.collection.addItinerary`: dot-separated segments of letters,
    /// digits and hyphens, at most 64 characters, and unique within the
    /// manifest. It is not a display name: it is an identifier the model calls
    /// and the browser dispatches on, so the 2 to 30 characters that bound every
    /// name a person reads do not apply to it. A name outside this form, or one
    /// appearing twice, is a 400.
    public var name: String
    /// Natural-language description of the tool, fed to the model's tool
    /// selection. Read by a model rather than shown to a person, so the
    /// 100-character ceiling that bounds every description a person reads does
    /// not apply to it; it holds at most 2000 characters.
    public var description: String
    /// JSON Schema object describing the tool's arguments. It is forwarded to
    /// the model as sent, except where the organization's AI provider accepts
    /// only a plain object schema: there a top-level `anyOf`, `oneOf` or `allOf`
    /// is flattened into one object, `"type": "object"` is added where it is
    /// missing, and a value that is not an object becomes an empty object
    /// schema. The browser still validates every call against its own schema.
    /// At most 32 top-level fields and 16 KiB as sent.
    public var parameters: [String: JSONValue]
    /// Whether calling the tool only reads state and changes nothing. The run
    /// uses this to compact its transcript: a superseded read is dropped, while
    /// anything that may have changed the world is retained verbatim. Omitted
    /// when unknown, which the run treats as "may mutate" and never drops.
    public var read_only: Bool?
    /// Whether running the tool interrupts the user with a confirmation prompt
    /// before it takes effect. It is restated in the tool description the model
    /// is given, so the model can sequence an interrupting tool last rather than
    /// stalling a multi-step sequence midway. Omitted when false.
    public var confirms: Bool?

    /// Creates a `AgentClientToolManifest` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      name: String,
      description: String,
      parameters: [String: JSONValue],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.description = description
      self.parameters = parameters
      self.read_only = nil
      self.confirms = nil
      configure(&self)
    }

    /// Reads a `AgentClientToolManifest` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.description = try container.decode(String.self, forKey: "description")
      self.parameters = try container.decode([String: JSONValue].self, forKey: "parameters")
      self.read_only = try container.decodeIfPresent(Bool.self, forKey: "read_only")
      self.confirms = try container.decodeIfPresent(Bool.self, forKey: "confirms")
    }

    /// Writes a `AgentClientToolManifest` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encode(self.description, forKey: "description")
      try container.encode(self.parameters, forKey: "parameters")
      try container.encodeIfPresent(self.read_only, forKey: "read_only")
      try container.encodeIfPresent(self.confirms, forKey: "confirms")
    }
  }
}
