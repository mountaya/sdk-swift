// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Collections is every operation of `studio.collections`, one method to an operation.
  public struct Collections: Sendable {
    let sender: any OperationSending

    /// Delete a collection.
    ///
    /// Permanently deletes the collection. The itineraries and zones it held are
    /// NOT deleted: only the references linking them to this collection are, so
    /// every resource survives in the organization that owns it. This action cannot
    /// be undone.
    ///
    /// Deleting is an administrative act on a shared folder, so it takes the same
    /// grant as renaming one: a write role, and on top of it either the
    /// collection's authorship or `owner` / `admin` in the owning organization. A
    /// `contributor`, who may add and remove the collection's contents, cannot
    /// delete a folder it did not create: changing what a collection CONTAINS and
    /// changing what it IS are separate permissions on purpose. Any active share
    /// link is disabled with it, and every URL built from that link stops
    /// resolving.
    ///
    /// Send the collection's `etag` as `If-Match` to make the delete conditional:
    /// a collection changed since that read is a `412`, and nothing is deleted.
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
    public func deleteCollection(
      collection_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteCollection,
        pathParameters: ["collection_id": collection_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Remove an itinerary from a collection.
    ///
    /// Removes one itinerary from the collection and closes the collection's
    /// ordering up around the gap. The itinerary itself is not deleted: only its
    /// place in this collection is, so it stays in its organization and in every
    /// other collection holding it. A link minted for this collection stops
    /// reaching it. The answer is the collection after the change, as
    /// `getCollection` reads it.
    ///
    /// Removing an itinerary the collection does not hold is not refused: it
    /// changes nothing, and the answer is the collection as it stands, so a
    /// removal sent twice answers alike both times. An itinerary this credential
    /// cannot view is the `404` below, exactly like an identifier that names no
    /// itinerary, so the call cannot be used to learn which itinerary ids exist.
    ///
    /// Send the collection's `etag` as `If-Match` to make the removal
    /// conditional: a collection changed since that read, its contents included,
    /// is a `412`, and nothing is removed.
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
    public func deleteCollectionItinerary(
      collection_id: String,
      itinerary_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteCollectionItinerary,
        pathParameters: ["collection_id": collection_id, "itinerary_id": itinerary_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Remove the collection's share link.
    ///
    /// Removes the collection's share link, so every URL built from its token stops
    /// resolving. Mountaya refuses the old token from the next request on, with a
    /// `401`. An answer a shared cache already holds for a request carrying it is
    /// served from there until its lifetime runs out: at most 5 minutes for a
    /// public tile and 25 hours for the layer catalog, as each states in its
    /// `Cache-Control`. It takes the same write role the mint takes. A collection
    /// with no share link is answered the same way, so removing a link that is
    /// already gone is not an error.
    ///
    /// A link is not part of what `getCollection` reads, so removing one does not
    /// move the collection's `etag`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func deleteCollectionShareLink(
      collection_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteCollectionShareLink,
        pathParameters: ["collection_id": collection_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Remove a zone from a collection.
    ///
    /// Removes one zone from the collection. The zone itself is not deleted: only
    /// its place in this collection is, so it stays in its organization and in
    /// every other collection holding it. A link minted for this collection stops
    /// reaching it. The answer is the collection after the change, as
    /// `getCollection` reads it.
    ///
    /// Removing a zone the collection does not hold is not refused: it changes
    /// nothing, and the answer is the collection as it stands, so a removal sent
    /// twice answers alike both times. A zone this credential cannot view is the
    /// `404` below, exactly like an identifier that names no zone, so the call
    /// cannot be used to learn which zone ids exist.
    ///
    /// Send the collection's `etag` as `If-Match` to make the removal
    /// conditional: a collection changed since that read, its contents included,
    /// is a `412`, and nothing is removed.
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
    public func deleteCollectionZone(
      collection_id: String,
      zone_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteCollectionZone,
        pathParameters: ["collection_id": collection_id, "zone_id": zone_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve a single collection with its itineraries and zones.
    ///
    /// Returns the collection details, with counts of the itineraries and zones it
    /// contains.
    ///
    /// This is the read an embed makes, and the one a share link serves.
    ///
    /// A collection is scoped by the organization that owns it. A private
    /// collection is reached only with that organization's key, and a personal one,
    /// owned by no organization, is reached by a key only when it is public. A
    /// public collection is additionally readable by id across organizations, but
    /// only the collection itself: under another organization's key, its
    /// itineraries and zones are neither listed nor drawn.
    ///
    /// A share token minted for this collection reaches it read-only whatever its
    /// privacy, and reaches the itineraries and zones it contains. A collection
    /// this credential cannot view answers 404, exactly like an id that matches no
    /// collection.
    ///
    /// A collection has no published snapshot: every credential reads it as it
    /// stands, and the itineraries and zones it holds are served by their own
    /// read tiers, as last published to every credential but a session naming a
    /// member.
    /// A bare publishable key reaches its own organization's collections whether
    /// public or private, and another organization's public one, and so does the
    /// key with a session token minted without `user_id`, which reads as the key
    /// alone does; a share token reaches only what its link names. See the read
    /// tiers in the API description.
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
    public func getCollection(
      collection_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getCollection,
        pathParameters: ["collection_id": collection_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the itineraries a collection contains.
    ///
    /// Returns the itineraries filed in the collection, one page at a time, in
    /// the collection's own ordering unless `sort` names another.
    ///
    /// This is the forward direction of the membership question. `getCollections`
    /// with `itinerary_id` answers the inverse, which collections hold a given
    /// itinerary; this one answers which itineraries a given collection holds.
    /// `getCollection` reports how many there are as a count, and this returns
    /// them.
    ///
    /// The listing reflects the READ TIER the credential opens. On a collection
    /// your organization owns, a publishable key alone lists its public
    /// itineraries, and the same key with a session token naming a member lists
    /// its private ones too, while a session token minted without `user_id` lists
    /// what the key alone does. Another organization's public collection is
    /// readable by id, but under your key this lists none of its itineraries and
    /// its tiles draw none. See the read tiers in the API description.
    ///
    /// A SHARE TOKEN minted for this collection reads it, and this is the operation
    /// a collection link enumerates through: list the itineraries here, then read
    /// each one by id with the same token. `getItineraries`, the global listing,
    /// refuses a share token, so enumeration stays bounded by the collection the
    /// link names.
    ///
    /// The page is cut after authorization, so it never holds an itinerary the
    /// caller may not see, and the collection's `count`, which counts every
    /// member, can be larger than what this lists. The listing ends at the page
    /// whose `extensions.metadata.pagination.next_cursor` is `null`.
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
    public func getCollectionItineraries(
      collection_id: String,
      query: RestSchema.GetCollectionItinerariesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Itinerary], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getCollectionItineraries,
        pathParameters: ["collection_id": collection_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetCollectionItineraries walks the listing `getCollectionItineraries` answers, one row
    /// at a time, requesting a page only as the rows before it are read
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
    public func walkGetCollectionItineraries(
      collection_id: String,
      query: RestSchema.GetCollectionItinerariesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      RestSchema.GetCollectionItinerariesQuery, RestSchema.Itinerary
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getCollectionItineraries(
          collection_id: collection_id, query: page, options: options)
      }
    }

    /// Read the collection's share link.
    ///
    /// Returns the collection's share link, its token and when that token was
    /// minted, or `null` when the collection has none. Reading never mints one:
    /// `postCollectionShareLink` does.
    ///
    /// Reading a link takes the same write role minting one takes, because the
    /// token opens the collection to anyone who holds it. A member who can only
    /// view the collection cannot read its link, and neither can another
    /// organization's key that sees the collection only because it is public.
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
    public func getCollectionShareLink(
      collection_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getCollectionShareLink,
        pathParameters: ["collection_id": collection_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the zones a collection contains.
    ///
    /// Returns the zones filed in the collection, one page at a time.
    ///
    /// This is the forward direction of the membership question. `getCollections`
    /// with `zone_id` answers the inverse, which collections hold a given zone;
    /// this one answers which zones a given collection holds. `getCollection`
    /// reports how many there are as a count, and this returns them.
    ///
    /// The listing reflects the READ TIER the credential opens. On a collection
    /// your organization owns, a publishable key alone lists its public zones
    /// that are currently published, each as last published, and the same key
    /// with a session token naming a member lists its private and unpublished
    /// ones too, each as its draft, while a session token minted without
    /// `user_id` lists what the key alone does. A share token minted for the
    /// collection lists the zones it holds that are currently published, each
    /// as last published, whatever their privacy. A zone never published, or
    /// taken down, is absent from every listing served the published snapshot.
    /// Another organization's public collection is readable by id, but under
    /// your key this lists none of its zones and its tiles draw none. See the
    /// read tiers in the API description.
    ///
    /// A SHARE TOKEN minted for this collection reads it, which is what lets a
    /// collection link draw and label the zones it carries: the tiles arrive from
    /// `getCollectionTile`, and the detail behind each of them from here.
    /// `getZones`, the organization's listing, refuses a share token, so a link
    /// never reaches past the collection it names.
    ///
    /// The page is cut after authorization, so it never holds a zone the caller
    /// may not see, and the collection's `count`, which counts every member, can
    /// be larger than what this lists. The listing ends at the page whose
    /// `extensions.metadata.pagination.next_cursor` is `null`.
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
    public func getCollectionZones(
      collection_id: String,
      query: RestSchema.GetCollectionZonesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Zone], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getCollectionZones,
        pathParameters: ["collection_id": collection_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetCollectionZones walks the listing `getCollectionZones` answers, one row at a time,
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
    public func walkGetCollectionZones(
      collection_id: String,
      query: RestSchema.GetCollectionZonesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<RestSchema.GetCollectionZonesQuery, RestSchema.Zone> {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getCollectionZones(collection_id: collection_id, query: page, options: options)
      }
    }

    /// List collections.
    ///
    /// Returns the collections of the key's organization that this credential
    /// reaches, one page at a time. A collection belongs to the organization that
    /// owns it, not to the user who created it, so this is the listing every
    /// member shares.
    ///
    /// The listing reflects the READ TIER the credential opens. A bare publishable
    /// key lists the organization's PUBLIC collections only: a private collection
    /// is never discoverable with one. The same key with a session token naming
    /// a member lists the organization's collections whole, private included,
    /// and with a session token minted without `user_id` lists the public ones
    /// only, as the key alone does. Either way each collection reports the role
    /// `viewer`, because a key holds no membership. Another organization's public
    /// collection is read by its identifier with `getCollection` and never appears
    /// here, and a key lists no personal collection, owned by no organization. A
    /// share token lists no collection: the one its link names is read with
    /// `getCollection`. See the read tiers in the API description.
    ///
    /// `itinerary_id` and `zone_id` list only the collections holding that
    /// itinerary or that zone, which is how a client shows where something is
    /// filed. An identifier that names nothing this credential can view lists
    /// nothing, the same answer as one no collection holds, so neither filter can
    /// be used to learn which identifiers exist. Every filter sent narrows the
    /// listing further, and none of them widens what the credential reaches.
    ///
    /// The page is cut after authorization, so it never holds a collection the
    /// caller may not see. The listing ends at the page whose
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
    public func getCollections(
      query: RestSchema.GetCollectionsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Collection], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getCollections,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetCollections walks the listing `getCollections` answers, one row at a time, requesting
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
    public func walkGetCollections(
      query: RestSchema.GetCollectionsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<RestSchema.GetCollectionsQuery, RestSchema.Collection> {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getCollections(query: page, options: options)
      }
    }

    /// Update an existing collection.
    ///
    /// Updates the collection's name, description and privacy. Every field is
    /// optional and an omitted field keeps its current value; send `null`, or a
    /// description that trims to nothing, to clear the description.
    ///
    /// Renaming or re-describing a collection is an administrative act on a shared
    /// folder, so it needs more than a write role: the user the session token
    /// names must have created the collection, or hold `owner` or `admin` in the
    /// owning organization. A contributor may change what a collection CONTAINS
    /// but not what it IS. Anything less is 403.
    ///
    /// Returns 409 when another collection in the organization already carries the
    /// new name. The response carries the conflicting collection's id in
    /// `extensions.metadata`, so a client can link straight to it rather than
    /// making the user hunt for the clash.
    ///
    /// Send the collection's `etag` as `If-Match` to make the change conditional:
    /// a collection changed since that read is a `412`, and nothing is changed.
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
    public func patchCollection(
      collection_id: String,
      body: RestSchema.CollectionUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchCollection,
        pathParameters: ["collection_id": collection_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Set an itinerary's position within a collection.
    ///
    /// Sets the zero-based display position of an itinerary within the collection
    /// and renumbers the remaining itineraries so positions stay contiguous. A
    /// position beyond the current range is clamped to the last slot. The answer
    /// is the collection after the move, as `getCollection` reads it.
    ///
    /// Send the collection's `etag` as `If-Match` to make the move conditional: a
    /// collection changed since that read, its contents included, is a `412`, and
    /// nothing moves.
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
    public func patchCollectionItinerary(
      collection_id: String,
      itinerary_id: String,
      body: RestSchema.CollectionItineraryUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchCollectionItinerary,
        pathParameters: ["collection_id": collection_id, "itinerary_id": itinerary_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a new collection.
    ///
    /// Creates a new collection in the key's organization. Returns 409 Conflict
    /// when another collection in that organization already carries the name.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postCollection(
      body: RestSchema.CollectionCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postCollection,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Add itineraries to a collection.
    ///
    /// Adds one or more itineraries to the collection. New members are appended at
    /// the end of the collection's ordering. Itineraries that are already in the
    /// collection keep their place and are otherwise silently ignored, so
    /// re-sending the same set is safe: it changes nothing, and answers the
    /// collection as it stands. The answer is the collection after the change, as
    /// `getCollection` reads it, so its `count` and `etag` include what was added.
    ///
    /// Every itinerary must belong to the SAME organization as the collection. A
    /// collection is scoped by its organization, so holding a resource from another
    /// one would make it reachable to that organization's members through the
    /// folder. An itinerary from elsewhere whose publication this credential is
    /// served, another organization's public itinerary while it is published and
    /// that organization's agreement includes Map Publishing, is rejected with `400`,
    /// and the validation entry names the offending position in the submitted
    /// array. One it is served nothing of is the `404` below, as its read is: one
    /// it cannot view, and one it reads as published that has never been published,
    /// has been taken down, or whose organization's agreement does not include Map
    /// Publishing. Either way the whole call is refused, not partially applied.
    ///
    /// Send the collection's `etag` as `If-Match` to make the add conditional: a
    /// collection changed since that read, its contents included, is a `412`, and
    /// nothing is added.
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
    public func postCollectionItineraries(
      collection_id: String,
      body: RestSchema.CollectionItinerariesAddParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postCollectionItineraries,
        pathParameters: ["collection_id": collection_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Mint the collection's share link, or return the one it has.
    ///
    /// Sets the collection's share link: mints one when the collection has none,
    /// answering `201`, and returns the existing one otherwise, answering `200`,
    /// so calling again never mints a second token. Both private and public
    /// collections are shareable.
    ///
    /// Minting takes a write role in the organization that owns the collection. A
    /// member who can only view the collection cannot mint a link, and neither can
    /// another organization's key that sees it only because it is public, so a link
    /// never outlives the publisher flipping the collection private. A personal
    /// collection, owned by no organization, has no share link: minting one for
    /// it, which only Mountaya's web application could ask for, is refused with a
    /// `403`.
    ///
    /// The resulting link exposes the collection's itineraries and zones
    /// read-only, each as last published.
    /// That is the deliberate difference from an itinerary share link, which
    /// exposes a single itinerary and never its collection's siblings.
    ///
    /// A link is not part of what `getCollection` reads, so minting one does not
    /// move the collection's `etag`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postCollectionShareLink(
      collection_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postCollectionShareLink,
        pathParameters: ["collection_id": collection_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Rotate the collection's share link.
    ///
    /// Replaces the collection's share token with a freshly generated one and
    /// returns the link with it, so every URL built from the previous token stops
    /// resolving (the cut-off for a link that has spread too far or outlived its
    /// intended audience). It takes the same write role the mint takes. A
    /// collection with no share link has nothing to rotate, and is a `409`: mint
    /// one with `postCollectionShareLink`. A personal collection, owned by no
    /// organization, has no share link, and rotating one for it, which only
    /// Mountaya's web application could ask for, is refused with a `403` as the
    /// mint is.
    ///
    /// **Send an `Idempotency-Key`.** Each rotation mints a new token, so a retry
    /// without one rotates again: if the first call succeeded but its response
    /// was lost (a timeout, a dropped connection) the retry mints a third token
    /// and invalidates the second, leaving a link nobody holds. A retry carrying
    /// the first call's key is answered with the first call's token instead.
    ///
    /// A link is not part of what `getCollection` reads, so rotating one does not
    /// move the collection's `etag`.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postCollectionShareLinkRotate(
      collection_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.ShareLink, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postCollectionShareLinkRotate,
        pathParameters: ["collection_id": collection_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Add zones to a collection.
    ///
    /// Adds one or more zones to the collection. Zones that are already in the
    /// collection are silently ignored, so re-sending the same set is safe: it
    /// changes nothing, and answers the collection as it stands. The answer is the
    /// collection after the change, as `getCollection` reads it, so its `count`
    /// and `etag` include what was added.
    ///
    /// Every zone must belong to the SAME organization as the collection. A
    /// collection is scoped by its organization, so holding a resource from another
    /// one would make it reachable to that organization's members through the
    /// folder. A zone from elsewhere whose publication this credential is
    /// served, another organization's public zone while it is published and that
    /// organization's agreement includes Map Publishing, is rejected with `400`,
    /// and the validation entry names the offending position in the submitted
    /// array. One it is served nothing of is the `404` below, as its read is: one
    /// it cannot view, and one it reads as published that has never been
    /// published, has been taken down, or whose organization's agreement does not
    /// include Map Publishing. Either way the whole call is refused, not
    /// partially applied.
    ///
    /// The collection's organization must hold Map Studio, or the call is refused
    /// with a `402`. A personal collection, owned by no organization, holds no
    /// zone: adding one to it, which only Mountaya's web application could ask
    /// for, is refused with a `403`.
    ///
    /// Send the collection's `etag` as `If-Match` to make the add conditional: a
    /// collection changed since that read, its contents included, is a `412`, and
    /// nothing is added.
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
    public func postCollectionZones(
      collection_id: String,
      body: RestSchema.CollectionZonesAddParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Collection, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postCollectionZones,
        pathParameters: ["collection_id": collection_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
