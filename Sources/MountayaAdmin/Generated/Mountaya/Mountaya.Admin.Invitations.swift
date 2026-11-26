// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Invitations is every operation of `admin.invitations`, one method to an operation.
  public struct Invitations: Sendable {
    let sender: any OperationSending

    /// Withdraw a pending invitation.
    ///
    /// Withdraws an invitation still waiting for an answer, which frees its seat.
    /// The person it names cannot accept it afterwards, and the address may be
    /// invited again.
    /// - Owner or admin only (403 otherwise), whatever role the invitation
    ///   grants: withdrawing grants nothing.
    /// - Withdrawing is an act on the invitation's state rather than on a
    ///   resource, so an invitation already gone answers 200 and changes nothing:
    ///   one already declined, withdrawn or lapsed, and an identifier naming no
    ///   invitation of this organization at all. A withdrawal sent again, or
    ///   racing the person's own answer, is therefore not an error.
    /// - An invitation already accepted is gone as well: the person is a member,
    ///   and `deleteOrganizationMember` removes them.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func deleteOrganizationInvitation(
      organization_id: String,
      invitation_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationInvitation,
        pathParameters: ["organization_id": organization_id, "invitation_id": invitation_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve a pending invitation.
    ///
    /// Returns one invitation to the organization that is still waiting for an
    /// answer: the address it names, the role accepting grants, who made it, and
    /// when it lapses. Once the person accepts or declines it, or it is withdrawn
    /// or lapses, it is gone and its identifier is a 404; a person who accepted
    /// is a member `getOrganizationMembers` lists.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user is a member of the organization, in any role, and is a 403
    ///   otherwise.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationInvitation(
      organization_id: String,
      invitation_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationInvitation, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationInvitation,
        pathParameters: ["organization_id": organization_id, "invitation_id": invitation_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's pending invitations.
    ///
    /// Returns the invitations to the organization still waiting for an answer:
    /// the address each names, the role accepting grants, who made it, and when it
    /// lapses. An invitation leaves this listing when the person accepts it, and
    /// is then a member `getOrganizationMembers` lists, when they decline it, when
    /// it is withdrawn, or when it expires thirty days after it was made. Every
    /// invitation listed holds a seat.
    /// - It names addresses and never accounts: whether an account carries an
    ///   address is not part of the answer.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user is a member of the organization, in any role, and is a 403
    ///   otherwise. Inviting and withdrawing take the owner or admin role.
    /// - The listing pages by cursor. `role` narrows it to the invitations
    ///   granting one role, and `sort` orders it by `created_at`, newest first
    ///   unless asked otherwise. Follow
    ///   `extensions.metadata.pagination.next_cursor` until it reads `null`,
    ///   which is the end of the listing.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationInvitations(
      organization_id: String,
      query: AdminSchema.GetOrganizationInvitationsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.OrganizationInvitation], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationInvitations,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationInvitations walks the listing `getOrganizationInvitations` answers, one
    /// row at a time, requesting a page only as the rows before it are read
    /// (`transport.pagination.walk`).
    ///
    /// Every request sends `query`, its filters and `sort` included, with its `limit` replaced by
    /// `pageSize`, from 1 to 100, and its `cursor` by the one the walk has reached, starting from
    /// `query`'s own, so a walk resumes where an earlier one stopped. It follows every page for as
    /// long as a `next_cursor` names one, an empty page included, and stops at a null
    /// `next_cursor`, at `maxPages` requests, which raises nothing, or at a cursor it has already
    /// sent, which raises the base `APIError`. A cancelled task requests no further page.
    ///
    /// `options` overrides what every request of the walk may of the client's configuration. It
    /// throws `ConfigurationError` for a `pageSize` or a `maxPages` out of its range, before any
    /// request.
    public func walkGetOrganizationInvitations(
      organization_id: String,
      query: AdminSchema.GetOrganizationInvitationsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationInvitationsQuery, AdminSchema.OrganizationInvitation
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationInvitations(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Invite somebody to an organization by email.
    ///
    /// Invites one address, with the role the person holds once they accept. A
    /// client inviting several people sends one request for each. Nothing is sent
    /// to the address: telling the person is the caller's to do. The person finds
    /// the invitation through `getMyInvitations` once their account has verified
    /// the address, under a session token `postSession` mints for them before they
    /// have joined, and answers it with `postMyInvitationAccept` or
    /// `deleteMyInvitation`.
    /// - Owner or admin only (403 otherwise). Under a key, inviting as `admin` is
    ///   a 403 whoever asks, the owner included, whose session under a key is
    ///   answered as an admin's: only the owner invites an admin, signed in to
    ///   Mountaya's web application.
    /// - Any well-formed address is accepted, stored trimmed and lowercased, and
    ///   answered alike whether or not an account carries it, so this cannot be
    ///   used to learn which addresses have accounts. An address no account
    ///   carries waits for the person to sign up and verify it.
    /// - An address that already belongs to a member, or that already has an
    ///   invitation waiting for an answer, is a 409 naming which, so a second
    ///   request for one address never makes a second invitation. To change the
    ///   role of a waiting invitation, withdraw it with
    ///   `deleteOrganizationInvitation` and invite again.
    /// - `owner` is never granted by invitation, so asking for it is a 400.
    /// - Every invitation holds a seat from the moment it is made, and seats count
    ///   the organization's members and its unexpired invitations together. One
    ///   that would take that count past the seats the organization's agreement
    ///   allows is a 429 coded `LIMIT_REACHED`, whose `extensions.metadata.limit`
    ///   reads `seats`; an agreement that names no seat limit allows any number.
    ///   Invitations sent at the same moment cannot both take the last seat. It
    ///   clears when a member is removed or leaves, an invitation is declined,
    ///   withdrawn or lapses, or the organization's agreement allows more seats.
    /// - At most 500 invitations wait at once in an organization: one more is a
    ///   429 coded `LIMIT_REACHED`, whose `extensions.metadata.limit` reads
    ///   `pending-invitations`, and which no agreement raises, so it clears only
    ///   as invitations are answered, withdrawn or lapse.
    /// - Neither ceiling carries `Retry-After`, since no wait lifts it, and
    ///   `extensions.metadata` carries how many it allows, `allowed`, and how
    ///   many are held, `used`. Nothing is invited. The seats are asked before
    ///   the invitations waiting, and both after every other refusal, so a request
    ///   refused with a `400`, a `409`, or a `403` for the caller's role is
    ///   answered that way whatever is left of either.
    /// - An invitation lapses thirty days after it is made if nobody answers it,
    ///   which frees its seat and lets the address be invited again.
    /// - Invitations are limited to 30 per minute for the user the session token
    ///   names, and to 200 per day for the organization; past either limit the
    ///   answer is a `429` carrying `Retry-After`. An invitation counts toward the
    ///   organization's day only once the user is known to be one of its owners or
    ///   admins and the request is well formed: one refused with a `400`, or with
    ///   the `403` of a role that may not send it, never spends it, so nobody
    ///   outside the organization can use up its day.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postOrganizationInvitation(
      organization_id: String,
      body: AdminSchema.OrganizationInvitationCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationInvitation, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationInvitation,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
