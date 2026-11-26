// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Parameters for creating a session. Requires a valid publishable key value,
  /// and names the user the session acts as where it will act as one.
  public struct SessionCreateParams: Sendable, Hashable, Codable {
    /// The publishable key value to bind the session to. Always the `pk_` prefix
    /// followed by 32 lowercase hexadecimal characters, 35 in all, the shape
    /// every key is minted with.
    public var publishable_key: String
    /// The user the session acts as, which your backend asserts: a member of the
    /// publishable key's organization, or a user whose invitation to it is still
    /// pending, matched by an address the user's account has verified. The
    /// token is signed with it, and every operation whose `x-acting-user` is
    /// `required` acts as the user the token names, so a page holding the token
    /// acts as this user and nobody else. A `management` read under the token is answered only
    /// while this
    /// user holds the role that read asks of a member of the organization. The
    /// session governs the members with at most an admin's say, whoever it
    /// names: a session naming the owner is answered as an admin's on the
    /// owner's own acts, which are made only signed in to Mountaya's web
    /// application. A user who is neither a member nor invited answers `403`,
    /// the same answer whether or not the user exists, and nothing is minted.
    ///
    /// Omitted, the session is minted without `user_id`, and no operation whose
    /// `x-acting-user` is `required` accepts it. Whatever its surface, it reads
    /// what the publishable key alone does: the last published snapshot and
    /// never a draft, and public-only listings. Minted for `api` it also makes
    /// every `management` read its key's `management` scope allows, so a
    /// session minted without `user_id` for a key carrying `management` stays
    /// on your own backend, and one you hand to a page is minted for a key
    /// without `management`; minted for `studio-embedded`, for an Embedded
    /// Studio's read-only viewer, it makes no `management` read, which answers
    /// it `401`. Name a member when a backend or a viewer must read drafts. A
    /// malformed value, or the nil UUID, is a `400` naming the field.
    public var user_id: String?
    /// The surface the session is minted for, which it keeps for its whole
    /// life. Omitted, it is `api`, the surface of your own clients.
    ///
    /// Ask for `studio-embedded` for every Embedded Studio you mount, the
    /// editor and its read-only viewer alike: it is the only session a
    /// `studio-embedded` operation accepts, and what the studio then reaches on
    /// the Data API and the Tile API is recorded as `studio-embedded` usage and
    /// never counted toward the organization's limits, allowances or invoice.
    /// It is minted only for a publishable key that reaches the
    /// `studio-embedded` scope, and a key that does not is a `403`, and only
    /// for an organization that holds Embedded Studio, one that does not being
    /// the `402` a `studio-embedded` operation answers. It may name a member,
    /// for the editor, or be minted without `user_id`, for a viewer that only
    /// reads, which is then served what the publishable key alone is: published
    /// content and never a draft, and the organization's private resources only
    /// by their id, never in a listing.
    ///
    /// `mcp` is minted only for Mountaya's MCP server, and asked for here it is
    /// a `403`.
    public var surface: RestSchema.SessionSurface?

    /// Creates a `SessionCreateParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      publishable_key: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.publishable_key = publishable_key
      self.user_id = nil
      self.surface = nil
      configure(&self)
    }

    /// Reads a `SessionCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.publishable_key = try container.decode(String.self, forKey: "publishable_key")
      self.user_id = try container.decodeIfPresent(String.self, forKey: "user_id")
      self.surface = try container.decodeIfPresent(
        RestSchema.SessionSurface.self, forKey: "surface")
    }

    /// Writes a `SessionCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.publishable_key, forKey: "publishable_key")
      try container.encodeIfPresent(self.user_id, forKey: "user_id")
      try container.encodeIfPresent(self.surface, forKey: "surface")
    }
  }
}
