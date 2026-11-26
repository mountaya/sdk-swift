// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Users is every operation of `admin.users`, one method to an operation.
  public struct Users: Sendable {
    let sender: any OperationSending

    /// Decline an invitation.
    ///
    /// Declines an invitation waiting for the user the session token names, which
    /// frees the seat it held. The organization sees it leave
    /// `getOrganizationInvitations`, and may invite the address again.
    /// - Only the invited person declines, and only an invitation that is theirs:
    ///   one made to an address their account has verified, to the key's
    ///   organization.
    /// - Declining is an act on the invitation's state rather than on a resource,
    ///   so an identifier naming nothing waiting for this user answers 200 and
    ///   changes nothing: an invitation already declined, withdrawn or lapsed,
    ///   another person's, one to an address the account has not verified, and
    ///   one that never existed. A decline racing a withdrawal is therefore not
    ///   an error, and nobody learns from it which invitation ids exist.
    /// - A user whose declined invitation was their only tie to the organization
    ///   holds nothing there afterwards, so a decline they send again is refused
    ///   with 403 unless it carries the first request's `Idempotency-Key`, which
    ///   answers it with the first one's 200.
    /// - An invitation already accepted is gone as well: the person is a member,
    ///   and leaves with `deleteOrganizationMember`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, the invited person, whom
    /// the request acts as. A publishable key without a session token minted for
    /// `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func deleteMyInvitation(
      invitation_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteMyInvitation,
        pathParameters: ["invitation_id": invitation_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the invitations waiting for the acting user.
    ///
    /// Returns the invitations waiting for an answer from the user the session
    /// token names, each with the organization's name and the products it holds
    /// and the role accepting grants, so a person can decide without a second
    /// read. Under a publishable key that is the invitations to the key's
    /// organization alone.
    ///
    /// An invitation is the user's when it was made to an address their account
    /// has VERIFIED. One made to an address the account carries unverified is not
    /// listed, and is listed from the moment the account verifies it, so nobody
    /// reads an invitation by claiming an address they do not hold. A lapsed
    /// invitation is not listed.
    /// - A user who has not joined the organization reaches this with the session
    ///   token `postSession` mints for them because an invitation is waiting for
    ///   them: that is how an invited person answers before joining.
    /// - `postMyInvitationAccept` accepts an invitation and `deleteMyInvitation`
    ///   declines it.
    /// - The listing pages by cursor, newest invitation first, with invitations
    ///   made at the same instant ordered by `id`; the order is not the
    ///   caller's to choose, so the listing takes no `sort`. Follow
    ///   `extensions.metadata.pagination.next_cursor` until it reads `null`,
    ///   which is the end of the listing.
    ///
    /// Like every read made with a session token, it is limited to 1200 a minute
    /// per user the token names and then to 6000 a minute per organization; past
    /// either, the answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member of any role or a
    /// user whose invitation to the key's organization is waiting, whom the
    /// request acts as. A publishable key without a session token minted for
    /// `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    public func getMyInvitations(
      query: AdminSchema.GetMyInvitationsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.UserInvitation], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getMyInvitations,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetMyInvitations walks the listing `getMyInvitations` answers, one row at a time,
    /// requesting a page only as the rows before it are read (`transport.pagination.walk`).
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
    public func walkGetMyInvitations(
      query: AdminSchema.GetMyInvitationsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetMyInvitationsQuery, AdminSchema.UserInvitation
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getMyInvitations(query: page, options: options)
      }
    }

    /// Retrieve the acting user's notification emails for an organization.
    ///
    /// Returns which notification emails about the organization the user the session token
    /// names receives. Every one is on until the member turns it off, and the security
    /// notifications, a role changed or a removal made by somebody else, are always sent:
    /// they are listed locked, with the reason.
    /// - An owner and an admin are listed the notifications about the organization's
    ///   webhook endpoints as well; a contributor and a viewer are not, and are sent none.
    /// - The invitation email goes to an address before it belongs to a member, and is
    ///   never listed.
    ///
    /// Like every read made with a session token, it is limited to 1200 a minute per user
    /// the token names and then to 6000 a minute per organization; past either, the answer
    /// is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session token
    /// minted for `studio-embedded` naming a user, a member of the key's organization in
    /// any role, whom the request acts as. A publishable key without a session token minted
    /// for `studio-embedded` naming a user, a token minted for another surface included, is
    /// refused with **401**.
    public func getMyOrganizationNotificationPreferences(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.NotificationPreferences, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getMyOrganizationNotificationPreferences,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the acting user's memberships.
    ///
    /// Returns the memberships of the user the session token names, each carrying
    /// the organization's name and the products it holds beside the role, so a
    /// client can label the organization it acts in, and tell whether it holds
    /// Map Studio, without a second read. Under a publishable key that is the
    /// user's membership of the key's organization alone: a one-entry list, or an
    /// empty one while the user has not joined it, as a user whose invitation is
    /// still waiting has not. An invitation is not a membership:
    /// `getMyInvitations` lists those.
    ///
    /// Each entry also says what the user may use in the studio there:
    /// `studio_entitlements`, the features the organization's agreement covers
    /// for that member's role, Map Publishing's publishing, video export and
    /// embed among them. Read with a key, the features are narrowed by the
    /// organization's safety rules, as what the key is served is: the points of
    /// interest, the other overlays and the profile analysis each follow the rule
    /// that governs them. An Embedded Studio reads its viewer from them, so it
    /// shows what the agreement covers with no mapping of products to features of
    /// its own.
    ///
    /// The listing pages by cursor like every listing of what an organization or
    /// its members create, so a client written against it reads
    /// `extensions.metadata.pagination.next_cursor` and stops at `null`, which
    /// under a publishable key is always the first page. Memberships come in
    /// the order of the organizations' names; the order is not the caller's to
    /// choose, so the listing takes no `sort`.
    ///
    /// Like every read made with a session token, it is limited to 1200 a minute
    /// per user the token names and then to 6000 a minute per organization; past
    /// either, the answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member of any role or a
    /// user whose invitation to the key's organization is waiting, whom the
    /// request acts as. A publishable key without a session token minted for
    /// `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    public func getMyOrganizations(
      query: AdminSchema.GetMyOrganizationsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.Membership], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getMyOrganizations,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetMyOrganizations walks the listing `getMyOrganizations` answers, one row at a time,
    /// requesting a page only as the rows before it are read (`transport.pagination.walk`).
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
    public func walkGetMyOrganizations(
      query: AdminSchema.GetMyOrganizationsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetMyOrganizationsQuery, AdminSchema.Membership
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getMyOrganizations(query: page, options: options)
      }
    }

    /// Retrieve the acting user's display preferences.
    ///
    /// Returns the six preferences the user the session token names reads and
    /// renders by: the language, the theme, and the units of length, pace, slope
    /// and temperature.
    ///
    /// They belong to the PERSON, not to an organization, so the same six are
    /// read in every organization the user is a member of. They shape rendering
    /// only: no operation returns different figures because of them, and a client
    /// formats what it is given.
    ///
    /// Like every read made with a session token, it is limited to 1200 a minute
    /// per user the token names and then to 6000 a minute per organization; past
    /// either, the answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member of the key's
    /// organization in any role, whom the request acts as. A publishable key
    /// without a session token minted for `studio-embedded` naming a user, a token
    /// minted for another surface included, is refused with **401**.
    public func getMyPreferences(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.Preferences, [String: JSONValue]?> {
      let request = OperationRequest(facts: .getMyPreferences)
      return try await sender.envelope(request, options: options)
    }

    /// Turn the acting user's notification emails for an organization on or off.
    ///
    /// Turns notification emails about the organization on or off for the user the session
    /// token names, and answers them all afterwards. A notification left out keeps its
    /// setting. A user changes their own and nobody else's, so the operation takes no user
    /// id: it writes those of the user the session token names.
    /// - A security notification, `member-role-changed` or `member-removed`, is always
    ///   sent: naming one is a `400` naming it, and nothing is changed. So is naming
    ///   `invitation`, which no member is sent, or a webhook endpoint's notification as a
    ///   contributor or a viewer.
    /// - Any role changes them, a viewer's included, since they change nothing the
    ///   organization holds.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session token
    /// minted for `studio-embedded` naming a user, a member of the key's organization in
    /// any role, whom the request acts as. A publishable key without a session token minted
    /// for `studio-embedded` naming a user, a token minted for another surface included, is
    /// refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func patchMyOrganizationNotificationPreferences(
      organization_id: String,
      body: AdminSchema.NotificationPreferencesUpdateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.NotificationPreferences, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchMyOrganizationNotificationPreferences,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update the acting user's display preferences.
    ///
    /// Changes any of the six preferences the user the session token names reads
    /// and renders by, and returns all six afterwards. Every field is optional and
    /// independent: what is sent is changed, what is omitted is left alone, and
    /// the reply is the whole set rather than the part that moved.
    ///
    /// They belong to the PERSON, not to an organization, so a change follows the
    /// user into every organization they are a member of. They shape rendering
    /// only: no operation returns different figures because of them, and a client
    /// formats what it is given. A user changes their own preferences and nobody
    /// else's, so the operation takes no user id: it writes those of the user the
    /// session token names.
    ///
    /// Any role changes them, a viewer's included, since they change nothing the
    /// organization holds.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member of the key's
    /// organization in any role, whom the request acts as. A publishable key
    /// without a session token minted for `studio-embedded` naming a user, a token
    /// minted for another surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func patchMyPreferences(
      body: AdminSchema.PreferencesUpdateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.Preferences, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchMyPreferences,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Accept an invitation.
    ///
    /// Accepts an invitation waiting for the user the session token names, which
    /// makes them a member of the organization with the role it grants, and
    /// answers the membership. The invitation is consumed: it leaves
    /// `getMyInvitations` and `getOrganizationInvitations`, and the person is
    /// listed by `getOrganizationMembers` from then on.
    /// - Only the invited person accepts. An invitation is theirs when it was made
    ///   to an address their account has verified, and is to the key's
    ///   organization. Any other identifier is a 404: an invitation to an address
    ///   the account has not verified, another person's, one already answered,
    ///   withdrawn or lapsed, and one that names nothing all answer alike.
    /// - It takes no seat. The invitation has held its seat since it was made, so
    ///   accepting is never refused for the organization's seats.
    /// - The session token the person used before joining needs no replacing: it
    ///   acts as the member, in the role granted, from the next request.
    /// - Accepting consumes the invitation, so the same request sent again is a
    ///   404 and changes nothing, unless it carries the first request's
    ///   `Idempotency-Key`, which answers it with the first one's 200.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, the invited person, whom
    /// the request acts as. A publishable key without a session token minted for
    /// `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postMyInvitationAccept(
      invitation_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.Membership, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postMyInvitationAccept,
        pathParameters: ["invitation_id": invitation_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
