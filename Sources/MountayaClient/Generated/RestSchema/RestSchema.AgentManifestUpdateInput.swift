// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Input signal replacing the run's contextual client-tool manifest. The browser
  /// routes a narrower set of tools to the model as the task moves (terrain tools
  /// while measuring a slope, editing tools once an edit is armed), and sends this
  /// when that set changes, so the model chooses among a coherent handful instead
  /// of the whole registry. The new manifest applies from the next provider turn
  /// and replaces the previous one wholesale; it never widens what the run may
  /// execute, which stays gated by the caller's capabilities.
  public struct AgentManifestUpdateInput: Sendable, Hashable, Codable {
    /// Always `manifest-update` on this input, and what the server routes the
    /// request body on. The enum carries every input an open run accepts.
    ///
    /// It is always `manifest-update`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunInputType {
      "manifest-update"
    }
    /// The browser's client-tool schemas from this point on. Merged with the
    /// server tools into the schema list handed to the model; a client tool may
    /// not shadow a server tool. An empty array leaves the model with the server
    /// tools alone.
    ///
    /// The bound matches the one on a run's opening manifest and matters more
    /// here: this call is repeatable, and every update replaces the manifest the
    /// run replays on every continuation. Over the bound is a validation error,
    /// never a truncation.
    public var client_tools: [RestSchema.AgentClientToolManifest]
    /// Names of the server tools the routed surfaces permit from this point on.
    /// Omitted, the server-tool set is unchanged; present, the schema list handed
    /// to the model carries only the named server tools from the next turn. Names
    /// that are not server tools are ignored, so the caller may pass its whole
    /// routed tool set, each name in the client tool name's form, at most 64
    /// characters. Advisory over what the model can SEE, never over what may
    /// run. Under a publishable key a run calls no server tool, and a
    /// non-empty list is a `400` naming `server_tools`.
    public var server_tools: [String]?

    /// Creates a `AgentManifestUpdateInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      client_tools: [RestSchema.AgentClientToolManifest],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.client_tools = client_tools
      self.server_tools = nil
      configure(&self)
    }

    /// Reads a `AgentManifestUpdateInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.client_tools = try container.decode(
        [RestSchema.AgentClientToolManifest].self, forKey: "client_tools")
      self.server_tools = try container.decodeIfPresent([String].self, forKey: "server_tools")
    }

    /// Writes a `AgentManifestUpdateInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.client_tools, forKey: "client_tools")
      try container.encodeIfPresent(self.server_tools, forKey: "server_tools")
    }
  }
}
