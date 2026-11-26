// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Webhooks is every operation of `admin.webhooks`, one method to an operation.
  public struct Webhooks: Sendable {
    let sender: any OperationSending

    /// Delete a webhook endpoint.
    ///
    /// Deletes an endpoint: nothing is delivered to it from then on, and its deliveries
    /// still retrying end `canceled`. Its deliveries already made stay readable for the 13
    /// months deliveries are kept, and `getOrganizationWebhookDeliveries` and
    /// `getOrganizationWebhookHealth` still narrow to it by its identifier. It frees its
    /// place under the organization's `webhook-endpoints` limit.
    /// - Owner or admin only (403 otherwise).
    /// - An endpoint already deleted is a `404`; a delete retried with the first one's
    ///   `Idempotency-Key` is answered its first `200`.
    /// - `If-Match` makes the deletion conditional: send the endpoint's `etag`, and an
    ///   endpoint changed since is refused with `412`, deleting nothing.
    /// - It is limited, together with the organization's other endpoint writes this
    ///   document's introduction lists, to 30 a minute per user and then 300 a minute per
    ///   organization; past either, the answer is a `429` carrying `Retry-After`, and
    ///   nothing is done.
    ///
    /// Requires a publishable key with the `management` scope AND a session token naming a
    /// user, a member with the owner or admin role, whom the request acts as. A session
    /// token minted without `user_id` is refused with **401**, and a publishable key
    /// without a session token is not accepted here: a key written to be shipped in a
    /// browser cannot be sufficient on its own to read or change an organization's
    /// account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteOrganizationWebhookEndpoint(
      organization_id: String,
      webhook_endpoint_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationWebhookEndpoint,
        pathParameters: [
          "organization_id": organization_id, "webhook_endpoint_id": webhook_endpoint_id,
        ],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's webhook deliveries.
    ///
    /// Returns every delivery of the organization's webhook events over the 13 months
    /// deliveries are kept: to its endpoints, and the notification emails its events
    /// caused, each with where it stands and its last attempt. An email delivery names its
    /// recipient and its notification, never what the email said.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - The filters combine: `webhook_endpoint_id` one endpoint, `event_id` one event,
    ///   `destination` endpoints or emails, `outcome` where a delivery stands,
    ///   `failure_class` and `failure_kind` how its last attempt failed, `event_type` the
    ///   type delivered, `trigger_id` the deliveries one resend, test or redelivery
    ///   started, and `start_at` and `end_at` when the deliveries started: a delivery is
    ///   listed by its first attempt, wherever its later ones fall.
    /// - The listing is paged, 50 deliveries a page unless `limit` says otherwise, the most
    ///   recently started first. Send the page's `next_cursor` back as `cursor` for the
    ///   next one; the last page reports `next_cursor: null`.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookDeliveries(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookDeliveriesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.WebhookDelivery], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookDeliveries,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationWebhookDeliveries walks the listing `getOrganizationWebhookDeliveries`
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
    public func walkGetOrganizationWebhookDeliveries(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookDeliveriesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationWebhookDeliveriesQuery, AdminSchema.WebhookDelivery
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationWebhookDeliveries(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Retrieve a webhook delivery with its attempts.
    ///
    /// Returns one delivery with every attempt made of it: when each was due and made, how
    /// it ended and whose a failure was, and for an endpoint the status it answered and the
    /// first 2 KiB of its answer. A notification email's delivery names its recipient and
    /// its notification, never what the email said.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - A delivery is kept 13 months; one older is a `404`.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookDelivery(
      organization_id: String,
      delivery_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookDeliveryWithAttempts, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookDelivery,
        pathParameters: ["organization_id": organization_id, "delivery_id": delivery_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve a webhook endpoint.
    ///
    /// Returns one of the organization's webhook endpoints, as
    /// `getOrganizationWebhookEndpoints` lists it. Its secret is never answered.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - The answer's `ETag` is the endpoint's `etag`. Send it as `If-Match` on
    ///   `patchOrganizationWebhookEndpoint` or `deleteOrganizationWebhookEndpoint` to make
    ///   the change conditional on nobody having changed the endpoint since.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookEndpoint(
      organization_id: String,
      webhook_endpoint_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookEndpoint, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookEndpoint,
        pathParameters: [
          "organization_id": organization_id, "webhook_endpoint_id": webhook_endpoint_id,
        ]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's webhook endpoints.
    ///
    /// Returns the organization's webhook endpoints, enabled and disabled, each with the
    /// event types it is sent, its status and when its run of failed deliveries began. A
    /// secret is never answered: `postOrganizationWebhookEndpoint` answers it once.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - The listing is paged, 50 endpoints a page unless `limit` says otherwise, oldest
    ///   first. An organization holds 2 unless its agreement says otherwise, 6 at most, so
    ///   one page holds them all. Send the page's `next_cursor` back as `cursor` for the
    ///   next one; the last page reports `next_cursor: null`.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookEndpoints(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookEndpointsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.WebhookEndpoint], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookEndpoints,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationWebhookEndpoints walks the listing `getOrganizationWebhookEndpoints`
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
    public func walkGetOrganizationWebhookEndpoints(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookEndpointsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationWebhookEndpointsQuery, AdminSchema.WebhookEndpoint
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationWebhookEndpoints(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Retrieve a webhook event with its deliveries.
    ///
    /// Returns one webhook event, the envelope its deliveries carried, with the deliveries
    /// made of it: one per endpoint it was sent to, per notification email it caused, and
    /// per resend or redelivery since, each with its last attempt.
    /// - `delivery_count` is how many deliveries were made of the event, and `deliveries`
    ///   carries them all up to 100. Past that it carries the 100 most recently started:
    ///   `getOrganizationWebhookDeliveries` pages every one of them by `event_id`.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - An event is kept 13 months; one older is a `404`.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookEvent(
      organization_id: String,
      event_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookEventWithDeliveries, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookEvent,
        pathParameters: ["organization_id": organization_id, "event_id": event_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's webhook events.
    ///
    /// Returns every public webhook event recorded in the organization over the 13 months
    /// events are kept, whether or not an endpoint was sent it: what its members' acts and
    /// Mountaya recorded, before any endpoint subscribes. Each is the envelope a delivery
    /// carries, exactly. It is how a receiver that was down past the retries reconciles:
    /// list from the last event it processed, and redeliver or read what it missed.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - The filters combine. `type` keeps one type and `family` every type of one family;
    ///   `related_object_id` the events about one object; `request_id` the events one API
    ///   request recorded, by the `X-Request-Id` its answer carried; `actor_type` and
    ///   `actor_user_id` who made the change; `delivery_outcome` the events with at least
    ///   one delivery standing so; `start_at` and `end_at` when they were recorded.
    /// - The listing is paged, 50 events a page unless `limit` says otherwise, the most
    ///   recent first. Send the page's `next_cursor` back as `cursor` for the next one; the
    ///   last page reports `next_cursor: null`.
    /// - An event is listed within seconds of its change. `getOrganizationWebhookEvent`
    ///   reads one with its deliveries.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookEvents(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookEventsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.WebhookEvent], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookEvents,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationWebhookEvents walks the listing `getOrganizationWebhookEvents` answers,
    /// one row at a time, requesting a page only as the rows before it are read
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
    public func walkGetOrganizationWebhookEvents(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookEventsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationWebhookEventsQuery, AdminSchema.WebhookEvent
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationWebhookEvents(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Retrieve the reliability of an organization's webhooks.
    ///
    /// Returns how reliably the organization's webhook events were delivered over a window:
    /// as totals, as a series of hours or days, and one line per destination. It keeps
    /// Mountaya's service availability apart from each endpoint's success, since every
    /// failed attempt is classed as the receiver's or as Mountaya's.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the organization, and is a 403 otherwise.
    /// - `window` asks for the last 24 hours or 7 days, an hour at a time, or the last 30
    ///   days, a day at a time, ending at the hour the request is answered in. Omitted with
    ///   no range, it is `24h`.
    /// - `start_at` and `end_at` ask for a range instead, at most 92 days within the 13
    ///   months deliveries are kept: an hour at a time up to 7 days, a day at a time
    ///   beyond. `window` beside either is a `400`.
    /// - `webhook_endpoint_id` narrows the report to one endpoint; omitted, it covers every
    ///   endpoint and the notification emails, each a destination line of its own.
    /// - `availability` is Mountaya's: the share of the attempts due that were made on
    ///   schedule with no failure of Mountaya's. The success rates are the endpoints': how
    ///   often a delivery succeeded at its first attempt, and at any.
    /// - The figures are a series over the window, not a listing, so they are not paged.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getOrganizationWebhookHealth(
      organization_id: String,
      query: AdminSchema.GetOrganizationWebhookHealthQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookHealth, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationWebhookHealth,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the public webhook event types.
    ///
    /// Returns every public webhook event type with its family and what records it: the
    /// members of `WebhookEventType`, which an endpoint's `enabled_events` names. The
    /// catalog is the same for every organization, and this document's `webhooks` describes
    /// each type's payload.
    /// - A session token minted for `api` without `user_id` is asked for no member role
    ///   on this read; one minted for `studio-embedded` without `user_id` is the `401`
    ///   a key alone gets. One that names a user is answered only while that user holds
    ///   the owner or admin role in the key's organization, and is a 403 otherwise.
    /// - The catalog is a set of a size Mountaya decides, so it is not paged.
    ///
    /// Like every read made with a session token naming a user, it is limited to 1200 a
    /// minute per user the token names and then to 6000 a minute per organization, and one
    /// made with a session token minted without `user_id` is held as the key alone is, to
    /// 600 a minute per client IP address and then 6000 per organization; past either, the
    /// answer is a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token. A
    /// publishable key without a session token is not accepted here: a key written to be
    /// shipped in a browser cannot be sufficient on its own to read or change an
    /// organization's account.
    public func getWebhookEventTypes(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.WebhookEventCatalogEntry], [String: JSONValue]?> {
      let request = OperationRequest(facts: .getWebhookEventTypes)
      return try await sender.envelope(request, options: options)
    }

    /// Update a webhook endpoint.
    ///
    /// Changes an endpoint's URL, description, event types or status. Each field is
    /// optional and an omitted one keeps its value; `enabled_events` is replaced whole. An
    /// empty object changes nothing and answers the endpoint as it stands.
    /// - Owner or admin only (403 otherwise).
    /// - `url` and `enabled_events` are held to the rules of a new endpoint's, and refused
    ///   the same way.
    /// - `status` `disabled` stops every delivery to the endpoint, the ones still retrying
    ///   included, which end `canceled`. `enabled` starts them again from the next event
    ///   recorded, and clears `failing_since`; the events recorded while it was disabled
    ///   are not sent on their own, and `postOrganizationWebhookDelivery` redelivers those
    ///   of the last 30 days.
    /// - The secret is not changed here.
    /// - `If-Match` makes the change conditional: send the endpoint's `etag`, and an
    ///   endpoint changed since is refused with `412`, changing nothing.
    /// - It is limited, together with the organization's other endpoint writes this
    ///   document's introduction lists, to 30 a minute per user and then 300 a minute per
    ///   organization; past either, the answer is a `429` carrying `Retry-After`, and
    ///   nothing is done.
    ///
    /// Requires a publishable key with the `management` scope AND a session token naming a
    /// user, a member with the owner or admin role, whom the request acts as. A session
    /// token minted without `user_id` is refused with **401**, and a publishable key
    /// without a session token is not accepted here: a key written to be shipped in a
    /// browser cannot be sufficient on its own to read or change an organization's
    /// account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchOrganizationWebhookEndpoint(
      organization_id: String,
      webhook_endpoint_id: String,
      body: AdminSchema.WebhookEndpointUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookEndpoint, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationWebhookEndpoint,
        pathParameters: [
          "organization_id": organization_id, "webhook_endpoint_id": webhook_endpoint_id,
        ],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Resend an event, send a test event, or redeliver an endpoint's events.
    ///
    /// Starts deliveries to one of the organization's endpoints, which run after the
    /// answer. The body names the endpoint and exactly one of three things:
    /// - `event_id`, a resend: one event recorded in the last 30 days, delivered again on
    ///   the delivery schedule, whether or not the endpoint was sent it the first time.
    /// - `test`, a test: a test event of the type named, its payload this contract's
    ///   example for the type with an `id` of its own, delivered once without retries. It
    ///   is recorded nowhere else and listed by no `getOrganizationWebhookEvents`.
    /// - `since`, a redelivery: every event recorded from that instant on, at most 30 days
    ///   ago, whose type the endpoint is sent, delivered again oldest first at a paced
    ///   rate. Use it after an outage outlasted the retries, or after enabling an endpoint
    ///   again, from the `failing_since` the endpoint carried before it was enabled. One
    ///   redelivery runs at a time for an endpoint.
    ///
    /// Each delivery it starts carries the answer's `id` as `trigger_id`, and is read as
    /// any other.
    /// - Owner or admin only (403 otherwise).
    /// - A disabled endpoint is a `409`: enable it first. A redelivery asked while another
    ///   to the same endpoint still runs is a `409` coded `REDELIVERY_IN_PROGRESS`, naming
    ///   the one running. An event older than 30 days, or a `since` further back or still to
    ///   come, is a `400` naming it.
    /// - It is limited to 30 a minute per user and then 300 a minute per organization, and
    ///   a redelivery to 10 an hour per user and 30 an hour per organization besides; past
    ///   any of them, the answer is a `429` carrying `Retry-After`.
    /// - A request sent again with its `Idempotency-Key` starts nothing twice.
    ///
    /// Requires a publishable key with the `management` scope AND a session token naming a
    /// user, a member with the owner or admin role, whom the request acts as. A session
    /// token minted without `user_id` is refused with **401**, and a publishable key
    /// without a session token is not accepted here: a key written to be shipped in a
    /// browser cannot be sufficient on its own to read or change an organization's
    /// account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postOrganizationWebhookDelivery(
      organization_id: String,
      body: AdminSchema.WebhookDeliveryCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookDeliveryTrigger, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationWebhookDelivery,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create a webhook endpoint.
    ///
    /// Creates an endpoint Mountaya delivers the organization's webhook events to: every
    /// event of a type its `enabled_events` names, from the next one recorded on, signed
    /// with a secret of its own, answered here once. A create sent twice without an
    /// `Idempotency-Key` makes two endpoints; with one, the second is not answered the
    /// first one's endpoint, since that answer carried the secret and is never kept: it is
    /// the `409` coded `IDEMPOTENCY_ANSWER_UNAVAILABLE`. A create sent again with the key,
    /// after the first failed with a `5xx` once the endpoint was made, is that `409` too,
    /// whose `extensions.metadata.location` names the endpoint made,
    /// `/v1/organizations/{organization_id}/webhook-endpoints/{webhook_endpoint_id}`. This
    /// API answers a secret once: an owner or an admin reads that endpoint's again in
    /// Mountaya's web application, or deletes it and creates another.
    /// - Owner or admin only (403 otherwise).
    /// - `url` is `https`, written in printable ASCII, at most 2048 characters, with no
    ///   credentials before its host and no fragment, its host, port included, at most 259
    ///   characters; and that host resolves to a public address: a private, loopback or
    ///   link-local one is a `400` naming `url`, and so is one Mountaya cannot resolve. A
    ///   redirect is never followed.
    /// - `enabled_events` names types, families followed by `.*`, or `*`. A type or a
    ///   family the contract does not publish is a `400` naming its position;
    ///   `getWebhookEventTypes` lists them.
    /// - An organization holds 2 endpoints, enabled and disabled, unless its agreement
    ///   says otherwise, 6 at most: one more is refused at `webhook-endpoints`, a `429`
    ///   coded `LIMIT_REACHED` with no `Retry-After`. Delete one first, or agree a higher
    ///   limit. An organization whose limit was lowered below what it holds keeps its
    ///   endpoints, and creates none until it holds fewer than the limit.
    /// - It is limited, together with the organization's other endpoint writes this
    ///   document's introduction lists, to 30 a minute per user and then 300 a minute per
    ///   organization; past either, the answer is a `429` carrying `Retry-After`, and
    ///   nothing is done.
    /// - Mountaya delivers each event at least once, in no promised order, retrying a
    ///   failed attempt for about 72 hours. This document's introduction says how a
    ///   delivery is signed, retried and recorded.
    ///
    /// Requires a publishable key with the `management` scope AND a session token naming a
    /// user, a member with the owner or admin role, whom the request acts as. A session
    /// token minted without `user_id` is refused with **401**, and a publishable key
    /// without a session token is not accepted here: a key written to be shipped in a
    /// browser cannot be sufficient on its own to read or change an organization's
    /// account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postOrganizationWebhookEndpoint(
      organization_id: String,
      body: AdminSchema.WebhookEndpointCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.WebhookEndpointWithSecret, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationWebhookEndpoint,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
