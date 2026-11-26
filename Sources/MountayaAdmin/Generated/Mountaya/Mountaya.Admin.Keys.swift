// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Keys is every operation of `admin.keys`, one method to an operation.
  public struct Keys: Sendable {
    let sender: any OperationSending

    /// Revoke a publishable key.
    ///
    /// Revokes a publishable key. Mountaya answers every client still presenting
    /// it with a 401 from its next request, so revoke a key that has leaked and
    /// create its replacement first if the surface using it cannot go dark. An
    /// answer a shared cache already holds for the key is served from there until
    /// its lifetime runs out, which no revocation shortens: at most 5 minutes for
    /// a public tile, 6 for a published itinerary read or its pace, and 25 hours
    /// for the layer catalog, as each of those reads states in its
    /// `Cache-Control`.
    /// - Owner or admin only (403 otherwise).
    /// - It cannot be undone. A revoked key stays in
    ///   `getOrganizationPublishableKeys` carrying `revoked_at`, and is never
    ///   accepted again.
    /// - The answer is the revoked key, carrying `revoked_at`, with its `ETag`.
    ///   Revoking a key already revoked changes nothing and answers 200 again
    ///   with the key as it stands, so a revocation is safe to repeat.
    /// - Revoking the key a session was minted against ends that session too: a
    ///   session token names the key it was issued for, and a stream opened with
    ///   it ends with a `reconnect` event whose reason is `credential-revoked`.
    /// - `If-Match` makes the revocation conditional: send the key's `etag`, and
    ///   a key changed since is refused with `412`, revoking nothing.
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
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteOrganizationPublishableKey(
      organization_id: String,
      key_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PublishableKey, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationPublishableKey,
        pathParameters: ["organization_id": organization_id, "key_id": key_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve a publishable key.
    ///
    /// Returns one of the organization's publishable keys, as
    /// `getOrganizationPublishableKeys` lists it: its scopes, when it was created,
    /// when a request last presented it, and `revoked_at` once it is revoked. A
    /// revoked key is still returned, so the key a `Location` or an audit names
    /// can always be read back. The key value itself is returned in full, as on
    /// every read.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user holds the owner or admin role in the organization, and is a 403
    ///   otherwise.
    /// - The answer's `ETag` is the key's `etag`. Send it as `If-Match` on
    ///   `patchOrganizationPublishableKey` or `deleteOrganizationPublishableKey`
    ///   to make the change conditional on nobody having changed the key since.
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
    public func getOrganizationPublishableKey(
      organization_id: String,
      key_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PublishableKey, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationPublishableKey,
        pathParameters: ["organization_id": organization_id, "key_id": key_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's publishable keys.
    ///
    /// Returns the publishable keys the organization holds, revoked ones
    /// included, each with its scopes, when it was created and when a request last
    /// presented it. The key value itself is returned in full: a publishable key is
    /// meant to be seen, which is what distinguishes it from the secret key that
    /// mints sessions.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user holds the owner or admin role in the organization, and is a 403
    ///   otherwise. Creating, changing and revoking keys take the same role, held
    ///   by the user the session token names, which a write requires.
    /// - A revoked key carries `revoked_at` and stays in the listing, so an audit
    ///   of what was once in circulation does not need a second source.
    /// - `scope` keeps the keys given that scope, revoked ones included.
    /// - The listing is paged. Nothing caps how many keys an organization mints,
    ///   so a page holds 50 keys unless `limit` says otherwise, most recently
    ///   created first unless `sort` says otherwise. Send the page's
    ///   `next_cursor` back as `cursor` for the next one; the last page reports
    ///   `next_cursor: null`.
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
    public func getOrganizationPublishableKeys(
      organization_id: String,
      query: AdminSchema.GetOrganizationPublishableKeysQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.PublishableKey], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationPublishableKeys,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationPublishableKeys walks the listing `getOrganizationPublishableKeys`
    /// answers, one row at a time, requesting a page only as the rows before it are read
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
    public func walkGetOrganizationPublishableKeys(
      organization_id: String,
      query: AdminSchema.GetOrganizationPublishableKeysQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationPublishableKeysQuery, AdminSchema.PublishableKey
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationPublishableKeys(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Update a publishable key's name or scopes.
    ///
    /// Changes what a key is called, what it reaches, or both. Each field is
    /// optional and an omitted one is left alone, but `scopes` is replaced whole
    /// rather than merged: a request that sends it lists every scope the key is to
    /// keep, and a scope left out is removed. Mountaya answers the key's next
    /// request by its new scopes, so a page still holding it starts getting 403
    /// on what it stops reaching. An answer a shared cache already holds for the
    /// key is served from there until its lifetime runs out: at most 5 minutes
    /// for a public tile, 6 for a published itinerary read or its pace
    /// (`max-age=300` and `stale-while-revalidate=60`), and 25 hours for the
    /// layer catalog (`max-age=86400` and `stale-while-revalidate=3600`).
    /// - Owner or admin only (403 otherwise).
    /// - A key carrying `management` carries no other scope. A `scopes` list
    ///   naming `management` beside another scope is a `400` and nothing is
    ///   changed, the name included: the answer carries one `VALIDATION_FAILED`
    ///   entry per scope listed beside `management`, each naming that scope's
    ///   position in `scopes`. It is asked whatever the key carries now, and
    ///   before any scope's product, so such a list is never answered `402`.
    /// - A key carrying `studio-embedded` carries `tiles` and `data` beside it,
    ///   the scopes its editor's map and previews are requested under. A
    ///   `scopes` list naming `studio-embedded` without one of them is a `400`
    ///   and nothing is changed, the name included: the answer carries one
    ///   `VALIDATION_FAILED` entry per missing scope, each naming `scopes`.
    ///   Neither is added for the caller, it is asked whatever the key carries
    ///   now, and before any scope's product, so such a list is never answered
    ///   `402`.
    /// - A scope the key does not already carry can be granted only while the
    ///   organization holds its product. Granting one it does not hold is a `402`
    ///   and nothing is changed, the name included: the answer carries one entry
    ///   per refused scope, each naming that scope's position in `scopes`.
    /// - A scope the key already carries is kept even when its product has since
    ///   been switched off, so sending a key its own list back is never refused.
    ///   Such a scope answers `402` wherever a request uses it, until the product
    ///   returns.
    /// - The key is given exactly the list sent: none is added because another is
    ///   present.
    /// - An empty `scopes` list is a `400` naming `scopes`, as it is on creation:
    ///   a key carries at least one scope.
    /// - The `pk_` value never changes. Replacing a key that has leaked is revoking
    ///   it and creating another.
    /// - A revoked key cannot be changed: the request is a `409` and nothing is
    ///   changed.
    /// - `If-Match` makes the change conditional: send the key's `etag`, and a
    ///   key changed since is refused with `412`, changing nothing.
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
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchOrganizationPublishableKey(
      organization_id: String,
      key_id: String,
      body: AdminSchema.PublishableKeyUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PublishableKey, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationPublishableKey,
        pathParameters: ["organization_id": organization_id, "key_id": key_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a publishable key.
    ///
    /// Creates a publishable key with exactly the scopes the request names: none
    /// is added because another is present. Both the name and the scopes are
    /// required, and an empty `scopes` list is a `400` naming `scopes`: a key with
    /// no scopes reaches nothing, so there is no useful default to fall back on.
    /// The key value is returned here and on every later read, so nothing is lost
    /// by not recording it now. A create sent twice without an `Idempotency-Key`
    /// makes two keys; with one, the second is answered the first one's key. A
    /// create sent again with it, after the first failed with a `5xx` once the
    /// key was made, is the `409` coded `IDEMPOTENCY_ANSWER_UNAVAILABLE`, whose
    /// `extensions.metadata.location` names the key made,
    /// `/v1/organizations/{organization_id}/publishable-keys/{key_id}`, so carry
    /// on with that one rather than creating it again.
    /// - Owner or admin only (403 otherwise).
    /// - A key carrying `management` carries no other scope. A `scopes` list
    ///   naming `management` beside another scope is a `400` and no key is
    ///   created: the answer carries one `VALIDATION_FAILED` entry per scope
    ///   listed beside `management`, each naming that scope's position in
    ///   `scopes`. It is asked before any scope's product, so such a list is
    ///   never answered `402`.
    /// - A key carrying `studio-embedded` carries `tiles` and `data` beside it,
    ///   the scopes its editor's map and previews are requested under. A
    ///   `scopes` list naming `studio-embedded` without one of them is a `400`
    ///   and no key is created: the answer carries one `VALIDATION_FAILED` entry
    ///   per missing scope, each naming `scopes`. Neither is added for the
    ///   caller, and it is asked before any scope's product, so such a list is
    ///   never answered `402`.
    /// - A scope can be granted only while the organization holds its product.
    ///   Granting one it does not hold is a `402` and no key is created: the
    ///   answer carries one entry per refused scope, each naming that scope's
    ///   position in `scopes`. `publishing` needs Map Publishing, `studio-embedded`
    ///   needs Embedded Studio and Map Studio, and `tiles` needs the Tile API,
    ///   each granted by the organization's agreement with Mountaya. `data` and
    ///   `mcp` need the Data API, which the organization holds once its first
    ///   card has opened its Data API subscription, or by its agreement, so they
    ///   are refused before that. `management` belongs to no product and is
    ///   never refused this way.
    /// - A key keeps a scope whose product is later switched off. The scope
    ///   answers `402` wherever a request uses it, and works again once the
    ///   product returns.
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
    public func postOrganizationPublishableKey(
      organization_id: String,
      body: AdminSchema.PublishableKeyCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PublishableKey, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationPublishableKey,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
