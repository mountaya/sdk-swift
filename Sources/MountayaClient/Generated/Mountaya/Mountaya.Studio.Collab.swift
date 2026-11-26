// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Collab is every operation of `studio.collab`, one method to an operation.
  public struct Collab: Sendable {
    let sender: any OperationSending

    /// Stream one itinerary's collaboration session over SSE.
    ///
    /// Opens a Server-Sent Events (SSE) stream of one itinerary's real-time editing
    /// session, so every member with the itinerary open converges on the same view
    /// and sees who else is editing. The response Content-Type is
    /// `text/event-stream` and the connection stays open until the client
    /// disconnects or the credential it was opened with ends.
    ///
    /// The member's access is checked again about every ten seconds while the
    /// stream is open. When the member does not reach the itinerary, the stream
    /// ends, and reopening it answers 404, or 402 when the organization does not
    /// hold Map Studio. A member who holds no write role keeps watching, and any
    /// soft lock or uncommitted draft they hold is released and cleared for the
    /// other members (`lock.released`, `draft.clear`).
    ///
    /// On connect the server sends, directly to this connection, a
    /// `presence.snapshot` of the members currently present and a `lock.snapshot`
    /// of every soft lock already held, then broadcasts a `presence.join` to the
    /// session, which reaches this connection too, as every signal of the
    /// member's own comes back to it. It then re-sends a fresh `presence.snapshot` and
    /// `lock.snapshot` down this connection periodically (every few seconds); the
    /// pair sent on connect can be up to one such interval old, and so can miss
    /// this connection's own arrival. A peer that disconnects uncleanly, from a
    /// killed tab or a dropped network that sends no `presence.leave` or
    /// `lock.released`, keeps its entries until they lapse, 45 seconds for its
    /// presence and 60 seconds for its locks after its stream ends, so its stale
    /// avatar and lock badge clear on the first snapshot after that: within about
    /// a minute. Each event is framed as `id: <stream-id>`, `event: <type>`, and
    /// `data: <json>`; only the durable change events carry an `id:`, the
    /// live-only signals do not.
    ///
    /// The stream ends with its credential. When the session token reaches its
    /// expiry, or the key is revoked, loses the `studio-embedded` scope or its
    /// organization is canceled, the stream writes a last `reconnect` event,
    /// whose `data:` carries `reason` `credential-expired` or
    /// `credential-revoked`, and closes. That is not a failure: reopen at once
    /// with a fresh session token and `Last-Event-ID`, and the durable changes
    /// written in between are replayed. A `401` on the reopen means the
    /// credential itself is gone, and the stream ends there. A `HEAD` on this
    /// path opens no subscription.
    ///
    /// It also ends when the server cannot keep delivering its events, because
    /// the reader fell behind or the server's subscription was lost: it writes a
    /// last `reconnect` event whose `reason` is `interrupted`, and closes. Reopen
    /// at once with `Last-Event-ID`, and the durable events written in between
    /// are replayed.
    ///
    /// The `event:` type is one of:
    ///
    /// - `itinerary.changed`, `segment.changed`, `waypoint.changed`: a durable
    ///   structural change to the itinerary or one of its segments/waypoints.
    ///
    /// - `presence.snapshot`: the authoritative set of members present, sent on
    ///   connect and re-sent periodically; a client replaces its roster wholesale
    ///   from it.
    ///
    /// - `lock.snapshot`: the authoritative full set of held locks, sent on connect
    ///   and re-sent periodically; a client replaces its lock state wholesale from
    ///   it, so a lock held by an uncleanly disconnected peer clears once its
    ///   registry entry lapses.
    ///
    /// - `presence.join`, `presence.leave`: a member joined or left the session.
    /// - `selection`: a member's current selection (a segment or waypoint), or
    ///   null.
    /// - `cursor`: a member's cursor position, or null.
    /// - `lock.acquired`, `lock.released`: a member took or released the soft edit
    ///   lock on an entity (a live delta between snapshots).
    ///
    /// - `draft.update`, `draft.clear`: a member's uncommitted draft of an entity,
    ///   or its clear.
    ///
    /// - `reconnect`: the credential the stream was opened with ended, or the
    ///   server cannot keep delivering the stream, and the stream closes after
    ///   it (see above).
    ///
    /// The `event:` type and the shape of the matching `data:` payload are the
    /// CollabStreamEvent schema: it is a union discriminated on `type`, so every
    /// frame kind this stream can send is stated once and cannot drift from the
    /// list above. The union spans all three collaboration streams; the frames
    /// named here are the subset this one carries.
    ///
    /// To resume after a dropped connection, the client reconnects with the
    /// `Last-Event-ID` request header set to the last `id:` it received; the server
    /// replays the durable change events after that id before resuming the live
    /// feed. The live-only signals (presence, cursor, lock, draft) are never
    /// replayed. Without the header, the server first replays every durable
    /// change it still holds for the itinerary, so a fresh connection receives
    /// recent changes it may already reflect; applying one again is harmless,
    /// since each only names what to refetch. The stream keeps about the last
    /// thousand changes, for an hour after the latest one, so a `Last-Event-ID`
    /// older than that replays only what remains: after a long disconnect,
    /// refetch the itinerary rather than rely on the replay. A `Last-Event-ID`
    /// that is not a stream id (two numbers joined by a hyphen, the form of every
    /// `id:`) is a **400**, answered before the stream opens.
    ///
    /// While the stream is open the server writes a comment (a line beginning
    /// with a colon) every 15 seconds, whatever else the stream carries. A
    /// comment is not an event: it has no `id:` and no `data:`, and a client
    /// discards it. It keeps the connection, and any proxy in between, from
    /// closing a quiet stream as idle.
    ///
    /// Any member of the key's organization may watch, whatever their role;
    /// sending any signal through `postItineraryCollab`, a cursor or a selection
    /// as much as a lock or a draft, needs a write role. A personal itinerary,
    /// owned by no organization, has no collaboration session.
    ///
    /// Opening the stream is limited to 60 opens a minute per user and 1200 a
    /// minute per organization, counted across every event stream, and every open
    /// is a read made with a session token besides, limited to 1200 requests a
    /// minute per user and 6000 a minute per organization; past any of them, the
    /// open is refused with **429** and `Retry-After`, and no stream starts. A
    /// reopen after a `reconnect` event counts as an open.
    ///
    /// At most 20 streams are held open at once for each user, 50 for each client
    /// IP address and 1,000 for each organization, counted across every event
    /// stream. An open past any of them is a `429` with `Retry-After`, and no
    /// stream starts; a stream gives its place back when it ends.
    ///
    /// The `studio-embedded` scope is NOT the scope the resource itself reads
    /// under. `getItinerary` takes `publishing`, and holding `publishing` does not
    /// grant `studio-embedded`: a key carrying only `publishing` reads the resource
    /// and is refused here with a `403`. The stream is scoped to `studio-embedded`
    /// because it is the live editing session an embedded studio opens on behalf
    /// of a member, not a change feed on a resource.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with any role,
    /// whom the request acts as. A publishable key without a session token minted
    /// for `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    public func getItineraryEvents(
      itinerary_id: String,
      options: RequestOptions = RequestOptions()
    ) throws -> EventStream<RestSchema.CollabStreamEvent> {
      let request = OperationRequest(
        facts: .getItineraryEvents,
        pathParameters: ["itinerary_id": itinerary_id]
      )
      return try sender.events(request, options: options)
    }

    /// Stream an organization's list events over SSE.
    ///
    /// Opens a Server-Sent Events (SSE) stream of the changes to the target
    /// organization's itineraries, zones and collections, so every member
    /// watching the studio sees its lists converge without polling. The path
    /// names the key's own organization: a key is pinned to the organization it
    /// was issued for, and naming another is a `403` whether or not it exists.
    /// The response Content-Type is `text/event-stream` and the connection stays
    /// open until the client disconnects or the credential it was opened with
    /// ends. A `HEAD` on this path answers the stream's headers and opens no
    /// subscription.
    ///
    /// The member's membership is checked again about every ten seconds while the
    /// stream is open. When the member does not belong to the organization, the
    /// stream ends, and reopening it answers 403, or 402 when the organization does
    /// not hold Map Studio.
    ///
    /// A stream ends with its credential. When the session token reaches its
    /// expiry, or the publishable key is revoked, loses the `studio-embedded`
    /// scope or its organization is canceled, the stream writes one last record,
    /// `event: reconnect` with `data: {"reason":"credential-expired"}` or
    /// `data: {"reason":"credential-revoked"}`, and closes. That close is not a
    /// failure: reopen at once with a fresh session token and the
    /// `Last-Event-ID` last received, and the events written in between are
    /// replayed. A `401` on that reopen means the credential itself is gone, and
    /// the stream ends there.
    ///
    /// It also ends when the server cannot keep delivering its events, because
    /// the reader fell behind or the server's subscription was lost: it writes a
    /// last `reconnect` event whose `reason` is `interrupted`, and closes. Reopen
    /// at once with `Last-Event-ID`, and the durable events written in between
    /// are replayed.
    ///
    /// The stream carries only durable events that move a resource in or out of a
    /// member's list, or change how it is filed: an itinerary, a zone or a
    /// collection changing in the organization. It does not carry the editing
    /// signals of one itinerary or one zone, which are on the editor streams,
    /// `getItineraryEvents` and `getZoneEvents`. Each event is framed as
    /// `id: <stream-id>`, `event: <type>`, and `data: <json>`.
    ///
    /// The `event:` type is one of:
    ///
    /// - `itinerary.changed`: an itinerary was created, updated, or deleted in the
    ///   organization.
    ///
    /// - `zone.changed`: a zone was created, updated, or deleted in the
    ///   organization.
    ///
    /// - `collection.changed`: a collection was created, updated, or deleted in the
    ///   organization, or an itinerary or zone entered or left one. A collection
    ///   has no editor stream of its own: it is a folder, so every change to it is
    ///   a list concern and arrives here. The frame names the COLLECTION in `id`
    ///   even when what moved was one of its members, because the consumer
    ///   refetches the group; naming the itinerary that entered or left would be
    ///   both ambiguous and useless. `itinerary_id` is the all-zero UUID and
    ///   `revision` is always 0, since a collection is not revisioned.
    ///
    /// - `reconnect`: the last record, written when the credential ends or the
    ///   server cannot keep delivering the stream. It carries no `id:` and is
    ///   never replayed.
    ///
    /// The `event:` type and the shape of the matching `data:` payload are the
    /// CollabStreamEvent schema: it is a union discriminated on `type`, so every
    /// frame kind this stream can send is stated once and cannot drift from the
    /// list above. The union spans all three collaboration streams; the four
    /// frames named here are the subset this one carries, and the live-only
    /// editing signals are not among them.
    ///
    /// To resume after a dropped connection, the client reconnects with the
    /// `Last-Event-ID` request header set to the last `id:` it received; the server
    /// replays events after that id from the organization's durable stream before
    /// resuming the live feed. Without the header, the server first replays every
    /// event it still holds for the organization, so a fresh connection receives
    /// recent changes its lists may already reflect; applying one again is
    /// harmless, since each only names what to refetch. The stream keeps about
    /// the last thousand events, for an hour after the latest one, so a
    /// `Last-Event-ID` older than that replays only what remains: after a long
    /// disconnect, refetch the lists rather than rely on the replay. A
    /// `Last-Event-ID` that is not a stream id (two numbers joined by a hyphen,
    /// the form of every `id:`) is a **400**, answered before the stream opens.
    ///
    /// While the stream is open the server writes a comment (a line beginning
    /// with a colon) every 15 seconds, whatever else the stream carries. A
    /// comment is not an event: it has no `id:` and no `data:`, and a client
    /// discards it. It keeps the connection, and any proxy in between, from
    /// closing a quiet stream as idle.
    ///
    /// Opening the stream is limited to 60 opens a minute per user and 1,200 per
    /// organization, and each open is also a read made with a session token, held to
    /// the 1200 reads per user and the 6000 per organization per minute every such
    /// read shares; over any of them, the open is a `429` carrying `Retry-After`,
    /// and no stream starts.
    ///
    /// At most 20 streams are held open at once for each user, 50 for each client
    /// IP address and 1,000 for each organization, counted across every event
    /// stream. An open past any of them is a `429` with `Retry-After`, and no
    /// stream starts; a stream gives its place back when it ends.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with any role,
    /// whom the request acts as. A publishable key without a session token minted
    /// for `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    public func getOrganizationEvents(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) throws -> EventStream<RestSchema.CollabStreamEvent> {
      let request = OperationRequest(
        facts: .getOrganizationEvents,
        pathParameters: ["organization_id": organization_id]
      )
      return try sender.events(request, options: options)
    }

    /// Stream one zone's collaboration session over SSE.
    ///
    /// Opens a Server-Sent Events (SSE) stream of one zone's real-time editing
    /// session, so every member with the zone open converges on the same view and
    /// sees who else is editing. The response Content-Type is `text/event-stream`
    /// and the connection stays open until the client disconnects or the
    /// credential it was opened with ends. It is the zone twin of the itinerary
    /// editor stream, `getItineraryEvents`. A `HEAD` on this path answers the
    /// stream's headers and opens no subscription.
    ///
    /// The member's access is checked again about every ten seconds while the
    /// stream is open. When the member does not reach the zone, the stream ends,
    /// and reopening it answers 404, or 402 when the organization does not hold
    /// Map Studio. A member who holds no write role keeps watching, and any soft
    /// lock or uncommitted draft they hold is released and cleared for the other
    /// members (`lock.released`, `draft.clear`).
    ///
    /// A stream ends with its credential. When the session token reaches its
    /// expiry, or the publishable key is revoked, loses the `studio-embedded`
    /// scope or its organization is canceled, the stream writes one last record,
    /// `event: reconnect` with `data: {"reason":"credential-expired"}` or
    /// `data: {"reason":"credential-revoked"}`, and closes. That close is not a
    /// failure: reopen at once with a fresh session token and the
    /// `Last-Event-ID` last received, and the durable changes written in between
    /// are replayed. A `401` on that reopen means the credential itself is gone,
    /// and the stream ends there.
    ///
    /// It also ends when the server cannot keep delivering its events, because
    /// the reader fell behind or the server's subscription was lost: it writes a
    /// last `reconnect` event whose `reason` is `interrupted`, and closes. Reopen
    /// at once with `Last-Event-ID`, and the durable events written in between
    /// are replayed.
    ///
    /// On connect the server sends, directly to this connection, a
    /// `presence.snapshot` of the members currently present and a `lock.snapshot`
    /// of every soft lock already held, then broadcasts a `presence.join` to the
    /// session, which reaches this connection too, as every signal of the
    /// member's own comes back to it. It then re-sends a fresh `presence.snapshot` and
    /// `lock.snapshot` down this connection periodically (every few seconds); the
    /// pair sent on connect can be up to one such interval old, and so can miss
    /// this connection's own arrival. A peer that disconnects uncleanly, from a
    /// killed tab or a dropped network that sends no `presence.leave` or
    /// `lock.released`, keeps its entries until they lapse, 45 seconds for its
    /// presence and 60 seconds for its locks after its stream ends, so its stale
    /// avatar and lock badge clear on the first snapshot after that: within about
    /// a minute. Each event is framed as `id: <stream-id>`, `event: <type>`, and
    /// `data: <json>`; only the durable change events carry an `id:`, the
    /// live-only signals and the closing `reconnect` do not.
    ///
    /// The `event:` type is one of:
    ///
    /// - `zone.changed`: a durable structural change to the zone.
    /// - `presence.snapshot`: the authoritative set of members present, sent on
    ///   connect and re-sent periodically; a client replaces its roster wholesale
    ///   from it.
    ///
    /// - `lock.snapshot`: the authoritative full set of held locks, sent on connect
    ///   and re-sent periodically; a client replaces its lock state wholesale from
    ///   it, so a lock held by an uncleanly disconnected peer clears once its
    ///   registry entry lapses.
    ///
    /// - `presence.join`, `presence.leave`: a member joined or left the session.
    /// - `selection`: a member's current selection, or null.
    /// - `cursor`: a member's cursor position, or null.
    /// - `lock.acquired`, `lock.released`: a member took or released the soft edit
    ///   lock on an entity (a live delta between snapshots).
    ///
    /// - `draft.update`, `draft.clear`: a member's uncommitted draft of an entity,
    ///   or its clear.
    ///
    /// - `reconnect`: the last record, written when the credential ends or the
    ///   server cannot keep delivering the stream.
    ///
    /// The `event:` type and the shape of the matching `data:` payload are the
    /// CollabStreamEvent schema: it is a union discriminated on `type`, so every
    /// frame kind this stream can send is stated once and cannot drift from the
    /// list above. The union spans all three collaboration streams; the frames
    /// named here are the subset this one carries.
    ///
    /// To resume after a dropped connection, the client reconnects with the
    /// `Last-Event-ID` request header set to the last `id:` it received; the server
    /// replays the durable change events after that id before resuming the live
    /// feed. The live-only signals (presence, cursor, lock, draft) are never
    /// replayed. Without the header, the server first replays every durable
    /// change it still holds for the zone, so a fresh connection receives recent
    /// changes it may already reflect; applying one again is harmless, since each
    /// only names what to refetch. The stream keeps about the last thousand
    /// changes, for an hour after the latest one, so a `Last-Event-ID` older than
    /// that replays only what remains: after a long disconnect, refetch the zone
    /// rather than rely on the replay. A `Last-Event-ID` that is not a stream id
    /// (two numbers joined by a hyphen, the form of every `id:`) is a **400**,
    /// answered before the stream opens.
    ///
    /// While the stream is open the server writes a comment (a line beginning
    /// with a colon) every 15 seconds, whatever else the stream carries. A
    /// comment is not an event: it has no `id:` and no `data:`, and a client
    /// discards it. It keeps the connection, and any proxy in between, from
    /// closing a quiet stream as idle.
    ///
    /// Any member of the key's organization may watch, whatever their role;
    /// sending any signal through `postZoneCollab`, a cursor or a selection as
    /// much as a lock or a draft, needs a write role. A personal zone, owned by no
    /// organization, has no collaboration session.
    ///
    /// The `studio-embedded` scope is NOT the scope the resource itself reads
    /// under. `getZone` takes `publishing`, and holding `publishing` does not grant
    /// `studio-embedded`: a key carrying only `publishing` reads the resource and
    /// is refused here with a `403`. The stream is scoped to `studio-embedded`
    /// because it is the live editing session an embedded studio opens on behalf
    /// of a member, not a change feed on a resource.
    ///
    /// Opening the stream is limited to 60 opens a minute per user and 1,200 per
    /// organization, and each open is also a read made with a session token, held to
    /// the 1200 reads per user and the 6000 per organization per minute every such
    /// read shares; over any of them, the open is a `429` carrying `Retry-After`,
    /// and no stream starts.
    ///
    /// At most 20 streams are held open at once for each user, 50 for each client
    /// IP address and 1,000 for each organization, counted across every event
    /// stream. An open past any of them is a `429` with `Retry-After`, and no
    /// stream starts; a stream gives its place back when it ends.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with any role,
    /// whom the request acts as. A publishable key without a session token minted
    /// for `studio-embedded` naming a user, a token minted for another surface
    /// included, is refused with **401**.
    public func getZoneEvents(
      zone_id: String,
      options: RequestOptions = RequestOptions()
    ) throws -> EventStream<RestSchema.CollabStreamEvent> {
      let request = OperationRequest(
        facts: .getZoneEvents,
        pathParameters: ["zone_id": zone_id]
      )
      return try sender.events(request, options: options)
    }

    /// Send a collaboration signal into an itinerary's session.
    ///
    /// Sends a live collaboration signal into an itinerary's real-time session,
    /// fanned out over the editor stream (getItineraryEvents) to every connection
    /// on it. The sender's own connections receive it too, recognizable by their
    /// `user_id`, which is the sender's. The request body shape is selected by its
    /// `type` discriminator:
    ///
    /// - `selection`: the current selection (a segment or waypoint), or null to
    ///   clear it.
    /// - `cursor`: the cursor position, or null to clear it.
    /// - `lock.acquire`: take the soft edit lock on an entity; refused with 409
    ///   when another member holds it. The lock lapses after 60 seconds unless
    ///   the member keeps the editor stream open.
    /// - `lock.release`: release the soft edit lock the member holds on an entity.
    /// - `draft.update`: an uncommitted draft of an entity being edited; requires
    ///   the member to already hold the entity's lock (409 otherwise).
    /// - `draft.clear`: clear the member's uncommitted draft; requires the lock
    ///   too.
    ///
    /// The lock and draft signals name an entity this session guards, one the
    /// itinerary's writes check: a segment, a segment group or a waypoint. A zone
    /// is locked in its own session, `postZoneCollab`; named here, it is the
    /// `400` below and takes no lock.
    ///
    /// The server always stamps the user the session token names onto the
    /// broadcast; a user id inside the body is never trusted. Every signal needs a
    /// member with a write role, a `selection` or a `cursor` as much as a lock: a
    /// viewer may watch the stream but not send into it. Beyond that, the
    /// itinerary must be one the key's organization owns: another organization's,
    /// public ones included, is the 404 below. The response is 200 with no data
    /// once the signal is accepted.
    ///
    /// A signal states where the sender is rather than adding to anything: a
    /// selection, a cursor, a lock the sender holds, a draft. Sending the same
    /// signal again restates it, so the request is safe to repeat, and it takes
    /// no `Idempotency-Key`: a retry needs no stored answer to be safe.
    ///
    /// Signals are limited to 1200 a minute per user, across every collaboration
    /// session; past that, the request is refused with **429** and `Retry-After`.
    /// A client that sends a signal on every pointer move throttles it to well
    /// under that.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    public func postItineraryCollab(
      itinerary_id: String,
      body: RestSchema.CollabSignalParams,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postItineraryCollab,
        pathParameters: ["itinerary_id": itinerary_id],
        body: .json(body)
      )
      return try await sender.envelope(request, options: options)
    }

    /// Send a collaboration signal into a zone's session.
    ///
    /// Sends a live collaboration signal into a zone's real-time session, fanned
    /// out over the editor stream, `getZoneEvents`, to every connection on it. The
    /// sender's own connections receive it too, recognizable by their `user_id`,
    /// which is the sender's. It is the zone twin of `postItineraryCollab` and
    /// reuses the same signal shapes. The request body shape is selected by its `type`
    /// discriminator:
    ///
    /// - `selection`: the current selection, or null to clear it.
    /// - `cursor`: the cursor position, or null to clear it.
    /// - `lock.acquire`: take the soft edit lock on an entity; refused with 409
    ///   when another member holds it. The lock lapses after 60 seconds unless
    ///   the member keeps the editor stream open.
    /// - `lock.release`: release the soft edit lock the member holds on an entity.
    /// - `draft.update`: an uncommitted draft of an entity being edited; requires
    ///   the member to already hold the entity's lock (409 otherwise).
    /// - `draft.clear`: clear the member's uncommitted draft; requires the lock
    ///   too.
    ///
    /// The lock and draft signals name the one entity this session guards, the
    /// zone itself, of kind `zone`. A segment, a segment group or a waypoint is
    /// locked in its itinerary's session, `postItineraryCollab`; named here, it
    /// is the `400` below and takes no lock.
    ///
    /// The server always stamps the user the session token names onto the
    /// broadcast; a user id inside the body is never trusted. Every signal needs a
    /// member with a write role, a `selection` or a `cursor` as much as a lock: a
    /// viewer may watch the stream but not send into it. Beyond that, `selection`
    /// and `cursor` need the zone to be one this credential can view, and the lock
    /// and draft signals need it to be one the member can edit. The response is 200
    /// with no data once the signal is accepted.
    ///
    /// A signal sets live state rather than adding to it: sending the same one
    /// again leaves the session as the first one left it, and taking a lock the
    /// member already holds renews it. A lock on the zone itself also refuses `patchZone` from
    /// every
    /// other member while it is held. That is why it takes no `Idempotency-Key`:
    /// a signal sent twice has no second effect, so a retry needs no stored
    /// answer to be safe.
    ///
    /// Signals are limited to 1200 per user per minute; over it, the signal is a
    /// `429` carrying `Retry-After`, and it is not sent.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    public func postZoneCollab(
      zone_id: String,
      body: RestSchema.CollabSignalParams,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postZoneCollab,
        pathParameters: ["zone_id": zone_id],
        body: .json(body)
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
