// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Itineraries is every operation of `studio.itineraries`, one method to an operation.
  public struct Itineraries: Sendable {
    let sender: any OperationSending

    /// Delete an itinerary.
    ///
    /// Permanently deletes the itinerary and all of its segments and waypoints.
    /// This action cannot be undone.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the delete conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is deleted.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteItinerary(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItinerary,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Take the itinerary's publication down.
    ///
    /// Takes the itinerary off the public surfaces. Mountaya stops serving it from
    /// the next request: share links and embeds stop resolving it, and Mountaya's
    /// own caches stop serving its published tiles: they are not evicted, but
    /// nothing reaches them and they age out. An answer a shared cache
    /// between a reader and Mountaya already holds is served from there until its
    /// lifetime runs out, which taking the itinerary down does not shorten: at
    /// most 6 minutes for a published read of the itinerary or its pace
    /// (`max-age=300` and `stale-while-revalidate=60`), and 5 for a public tile
    /// of it (`max-age=300`).
    ///
    /// It acts on a state, so an itinerary that is not published is answered
    /// `200` as well, whether it never was or is already taken down: the request
    /// leaves it unpublished either way, and a repeated request is harmless.
    ///
    /// The publication is kept, not deleted. Publishing again therefore creates the
    /// NEXT publication rather than reusing the number that was live: a publication
    /// number is never reissued, so a client that cached one can always tell the
    /// two apart. What unpublishing clears is whether a publication is live, not
    /// the publication itself.
    ///
    /// The draft is untouched. The studio reads and writes the draft whatever is
    /// published, so unpublishing changes nothing a member sees in the editor; it
    /// changes what everyone else sees, which is nothing.
    ///
    /// Unlike publishing, this is never refused for a held collaboration lock.
    /// Publishing freezes a state and so cannot run over an in-flight edit;
    /// unpublishing freezes nothing.
    ///
    /// Unpublishing frees the itinerary's place under the organization's
    /// published-itineraries limit at once. It is never refused for Map Studio,
    /// for Map Publishing or for that limit, so an organization whose agreement
    /// includes neither can still take its itineraries down, and the one 402 it
    /// declares is the one every `studio-embedded` operation shares.
    ///
    /// Taking the publication down changes what a read of the itinerary returns,
    /// so it moves the itinerary's `etag`. Send the itinerary's `ETag` as
    /// `If-Match` to make it conditional on nobody having changed the itinerary
    /// since you read it; a stale tag is refused with `412`.
    ///
    /// Takes no request body. Returns the itinerary with its full segments,
    /// waypoints, and groups, with `status` back to draft and `published_at` null.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteItineraryPublication(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItineraryPublication,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Delete a segment from an itinerary.
    ///
    /// Permanently deletes the segment. This action cannot be undone.
    ///
    /// An itinerary's segments form a chain, each one starting where the previous
    /// ends, so only a segment at an END of that chain may be deleted: the first,
    /// the last, or (on a single-segment itinerary) the one that is both. Removing
    /// an interior segment would leave the two it sat between disconnected, and is
    /// refused with a `409` whose `extensions.code` is `CONFLICT`: the chain's
    /// shape forbids it, and the same request is refused the same way until the
    /// chain changes.
    ///
    /// Deleting an end is otherwise lossless: the remaining segments keep their
    /// order and their geometry is not recomputed, because a promoted first segment
    /// has no predecessor to meet. The one exception is grouping: when the deleted
    /// segment was one of a group's only two members, the group is dissolved and
    /// the member left behind is un-grouped, since a group never covers fewer than
    /// two segments.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does, so the client sees the chain
    /// renumbered and any group dissolved.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the delete conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is deleted.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteItinerarySegment(
      itinerary_id: String,
      segment_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItinerarySegment,
        pathParameters: ["itinerary_id": itinerary_id, "segment_id": segment_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Delete a segment group.
    ///
    /// Dissolves the group. Its members are un-grouped and are otherwise untouched:
    /// each keeps its own name, color, speed, geometry, metrics, and position, and
    /// the elevation profile goes back to showing them as separate bands. No
    /// segment is ever deleted by this operation. Clearing a member's `group_id`
    /// writes no new revision of it, so its `revision` does not move.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does, so the client sees the cleared
    /// group_id on every former member.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the delete conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is deleted.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteItinerarySegmentGroup(
      itinerary_id: String,
      group_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItinerarySegmentGroup,
        pathParameters: ["itinerary_id": itinerary_id, "group_id": group_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Remove the itinerary's share link.
    ///
    /// Removes the itinerary's share link, so every URL built from its token stops
    /// resolving. Mountaya refuses the old token from the next request on, with a
    /// `401`. An answer a shared cache already holds for a request carrying it is
    /// served from there until its lifetime runs out: at most 5 minutes for a
    /// public tile and 25 hours for the layer catalog, as each states in its
    /// `Cache-Control`. It takes the same write role the mint takes. There is no
    /// undo: minting again produces a new token, not the old one.
    ///
    /// It acts on a state, so an itinerary that has no share link is answered
    /// `200` as well, whether it never had one or it was already removed: the
    /// request leaves it without a link either way, and a repeated request is
    /// harmless.
    ///
    /// A share link does not change what a read of the itinerary returns, so this
    /// leaves the itinerary's `etag` where it is and takes no `If-Match`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func deleteItineraryShareLink(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItineraryShareLink,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Delete a waypoint from an itinerary.
    ///
    /// Permanently deletes the waypoint. This action cannot be undone. The
    /// remaining waypoints keep their positions: nothing is renumbered.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does. Send the itinerary's `ETag` as
    /// `If-Match` to make the delete conditional on nobody having changed the
    /// itinerary since you read it; a stale tag is refused with `412` and nothing
    /// is deleted.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteItineraryWaypoint(
      itinerary_id: String,
      waypoint_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteItineraryWaypoint,
        pathParameters: ["itinerary_id": itinerary_id, "waypoint_id": waypoint_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the itineraries the credential reaches.
    ///
    /// Returns the itineraries of the key's organization that the request's
    /// credential reaches, one page at a time. Each itinerary carries its summary
    /// fields and counts but not its segments and waypoints, which
    /// `getItinerary` returns.
    ///
    /// The listing is always the key's organization. `organization_id` may name
    /// that organization, which changes nothing, and naming any other
    /// organization is a `403` whether or not it exists. A personal itinerary,
    /// owned by no organization, never appears.
    ///
    /// WHICH itineraries appear depends on the credential. A publishable key alone
    /// lists the organization's PUBLIC itineraries that are currently published,
    /// and serves the published snapshot of each: one never published, or taken
    /// down, is absent, and so is every itinerary while the organization's
    /// agreement does not include Map Publishing. The same key with a session token
    /// naming a member of the organization lists its private ones and its
    /// unpublished ones as well, and serves the draft of each; a session token
    /// minted without `user_id`, whatever surface it was minted for, lists and
    /// serves what the key alone does, and so does one naming a user whose
    /// invitation is still pending or a member removed since it was minted,
    /// membership being checked again on every request. A caller that finds its own
    /// itineraries missing is almost always sending the key without a session
    /// naming a member. There is no "current user" on this read: whether the
    /// session names a member decides the tier, and which member it names decides
    /// nothing, the scope being the organization and the privacy of each itinerary,
    /// never the identity of whoever holds the key. A share token does not open
    /// this listing: a collection's link lists what it holds through
    /// `getCollectionItineraries`, and an itinerary's link names one itinerary and
    /// lists nothing.
    ///
    /// The filters narrow that set and never widen it, and they combine: an
    /// itinerary is listed only when it matches every one sent. `status` and
    /// `is_private` read each itinerary as it is served, so under a key alone,
    /// and under a session token minted without `user_id`, `status=draft` and
    /// `is_private=true` list nothing. `in_collection` counts only the
    /// collections this credential lists: under a key alone, or a token minted
    /// without `user_id`, that is the organization's public collections, so an
    /// itinerary filed only in a private one is listed by
    /// `in_collection=false`; with a token naming a member every collection of
    /// the organization counts. `getCollectionItineraries` lists
    /// the itineraries of one collection.
    ///
    /// The listing is paged by cursor. Send the `next_cursor` a page reports, with
    /// the same filters and `sort`, to read the next one; the last page reports a
    /// `next_cursor` of `null`. `sort` orders the whole listing before it is
    /// paged, so a walk from the first page to the last serves once every
    /// matching itinerary whose sort key does not change during the walk. An
    /// itinerary edited during a walk ordered by `updated_at` moves in that
    /// order: past the cursor it is served again, and behind it, not at all.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization, and a key with a session token
    /// naming a user to 1200 per user the token names and then 6000 per
    /// organization, counted apart from the reads made under the key alone. Past
    /// any of them the read is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `publishing` scope, or the
    /// `studio-embedded` scope that includes it.
    public func getItineraries(
      query: RestSchema.GetItinerariesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Itinerary], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getItineraries,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetItineraries walks the listing `getItineraries` answers, one row at a time, requesting
    /// a page only as the rows before it are read (`transport.pagination.walk`).
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
    public func walkGetItineraries(
      query: RestSchema.GetItinerariesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<RestSchema.GetItinerariesQuery, RestSchema.Itinerary> {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getItineraries(query: page, options: options)
      }
    }

    /// Retrieve a single itinerary with its segments and waypoints.
    ///
    /// Returns the full itinerary including all of its segments and waypoints. Each
    /// segment carries its geometry and computed metrics; each waypoint carries its
    /// location.
    ///
    /// WHICH VERSION you are served depends on the credential. A publishable key
    /// alone, and a share token, are served the last PUBLISHED snapshot; the same
    /// key with a session token naming a member is served its own organization's
    /// DRAFT, which is what the studio edits, unless it passes
    /// `surface=published`. A session token minted without `user_id`, such as the
    /// one a read-only viewer runs on, is served what the key alone is, the
    /// published snapshot and never the draft, whatever surface it was minted
    /// for. Another organization's public itinerary is served as it was last
    /// published whatever the credential. Whenever the published snapshot is what
    /// a request is served, an itinerary that has never been published, or has
    /// been taken down, answers 404, and so does one whose organization's
    /// agreement does not include Map Publishing, which withdraws what the
    /// organization published rather than refusing it; a share token of such an
    /// organization does not resolve at all and answers `401`. A bare publishable
    /// key, and the key with a session token minted without `user_id`, reaches
    /// its own organization's itineraries whether public or private, and another
    /// organization's public one; a share token reaches only what its link names.
    /// See the read tiers in the API description.
    ///
    /// Refused with 403 when `surface=published` names a PERSONAL itinerary, that
    /// is, one owned by no organization. The published-surface opt-in is how the
    /// studio's video and embed previews read an itinerary, and a video and an
    /// embed are outputs of an organization's products, which a personal itinerary,
    /// owned by none, never has, whatever the credential. A request without the
    /// opt-in is not refused this way. Only the person whose itinerary it is reads
    /// it as its draft and is refused this way; every other caller, every
    /// publishable key included, reads it as published, is served nothing of a
    /// personal itinerary, which is never published, and is answered `404` before
    /// this refusal is reached, as a caller who cannot view it is.
    ///
    /// A published snapshot is a copy, and its segments and waypoints carry the
    /// snapshot's own ids: they differ from the draft's, and they change at every
    /// publish. An id read from one version names nothing in the other, so take
    /// the `segment_id` of an export, or the `segment_ids` of a duplicate, from a
    /// read of the version that operation reads.
    ///
    /// The answer carries `ETag`, the version of what it returns, which is also
    /// the body's `etag`: send it as `If-Match` on a write to the itinerary to
    /// make that write conditional on nobody having changed it since.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// A publishable key needs the `publishing` scope, or the `studio-embedded`
    /// scope that includes it. A share token carries its own authority and needs
    /// none.
    public func getItinerary(
      itinerary_id: String,
      query: RestSchema.GetItineraryQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getItinerary,
        pathParameters: ["itinerary_id": itinerary_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Export an itinerary as a downloadable file.
    ///
    /// Exports the itinerary in the requested format. The optional segment_id query
    /// parameter limits the export to a single segment within the itinerary. Every
    /// format carries track point elevation when the geometry holds it. GPX emits a
    /// single track with one segment per itinerary segment; GeoJSON returns a
    /// FeatureCollection; KML and KMZ carry per-segment styling; FIT and TCX are
    /// time-series formats whose file type the optional variant query parameter
    /// selects; CSV is a flat coordinate table and is lossy. The format query
    /// parameter is required.
    ///
    /// WHICH VERSION is exported depends on the credential, exactly as on
    /// getItinerary. A publishable key alone, and a share token, export the last
    /// PUBLISHED snapshot; the same key with a session token naming a member
    /// exports its own organization's DRAFT unless it passes
    /// `surface=published`, and a session token minted without `user_id` exports
    /// the published snapshot as the key alone does. Whenever the published
    /// snapshot is what a request is served, an itinerary that has never been
    /// published answers 404, and so does one that has been taken down, before any
    /// refusal below is reached, exactly as getItinerary answers it. A
    /// `format` or `variant` that is not one of its values is a `400` before that,
    /// since the request is validated before the itinerary is looked up; a
    /// `variant` sent with a format it does not apply to is refused only once the
    /// itinerary is found.
    ///
    /// Refused with 403 when the itinerary is PERSONAL, that is, owned by no
    /// organization, and the request reads its draft, which only the person whose
    /// itinerary it is does. A downloadable file is an output of an organization's
    /// products, like the embed and the share link, and a personal itinerary, owned
    /// by none, has none of them. Every other caller, every publishable key
    /// included, reads a personal itinerary as published, and since one is never
    /// published it is answered the `404` below instead. A share token minted for a
    /// personal itinerary never resolves, so it answers `401` before this refusal
    /// is reached.
    ///
    /// Refused with a plain 402 `PAYMENT_REQUIRED` when the DRAFT is what the
    /// request is served and its organization does not hold Map Publishing: a
    /// draft leaves the studio as a file only for an organization whose agreement
    /// with Mountaya includes Map Publishing, the product downloads belong to,
    /// and the refusal clears when the agreement changes rather than when the
    /// request does. This refusal never asks for Map Studio: a download changes
    /// nothing. It is decided after the personal refusal above and before
    /// `format` and `variant` are checked against each other. A request served
    /// the published snapshot is never refused this way: an organization whose
    /// agreement does not include Map Publishing has its publications withdrawn,
    /// so its published snapshot answers the `404` below, which tells a visitor
    /// nothing about its owner.
    ///
    /// Refused with 413 when the itinerary holds more than 500,000 positions,
    /// every position of its segments' geometry, the vias of its routed lines
    /// included, plus one per waypoint: more than one answer carries. They are
    /// counted over the whole itinerary, before anything is loaded, so a single
    /// segment's export is refused as well. This is decided after every other
    /// refusal, the `404` of a surface not served included.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// An export is held to a limit of its own beside them, at the figure the
    /// signed download URL of the same file is held to: 60 exports a minute per
    /// client IP address under a publishable key sent without a session token
    /// or with one minted without `user_id`, and under a share token, and 60
    /// exports a minute per user under a key with a session token naming a
    /// user. It is checked before the read limits, so an export it refuses
    /// spends nothing of them, and past it the export is a `429` carrying
    /// `Retry-After` as well.
    ///
    /// A publishable key needs the `publishing` scope, or the `studio-embedded`
    /// scope that includes it. A share token carries its own authority and needs
    /// none.
    public func getItineraryExport(
      itinerary_id: String,
      query: RestSchema.GetItineraryExportQuery,
      options: RequestOptions = RequestOptions()
    ) async throws -> BinaryResponse {
      let request = OperationRequest(
        facts: .getItineraryExport,
        pathParameters: ["itinerary_id": itinerary_id],
        query: query.items
      )
      return try await sender.binary(request, options: options)
    }

    /// Re-time an itinerary at a travel pace the caller names.
    ///
    /// Answers how long the itinerary takes at the flat pace the `speed` query
    /// parameter names, for the caller asking and for nobody else. The itinerary's
    /// stored speeds are not touched, no revision is written, and the next reader
    /// without a pace of their own is served the author's figures. This is what
    /// lets an embedded visitor read a route at their own rate: a fast walker and a
    /// slow one are looking at the same published itinerary.
    ///
    /// The requested pace REPLACES every per-segment `speed` and every segment
    /// group's `speed` override for the length of the answer. One pace means one
    /// pace: a group override that survived would produce a run whose duration
    /// disagreed with the total returned beside it.
    ///
    /// Only the flat pace moves. The ground does not: the model still slows a
    /// climb, speeds a descent, and charges for a coarse surface or a technical
    /// trail, exactly as it does for the committed durations. That is why the
    /// answer carries `speed_info`, the per-stretch speed each duration was
    /// integrated over, and no other info-family member: a pace does not change
    /// what is underfoot. It also costs no routing call and no elevation read, the
    /// ground is already on the stored segments, so this is a re-integration of
    /// what the itinerary already holds.
    ///
    /// WHICH VERSION is re-timed depends on the credential, exactly as on
    /// getItinerary. A publishable key alone, and a share token, re-time the last
    /// PUBLISHED snapshot; the same key with a session token naming a member
    /// re-times its own organization's DRAFT unless it passes
    /// `surface=published`, and a session token minted without `user_id`
    /// re-times the published snapshot as the key alone does.
    /// Whenever the published snapshot is what a request is served, an itinerary
    /// that has never been published answers 404.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// A publishable key needs the `publishing` scope, or the `studio-embedded`
    /// scope that includes it. A share token carries its own authority and needs
    /// none.
    ///
    /// Refused with 403 when `surface=published` names a PERSONAL itinerary, that
    /// is, one owned by no organization. The published-surface opt-in is how the
    /// studio's video and embed previews re-time an itinerary, and a video and an
    /// embed are outputs of an organization's products, which a personal itinerary,
    /// owned by none, never has, whatever the credential. A request without the
    /// opt-in is not refused this way. Only the person whose itinerary it is reads
    /// it as its draft and is refused this way; every other caller, every
    /// publishable key included, reads it as published, is served nothing of a
    /// personal itinerary, which is never published, and is answered `404` before
    /// this refusal is reached, as a caller who cannot view it is.
    public func getItineraryPace(
      itinerary_id: String,
      query: RestSchema.GetItineraryPaceQuery,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryPace, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getItineraryPace,
        pathParameters: ["itinerary_id": itinerary_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Read the itinerary's share link.
    ///
    /// Returns the itinerary's share link, its token and when it was minted, or
    /// `data: null` when the itinerary has none: none was ever minted, or the
    /// last one was removed. An itinerary has at most one link at a time.
    /// `postItineraryShareLink` mints one, `postItineraryShareLinkRotate`
    /// replaces its token and `deleteItineraryShareLink` removes it.
    ///
    /// Reading a link takes the same write role minting one does, in the
    /// organization that owns the itinerary: the token opens the itinerary to
    /// anyone holding it, so a member who can only view the itinerary cannot
    /// read it, and neither can another organization's key that sees the
    /// itinerary only because it is public. `getItinerary` never carries the
    /// token, in any form.
    ///
    /// Like every read made with a session token, it is limited to 1200 a minute
    /// per user the token names and then to 6000 a minute per organization; past
    /// either, the answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    public func getItineraryShareLink(
      itinerary_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getItineraryShareLink,
        pathParameters: ["itinerary_id": itinerary_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an existing itinerary.
    ///
    /// Updates the itinerary's name, description and privacy. Every field is
    /// optional and an omitted field keeps its current value; send null to clear
    /// the description. Returns 409 Conflict when another itinerary in the
    /// organization already carries the requested name. The response is the
    /// itinerary's full draft: `description`, `distance` and `ascent` are `null`
    /// when it has none.
    ///
    /// Every accepted request writes a new revision, even one that changes
    /// nothing: it raises `revision`, moves `updated_at` and, on a published
    /// itinerary, sets `has_unpublished_changes`.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the update conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is changed.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchItinerary(
      itinerary_id: String,
      body: RestSchema.ItineraryUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchItinerary,
        pathParameters: ["itinerary_id": itinerary_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an existing segment.
    ///
    /// Updates an existing segment within the itinerary. Every field is optional:
    /// an omitted field keeps its current value, and `null` clears a nullable one.
    /// A new `geojson` re-derives the segment's geometry and totals, and the shared
    /// points of the neighbouring segments follow it. The segment's mode is changed
    /// by its own operation, `postItinerarySegmentConvert`.
    ///
    /// Waypoints the routing engine cannot route between, in this segment in
    /// `directions` mode or in a `directions` neighbour the update re-routes, are a
    /// 400 naming `geojson`, and nothing is written.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does: a new `geojson` moves the shared
    /// points of the neighbours, and the itinerary's totals follow the segment's.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the update conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is changed.
    ///
    /// Segment updates are routed writes, limited together with every other
    /// routed segment write (create, split, merge and convert) to 120 requests a
    /// minute per user and 1200 a minute per organization; past either, the
    /// request is refused with **429** and `Retry-After`. The routing they do is
    /// recorded as the organization's `studio-embedded` data usage, which
    /// `getOrganizationUsageData` reports and which never counts toward the Data
    /// API's per-minute limit, monthly allowance or invoice.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchItinerarySegment(
      itinerary_id: String,
      segment_id: String,
      body: RestSchema.SegmentUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchItinerarySegment,
        pathParameters: ["itinerary_id": itinerary_id, "segment_id": segment_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update a segment group.
    ///
    /// Updates the group's name, color, speed, or membership. Membership changes
    /// obey the same rules as creation: the segments must form a contiguous run of
    /// the chain and at least two are required, each a 400 otherwise, and none may
    /// already belong to another group, a 409 naming each such segment's position
    /// in `segment_ids`. Segments dropped from the run are un-grouped.
    ///
    /// A group is presentation only, so no update here ever touches a member
    /// segment's geometry, metrics, or position. The lock this operation contends
    /// on is the group's own, so renaming a group while a collaborator edits one of
    /// its members' geometry is legal and expected.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does: a membership change rewrites the
    /// group_id of every segment entering or leaving the run.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the update conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is changed.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchItinerarySegmentGroup(
      itinerary_id: String,
      group_id: String,
      body: RestSchema.SegmentGroupUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchItinerarySegmentGroup,
        pathParameters: ["itinerary_id": itinerary_id, "group_id": group_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an existing waypoint.
    ///
    /// Updates an existing waypoint within the itinerary. Every field is optional:
    /// an omitted field keeps its current value, and `null` clears a nullable one.
    /// A `contact`, `media` or `timing` object whose members are all null or absent
    /// (a `media` with empty lists included) is stored as none, so sending one
    /// clears the field.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does. Send the itinerary's `ETag` as
    /// `If-Match` to make the update conditional on nobody having changed the
    /// itinerary since you read it; a stale tag is refused with `412` and nothing
    /// is changed.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchItineraryWaypoint(
      itinerary_id: String,
      waypoint_id: String,
      body: RestSchema.WaypointUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchItineraryWaypoint,
        pathParameters: ["itinerary_id": itinerary_id, "waypoint_id": waypoint_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a new itinerary.
    ///
    /// Creates a new itinerary in the key's organization. Returns 409 Conflict when
    /// another itinerary in that organization already carries the name. The
    /// response is the created itinerary's full draft: its segments and waypoints
    /// arrays are empty, and `description`, `distance` and `ascent` are `null` when
    /// it has none.
    ///
    /// The organization must hold Map Studio, or the create is refused with a
    /// `402`. An organization keeps any number of itineraries. A personal
    /// itinerary, owned by no organization, is created only from Mountaya's web
    /// application, and a person keeps at most three: a fourth is refused with a
    /// `429` coded `LIMIT_REACHED`, whose `extensions.metadata` names the
    /// ceiling, `personal-itineraries`, with what it allows and what is held, and
    /// which carries no `Retry-After`, since no wait lifts it.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItinerary(
      body: RestSchema.ItineraryCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItinerary,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Duplicate an itinerary into the key's organization.
    ///
    /// Copies the selected segments and waypoints of an existing itinerary into a
    /// new one in the key's organization, which is also what an omitted
    /// `organization_id` means. Reading the source needs only view access (matching
    /// the "anyone with the link" model), so another organization's public
    /// itinerary can be copied, as it was last published; writing the copy needs a
    /// write role in the key's organization. Returns 409 Conflict when another itinerary in that
    /// organization already carries the requested name.
    ///
    /// The copy is a pure copy: every selected segment keeps its stored geometry
    /// and metrics verbatim and is never re-routed, so duplicating is
    /// deterministic, instantaneous, and free of routing-engine failure modes.
    /// Positions are renumbered from zero over the kept segments.
    ///
    /// Omitting `segment_ids` and `waypoint_ids` copies the itinerary whole,
    /// however many segments and waypoints it holds, from the source as it is
    /// read. A source holding more than 500,000 positions is refused with a `413`:
    /// every position of its segments' geometry, the vias of its routed lines
    /// included, plus one per waypoint, more than one request copies. They are
    /// counted over the whole source, for a partial copy as well, before any of
    /// it is loaded: once the source is known to be one the credential reads,
    /// and before the selection is held to it and the organization the copy goes
    /// to is looked at. A partial copy names what it keeps, and its segment selection must
    /// be contiguous: max(position) - min(position) + 1 must equal the number of
    /// segments given. That is what keeps the copy a connected route. A source group carries over
    /// only when at least two of its members are
    /// kept. The copy is always private, never carries the source's share link, and
    /// starts unpublished.
    ///
    /// A copy is a new itinerary, so it passes the same gates a create does: the
    /// organization it is created in must hold Map Studio, or the copy is refused
    /// with a `402`. A copy into the personal space, owned by no organization,
    /// is made only from Mountaya's web application, and a person keeps at most
    /// three personal itineraries, so a fourth is refused with a `429` coded
    /// `LIMIT_REACHED`, whose `extensions.metadata` names the ceiling,
    /// `personal-itineraries`, and which carries no `Retry-After`, since no wait
    /// lifts it. No other ceiling counts against a copy: an itinerary takes
    /// any number of segments and waypoints, and an organization keeps any
    /// number of itineraries.
    ///
    /// Copies are limited to 30 a minute per user and 300 a minute per
    /// organization; past either, the copy is a `429` carrying `Retry-After`, and
    /// nothing is copied.
    ///
    /// Returns the new itinerary with its full segments, waypoints, and groups.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItineraryDuplicate(
      itinerary_id: String,
      query: RestSchema.PostItineraryDuplicateQuery = .init(),
      body: RestSchema.ItineraryDuplicateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryDuplicate,
        pathParameters: ["itinerary_id": itinerary_id],
        query: query.items,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Confirm an itinerary import, persisting the reviewed draft.
    ///
    /// Persists a reviewed import draft atomically: the itinerary, its ordered
    /// segments and its waypoints are created together or not at all. Every
    /// segment's metrics are recomputed server-side from its defining geometry,
    /// never trusted from the client, and a segment the routing engine cannot
    /// route is a 400 naming that segment's `geojson`, with nothing created.
    /// Returns 409 Conflict when another itinerary in the key's organization
    /// already carries the name. The response is the created itinerary with its
    /// full segments and waypoints.
    ///
    /// Every field of the draft, each segment's and each waypoint's included, is
    /// validated before any segment is routed, and so is the name: a draft
    /// refused for what it holds is refused before any routing is spent.
    ///
    /// This is a general "create itinerary with full details" path and is not
    /// import-specific; the preview step (POST /v1/itineraries/preview) is
    /// optional.
    ///
    /// The organization the itinerary is created in must hold Map Studio, or the
    /// confirm is refused with a `402` before any segment is routed. An import into
    /// the personal space, owned by no organization, is made only from Mountaya's
    /// web application, and a person keeps at most three personal itineraries, so
    /// a fourth is refused with a `429` coded `LIMIT_REACHED`, whose
    /// `extensions.metadata` names the ceiling, `personal-itineraries`, and which
    /// carries no `Retry-After`, since no wait lifts it. No other ceiling holds an
    /// import: an organization keeps any number of itineraries, and an itinerary
    /// takes any number of segments and waypoints. The bounds on `segments` and
    /// `waypoints` in the body are on the size of one request, and a draft over
    /// either is a `400` naming the field. What else counts against an import is
    /// the rate limits below.
    ///
    /// The routing an import does is recorded as the organization's `studio-embedded`
    /// data usage, which `getOrganizationUsageData` reports and which never
    /// counts toward the Data API's per-minute limit, monthly allowance or
    /// invoice. Imports and previews are limited together to 10 requests a minute
    /// per user and 60 a minute per organization, and the requests they send the
    /// routing engine to 4,000 a minute per user and 24,000 per organization. A
    /// confirm holds, while it runs, one for each segment of its draft and 120
    /// more, so a draft at its 1,000 segments holds 1,120: a routed segment is
    /// one route, a freehand segment one analysis of its line, and the 120 are
    /// the most it sends to analyse in parts a line the engine could not analyse
    /// whole, in rounds: every freehand segment it could not analyse whole is
    /// split in two before any half is split again, and where the 120 run out
    /// within a round, the segments first in the draft are split. Past them, a
    /// stretch left unanalysed is stored with an unknown surface, way type and
    /// difficulty. Once it ends, whatever its answer, it is charged the ones it
    /// sent, so a draft refused before it routes, its name already taken among
    /// them, is charged none. Past any of these limits, the request is refused
    /// with **429** and `Retry-After`, and nothing is routed or created.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItineraryImport(
      body: RestSchema.ItineraryImportConfirmParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryImport,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Preview an itinerary import without persisting it.
    ///
    /// Parses an uploaded itinerary file, segments each track, and computes
    /// per-segment mode candidates (directions and/or linestring) with a server
    /// recommendation. Nothing is persisted: the response is a reviewable draft the
    /// client edits before confirming it with `postItineraryImport`. Since a
    /// preview creates nothing, the request is safe to repeat.
    ///
    /// The body is `multipart/form-data` carrying the uploaded `file`, the
    /// `provider` naming its format (gpx, geojson, kml, kmz, fit, tcx) and the
    /// `activity_id` the import is for, plus optional form fields. No file format
    /// carries an activity the server reads, so `activity_id` is required. FIT and
    /// TCX uploads may be either a course or a recorded activity; the file type is
    /// detected from the file and never supplied by the client. An upload is at
    /// most 25 MiB; a larger one is refused with `413`. Every other form field is
    /// at most 4 KiB; a longer one is a `400`.
    ///
    /// A source holding more than 500,000 points across its tracks is refused with
    /// `413` as well, whatever its size and whichever format it comes in, and
    /// so is one with a stretch the confirm could not take back as it is proposed:
    /// a freehand segment longer than 500 km or of more than 10,000 positions, or
    /// one whose duration at the activity's pace cannot be stored. Split such a
    /// source, or preview it with a finer `granularity`.
    ///
    /// Previewing routes, so it passes the gates a confirm does: the itinerary
    /// would be created in the key's organization, which must hold Map Studio, and
    /// the activity must be one `getActivities` lists. A preview into the personal
    /// space, which only Mountaya's web application makes, is refused as the
    /// confirm would be when its person already keeps three personal itineraries:
    /// a `429` coded `LIMIT_REACHED`, whose `extensions.metadata` names the
    /// ceiling, `personal-itineraries`, and which carries no `Retry-After`, since
    /// no wait lifts it. A source is split into at
    /// most 60 proposed segments, a bound on the routing one upload can spend
    /// rather than on what an itinerary may hold. It proposes at most 5,000
    /// waypoints, the most a confirm takes in one request: a source carrying more
    /// proposes its first 5,000 and reports `waypoints-truncated` in `warnings`.
    ///
    /// The routing a preview does is recorded as the organization's `studio-embedded` data
    /// usage, which `getOrganizationUsageData` reports and which never counts
    /// toward the Data API's per-minute limit, monthly allowance or invoice.
    /// Previews and imports are limited together to 10 requests a minute per user
    /// and 60 a minute per organization, and the requests they send the routing
    /// engine to 4,000 a minute per user and 24,000 per organization. A preview
    /// holds 1,188 of them while it runs, the most it may send, and once it ends,
    /// whatever its answer, it is charged the ones it sent: a preview of a
    /// recording that follows mapped ways sends a few dozen. Of those, it sends
    /// at most 120 to analyse in parts a line the engine could not analyse whole,
    /// in rounds: every line it could not analyse whole is split in two before
    /// any half is split again, and where the 120 run out within a round, the
    /// lines first in the file are split. Past them, a stretch left unanalysed is
    /// reported with an unknown surface, way type and difficulty. Past any of
    /// these limits, the request is refused with **429** and `Retry-After`, and
    /// nothing is routed.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItineraryPreview(
      body: RestSchema.PostItineraryPreviewMultipartBody,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryImportPreview, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryPreview,
        body: .multipart(body.parts),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Publish the itinerary's current draft.
    ///
    /// Sets the itinerary's publication to its current draft: the draft's content
    /// is frozen into a publication and becomes what the public surfaces serve.
    /// Until the first publish, share links and embeds resolve nothing for the
    /// itinerary; after it, they serve that snapshot and are unaffected by any
    /// further draft edit until the itinerary is published again. The studio
    /// always reads and writes the draft, whatever is published.
    ///
    /// The publication is a state the itinerary is set to, so the request is safe
    /// to repeat: sent again with nothing changed in between, it leaves what
    /// readers are served as it is and returns the itinerary. Sent after the
    /// draft has been edited, it publishes the edits.
    ///
    /// Publishing copies content rather than referencing it, so the published
    /// version can never be altered or hollowed out by a later draft edit, not even
    /// by deleting a segment outright. Each publish creates the next publication
    /// and the live one is never rewritten in place.
    ///
    /// One publication is retained: the most recent. Publishing again supersedes
    /// the previous one and its content is discarded, so there is no version
    /// history to read back. The publication NUMBER is never reissued; it only ever
    /// climbs, which is what lets a client tell one publication's cached tiles
    /// apart from another's.
    ///
    /// Publication is what every published output of an itinerary hangs off: the
    /// embed, the share link, and every export made without a session of the
    /// owning organization naming a member all read the live publication this
    /// sets. Only that organization's key with a session token naming a member
    /// exports the draft instead, unless it passes `surface=published`; a token
    /// minted without `user_id` reads as the key alone does. Publishing charges
    /// nothing and raises no invoice: how many itineraries an organization may
    /// have published at once is set by its agreement with Mountaya.
    ///
    /// Refused with 402 for one of three reasons. The first is the one every
    /// `studio-embedded` operation shares: the organization does not hold
    /// Embedded Studio. The second is the one every change to an organization's
    /// itineraries shares: the organization does not hold Map Studio. The third
    /// is publishing's own: the organization does not hold Map Publishing, the
    /// product every published output of an itinerary belongs to. All three are
    /// a plain `PAYMENT_REQUIRED`. Taking an itinerary down is never refused for
    /// the last two, so the one 402 `deleteItineraryPublication` declares is the
    /// first. A personal itinerary, owned by no organization, is never published,
    /// and is refused with a `403`.
    ///
    /// Refused with a `429` coded `LIMIT_REACHED` for the organization's limit:
    /// it already has as many itineraries published as its agreement allows,
    /// which is none until the agreement names a number, and a higher one is
    /// agreed rather than bought. The entry carries a `path`,
    /// `["request", "params", "itinerary_id"]`, naming the itinerary that could
    /// not take a place, and `extensions.metadata` names the ceiling,
    /// `published-itineraries`, with how many it allows and how many are
    /// published, so a client says what is full without a second read. It
    /// carries no `Retry-After`, since no wait lifts it: it clears by
    /// unpublishing something or by agreeing a higher limit. It refuses a FIRST
    /// publish only: republishing an itinerary that is already live is never
    /// refused by it. It holds for publishes sent at the same moment too: two
    /// requests cannot both take the last place. Taking an itinerary down is
    /// never refused by it.
    ///
    /// Refused with 409 when the itinerary has no segments: there would be
    /// nothing to serve, so the itinerary's state forbids the publish until a
    /// segment is added. The segments are counted again as the publication is
    /// taken, so a last segment deleted while the publish runs is refused with
    /// the same `409` rather than published empty. Refused with 409 as well when
    /// ANY segment, waypoint, or group of the itinerary is locked in the
    /// collaboration session, including by the user the session token names: a
    /// held lock means an in-flight edit that has not been committed, and
    /// publishing it would freeze a half-finished state.
    /// When more than one refusal applies, the missing Embedded Studio product is
    /// answered first (`402`), then the missing Map Studio product (`402`), then
    /// the missing Map Publishing product (`402`), then an itinerary with no
    /// segments (`409`), then the held lock (`409`), then the published-itinerary
    /// limit (`429`), and last a stale `If-Match` (`412`). An itinerary with
    /// nothing to publish is told so before the limit is asked, and a stale tag is
    /// answered only for a publish that would otherwise go through.
    ///
    /// Publishing changes what a read of the itinerary returns, so it moves the
    /// itinerary's `etag`. Send the itinerary's `ETag` as `If-Match` to publish
    /// only the version you read; a stale tag is refused with `412` and nothing is
    /// published.
    ///
    /// Takes no request body. Returns the itinerary with its full segments,
    /// waypoints, and groups, with the derived status, published_at, and
    /// has_unpublished_changes fields reflecting the new publication.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItineraryPublication(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryPublication,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a segment, at the end of the chain or before another.
    ///
    /// Creates a new segment within the itinerary, at the end of its chain or
    /// anywhere before it, and renumbers the chain.
    ///
    /// Without `before_segment_id`, the segment is appended to the end of the
    /// chain, and it starts where the chain ends: on an itinerary that already has
    /// segments, the first position of `geojson` is replaced with the last point
    /// of the current last segment before the 100 km limit is checked.
    ///
    /// With `before_segment_id`, the segment is inserted ahead of that one, so the
    /// first segment's identifier inserts at the head of the chain, and every
    /// segment from that one on moves down a `position`. The new segment keeps
    /// the geometry sent, and its neighbours move to meet it: the segment before
    /// it has its last point moved onto the new segment's first point, and the
    /// segment it is inserted before has its first point moved onto the new
    /// segment's last point. Each neighbour that moved is recomputed through its
    /// own mode, a `directions` neighbour being re-routed. An identifier that
    /// names no segment of this itinerary's chain is a 400 naming
    /// `before_segment_id`.
    ///
    /// A routed segment, appended, inserted or a neighbour re-routed, is pinned
    /// onto the junctions it meets: the route the engine returns is joined to
    /// each junction it does not reach, one off the routable network, by a short
    /// straight connector. So a `directions` segment starts where the chain ends
    /// and stays exactly connected to its neighbours, as a `linestring` one does.
    ///
    /// The create is atomic: if any of its routing fails, the request fails and
    /// the itinerary is left exactly as it was. Waypoints the routing engine
    /// cannot route between, one away from any routable way or two with no
    /// connection between them, in the new segment or in a re-routed neighbour,
    /// are a 400 naming `geojson`.
    ///
    /// The new segment joins a group only when BOTH of its neighbours already
    /// belong to the same one. A segment appended at the end, or inserted at the
    /// head, has only one neighbour and joins none, since joining would silently
    /// extend the group's boundary.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does: a create can renumber every
    /// following position and rewrite up to two neighbours, which one segment
    /// would not show. `Location` and `extensions.metadata.created.id` name the
    /// segment created.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the create conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is created.
    ///
    /// Segment creates are routed writes, limited together with every other
    /// routed segment write (split, merge, convert and update) to 120 requests a
    /// minute per user and 1200 a minute per organization; past either, the
    /// request is refused with **429** and `Retry-After`. The routing they do is
    /// recorded as the organization's `studio-embedded` data usage, which
    /// `getOrganizationUsageData` reports and which never counts toward the Data
    /// API's per-minute limit, monthly allowance or invoice.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItinerarySegment(
      itinerary_id: String,
      body: RestSchema.SegmentCreateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<
      RestSchema.ItineraryWithDetails, RestSchema.ResponseMetadataCreatedPart
    > {
      let request = OperationRequest(
        facts: .postItinerarySegment,
        pathParameters: ["itinerary_id": itinerary_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Convert a segment between routed and freehand.
    ///
    /// Converts the segment to the mode the body names, routed (`directions`) or
    /// freehand (`linestring`), and re-derives its geometry accordingly. This is
    /// its own operation rather than a field on `patchItinerarySegment` because
    /// it can fail routing where a metadata update cannot, and giving it a
    /// dedicated operation leaves exactly one way to change a segment's engine.
    ///
    /// directions to linestring keeps the routed line as the freehand line,
    /// simplified and resampled as a line drawn on creation is
    /// (`SegmentCreateParams.geojson`), and clears the turn-by-turn steps, which
    /// describe nothing a freehand line carries. A routed line of more positions
    /// than the 10,000 a segment write takes, if the simplification leaves it
    /// past them, is simplified further at a coarser tolerance until it fits
    /// them, keeping both its ends, so the freehand segment, like every segment,
    /// is accepted back as read.
    ///
    /// linestring to directions derives the waypoints to route through, using the
    /// segment's stored waypoints when it has them and otherwise a simplification
    /// of the drawn line, tightened until it fits within the directions limit of
    /// 45. It preserves the original endpoints exactly, and the routed segment is
    /// held to the 100 km every routed segment is, measured along the straight
    /// line through those waypoints. A routing failure aborts the change and
    /// writes nothing: waypoints the routing engine cannot route between are a
    /// 400 naming `geojson`, the segment's geometry.
    ///
    /// The mode is a state the segment is set to, so the request is safe to
    /// repeat: sending the mode the segment already has changes nothing and
    /// answers 200 with the itinerary.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does: the answer carries the
    /// itinerary's recomputed totals beside the segment. Neither neighbour
    /// changes, since both directions keep the segment's endpoints where they
    /// are.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the conversion
    /// conditional on nobody having changed the itinerary since you read it; a
    /// stale tag is refused with `412` and nothing is changed.
    ///
    /// Conversions are routed writes, limited together with every other routed
    /// segment write (create, split, merge and update) to 120 requests a minute
    /// per user and 1200 a minute per organization; past either, the request is
    /// refused with **429** and `Retry-After`. The routing they do is recorded as
    /// the organization's `studio-embedded` data usage, which `getOrganizationUsageData`
    /// reports and which never counts toward the Data API's per-minute limit,
    /// monthly allowance or invoice.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItinerarySegmentConvert(
      itinerary_id: String,
      segment_id: String,
      body: RestSchema.SegmentConvertParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItinerarySegmentConvert,
        pathParameters: ["itinerary_id": itinerary_id, "segment_id": segment_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Group a contiguous run of an itinerary's segments.
    ///
    /// Creates a segment group over the given segments. The segments themselves are
    /// unchanged: grouping only overrides the name, color, and speed shown for that
    /// run on the elevation profile and in the segment chooser, and every member
    /// stays individually selectable and editable.
    ///
    /// Refused with 400 when the segments do not form a contiguous run of the
    /// chain, when fewer than two are given, or when any of them does not belong
    /// to this itinerary.
    ///
    /// Refused with 409, its entries coded `CONFLICT`, when any of them already
    /// belongs to another group: one entry per such segment, naming its position
    /// in `segment_ids`. That is a state of the chain rather than a fault in the
    /// request, refused the same way until the other group lets the segment go,
    /// so leave it out of the run or change that group first.
    ///
    /// Refused with 409 as well when a concurrent writer reached the same segments first,
    /// either by grouping one of them between the validation and the write, or by
    /// reordering the chain so the run the request names stops being contiguous.
    /// Both are validated against the chain as the caller last read it and
    /// re-asserted under the chain lock before anything is written, so the loser of
    /// a race is told to reload rather than silently taking the winner's members or
    /// committing a broken run. The two read the same on the wire and call for the
    /// same response: re-read the itinerary and decide again against what it holds.
    ///
    /// Unlike the 409 on patchItinerarySegmentGroup and
    /// deleteItinerarySegmentGroup, this one never carries
    /// `extensions.metadata.holder` and uses the generic conflict shape: a holder
    /// identifies the collaborator whose lock refused the write, and there is no
    /// group to hold a lock on yet.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does: creating a group rewrites the
    /// group_id of every member, so the group alone would leave the client's
    /// segments stale. `Location` and `extensions.metadata.created.id` name the
    /// group created.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the create conditional
    /// on nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is created.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItinerarySegmentGroup(
      itinerary_id: String,
      body: RestSchema.SegmentGroupCreateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<
      RestSchema.ItineraryWithDetails, RestSchema.ResponseMetadataCreatedPart
    > {
      let request = OperationRequest(
        facts: .postItinerarySegmentGroup,
        pathParameters: ["itinerary_id": itinerary_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Merge a segment with the one that follows it.
    ///
    /// Fuses the segment into a single segment together with the next one in the
    /// chain, and renumbers the chain. The direction is fixed and takes no
    /// parameter: on an ordered chain, merging segment i with i-1 is the same
    /// operation as merging i-1 with its next, so a direction field would only add
    /// a redundant way to express the same request. The merged result keeps the
    /// identifier of the lower-positioned of the two.
    ///
    /// In directions mode the union of both segments' waypoints is re-routed as one
    /// request. The two existing geometries are never simply joined end to end: the
    /// junction may have been snapped, so the joined line would be a path routing
    /// would never return, leaving distance, duration and steps inconsistent with
    /// the geometry. In linestring mode the two stored lines are joined end to end,
    /// and the joined line is simplified, resampled and analysed as a newly drawn
    /// line is. The 3 m simplification removes the positions resampling added, and
    /// with them any vertex drawn that lies within 3 m of the straight line between
    /// the vertices kept on either side of it, the point where the two lines met
    /// included. The MultiPoint of vertices drawn that either segment's `geojson`
    /// carries is not read: the merged segment's vertices drawn are those of the
    /// joined line that the simplification keeps.
    ///
    /// Refused with 409, its entry coded `CONFLICT` and naming no field, when the
    /// chain does not allow the merge as it stands: the segment is the last of the
    /// chain, so there is no next segment to fuse with, or the two segments use
    /// different modes, or they belong to different groups. The same request is
    /// refused the same way until the chain changes. Refused with 400 when their
    /// combined waypoint count exceeds the directions limit of 45. The limit is
    /// checked before the routing call, and the error states the 45-waypoint
    /// limit. In directions mode the merged segment is held to the 100 km every
    /// routed segment is, measured along the straight line through its
    /// waypoints, so two segments that together exceed it are refused with 400
    /// too, and waypoints the routing engine cannot route between are a 400
    /// naming `geojson`, the merged segment's geometry, although a merge takes no
    /// body. In linestring mode the joined line is held to the 500 km every
    /// freehand segment is, measured as its stored distance is, so two lines that
    /// together measure more are refused with 400 naming `geojson` in the same
    /// way, and nothing is merged. When the vertices the simplification keeps of
    /// the joined line number more than the 10,000 positions a segment's
    /// `geojson` may carry, the merge is refused with 400, naming no field,
    /// before anything is analysed, and nothing is merged; the error states the
    /// 10,000-position limit.
    ///
    /// Takes no request body. Returns the whole itinerary with its segments,
    /// waypoints, and groups, as every write to an itinerary's parts does: a
    /// merge renumbers every following position and can change group membership.
    /// When the two segments were a group's only two members, the group is
    /// dissolved and the merged segment un-grouped, since a group never covers
    /// fewer than two segments.
    ///
    /// Not safe to repeat blindly: sent twice, it merges the merged segment with
    /// the one after it in turn. Send an `Idempotency-Key` and repeat it on a
    /// retry, which is then answered with the first attempt's outcome. Send the
    /// itinerary's `ETag` as `If-Match` to make the merge conditional on nobody
    /// having changed the itinerary since you read it; a stale tag is refused
    /// with `412` and nothing is merged.
    ///
    /// Merges are routed writes, limited together with every other routed segment
    /// write (create, split, convert and update) to 120 requests a minute per
    /// user and 1200 a minute per organization; past either, the request is
    /// refused with **429** and `Retry-After`. The routing they do is recorded as
    /// the organization's `studio-embedded` data usage, which `getOrganizationUsageData`
    /// reports and which never counts toward the Data API's per-minute limit,
    /// monthly allowance or invoice.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItinerarySegmentMerge(
      itinerary_id: String,
      segment_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ItineraryWithDetails, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItinerarySegmentMerge,
        pathParameters: ["itinerary_id": itinerary_id, "segment_id": segment_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Split a segment in two at a fraction of its length.
    ///
    /// Cuts the segment into two consecutive segments at the given fraction of its
    /// length, and renumbers the chain. The first half keeps the original
    /// identifier; the second is created after it. Both halves inherit the original
    /// segment's group, so a split never breaks a group's contiguity.
    ///
    /// The first half keeps the original's description, color, speed and planned
    /// start, and its name unless `first_name` renames it. The second half takes
    /// the original's color and speed, and its name unless `second_name` is sent;
    /// it starts with no description and no planned start, since both describe the
    /// original as a whole.
    ///
    /// The fraction is projected server-side onto the stored geometry and inserted
    /// as the first half's last vertex and the second half's first vertex, so the
    /// two halves stay exactly connected and no neighbour recompute is triggered.
    /// Both halves also take that junction as a waypoint. In directions mode BOTH
    /// halves are re-routed (a sub-path of a route is not, in general, the route of
    /// a sub-path), so a routing failure aborts the split and writes nothing:
    /// waypoints the routing engine cannot route between, in either half, are a
    /// 400 naming `geojson`, the segment's geometry.
    ///
    /// Refused with 400 when the projected point lands within 10 m of either
    /// endpoint, since a small fraction is degenerate on a short segment.
    ///
    /// A split creates a segment, the second half, so it answers `201`: the
    /// whole itinerary with its segments, waypoints, and groups, as every write
    /// to an itinerary's parts does, since a split renumbers every following
    /// position. `Location` and `extensions.metadata.created.id` name the second
    /// half; the first keeps the identifier in the path.
    ///
    /// Send the itinerary's `ETag` as `If-Match` to make the split conditional on
    /// nobody having changed the itinerary since you read it; a stale tag is
    /// refused with `412` and nothing is split.
    ///
    /// Splits are routed writes, limited together with every other routed segment
    /// write (create, merge, convert and update) to 120 requests a minute per
    /// user and 1200 a minute per organization; past either, the request is
    /// refused with **429** and `Retry-After`. The routing they do is recorded as
    /// the organization's `studio-embedded` data usage, which `getOrganizationUsageData`
    /// reports and which never counts toward the Data API's per-minute limit,
    /// monthly allowance or invoice.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItinerarySegmentSplit(
      itinerary_id: String,
      segment_id: String,
      body: RestSchema.SegmentSplitParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<
      RestSchema.ItineraryWithDetails, RestSchema.ResponseMetadataCreatedPart
    > {
      let request = OperationRequest(
        facts: .postItinerarySegmentSplit,
        pathParameters: ["itinerary_id": itinerary_id, "segment_id": segment_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Mint the itinerary's share link, or return the one it has.
    ///
    /// Sets the itinerary's share link: mints one when the itinerary has none,
    /// answering `201` with `Location` naming the link, and returns the existing
    /// one otherwise, answering `200` with the same token as before. Calling it
    /// again never mints a second link and never changes the token, so it is safe
    /// to repeat; `postItineraryShareLinkRotate` is what replaces a token. Both
    /// private and public itineraries can be shared.
    ///
    /// Minting takes a write role in the organization that owns the itinerary. A
    /// member who can only view the itinerary cannot mint a link, and neither can
    /// another organization's key that sees it only because it is public, so a
    /// link never outlives the publisher making the itinerary private.
    ///
    /// A share link does not change what a read of the itinerary returns, so it
    /// leaves the itinerary's `etag` where it is, takes no `If-Match`, and answers
    /// no `ETag`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItineraryShareLink(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryShareLink,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Rotate the itinerary's share link.
    ///
    /// Replaces the token of the itinerary's share link with a freshly generated
    /// one and returns it, so every URL built from the previous token stops
    /// resolving: the cut-off for a link that has spread too far or outlived its
    /// intended audience, without a window where no link works. It takes the same
    /// write role the mint takes. Refused with 409 when the itinerary has no share
    /// link to rotate: mint one with `postItineraryShareLink`.
    ///
    /// **Not safe to repeat blindly.** Every rotation mints a new token, so a
    /// retry sent without the first attempt's `Idempotency-Key` rotates again: if
    /// the first call succeeded but its answer was lost, the retry mints a third
    /// token and invalidates the second, leaving a link nobody holds. Send an
    /// `Idempotency-Key` and repeat it on the retry, which is then answered with
    /// the first attempt's token; without one, read the link back with
    /// `getItineraryShareLink` before deciding to call this again.
    ///
    /// A share link does not change what a read of the itinerary returns, so a
    /// rotation leaves the itinerary's `etag` where it is and takes no
    /// `If-Match`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postItineraryShareLinkRotate(
      itinerary_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryShareLinkRotate,
        pathParameters: ["itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a new waypoint within an itinerary.
    ///
    /// Creates a new waypoint within the specified itinerary. Its `position` is
    /// stored as the request gives it: a waypoint's order is the author's choice
    /// rather than something the route derives.
    ///
    /// Returns the whole itinerary with its segments, waypoints, and groups, as
    /// every write to an itinerary's parts does. `Location` and
    /// `extensions.metadata.created.id` name the waypoint created.
    ///
    /// A create meets no lock, unlike `patchItineraryWaypoint` and
    /// `deleteItineraryWaypoint`: a waypoint that does not exist yet cannot be
    /// locked by a collaborator, so its one `409` is a request whose
    /// `Idempotency-Key` is still in use. Send the itinerary's `ETag` as
    /// `If-Match` to make the create conditional on nobody having changed the
    /// itinerary since you read it; a stale tag is refused with `412` and nothing
    /// is created.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func postItineraryWaypoint(
      itinerary_id: String,
      body: RestSchema.WaypointCreateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<
      RestSchema.ItineraryWithDetails, RestSchema.ResponseMetadataCreatedPart
    > {
      let request = OperationRequest(
        facts: .postItineraryWaypoint,
        pathParameters: ["itinerary_id": itinerary_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
