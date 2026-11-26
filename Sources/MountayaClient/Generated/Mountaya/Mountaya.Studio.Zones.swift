// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Zones is every operation of `studio.zones`, one method to an operation.
  public struct Zones: Sendable {
    let sender: any OperationSending

    /// Delete a zone.
    ///
    /// Permanently deletes the zone and removes it from every collection that
    /// held it. This action cannot be undone.
    ///
    /// Send the zone's `etag` as `If-Match` to make the delete conditional: a
    /// zone changed since that read is a `412`, and nothing is deleted.
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
    public func deleteZone(
      zone_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteZone,
        pathParameters: ["zone_id": zone_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Take the zone's publication down.
    ///
    /// Takes the zone off the public surfaces. Mountaya stops serving it from the
    /// next request: a read of it as published answers `404`, the tiles drawn from
    /// published content, Mountaya's hosted embed among them, stop drawing it, and
    /// Mountaya's own caches stop serving its published tiles: they are not
    /// evicted, but nothing reaches them and they age out. An answer a
    /// shared cache between a reader and Mountaya already holds is served from
    /// there until its lifetime runs out, which taking the zone down does not
    /// shorten: at most 6 minutes for a published read of the zone
    /// (`max-age=300` and `stale-while-revalidate=60`), and 5 for a public tile
    /// of it (`max-age=300`).
    ///
    /// It acts on a state, so a zone that is not published is answered `200` as
    /// well, whether it never was or is already taken down: the request leaves it
    /// unpublished either way, and a repeated request is harmless.
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
    /// Unpublishing frees the zone's place under the organization's
    /// published-zones limit at once. It is never refused for Map Studio, for Map
    /// Publishing or for that limit, so an organization whose agreement includes
    /// neither can still take its zones down, and the one 402 it declares is the
    /// one every `studio-embedded` operation shares.
    ///
    /// Taking the publication down changes what a read of the zone returns, so it
    /// moves the zone's `etag`. Send the zone's `ETag` as `If-Match` to make it
    /// conditional on nobody having changed the zone since you read it; a stale
    /// tag is refused with `412`.
    ///
    /// Takes no request body. Returns the zone's draft, with `status` back to
    /// draft and `published_at` null.
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
    public func deleteZonePublication(
      zone_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Zone, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteZonePublication,
        pathParameters: ["zone_id": zone_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve a single zone with its geometry.
    ///
    /// Returns the zone, including the full `geojson` geometry, `created_by`, and
    /// the temporal validity window (`start_at` / `end_at`). This is the
    /// authoritative geometry for editing, unlike the simplified, clipped
    /// geometry served by the tile endpoint.
    ///
    /// A COLLECTION share token also reaches this endpoint, for the zones inside
    /// the collection it was minted for, read-only and regardless of privacy. An
    /// itinerary token never does: it grants exactly its one itinerary. A zone
    /// has no share link of its own.
    ///
    /// WHICH VERSION you are served depends on the credential. A publishable key
    /// alone, and a share token, are served the last PUBLISHED snapshot; the same
    /// key with a session token naming a member is served its own organization's
    /// DRAFT, which is what the studio edits, unless it passes
    /// `surface=published`. A session token minted without `user_id`, such as the
    /// one a read-only viewer runs on, is served what the key alone is, the
    /// published snapshot and never the draft, whatever surface it was minted
    /// for. Another organization's public zone is served as it was last published
    /// whatever the credential. Whenever the published snapshot is what a request
    /// is served, a zone that has never been published, or has been taken down,
    /// answers 404, and so does one whose organization's agreement does not
    /// include Map Publishing, which withdraws what the organization published
    /// rather than refusing it; a share token of such an organization does not
    /// resolve at all and answers `401`. A bare publishable key, and the key with
    /// a session token minted without `user_id`, reaches its own organization's
    /// zones whether public or private, and another organization's public one; a
    /// share token reaches only what its link names. See the read tiers in the
    /// API description.
    ///
    /// Refused with 403 when `surface=published` names a PERSONAL zone, that is,
    /// one owned by no organization, as a personal itinerary is. The published
    /// surface is what an embed is made of, and an embed is an output of an
    /// organization's products, which a personal zone, owned by none, never has,
    /// whatever the credential. A request without the opt-in is not refused this
    /// way. Only the person whose zone it is reads it as its draft and is refused
    /// this way; every other caller, every publishable key included, reads it as
    /// published, is served nothing of a personal zone, which is never published,
    /// and is answered `404` before this refusal is reached, as a caller who
    /// cannot view it is.
    ///
    /// The answer carries `ETag`, the version of what it returns, which is also
    /// the body's `etag`: send it as `If-Match` on a write to the zone to make
    /// that write conditional on nobody having changed it since.
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
    public func getZone(
      zone_id: String,
      query: RestSchema.GetZoneQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Zone, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getZone,
        pathParameters: ["zone_id": zone_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// List zones.
    ///
    /// Returns the zones of the key's organization, one page at a time. A zone
    /// belongs to the organization that owns it, not to the user who drew it, so
    /// this is the listing every member shares.
    ///
    /// The listing is always the key's organization. `organization_id` may name
    /// that organization, which changes nothing, and naming any other
    /// organization is a `403` whether or not it exists. A personal zone, owned
    /// by no organization, never appears.
    ///
    /// WHICH zones appear depends on the credential. A publishable key alone
    /// lists the organization's PUBLIC zones that are currently published, and
    /// serves the published snapshot of each: one never published, or taken
    /// down, is absent, and so is every zone while the organization's agreement
    /// does not include Map Publishing. The same key with a session token naming
    /// a member lists its private ones and its unpublished ones as well, and
    /// serves the draft of each; a session token minted without `user_id`,
    /// whatever surface it was minted for, lists and serves what the key alone
    /// does. A caller that finds its own zones missing is almost always sending
    /// the key without a session naming a member. A share token does not open
    /// this listing: the zones a collection link reaches are listed with
    /// `getCollectionZones`. See the read tiers in the API description.
    ///
    /// `level`, `mode` and `active_at` narrow the listing to the zones a map
    /// draws: of one severity, drawn with one tool, or in force at one instant.
    /// Every filter sent narrows the listing further, and none of them widens
    /// what the credential reaches: a zone is listed only when it matches every
    /// one sent. They read each zone as it is served, so under a key alone a zone
    /// is matched on its last published snapshot. `status` and `is_private` read
    /// each zone as it is served too, so under a key alone, and under a session
    /// token minted without `user_id`, `status=draft` and `is_private=true` list
    /// nothing.
    ///
    /// The page is cut after authorization, so it never holds a zone the caller
    /// may not see. The listing ends at the page whose
    /// `extensions.metadata.pagination.next_cursor` is `null`.
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
    public func getZones(
      query: RestSchema.GetZonesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Zone], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getZones,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetZones walks the listing `getZones` answers, one row at a time, requesting a page only
    /// as the rows before it are read (`transport.pagination.walk`).
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
    public func walkGetZones(
      query: RestSchema.GetZonesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<RestSchema.GetZonesQuery, RestSchema.Zone> {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getZones(query: page, options: options)
      }
    }

    /// Update an existing zone.
    ///
    /// Updates the zone's name, description, level and temporal validity window.
    /// Every field is optional and an omitted field keeps its current value. The
    /// area may be replaced by providing `geojson`, which must be a Polygon whose
    /// outline no meridian and no parallel crosses more than 512 times, every
    /// ring counted, and which is a valid polygon in degrees as sent and once
    /// projected to Web Mercator, as a map draws it: an outline too intricate, a
    /// ring that crosses itself or another ring, in either, a ring that touches
    /// itself, or a hole outside its shell is a `400` naming `geojson.geometry`. When omitted
    /// the existing area is carried forward, as it is. An area computed from a
    /// `source` held to none of these, or of more than 10,000 positions, is a
    /// `400` naming `source`, and nothing is written. A `mode` is sent with the area
    /// it describes: beside `geojson` any mode, beside a `source` only `polygon`,
    /// and a `mode` sent with neither is a `400` naming `mode`. Only a zone whose
    /// mode, sent or kept, is `polygon` takes a `source`: on any other mode it is a
    /// `400` naming `source`. `is_private` makes the zone private or public,
    /// independently of whether it is published. An `end_at` earlier than the
    /// zone's resulting `start_at`, whether either was sent or kept, is a `400`
    /// naming `end_at`. Every call writes a new revision, even one that changes
    /// nothing, so `revision` and `updated_at` move and, on a published zone,
    /// `has_unpublished_changes` is set: what the public surfaces serve moves
    /// only at the next `postZonePublication`, privacy aside, which is read from
    /// the draft and takes effect at once.
    ///
    /// A zone's name is unique within the organization: renaming it to a name
    /// another zone there already carries is a `409` naming that zone. Sending its
    /// current name again is not a conflict.
    ///
    /// While another member of the zone's collaboration session holds the soft
    /// edit lock on the zone, taken with a `lock.acquire` through
    /// `postZoneCollab`, the update is a `409` naming that member, and nothing
    /// is written. A lock held by the user the session token names does not
    /// refuse it. A lock lapses 60 seconds after its holder's editor stream ends,
    /// so the update succeeds once the holder releases it or goes away.
    ///
    /// Send the zone's `etag` as `If-Match` to make the update conditional: a
    /// zone changed since that read is a `412`, and nothing is written.
    ///
    /// The organization the zone belongs to must hold Map Studio, or the update is
    /// refused with a `402`. A zone owned by no organization is personal and is
    /// never edited: it stays readable and can be deleted, and an update to it is
    /// refused with a `403`.
    ///
    /// An update that sends a `source` runs that computation again for the
    /// organization. Under a key each run is recorded as `studio-embedded` data usage, so
    /// the organization sees it, and is never counted toward the Data API's
    /// per-minute limit, its monthly allowance or its invoice.
    ///
    /// Updating zones is limited to 30 per user and 300 per organization per
    /// minute; over either, the update is a `429` carrying `Retry-After`, and
    /// nothing is written.
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
    public func patchZone(
      zone_id: String,
      body: RestSchema.ZoneUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Zone, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchZone,
        pathParameters: ["zone_id": zone_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a new zone.
    ///
    /// Creates a zone in the key's organization: a named area drawn by hand as a
    /// single Polygon, or computed from a `source`. Any geometry other than a
    /// Polygon, a `null` geometry included, is a `400` naming `geojson.geometry`,
    /// and so is a Polygon whose outline one meridian or one parallel crosses
    /// more than 512 times, every ring counted, which is too intricate to be
    /// stored, and one that is not a valid polygon, in degrees as sent or once
    /// projected to Web Mercator, as a map draws it: a ring that crosses itself or
    /// another ring, a ring that touches itself, or a hole outside its shell. A
    /// straight edge in degrees is drawn as another line on a map, so an outline
    /// valid in degrees can cross itself once projected, and is refused. An
    /// area computed from a `source` held to none of these, or of more than 10,000
    /// positions, is a `400` naming `source`: change its location or range, or
    /// draw the zone. An `end_at` earlier than `start_at` is a `400` naming
    /// `end_at`.
    ///
    /// A new zone is a draft: the public surfaces serve nothing of it until
    /// `postZonePublication` publishes it, whatever `is_private` says, and
    /// `is_private` decides who may read it once it is.
    ///
    /// A zone's name is unique within the organization: a name another zone there
    /// already carries is a `409` naming that zone. So is an id: a `geojson.id`
    /// another zone already has is a `409` naming it.
    ///
    /// A new zone always belongs to an organization, and the organization must hold
    /// Map Studio, or the create is refused with a `402`. No new zone is
    /// personal: a request that would create one owned by no organization, which
    /// only Mountaya's web application can send, is refused with a `403`.
    ///
    /// A zone computed from a `source` runs that computation for the
    /// organization. Under a key each run is recorded as `studio-embedded` data usage, so
    /// the organization sees it, and is never counted toward the Data API's
    /// per-minute limit, its monthly allowance or its invoice.
    ///
    /// Creating zones is limited to 30 per user and 300 per organization per
    /// minute; over either, the create is a `429` carrying `Retry-After`, and
    /// nothing is created.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postZone(
      body: RestSchema.ZoneCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Zone, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postZone,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Publish the zone's current draft.
    ///
    /// Sets the zone's publication to its current draft: the draft's name,
    /// description, level, mode, area, validity window and source are frozen into
    /// a publication and become what the public surfaces serve. Until the first
    /// publish, the public surfaces resolve nothing for the zone: a read of it as
    /// published answers `404`, and the tiles drawn from published content,
    /// Mountaya's hosted embed among them, do not draw it. After it, they serve
    /// that snapshot and are unaffected by any further draft edit until the zone
    /// is published again. The studio always reads and writes the draft, whatever
    /// is published.
    ///
    /// The publication is a state the zone is set to, so the request is safe to
    /// repeat: sent again with nothing changed in between, it leaves what readers
    /// are served as it is and returns the zone. Sent after the draft has been
    /// edited, it publishes the edits.
    ///
    /// Publishing copies content rather than referencing it, so the published
    /// version can never be altered by a later draft edit. Each publish creates
    /// the next publication and the live one is never rewritten in place.
    ///
    /// One publication is retained: the most recent. Publishing again supersedes
    /// the previous one and its content is discarded, so there is no version
    /// history to read back. The publication NUMBER is never reissued; it only ever
    /// climbs, which is what lets a client tell one publication's cached tiles
    /// apart from another's.
    ///
    /// Publication is what every published output of a zone hangs off: every
    /// read, listing and tile made without a session of the owning organization
    /// naming a member, a collection's share link among them, and Mountaya's
    /// hosted embed, which draws a collection's published public zones, all read
    /// the live publication this sets. Only that organization's key with a
    /// session token naming a member reads the draft instead, unless it passes
    /// `surface=published`; a token minted without `user_id` reads as the key
    /// alone does. A zone has no share link of its own. Publishing charges
    /// nothing and raises no invoice: how many zones an organization may have
    /// published at once is set by its agreement with Mountaya.
    ///
    /// Refused with 402 for one of three reasons. The first is the one every
    /// `studio-embedded` operation shares: the organization does not hold
    /// Embedded Studio. The second is the one every change to an organization's
    /// zones shares: the organization does not hold Map Studio. The third is
    /// publishing's own: the organization does not hold Map Publishing, the
    /// product every published output of a zone belongs to. All three are a
    /// plain `PAYMENT_REQUIRED`. Taking a zone down is never refused for the last
    /// two, so the one 402 `deleteZonePublication` declares is the first. A
    /// personal zone, owned by no organization, is never published, and is
    /// refused with a `403`.
    ///
    /// Refused with a `429` coded `LIMIT_REACHED` for the organization's limit:
    /// it already has as many zones published as its agreement allows, which is
    /// none until the agreement names a number, and a higher one is agreed rather
    /// than bought. The entry carries a `path`,
    /// `["request", "params", "zone_id"]`, naming the zone that could not take a
    /// place, and `extensions.metadata` names the ceiling, `published-zones`,
    /// with how many it allows and how many are published, so a client says what
    /// is full without a second read. It carries no `Retry-After`, since no wait
    /// lifts it: it clears by unpublishing something or by agreeing a higher
    /// limit. It refuses a FIRST publish only: republishing a zone that is
    /// already live is never refused by it. It holds for publishes sent at the
    /// same moment too: two requests cannot both take the last place. Taking a
    /// zone down is never refused by it.
    ///
    /// Refused with 409 when the zone is locked in the collaboration session,
    /// including by the user the session token names: a held lock means an
    /// in-flight edit that has not been committed, and publishing it would freeze
    /// a half-finished state. When more than one refusal applies, the missing
    /// Embedded Studio product is answered first (`402`), then the missing Map
    /// Studio product (`402`), then the missing Map Publishing product (`402`),
    /// then the held lock (`409`), then the published-zone limit (`429`), and
    /// last a stale `If-Match` (`412`), so a stale tag is answered only for a
    /// publish that would otherwise go through.
    ///
    /// Publishing changes what a read of the zone returns, so it moves the zone's
    /// `etag`. Send the zone's `ETag` as `If-Match` to publish only the version you
    /// read; a stale tag is refused with `412` and nothing is published.
    ///
    /// Takes no request body. Returns the zone's draft, with the derived status,
    /// published_at, and has_unpublished_changes fields reflecting the new
    /// publication.
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
    public func postZonePublication(
      zone_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Zone, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postZonePublication,
        pathParameters: ["zone_id": zone_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
