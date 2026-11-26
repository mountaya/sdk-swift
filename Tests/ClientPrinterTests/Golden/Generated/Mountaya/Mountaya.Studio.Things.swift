// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Things is every operation of `studio.things`, one method to an operation.
  public struct Things: Sendable {
    let sender: any OperationSending

    /// Get a thing
    ///
    /// Returns one thing.
    public func getThing(
      thing_id: String,
      query: RestSchema.GetThingQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Thing, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getThing,
        pathParameters: ["thing_id": thing_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// The contract's `listThings`.
    public func listThings(
      query: RestSchema.ListThingsQuery,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.Thing], RestSchema.PageMeta> {
      let request = OperationRequest(
        facts: .listThings,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkListThings walks the listing `listThings` answers, one row at a time, requesting a page
    /// only as the rows before it are read (`transport.pagination.walk`).
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
    public func walkListThings(
      query: RestSchema.ListThingsQuery,
      pageSize: Int = 20,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<RestSchema.ListThingsQuery, RestSchema.Thing> {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await listThings(query: page, options: options)
      }
    }

    /// Update a thing. Patching is replaced by putThing, which this release adds beside it.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    @available(*, deprecated, message: "Update a thing.")
    public func patchThing(
      thing_id: String,
      body: RestSchema.ThingPatch,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchThing,
        pathParameters: ["thing_id": thing_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// The contract's `postThing`.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postThing(
      body: RestSchema.ThingCreate,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Thing?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postThing,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// The contract's `getThingEvents`.
    public func getThingEvents(
      thing_id: String,
      `X-Trace`: String? = nil,
      options: RequestOptions = RequestOptions()
    ) throws -> EventStream<RestSchema.Event> {
      let request = OperationRequest(
        facts: .getThingEvents,
        pathParameters: ["thing_id": thing_id],
        headers: ["X-Trace": `X-Trace`]
      )
      return try sender.events(request, options: options)
    }
  }
}
