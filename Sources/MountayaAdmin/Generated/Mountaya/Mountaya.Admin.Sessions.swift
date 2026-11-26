// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Sessions is every operation of `admin.sessions`, one method to an operation.
  public struct Sessions: Sendable {
    let sender: any OperationSending

    /// Create a session token using a secret key.
    ///
    /// Creates a short-lived session token by exchanging a secret key and a
    /// publishable key. The `X-API-Key` header with an `sk_` value is required to
    /// authenticate this request. The token accompanies the publishable key it is
    /// minted against: every Data API request, every `management` operation and
    /// every `studio-embedded` operation require one beside the key.
    ///
    /// Give it `surface` to say what the token is for. Omitted, it is `api`, the
    /// surface of your own clients. Every Embedded Studio you mount, the editor
    /// and its read-only viewer alike, needs a token minted for
    /// `studio-embedded`: it is the only token a `studio-embedded` operation
    /// accepts, a token minted for any other surface being a `401` there, and
    /// what the studio reaches with it on the Data API and the Tile API is
    /// recorded as `studio-embedded` usage and never counted toward the
    /// organization's limits, allowances or invoice. Such a token is minted only
    /// for a publishable key that reaches the `studio-embedded` scope, and a key
    /// that does not is a `403`, and only for an organization that holds
    /// Embedded Studio, one that does not being the `402` a `studio-embedded`
    /// operation answers. It names a member for the editor, or is minted without
    /// `user_id` for a viewer, which acts as nobody and, like every token minted
    /// without `user_id`, reads what the publishable key alone does. A viewer
    /// that must show drafts takes a token naming the member who looks. A token
    /// already minted stays valid for its whole life whatever the organization
    /// holds, but what it reaches on the Data API and the Tile API while the
    /// organization does not hold Embedded Studio is recorded and counted as
    /// `api` usage.
    ///
    /// Give it `user_id` to mint a token naming one user, as your backend asserts
    /// after signing that user in to your own product: a member of the key's
    /// organization, or a user whose verified email address has a pending
    /// invitation to it. The token names that user for its whole life and no
    /// header can name anybody else, so a page holding it acts as that user and
    /// nobody else. The answer's `user_id` is the user the token names, or null
    /// for a token minted without one.
    /// - A token naming a user is what acting as a user requires. Every operation
    ///   whose `x-acting-user` is `required`, which is every `studio-embedded`
    ///   operation, every `management` write and every operation under `/v1/me`,
    ///   refuses with a `401` a token minted without `user_id`, and acts as the
    ///   user the token names, answered only while that user holds the role it
    ///   asks. A user whose invitation is still pending holds no role, and
    ///   reaches only the operations under `/v1/me` marked `x-pending-invitee`.
    /// - The session acts as that member with at most an admin's say over the
    ///   organization's members. Any admin can create the secret key that mints a
    ///   session, and the session can name any member, so the owner's own acts,
    ///   granting, taking away or removing `admin`, inviting an admin, an admin
    ///   leaving and handing the organization on, are refused under any session
    ///   with a `403`, a session naming the owner included: the owner makes them
    ///   signed in to Mountaya's web application.
    /// - A token minted without `user_id` reads what the publishable key alone
    ///   does, whatever surface it was minted for: the last published snapshot
    ///   and never a draft, and public-only listings, and a backend that must
    ///   read drafts mints for a member. It reaches no operation that acts as a
    ///   user. Minted for `api` against a key that carries `management`, it
    ///   reaches every `management` read with no member role asked, so such a
    ///   token stays on your own backend; a token you hand to an anonymous
    ///   visitor is minted for a key without `management`. Minted for
    ///   `studio-embedded`, the `management` reads answer it the `401` a key
    ///   alone gets.
    /// - On a `management` read, a token naming a user is answered only while
    ///   that user holds the role the read asks of a member of the organization,
    ///   and is otherwise the `403` a member without that role gets.
    ///
    /// A token is valid for at most five minutes. A token minted moments earlier
    /// for the same publishable key, the same surface and the same user, or for
    /// the same key and surface and no user, is returned again while it has more
    /// than two minutes to run, so read `expires_at` rather than assuming the
    /// full lifetime. Sending the same
    /// request twice is harmless for that reason: the second is answered the
    /// first one's token, or another for the same key and user, and every token
    /// stays valid until its own expiry.
    ///
    /// An unknown, revoked or malformed secret key is a `401`, the same answer as
    /// sending none, and so is a key of an organization that has been canceled,
    /// so this operation cannot be used to learn which secret keys exist.
    ///
    /// Five limits hold this operation, and each is answered `429` with
    /// `Retry-After`, the seconds left in the minute:
    /// - Each client IP address, an IPv6 address counted by its `/64` prefix, may
    ///   fail 60 times a minute. Only a request that fails counts toward it, so a
    ///   backend minting tokens for many users from one address is never held to
    ///   it while its requests succeed. A request Mountaya's MCP server forwards
    ///   is counted against the address of the person it acts for, which the
    ///   server forwards, rather than against the server's own, and that address
    ///   may fail 6,000 times a minute there: an assistant reaches the MCP server
    ///   from a few addresses its provider shares among all its users, so one
    ///   organization's failing key would otherwise lock out every other
    ///   organization's sessions behind the same address.
    /// - Each secret key may fail 10 times a minute with a `401`, `403` or `404`.
    ///   Past that it is refused for the rest of the minute, even on a request
    ///   that is otherwise correct: a deployment pairing its secret key with a
    ///   wrong or revoked publishable key locks that secret key out until the
    ///   minute ends.
    /// - A `403` for `user_id` counts toward a limit of its own instead, 10 a
    ///   minute for that secret key and that `user_id`: a token asked for somebody
    ///   who has left the organization never locks out the tokens asked for
    ///   everybody else.
    /// - A refusal for `surface` counts toward a limit of its own instead, 10 a
    ///   minute for that secret key and that surface: the `403` of `mcp`, the
    ///   `402` of `mcp` that Mountaya's MCP server is answered for an
    ///   organization that does not hold the Data API, the `402`
    ///   of `studio-embedded` for an organization that does not hold Embedded
    ///   Studio and its `403` for a key that does not reach the
    ///   `studio-embedded` scope. Pages asking for a `studio-embedded` token for
    ///   an organization whose agreement does not include Embedded Studio never
    ///   lock out the tokens the same secret key asks for any other surface.
    /// - Each secret key mints at most 6000 tokens a minute. Only a token actually
    ///   minted counts toward it, and a token returned again is free. This
    ///   ceiling, not the failure limits, is what bounds a secret key that has
    ///   leaked: its requests succeed, so no failure is counted, and it mints at
    ///   most 6000 tokens a minute until it is revoked.
    ///
    /// Requires no publishable-key scope of its own: the secret key is the
    /// credential, and the publishable key named in the body is the subject of the
    /// session rather than the caller. The calling-page refusal in this document's
    /// introduction does not apply here.
    public func postSession(
      body: AdminSchema.SessionCreateParams,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Session, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postSession,
        body: .json(body)
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
