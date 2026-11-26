import Foundation
import MountayaAdmin
import MountayaClient

/// Calls calls one operation of every kind, and reads what each answers.
enum Calls {
  /// envelope reads a resource, then writes it under the tag it was read with.
  static func envelope(_ client: Mountaya) async throws {
    let read = try await client.studio.collections.getCollection(collection_id: "co")
    _ = (read.data, read.metadata, read.status, read.requestId, read.location, read.etag)
    _ = (read.headers, read.header("Cache-Control"))
    let written = try await client.studio.collections.deleteCollection(
      collection_id: "co",
      idempotencyKey: "order-7f3a",
      ifMatch: read.etag,
      options: RequestOptions(retry: try RetryPolicy(maxRetries: 0), timeout: .seconds(5))
    )
    _ = written.data
    let link = try await client.studio.itineraries.postItineraryShareLink(itinerary_id: "it")
    _ = (link.data.share_token, link.data.created_at, link.location)
  }

  /// body sends a body a caller builds, its optional fields set in the trailing closure, and
  /// a merge whose three states the type tells apart.
  static func body(_ client: Mountaya) async throws {
    _ = try await client.studio.itineraries.patchItinerarySegment(
      itinerary_id: "it",
      segment_id: "se",
      body: .init {
        $0.description = .some(nil)
        $0.speed = 4.5
      }
    )
  }

  /// file reads an export's bytes and the content type the server chose.
  static func file(_ client: Mountaya) async throws {
    let export = try await client.studio.itineraries.getItineraryExport(
      itinerary_id: "it", query: .init(format: .gpx))
    _ = (export.bytes, export.contentType, export.status, export.requestId)
  }

  /// events reads an agent run's stream to its end.
  static func events(_ client: Mountaya) async throws {
    for try await frame in try client.agent.runs.getAgentRunEvents(run_id: "ru") {
      switch frame.event {
      case .AgentMessageEvent(let message): _ = (frame.id, message.content)
      case .AgentDoneEvent(let done): _ = done.reason
      default: break
      }
    }
  }

  /// editors reads an itinerary's editor stream as the user a session token given as a value
  /// does not name.
  static func editors(_ client: Mountaya) async throws {
    let stream = try client.studio.collab.getItineraryEvents(itinerary_id: "it")
    for try await frame in stream.reading(asUser: "us") {
      if case .CollabPresenceJoinEvent(let join) = frame.event {
        _ = join.user_id
      }
    }
  }

  /// data asks the Data API for a narrowed result.
  static func data(_ client: Mountaya) async throws {
    let directions = try await client.data.directions(
      input: .init(activity: .hikingAndTrail, waypoints: [[6.86, 45.83], [6.87, 45.84]]),
      select: ["routes": ["distance": true, "duration": true]]
    )
    _ = directions.routes?.first?.distance
  }

  /// pages walks a paged listing, a page requested only as the rows before it are read.
  static func pages(_ client: Mountaya) async throws {
    let walk = try PageWalk(query: RestSchema.GetItinerariesQuery(), pageSize: 20, maxPages: 5) {
      try await client.studio.itineraries.getItineraries(query: $0)
    }
    for try await itinerary in walk {
      _ = (itinerary.id, itinerary.name, itinerary.etag)
    }
    _ = (PageWalk<RestSchema.GetItinerariesQuery, RestSchema.Itinerary>.defaultPageSize)
    let members = try client.admin.members.walkGetOrganizationMembers(
      organization_id: "or", pageSize: 25, maxPages: 2)
    for try await member in members {
      _ = (member.user_id, member.role)
    }
    // A listing this build prints no method for, walked by its declaration.
    let things: AsyncThrowingStream<JSONValue, any Error> = try client.walk(
      OperationDeclaration(operationId: "getThings", method: "GET"), path: "/v1/things",
      query: [URLQueryItem(name: "sort", value: "name")], headers: ["X-Trace": "consumer"],
      pageSize: 20, maxPages: 2)
    for try await thing in things {
      _ = thing
    }
  }

  /// templates reads the routes a map renderer fetches on its own, one filled in.
  static func templates(_ client: Mountaya) -> [String] {
    let tile = TileTemplates.getItineraryTile
    _ = (tile.operationId, tile.pathParameters, tile.queryParameters, tile.mediaTypes)
    return TileTemplates.all.map(\.path) + [
      client.baseUrls.tiles.absoluteString + tile.filled(with: ["itinerary_id": "it"])
    ]
  }

  /// declared calls an operation this build prints no method for, by its declaration.
  static func declared(_ client: Mountaya) async throws {
    let operation = OperationDeclaration(
      surface: .rest,
      operationId: "getThing",
      method: "GET",
      idempotent: true,
      credentials: CredentialDeclaration(requiresSession: true),
      timeout: .seconds(30)
    )
    let thing: Response<JSONValue, [String: JSONValue]?> = try await client.send(
      operation, path: "/v1/things/th", query: [URLQueryItem(name: "limit", value: "2")])
    _ = thing.data
    let upload: Response<JSONValue, [String: JSONValue]?> = try await client.send(
      OperationDeclaration(operationId: "postThingUpload", method: "POST"),
      path: "/v1/things/th/upload",
      body: .multipart([
        MultipartPart(name: "provider", content: .text("gpx")),
        MultipartPart(
          name: "file",
          content: .file(Data("<gpx/>".utf8), filename: "tour.gpx", contentType: "text/xml")),
      ]))
    _ = upload.status
    let elevation: DataSchema.TerrainSamplesResult = try await client.query(
      DataOperation(
        name: "terrainSamples", inputType: "TerrainSamplesInput!",
        selection: ["samples": ["elevation": true]], timeout: .seconds(30)),
      input: JSONValue.object(["points": .array([.array([.number(6.86), .number(45.83)])])]))
    _ = elevation
    for try await record in try client.events(operation, path: "/v1/things/th/events") {
      _ = (record.id, record.event.event, record.event.data, record.event.id)
    }
  }

  #if os(macOS) || os(Linux)
    /// mint mints a session token on a server, through the admin unit under the core's secret key,
    /// the answer the token an app's session engine is handed.
    static func mint(_ server: Mountaya, for user: String) async throws -> SessionToken {
      let minted = try await server.admin.sessions.postSession(
        body: .init(publishable_key: "pk_live_a") {
          $0.user_id = user
          $0.surface = .api
        })
      return .minted(minted.data)
    }

    /// webhook verifies a delivery, as bytes and as text, on a server, the one place its secret is
    /// kept, and reads the event of each kind it holds: one the type ties to its object and its
    /// previous attributes, one whose change moves no field, and one this build cannot type, every
    /// member of the envelope read off each alike.
    static func webhook(body: Data, signature: String?, secret: String) throws -> String {
      let event = try constructWebhookEvent(
        rawBody: body, signatureHeader: signature, secret: secret, tolerance: .seconds(600),
        now: Date(timeIntervalSince1970: 1_763_111_569))
      _ = try constructWebhookEvent(
        rawBody: String(decoding: body, as: UTF8.self), signatureHeader: signature, secret: secret)
      _ = (event.id, event.object, event.api_version, event.created_at, event.organization_id)
      _ = (event.task, event.related_object.id, event.request?.id, event.actor.type, event.type)
      switch event {
      case .organizationMemberUpdated(let payload):
        let previous: WebhookEvent.OrganizationMemberUpdatedPreviousAttributes? =
          payload.data.previous_attributes
        _ = (payload.id, payload.created_at, payload.task, payload.actor.type, payload.request?.id)
        return "\(payload.data.object.role) was \(previous?.role?.rawValue ?? "")"
      case .zoneDeleted(let payload):
        let none: Never? = payload.data.previous_attributes
        return "\(payload.data.object.id) \(none == nil)"
      case .unknown(let envelope):
        if case .unknown(let held) = envelope.data.object {
          return "\(envelope.type.rawValue) \(held)"
        }
        return envelope.type.rawValue
      default:
        return event.type.rawValue
      }
    }
  #endif
}
