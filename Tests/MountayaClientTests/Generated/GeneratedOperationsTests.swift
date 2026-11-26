import Foundation
import Testing

@testable import MountayaClient

/// The printed methods, called through a scripted seam: what each hands the transport is the
/// contract's operation, filled in by the call.
@Suite("Generated operations")
struct GeneratedOperationsTests {
  @Test("a path parameter is substituted and percent-encoded as one segment")
  func pathParameters() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.itineraries.getItinerary(itinerary_id: "a b/c?d")

    let request = try #require(await sender.sent.first?.request)
    #expect(request.path == "/v1/itineraries/a%20b%2Fc%3Fd")
    #expect(request.facts == .getItinerary)
    #expect(request.query.isEmpty)
  }

  @Test("an organization's lookup sends its key in the body, under no credential")
  func organizationLookup() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.organizations.postOrganizationLookup(
      body: .init(publishable_key: "pk_test_a"))

    let sent = try #require(await sender.sent.first)
    #expect(sent.request?.path == "/v1/organizations/lookup")
    #expect(sent.request?.facts == .postOrganizationLookup)
    #expect(sent.json == #"{"publishable_key":"pk_test_a"}"#)
  }

  @Test("a query carries its set parameters in the operation's order, and none it left unset")
  func query() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.itineraries.getItineraryPace(
      itinerary_id: "it",
      query: .init(speed: 4.5) { $0.surface = .published }
    )
    _ = try? await sender.client.studio.collections.getCollectionItineraries(
      collection_id: "co",
      query: .init { $0.limit = 20 }
    )
    _ = try? await sender.client.studio.collections.getCollectionItineraries(collection_id: "co")

    let sent = await sender.sent
    #expect(
      sent[0].request?.query
        == [QueryItem(name: "speed", value: "4.5"), QueryItem(name: "surface", value: "published")]
    )
    #expect(sent[1].request?.query == [QueryItem(name: "limit", value: "20")])
    #expect(sent[2].request?.query == [])
  }

  @Test("a merge body sends each of its three states as the contract reads them")
  func mergeBody() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.itineraries.patchItinerarySegment(
      itinerary_id: "it",
      segment_id: "se",
      body: .init {
        $0.description = .some(nil)
        $0.speed = 4.5
      }
    )

    let sent = try #require(await sender.sent.first)
    #expect(sent.json == #"{"description":null,"speed":4.5}"#)
    #expect(sent.request?.facts == .patchItinerarySegment)
  }

  @Test("a required, nullable property is written as null, which is the instruction")
  func requiredNullable() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.collab.postItineraryCollab(
      itinerary_id: "it",
      body: .CollabCursorSignal(.init(position: nil))
    )

    let json = try #require(await sender.sent.first?.json)
    #expect(json == #"{"position":null,"type":"cursor"}"#)
  }

  @Test(
    "a multipart form is sent a part to a property in the contract's order, a file as it names"
  )
  func multipartForm() async throws {
    let sender = ScriptedSender()
    let form = RestSchema.PostItineraryPreviewMultipartBody(
      provider: .gpx,
      file: Data("<gpx/>".utf8),
      activity_id: "ac"
    ) { $0.granularity = .single }
    _ = try? await sender.client.studio.itineraries.postItineraryPreview(body: form)

    let request = try #require(await sender.sent.first?.request)
    guard case .multipart(let parts) = request.body else {
      Issue.record("the form was not sent as multipart/form-data")
      return
    }
    #expect(
      parts == [
        MultipartPart(name: "provider", content: .text("gpx")),
        MultipartPart(
          name: "file",
          content: .file(Data("<gpx/>".utf8), contentType: "application/octet-stream")),
        MultipartPart(name: "activity_id", content: .text("ac")),
        MultipartPart(name: "granularity", content: .text("single")),
      ]
    )
  }

  @Test("a write hands the transport the key and the tag its caller passed, and none unset")
  func keyAndTag() async throws {
    let sender = ScriptedSender()
    _ = try? await sender.client.studio.collections.deleteCollection(
      collection_id: "co",
      idempotencyKey: "order-7f3a",
      ifMatch: "\"d43\""
    )
    _ = try? await sender.client.studio.collections.deleteCollection(collection_id: "co")

    let sent = await sender.sent
    #expect(sent[0].request?.idempotencyKey == "order-7f3a")
    #expect(sent[0].request?.ifMatch == "\"d43\"")
    #expect(sent[0].request?.facts.declaresIdempotencyKey == true)
    #expect(sent[1].request?.idempotencyKey == nil)
    #expect(sent[1].request?.ifMatch == nil)
  }

  @Test("a success is read into the declared data and metadata")
  func envelope() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": null}}}}"#,
      #"{"data": {"duration": 3600, "segments": []}}"#,
    ])
    let page = try await sender.client.studio.collections.getCollectionItineraries(
      collection_id: "co"
    )
    let pace = try await sender.client.studio.itineraries.getItineraryPace(
      itinerary_id: "it",
      query: .init(speed: 4)
    )

    #expect(page.data.isEmpty)
    #expect(page.metadata.pagination.limit == 50)
    #expect(page.metadata.pagination.next_cursor == nil)
    #expect(pace.data.duration == 3600)
    #expect(pace.metadata == nil)
  }

  @Test("an event stream's frames arrive in order, a member this build never saw passed over")
  func events() async throws {
    let sender = ScriptedSender(frames: [
      ("1", #"{"type": "message", "content": "Hello", "message_index": 0}"#),
      ("2", #"{"type": "brand-new", "x": 1}"#),
    ])
    let stream = try sender.client.agent.runs.getAgentRunEvents(run_id: "ru")
    var frames: [EventFrame<RestSchema.AgentRunEvent>] = []
    for try await frame in stream {
      frames.append(frame)
    }

    let request = try #require(await sender.sent.first?.request)
    #expect(request.headers.isEmpty)
    #expect(frames.map(\.id) == ["1"])
    guard case .AgentMessageEvent(let message) = frames.first?.event else {
      Issue.record("the first frame is not a message")
      return
    }
    #expect(message.content == "Hello")
  }

  @Test("a file is returned with the content type the server chose")
  func binary() async throws {
    let file = BinaryResponse(bytes: Data("<gpx/>".utf8), contentType: "application/gpx+xml")
    let sender = ScriptedSender(file: file)
    let export = try await sender.client.studio.itineraries.getItineraryExport(
      itinerary_id: "it",
      query: .init(format: .gpx)
    )

    #expect(export == file)
    #expect(await sender.sent.first?.request?.query == [QueryItem(name: "format", value: "gpx")])
  }

  /// collection is a collection as a listing answers it, holding what it requires and no more.
  private static func collection(_ id: String, name: String) -> String {
    #"{"count":{"itineraries":2,"zones":0},"created_at":"2026-11-14T09:12:44.000Z","#
      + #""created_by":{"id":"user"},"description":null,"etag":"\"e1\"","id":"\#(id)","#
      + #""is_private":false,"name":"\#(name)","organization_id":"org","role":"owner","#
      + #""sources":[],"updated_at":"2026-11-14T09:12:44.000Z"}"#
  }

  @Test(
    "a printed walk pages its listing at the operation's page size, each row as the listing types it"
  )
  func walk() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [\#(Self.collection("co_1", name: "Alps"))], "#
        + #""extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": "c2"}}}}"#,
      #"{"data": [\#(Self.collection("co_2", name: "Jura"))], "#
        + #""extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": null}}}}"#,
    ])
    var rows: [RestSchema.Collection] = []
    let walk = try sender.client.studio.collections.walkGetCollections(
      query: .init { $0.cursor = "c1" },
      options: RequestOptions(retry: try RetryPolicy(maxRetries: 0)))
    for try await row in walk {
      rows.append(row)
    }

    let sent = await sender.sent
    #expect(rows.map(\.id) == ["co_1", "co_2"])
    #expect(rows.map(\.name) == ["Alps", "Jura"])
    #expect(sent.map { $0.request?.facts } == [.getCollections, .getCollections])
    #expect(sent.map { $0.request?.path } == Array(repeating: "/v1/collections", count: 2))
    #expect(
      sent.map { $0.request?.query }
        == [
          [QueryItem(name: "cursor", value: "c1"), QueryItem(name: "limit", value: "50")],
          [QueryItem(name: "cursor", value: "c2"), QueryItem(name: "limit", value: "50")],
        ])
    #expect(sent.allSatisfy { $0.options.retry?.maxRetries == 0 })
  }

  @Test("a printed walk fills its path as its method does, each parameter one encoded segment")
  func walkPath() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": null}}}}"#
    ])
    for try await _ in try sender.client.studio.collections.walkGetCollectionZones(
      collection_id: "co/1")
    {}

    #expect(await sender.sent.map { $0.request?.path } == ["/v1/collections/co%2F1/zones"])
  }

  @Test(
    "a printed walk asks the page size and the ceiling it is given, and refuses one out of range")
  func walkBounds() async throws {
    let sender = ScriptedSender(answers: [
      #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 7, "next_cursor": "c2"}}}}"#
    ])
    for try await _ in try sender.client.studio.itineraries.walkGetItineraries(
      pageSize: 7, maxPages: 1)
    {}

    let sent = await sender.sent
    #expect(sent.map { $0.request?.query } == [[QueryItem(name: "limit", value: "7")]])
    #expect(throws: MountayaError.self) {
      _ = try sender.client.studio.itineraries.walkGetItineraries(pageSize: 101)
    }
    #expect(throws: MountayaError.self) {
      _ = try sender.client.studio.zones.walkGetZones(maxPages: 0)
    }
    #expect(await sender.sent.count == 1, "a refused walk requests nothing")
  }

  @Test("a Data API operation called by its declaration is sent as its printed method sends it")
  func declaredDataOperation() async throws {
    let sender = ScriptedSender(answers: [#"{"routes": [{"distance": 1200}]}"#])
    let declared = DataOperation(
      name: "directions", inputType: "DirectionsInput!",
      selection: DataOperation.directions.selection, timeout: .seconds(30))
    let result: DataSchema.DirectionsResult = try await sender.client.query(
      declared,
      input: DataSchema.DirectionsInput(
        activity: .hikingAndTrail, waypoints: [[6.86, 45.83], [6.87, 45.84]]),
      select: ["routes": ["distance": true]])

    let sent = try #require(await sender.sent.first)
    #expect(sent.operation == declared)
    #expect(sent.facts == .directions, "the facts every Data API operation declares")
    #expect(sent.select == ["routes": ["distance": true]])
    #expect(result.routes?.first?.distance == 1200)
  }

  @Test("a Data API call hands the seam its operation, input and selection")
  func dataOperation() async throws {
    let sender = ScriptedSender(answers: [#"{"routes": [{"distance": 1200}]}"#])
    let result = try await sender.client.data.directions(
      input: .init(activity: .hikingAndTrail, waypoints: [[6.86, 45.83], [6.87, 45.84]]),
      select: ["routes": ["distance": true]],
      options: RequestOptions(retry: try RetryPolicy(maxRetries: 0))
    )

    let sent = try #require(await sender.sent.first)
    #expect(sent.operation == .directions)
    #expect(sent.facts == .directions)
    #expect(
      sent.json == #"{"activity":"HIKING_AND_TRAIL","waypoints":[[6.86,45.83],[6.87,45.84]]}"#)
    #expect(sent.select == ["routes": ["distance": true]])
    #expect(sent.options.retry?.maxRetries == 0)
    #expect(result.routes?.first?.distance == 1200)
  }
}
