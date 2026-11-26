// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Members is every operation of `admin.members`, one method to an operation.
  public struct Members: Sendable {
    let sender: any OperationSending

    /// Remove a member from an organization, or leave it.
    ///
    /// Removes one member from the organization. What they created stays with the
    /// organization, and their seat is freed. A member naming themself in the path
    /// is leaving.
    /// - Removing somebody else takes the owner or admin role. Under a key,
    ///   removing a member who holds `admin` is a 403 whoever asks: the owner's
    ///   session under a key is answered as an admin's, and only the owner
    ///   removes an admin, signed in to Mountaya's web application.
    /// - Leaving is open to contributors and viewers. Under a key, an admin
    ///   naming themself is a 403, and so is the owner, answered as an admin
    ///   there: an admin leaves only from Mountaya's web application, since a
    ///   session token names whoever the holder of a secret key chose.
    /// - The owner cannot be removed, and cannot leave from Mountaya's web
    ///   application either: either is a 409. The owner hands the organization
    ///   to another member there first; the former owner is then an admin, who
    ///   leaves or is removed there.
    /// - Removing is an act on a membership rather than on a resource: for an
    ///   owner or admin, a `user_id` that matches no member who has joined the
    ///   organization answers 200 and changes nothing, whether or not an account
    ///   carries it, so a removal sent again, or racing another, is not an error.
    ///   An invitation is not a membership and is not withdrawn here:
    ///   `deleteOrganizationInvitation` withdraws it.
    /// - A member who has left holds no role, so a leave sent again is refused
    ///   with 403 unless it carries the first request's `Idempotency-Key`, which
    ///   answers it with the first one's 200.
    /// - The removed member's session tokens act as nobody in the organization
    ///   from their next request: every operation asking a role refuses them,
    ///   and every read, every tile and the Data API serve them published
    ///   content only, as the key alone is served.
    /// - Removing a member, or a member leaving, also ends every MCP connector
    ///   that person authorized through Mountaya's OAuth consent, whichever
    ///   organization's key it was bound to, when they joined the organization
    ///   themself, signed in to Mountaya's web application: by creating it or by
    ///   accepting its invitation there. The consents are ended for the person,
    ///   not for this organization. A connector bound to this organization's key
    ///   stops within a minute; one bound to another organization they still
    ///   belong to keeps working until its access token expires and, once the
    ///   consents are ended, cannot renew it, so they authorize it again. The
    ///   removal is answered `200` once the membership is removed: ending the
    ///   consents never fails that answer, waits on the provider for at most five
    ///   seconds, and is retried until it is done. A connector the person
    ///   authorizes again before it is done, for another organization or for this
    ///   one once invited back, is ended with the rest, and they authorize it
    ///   once more.
    /// - A membership accepted under a publishable key, with a session token
    ///   naming the person, ends none of their consents when it is removed: the
    ///   organization made it without a session of the person's own, so its
    ///   removal leaves their connectors to their other organizations alone. A
    ///   connector bound to this organization's key still stops within a minute,
    ///   since it is refused while the person is not a member. How the
    ///   membership was accepted decides, whoever removes it and whichever
    ///   credential the removal is sent under. A membership accepted before this
    ///   release counts as accepted in Mountaya's web application, however it
    ///   was accepted.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member of any role, whom the request acts as. A session
    /// token minted without `user_id` is refused with **401**, and a publishable
    /// key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func deleteOrganizationMember(
      organization_id: String,
      user_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationMember,
        pathParameters: ["organization_id": organization_id, "user_id": user_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's members.
    ///
    /// Returns everybody who has joined the organization, with the role each
    /// holds and when they joined. An invitation still waiting for an answer is
    /// not a member and is never listed here: `getOrganizationInvitations` lists
    /// those, and an invited person appears here once they accept. A member whose
    /// account cannot be resolved at that moment is listed without `name` and
    /// `email`.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user is a member of the organization, in any role, and is a 403
    ///   otherwise.
    /// - The writes beside it act as the user the session token names:
    ///   `patchOrganizationMember` changes a member's role, and
    ///   `deleteOrganizationMember` removes a member or lets one leave. The
    ///   owner's own acts, granting, taking away or removing `admin`, an admin
    ///   leaving and handing the organization to another member, are made only
    ///   by the owner, signed in to Mountaya's web application.
    /// - The listing pages by cursor. `role` narrows it to the members holding
    ///   one role, and `sort` orders it by `joined_at`, oldest first unless asked
    ///   otherwise. Follow `extensions.metadata.pagination.next_cursor` until it
    ///   reads `null`, which is the end of the listing.
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
    public func getOrganizationMembers(
      organization_id: String,
      query: AdminSchema.GetOrganizationMembersQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.OrganizationMember], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationMembers,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationMembers walks the listing `getOrganizationMembers` answers, one row at a
    /// time, requesting a page only as the rows before it are read (`transport.pagination.walk`).
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
    public func walkGetOrganizationMembers(
      organization_id: String,
      query: AdminSchema.GetOrganizationMembersQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationMembersQuery, AdminSchema.OrganizationMember
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationMembers(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Change a member's role.
    ///
    /// Changes what one member may do in the organization. The role is the whole
    /// of what a membership carries that a caller can change; the member keeps
    /// their `joined_at`, and the new role governs every request they make from
    /// the next one.
    /// - Owner or admin only (403 otherwise).
    /// - Under a key, `admin` is neither granted nor taken away: granting it, and
    ///   changing the role of a member who holds it, an admin's own role
    ///   included, is a 403 whoever asks. The owner's session under a key is
    ///   answered as an admin's, because a session token names whoever the
    ///   holder of a secret key chose, so these acts are made only by the owner,
    ///   signed in to Mountaya's web application. A key moves members between
    ///   `contributor` and `viewer`.
    /// - The owner's role cannot be changed, the owner's own request included: it
    ///   is a 409. Ownership moves only in Mountaya's web application, where the
    ///   owner hands it to another member and becomes an admin. `owner` is not a
    ///   value this takes, so asking for it is a 400.
    /// - A `user_id` that matches no member who has joined the organization is a
    ///   404, whether or not an account carries it, and whether or not an invitation
    ///   to that person is waiting. An invitation's role is not changed here:
    ///   withdraw it with `deleteOrganizationInvitation` and invite again.
    /// - Sending the role the member already holds changes nothing and answers the
    ///   member as they stand.
    /// - A change of role changes nothing about seats: a member holds one seat
    ///   whatever their role, so no role costs more than another and no change is
    ///   refused for the organization's seats.
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
    public func patchOrganizationMember(
      organization_id: String,
      user_id: String,
      body: AdminSchema.OrganizationMemberUpdateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationMember, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationMember,
        pathParameters: ["organization_id": organization_id, "user_id": user_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
