import Foundation
import Testing

@testable import MountayaClient

@Suite("Mountaya", .timeLimit(.minutes(1)))
struct MountayaTests {
  @Test("every accessor sends through the client's one seam")
  func accessorsShareTheSeam() async throws {
    let sender = ScriptedSender()
    let client = sender.client
    _ = try? await client.studio.zones.getZone(zone_id: "zo")
    _ = try? await client.tiles.getZonesSpecification()

    let sent = await sender.sent
    #expect(sent.map(\.facts.operationId) == ["getZone", "getZonesSpecification"])
    #expect(sent.map(\.facts.surface) == [.rest, .tiles])
  }

  @Test("a client given no exchange sends through the platform's, over the process's session")
  func defaultExchange() throws {
    let client = try Mountaya(credential: .publishable(key: "pk_test_a"))
    let transport = try #require(client.sender as? Transport)
    let exchange = try #require(transport.exchange as? SystemExchange)

    #expect(exchange.loader === SystemExchange().loader)
  }

  /// client is a client whose every surface is a stub host answered by `scripts` in turn, over
  /// the platform's exchange.
  private static func client(_ scripts: [StubLoading.Script]) throws -> (Mountaya, String) {
    let host = StubLoading.host(scripts)
    let origin = try StubLoading.url(host)
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"),
      language: "fr",
      baseUrls: BaseURLs(data: origin, rest: origin, tiles: origin),
      retry: try RetryPolicy(maxRetries: 0),
      exchange: StubLoading.exchange()
    )
    return (client, host)
  }

  @Test("a printed write leaves over the platform's loader and answers what its success declares")
  func printedWrite() async throws {
    let (client, host) = try Self.client([
      .answer(
        201,
        headers: [
          "Location": "/v1/itineraries/it/share-link", "X-Request-Id": "req_201",
          "ETag": "\"e1\"",
        ],
        chunks: [#"{"data": {"share_token": "share_0a", "created_at": "2026-11-05T08:00:00Z"}}"#]
      )
    ])
    let link = try await client.studio.itineraries.postItineraryShareLink(
      itinerary_id: "it", idempotencyKey: "order-7f3a")

    #expect(link.status == 201)
    #expect(link.data.share_token == "share_0a")
    #expect(link.location == "/v1/itineraries/it/share-link")
    #expect(link.requestId == "req_201")
    #expect(link.etag == "\"e1\"")
    let sent = try #require(StubLoading.seen(host).first)
    #expect(sent.method == "POST")
    #expect(sent.url?.path == "/v1/itineraries/it/share-link")
    #expect(sent.header("X-API-Key") == "pk_test_a")
    #expect(sent.header("X-Session-Token") == "sess_a")
    #expect(sent.header("Accept-Language") == "fr")
    #expect(sent.header("Idempotency-Key") == "order-7f3a")
    #expect(sent.header("Accept") == "application/json")
    #expect(sent.header("Cookie") == nil)
    #expect(sent.header("X-Mountaya-Client") == "mountaya-swift/\(ClientIdentification.version)")
  }

  /// The contract's one operation that takes no credential, an organization's lookup, is the admin
  /// unit's, whose printed method `MountayaAdminTests` sends through this same transport; here it
  /// is declared, as an operation this build prints no method for is.
  @Test("an operation that takes no credential is sent none, and still names the SDK")
  func credentialless() async throws {
    let (client, host) = try Self.client([.answer(404, chunks: [#"{"errors": []}"#])])
    let lookup = OperationDeclaration(
      operationId: "postOrganizationLookup", method: "POST",
      credentials: CredentialDeclaration(takesNoCredential: true))
    let _: Response<JSONValue, JSONValue?>? = try? await client.send(
      lookup, path: "/v1/organizations/lookup",
      body: .json(JSONValue.object(["publishable_key": "pk_test_a"])))

    let sent = try #require(StubLoading.seen(host).first)
    #expect(sent.url?.path == "/v1/organizations/lookup")
    #expect(sent.header("X-API-Key") == nil)
    #expect(sent.header("X-Session-Token") == nil)
    #expect(sent.header("Accept-Language") == "fr")
    #expect(sent.header("X-Mountaya-Client") == ClientIdentification.value)
  }

  @Test("a call made by its declaration may not name the SDK's header, in any case")
  func declarationNamingTheIdentification() async throws {
    let (client, host) = try Self.client([])
    for name in ["X-Mountaya-Client", "x-mountaya-client"] {
      let error = await #expect(throws: MountayaError.self) {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          OperationDeclaration(operationId: "getThing", method: "GET"), path: "/v1/things",
          headers: [name: "mountaya-swift/9.9.9"])
      }
      #expect(error?.name == "ConfigurationError", "\(name)")
    }
    #expect(StubLoading.seen(host).isEmpty)
  }

  @Test("an export answers its bytes, the content type the server chose and its request id")
  func export() async throws {
    let (client, host) = try Self.client([
      .answer(
        200,
        headers: ["Content-Type": "application/gpx+xml", "X-Request-Id": "req_gpx"],
        chunks: ["<gpx>", "</gpx>"]
      )
    ])
    let file = try await client.studio.itineraries.getItineraryExport(
      itinerary_id: "it", query: .init(format: .gpx))

    #expect(file.bytes == Data("<gpx></gpx>".utf8))
    #expect(file.contentType == "application/gpx+xml")
    #expect(file.status == 200)
    #expect(file.requestId == "req_gpx")
    #expect(StubLoading.seen(host).first?.url?.query == "format=gpx")
    #expect(StubLoading.seen(host).first?.header("Accept") == "*/*")
  }

  @Test("an event stream is read as the platform delivers it, and ends on its done")
  func eventStream() async throws {
    let (client, host) = try Self.client([
      .answer(
        200,
        headers: ["Content-Type": "text/event-stream"],
        chunks: [
          "id: 1\nevent: message\ndata: {\"content\": \"Bonjour\", \"message_index\": 0}\n\n",
          "id: 2\nevent: done\ndata: {\"reason\": \"completed\"}\n\n",
        ],
        ending: .staysOpen
      )
    ])
    var frames: [EventFrame<RestSchema.AgentRunEvent>] = []
    for try await frame in try client.agent.runs.getAgentRunEvents(run_id: "ru") {
      frames.append(frame)
    }

    #expect(frames.map(\.id) == ["1", "2"])
    guard case .AgentMessageEvent(let message) = frames.first?.event else {
      Issue.record("the first frame is not a message")
      return
    }
    #expect(message.content == "Bonjour")
    #expect(StubLoading.seen(host).first?.header("Accept") == "text/event-stream")
    #expect(StubLoading.seen(host).first?.header("X-Mountaya-Client") == ClientIdentification.value)
    #expect(try await eventually { StubLoading.stops(host) == 1 })
  }

  @Test("a Data API call sends its digest alone, and its document where the server asks")
  func dataQuery() async throws {
    let (client, host) = try Self.client([
      .answer(200, chunks: [#"{"errors": [{"message": "PersistedQueryNotFound"}]}"#]),
      .answer(200, chunks: [#"{"data": {"directions": {"routes": [{"distance": 1200}]}}}"#]),
    ])
    let result = try await client.data.directions(
      input: .init(activity: .hikingAndTrail, waypoints: [[6.86, 45.83], [6.87, 45.84]]),
      select: ["routes": ["distance": true]]
    )

    #expect(result.routes?.first?.distance == 1200)
    let sent = StubLoading.seen(host)
    try #require(sent.count == 2)
    let first = try JSONValue.decoding(sent[0].body)
    let second = try JSONValue.decoding(sent[1].body)
    #expect(first.member("query") == nil)
    #expect(first.member("extensions", "persistedQuery", "sha256Hash") != nil)
    guard case .string(let document)? = second.member("query") else {
      Issue.record("the second attempt sent no document")
      return
    }
    #expect(document.hasPrefix("query Directions"))
    #expect(second.member("extensions", "persistedQuery", "sha256Hash") != nil)
    #expect(sent.allSatisfy { $0.method == "POST" && $0.header("X-Session-Token") == "sess_a" })
    #expect(sent.allSatisfy { $0.header("X-Mountaya-Client") == ClientIdentification.value })
  }

  @Test("a paged listing is walked over the platform's loader, one page a request")
  func pageWalk() async throws {
    let (client, host) = try Self.client([
      .answer(
        200,
        chunks: [
          #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 2, "next_cursor": "c2"}}}}"#
        ]),
      .answer(
        200,
        chunks: [
          #"{"data": [], "extensions": {"metadata": {"pagination": {"limit": 2, "next_cursor": null}}}}"#
        ]),
    ])
    let walk = try PageWalk(query: RestSchema.GetItinerariesQuery(), pageSize: 2) {
      try await client.studio.itineraries.getItineraries(query: $0)
    }
    var rows = 0
    for try await _ in walk {
      rows += 1
    }

    #expect(rows == 0)
    let queries = StubLoading.seen(host).map { $0.url?.query }
    #expect(queries == ["limit=2", "cursor=c2&limit=2"])
  }

  /// Thing is a row of a listing this build prints no method for.
  private struct Thing: Decodable, Sendable, Equatable {
    let id: String
  }

  /// things is an operation this build prints no method for, a paged listing.
  private static let things = OperationDeclaration(operationId: "getThings", method: "GET")

  /// page is a page's envelope holding `ids`, naming `next` as the cursor of the page after it.
  private static func page(_ ids: [String], next: String?) -> StubLoading.Script {
    let rows = ids.map { #"{"id": "\#($0)"}"# }.joined(separator: ", ")
    let cursor = next.map { #""\#($0)""# } ?? "null"
    return .answer(
      200,
      chunks: [
        #"{"data": [\#(rows)], "extensions": {"metadata": {"pagination": {"next_cursor": \#(cursor)}}}}"#
      ])
  }

  /// A listing this build prints no method for is walked by its declaration
  /// (`transport.pagination.walk`): the caller's query and headers on every page, its own cursor
  /// first, each page asked for only as the rows before it are read.
  @Test("a listing is walked by its declaration, each page asked for only as its rows are read")
  func walkByDeclaration() async throws {
    let (client, host) = try Self.client([
      Self.page(["a", "b"], next: "c2"), Self.page([], next: "c3"), Self.page(["c"], next: nil),
    ])
    let rows: AsyncThrowingStream<Thing, any Error> = try client.walk(
      Self.things, path: "/v1/things",
      query: [
        URLQueryItem(name: "sort", value: "name"), URLQueryItem(name: "cursor", value: "c1"),
        URLQueryItem(name: "limit", value: "9"),
      ],
      headers: ["X-Trace": "walk"], pageSize: 2)

    #expect(StubLoading.seen(host).isEmpty, "nothing is asked before a row is read")
    var iterator = rows.makeAsyncIterator()
    #expect(try await iterator.next() == Thing(id: "a"))
    #expect(StubLoading.seen(host).count == 1)
    #expect(try await iterator.next() == Thing(id: "b"))
    #expect(StubLoading.seen(host).count == 1, "the next page waits for its first row to be read")
    #expect(try await iterator.next() == Thing(id: "c"))
    #expect(try await iterator.next() == nil)
    let sent = StubLoading.seen(host)
    #expect(
      sent.map { $0.url?.query } == [
        "sort=name&cursor=c1&limit=2", "sort=name&cursor=c2&limit=2",
        "sort=name&cursor=c3&limit=2",
      ])
    #expect(sent.allSatisfy { $0.url?.path == "/v1/things" && $0.header("X-Trace") == "walk" })
  }

  @Test("a walk by its declaration stops at its ceiling, and refuses a cursor it has already sent")
  func walkByDeclarationStops() async throws {
    let (capped, cappedHost) = try Self.client([
      Self.page(["a"], next: "c2"), Self.page(["b"], next: "c3"),
    ])
    var read: [Thing] = []
    for try await row: Thing in try capped.walk(Self.things, path: "/v1/things", maxPages: 1) {
      read.append(row)
    }
    #expect(read == [Thing(id: "a")])
    #expect(StubLoading.seen(cappedHost).map { $0.url?.query } == ["limit=50"])

    let (looping, _) = try Self.client([Self.page(["a"], next: "c2"), Self.page(["b"], next: "c2")])
    var looped: [Thing] = []
    let error = await #expect(throws: MountayaError.self) {
      for try await row: Thing in try looping.walk(Self.things, path: "/v1/things") {
        looped.append(row)
      }
    }
    #expect(looped == [Thing(id: "a"), Thing(id: "b")], "the rows before the refusal are read")
    #expect(error?.name == "ApiError")
  }

  @Test("a walk by its declaration refuses a page size or a ceiling out of range, asking nothing")
  func walkByDeclarationRefused() throws {
    let (client, host) = try Self.client([])
    for (pageSize, maxPages) in [(0, nil), (101, nil), (50, 0)] as [(Int, Int?)] {
      let error = #expect(throws: MountayaError.self) {
        let _: AsyncThrowingStream<Thing, any Error> = try client.walk(
          Self.things, path: "/v1/things", pageSize: pageSize, maxPages: maxPages)
      }
      #expect(error?.name == "ConfigurationError", "\(pageSize) \(String(describing: maxPages))")
    }
    #expect(StubLoading.seen(host).isEmpty)
  }

  @Test("a map's file of the Tile API leaves through the transport under the map's credential")
  func mapFile() async throws {
    let (client, host) = try Self.client([
      .answer(200, headers: ["Content-Type": "image/png"], chunks: ["PNG"])
    ])
    let origin = try StubLoading.url(host)
    var base = origin.absoluteString
    while base.hasSuffix("/") {
      base.removeLast()
    }
    let tile = try #require(URL(string: base + "/v1/elevation/16/34017/23335?k=a%20b"))
    let file = try await client.mapFile(at: tile, operationId: "getElevationTile")

    #expect(file.bytes == Data("PNG".utf8))
    #expect(file.contentType == "image/png")
    let sent = try #require(StubLoading.seen(host).first)
    #expect(sent.url?.path == "/v1/elevation/16/34017/23335")
    #expect(sent.url?.query == "k=a%20b")
    #expect(sent.header("X-API-Key") == "pk_test_a")
    #expect(client.publishableKey == "pk_test_a")
  }

  @Test("a map's file elsewhere than the Tile API is refused, and sent nothing")
  func mapFileElsewhere() async throws {
    let (client, host) = try Self.client([])

    await #expect(throws: MountayaError.self) {
      _ = try await client.mapFile(
        at: try #require(URL(string: "https://example.com/v1/elevation/1/2/3")),
        operationId: "getElevationTile")
    }
    #expect(StubLoading.seen(host).isEmpty)
  }

  @Test("a client holding a share token, or a seam of its own, holds no publishable key")
  func noPublishableKey() throws {
    #expect(try Mountaya(credential: .share(token: "share_0a")).publishableKey == nil)
    #expect(ScriptedSender().client.publishableKey == nil)
  }
}

/// The headers a map renderer's own requests carry, read off the client every request.
@Suite("Mountaya's map requests")
struct MountayaMapRequestTests {
  private static func url(_ text: String) throws -> URL {
    try #require(URL(string: text))
  }

  /// identification is the header naming the SDK, which every request to the Tile API carries
  /// beside its credential.
  private static let identification = (
    name: ClientIdentification.header, value: ClientIdentification.value
  )

  /// Source is a session source whose token a test moves, read synchronously as a map reads it.
  private final class Source: SessionTokenSource {
    let held = Locked(SessionSnapshot(token: "sess_a", userId: "u1"))

    var snapshot: SessionSnapshot { held.value }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      AsyncStream { $0.yield(held.value) }
    }
  }

  @Test("a request to the Tile API carries the key, the session token, the language and the SDK")
  func publishable() throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"), language: "fr")
    let headers = try client.mapRequestHeaders(
      for: try Self.url("https://tiles.mountaya.com/v1/zones/12/2093/1425"))

    #expect(
      headers
        == [
          "X-API-Key": "pk_test_a", "X-Session-Token": "sess_a", "Accept-Language": "fr",
          "X-Mountaya-Client": "mountaya-swift/\(ClientIdentification.version)",
        ])
    #expect(client.language == "fr")
  }

  @Test("a request to any other host is no request of the client's, and is sent nothing")
  func elsewhere() throws {
    let client = try Mountaya(credential: .publishable(key: "pk_test_a"), language: "fr")

    #expect(
      try client.mapRequestHeaders(for: try Self.url("https://fonts.example.com/a.pbf")) == nil)
    #expect(
      try client.mapRequestHeaders(for: try Self.url("https://tiles.mountaya.com.evil.net/v1"))
        == nil)
  }

  @Test("a base URL with no scheme names no place without a page, and is refused as it is built")
  func schemelessBaseUrl() throws {
    for text in ["/tiles", "tiles.example.test", "//tiles.example.test/v1", ""] {
      let relative = try #require(URL(string: text) ?? URL(string: "relative"))
      for urls in [
        BaseURLs(tiles: relative), BaseURLs(data: relative), BaseURLs(rest: relative),
      ] {
        #expect(throws: MountayaError.self, "\(text)") {
          try Mountaya(credential: .publishable(key: "pk_test_a"), baseUrls: urls)
        }
      }
    }
    _ = try Mountaya(
      credential: .publishable(key: "pk_test_a"),
      baseUrls: BaseURLs(tiles: try Self.url("http://localhost:8080/tiles")))
  }

  @Test("the Tile API's origin is the client's own, a base URL with a path included")
  func origin() throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a"),
      baseUrls: BaseURLs(tiles: try Self.url("https://proxy.example.com/tiles")))

    #expect(
      try client.mapRequestHeaders(for: try Self.url("https://proxy.example.com/tiles/v1/zones"))
        == [
          "X-API-Key": "pk_test_a", "Accept-Language": "*",
          Self.identification.name: Self.identification.value,
        ])
    #expect(
      try client.mapRequestHeaders(for: try Self.url("https://tiles.mountaya.com/v1/zones"))
        == nil)
  }

  @Test("a share token replaces the key, and its visitor's cookies ride where their source answers")
  func share() throws {
    let client = try Mountaya(
      credential: .share(token: "share_a", cookies: { _ in "session=visitor" }))
    let headers = try client.mapRequestHeaders(
      for: try Self.url("https://tiles.mountaya.com/v1/itineraries/it/1/2/3"))

    #expect(
      headers
        == [
          "X-Share-Token": "share_a", "Cookie": "session=visitor", "Accept-Language": "*",
          Self.identification.name: Self.identification.value,
        ])
  }

  @Test("each request reads the session token as it stands then, and never waits for one")
  func readEachRequest() throws {
    let source = Source()
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: .source(source)))
    let tile = try Self.url("https://tiles.mountaya.com/v1/zones/1/2/3")

    #expect(try client.mapRequestHeaders(for: tile)?["X-Session-Token"] == "sess_a")
    source.held.withLock { $0 = SessionSnapshot(token: "sess_b", userId: "u1") }
    #expect(try client.mapRequestHeaders(for: tile)?["X-Session-Token"] == "sess_b")
    source.held.withLock { $0 = SessionSnapshot(isMinting: true) }
    #expect(
      try client.mapRequestHeaders(for: tile)
        == [
          "X-API-Key": "pk_test_a", "Accept-Language": "*",
          Self.identification.name: Self.identification.value,
        ])
  }

  @Test("a session token a function answers is held to a token's rules at the request")
  func refusedToken() throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_a", sessionToken: .function { "sk_live_oops" }))

    #expect(throws: MountayaError.self) {
      try client.mapRequestHeaders(for: try Self.url("https://tiles.mountaya.com/v1/zones/1/2/3"))
    }
  }

  #if os(macOS) || os(Linux)
    @Test("a secret key authenticates no route a map fetches, and is refused")
    func secretKey() throws {
      let client = try Mountaya(credential: .secret(key: "sk_test_a"))

      #expect(throws: MountayaError.self) {
        try client.mapRequestHeaders(for: try Self.url("https://tiles.mountaya.com/v1/zones/1/2/3"))
      }
    }
  #endif

  @Test("a client built over a seam of its own sends a map nothing, and names no language")
  func seam() throws {
    let client = ScriptedSender().client

    #expect(try client.mapRequestHeaders(for: try Self.url("https://tiles.mountaya.com/v1")) == nil)
    #expect(client.language == nil)
  }
}

extension JSONValue {
  /// decoding reads a request body a stub saw.
  fileprivate static func decoding(_ body: Data?) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: try #require(body))
  }

  /// member reads the value at a path of keys, or nil where one is missing.
  fileprivate func member(_ keys: String...) -> JSONValue? {
    var value: JSONValue? = self
    for key in keys {
      guard case .object(let members)? = value else { return nil }
      value = members[key]
    }
    return value
  }
}
