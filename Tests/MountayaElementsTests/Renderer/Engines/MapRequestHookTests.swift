import Foundation
import MapLibre
import MountayaClient
import MountayaGeo
import RendererSupport
import Testing
import os

@testable import MountayaElements

extension MapLibreSuites {
  @Suite("MapRequestHook")
  @MainActor
  struct MapRequestHookTests {
    private static func client(
      _ credential: Credential, language: String? = "fr", tiles: URL? = StubTileAPI.tiles
    ) throws -> Mountaya {
      try Mountaya(
        credential: credential, language: language, baseUrls: BaseURLs(tiles: try #require(tiles)))
    }

    /// shown is a renderer showing a map of `client`, its app's hook `transform`, with no base map:
    /// the hook sends its requests for as long as it is held.
    private static func shown(
      _ client: Mountaya, transform: (@Sendable (MapRequest) -> MapRequest)? = nil
    ) -> MapRenderer {
      MapRenderer(
        engine: MapEngine(
          client: client, geolocation: InertGeolocation(), transformRequest: transform),
        onReady: nil)
    }

    private static func sent(_ text: String) throws -> NSMutableURLRequest {
      MapRequestHook.shared.willSend(NSMutableURLRequest(url: try #require(URL(string: text))))
    }

    /// answered is MapLibre's answer of `status` to the request to `url`, as its delegate hears it.
    private static func answered(_ url: URL?, status: Int) throws -> MLNNetworkResponse {
      let answer = MLNNetworkResponse()
      answer.response = HTTPURLResponse(
        url: try #require(url), statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
      return answer
    }

    /// unanswered is a request to `url` that reached no answer, failing with `code`, as MapLibre's
    /// delegate hears it.
    private static func unanswered(_ url: URL, code: Int = NSURLErrorNetworkConnectionLost)
      -> MLNNetworkResponse
    {
      let failed = MLNNetworkResponse()
      failed.error = NSError(
        domain: NSURLErrorDomain, code: code, userInfo: [NSURLErrorFailingURLErrorKey: url])
      return failed
    }

    /// told is every event `map` told, read once the hook's answers have landed and the map is
    /// closed.
    private static func told(_ map: MapEngine, events: AsyncStream<MapEvent>) async -> [MapEvent] {
      await settled()
      map.close()
      var told: [MapEvent] = []
      for await event in events {
        told.append(event)
      }
      return told
    }

    /// sessionMap is a map shown alone, with no base map, whose client's session token is what
    /// `token` holds as each request reads it, so every answer the hook hears is told to it.
    private static func sessionMap(_ token: OSAllocatedUnfairLock<String?>) throws -> (
      MapEngine, MapRenderer
    ) {
      let client = try Self.client(
        .publishable(key: "pk_test_a", sessionToken: .function { token.withLock { $0 } }))
      let map = MapEngine(client: client, geolocation: InertGeolocation())
      return (map, MapRenderer(engine: map, onReady: nil))
    }

    /// namesTheSdk is whether the `X-Mountaya-Client` a request carries names this SDK and a
    /// version, `mountaya-swift/<MAJOR.MINOR.PATCH>`, the version being the client's to hold.
    private static func namesTheSdk(_ value: String?) -> Bool {
      guard let value, value.hasPrefix("mountaya-swift/") else { return false }
      let version = value.dropFirst("mountaya-swift/".count)
        .split(separator: ".", omittingEmptySubsequences: false)
      return version.count == 3
        && version.allSatisfy { part in
          !part.isEmpty && part.allSatisfy { ("0"..."9").contains($0) }
        }
    }

    @Test("the hook is MapLibre's one request hook, kept alive by the process")
    func installed() throws {
      let map = Self.shown(try Self.client(.publishable(key: "pk_test_a")))

      #expect(MLNNetworkConfiguration.sharedManager.delegate === MapRequestHook.shared)
      withExtendedLifetime(map) {}
    }

    @Test(
      "a request to the Tile API carries the client's credential and language, read per request")
    func tileApi() throws {
      let token = OSAllocatedUnfairLock(initialState: "sess_a")
      let session = SessionToken.function { token.withLock { $0 } }
      let map = Self.shown(
        try Self.client(.publishable(key: "pk_test_a", sessionToken: session)))

      let first = try Self.sent("https://tiles.example.test/v1/zones/12/2093/1425")
      #expect(first.value(forHTTPHeaderField: "X-API-Key") == "pk_test_a")
      #expect(first.value(forHTTPHeaderField: "X-Session-Token") == "sess_a")
      #expect(first.value(forHTTPHeaderField: "Accept-Language") == "fr")
      #expect(Self.namesTheSdk(first.value(forHTTPHeaderField: "X-Mountaya-Client")))

      token.withLock { $0 = "sess_b" }
      #expect(
        try Self.sent("https://tiles.example.test/v1/glyphs/Inter/0-255")
          .value(forHTTPHeaderField: "X-Session-Token") == "sess_b")
      withExtendedLifetime(map) {}
    }

    @Test("a request to any other host a style names is sent nothing of the client's")
    func elsewhere() throws {
      let map = Self.shown(
        try Self.client(.publishable(key: "pk_test_a", sessionToken: "sess_a")))
      let sent = try Self.sent("https://elsewhere.example.test/1/2/3.png")

      #expect(sent.value(forHTTPHeaderField: "X-API-Key") == nil)
      #expect(sent.value(forHTTPHeaderField: "X-Session-Token") == nil)
      #expect(sent.value(forHTTPHeaderField: "Accept-Language") == nil)
      #expect(sent.value(forHTTPHeaderField: "X-Mountaya-Client") == nil)
      withExtendedLifetime(map) {}
    }

    @Test("a share token replaces the key, and a client of no language asks for none in particular")
    func share() throws {
      let map = Self.shown(try Self.client(.share(token: "share_a"), language: nil))
      let sent = try Self.sent("https://tiles.example.test/v1/itineraries/it/1/2/3")

      #expect(sent.value(forHTTPHeaderField: "X-Share-Token") == "share_a")
      #expect(sent.value(forHTTPHeaderField: "X-API-Key") == nil)
      #expect(sent.value(forHTTPHeaderField: "Accept-Language") == "*")
      #expect(Self.namesTheSdk(sent.value(forHTTPHeaderField: "X-Mountaya-Client")))
      withExtendedLifetime(map) {}
    }

    @Test("the app's own hook is called first, and a header it sets stands over the client's")
    func transform() throws {
      let map = Self.shown(
        try Self.client(.publishable(key: "pk_test_a")),
        transform: { request in
          var request = request
          request.headers["accept-language"] = "de"
          request.headers["X-App"] = "app"
          return request
        })
      let sent = try Self.sent("https://tiles.example.test/v1/zones/1/2/3")

      #expect(sent.value(forHTTPHeaderField: "Accept-Language") == "de")
      #expect(sent.value(forHTTPHeaderField: "X-App") == "app")
      #expect(sent.value(forHTTPHeaderField: "X-API-Key") == "pk_test_a")
      withExtendedLifetime(map) {}
    }

    @Test("a request whose session token the client refuses is handed back unable to load")
    func refused() throws {
      let map = Self.shown(
        try Self.client(.publishable(key: "pk_test_a", sessionToken: .function { "sk_live" })))
      let sent = try Self.sent("https://tiles.example.test/v1/zones/1/2/3")

      #expect(sent.url?.scheme == "mountaya-refused")
      #expect(sent.value(forHTTPHeaderField: "X-API-Key") == nil)
      withExtendedLifetime(map) {}
    }

    // MARK: - Two maps

    @Test("two maps on two Tile APIs each send their own credential, and nothing to any other host")
    func twoOrigins() throws {
      let alpine = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_alpine"), tiles: URL(string: "https://alpine.hook.test")))
      let coast = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_coast"), tiles: URL(string: "https://coast.hook.test")))

      #expect(
        try Self.sent("https://alpine.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == "pk_test_alpine",
        "a map shown before keeps its credential on its own Tile API")
      #expect(
        try Self.sent("https://coast.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == "pk_test_coast")
      #expect(
        try Self.sent("https://inland.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == nil)
      withExtendedLifetime((alpine, coast)) {}
    }

    @Test("two maps on one Tile API send the credential of the map shown last")
    func oneOrigin() throws {
      let tiles = URL(string: "https://shared.hook.test")
      let first = Self.shown(try Self.client(.publishable(key: "pk_test_first"), tiles: tiles))
      let last = Self.shown(try Self.client(.publishable(key: "pk_test_last"), tiles: tiles))

      #expect(
        try Self.sent("https://shared.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == "pk_test_last")
      withExtendedLifetime((first, last)) {}
    }

    @Test("the app's hook of the map shown last that names one is called, for every map's request")
    func transformOfTheLastToNameOne() throws {
      let hooked = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_hooked"), tiles: URL(string: "https://hooked.hook.test")),
        transform: { request in
          var request = request
          request.headers["X-App"] = "hooked"
          return request
        })
      let plain = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_plain"), tiles: URL(string: "https://plain.hook.test")))
      let sent = try Self.sent("https://plain.hook.test/v1/zones/1/2/3")

      #expect(sent.value(forHTTPHeaderField: "X-App") == "hooked")
      #expect(sent.value(forHTTPHeaderField: "X-API-Key") == "pk_test_plain")
      withExtendedLifetime((hooked, plain)) {}
    }

    @Test("a map whose view is gone sends nothing more, and the maps shown before it send theirs")
    func mapLetGo() throws {
      let tiles = URL(string: "https://gone.hook.test")
      let kept = Self.shown(try Self.client(.publishable(key: "pk_test_kept"), tiles: tiles))
      do {
        let gone = Self.shown(try Self.client(.publishable(key: "pk_test_gone"), tiles: tiles))
        #expect(
          try Self.sent("https://gone.hook.test/v1/zones/1/2/3")
            .value(forHTTPHeaderField: "X-API-Key") == "pk_test_gone")
        withExtendedLifetime(gone) {}
      }

      #expect(
        try Self.sent("https://gone.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == "pk_test_kept")
      withExtendedLifetime(kept) {}
      _ = consume kept
      #expect(
        try Self.sent("https://gone.hook.test/v1/zones/1/2/3")
          .value(forHTTPHeaderField: "X-API-Key") == nil,
        "with no map shown, nothing is sent")
    }

    @Test("an answer is told to every map claiming its address, else to the one map shown alone")
    func claimants() {
      let claims = [
        [
          "https://tiles.example.test/v1/zones/", "https://tiles.example.test/v1/terrains/a/light/",
        ],
        ["https://tiles.example.test/v1/zones/"],
        ["https://elsewhere.example.test/"],
      ]

      #expect(
        MapRequestHook.claimants(of: "https://tiles.example.test/v1/zones/1/2/3", claims: claims)
          == [0, 1])
      #expect(
        MapRequestHook.claimants(
          of: "https://tiles.example.test/v1/terrains/a/light/sprite.png", claims: claims) == [0])
      #expect(
        MapRequestHook.claimants(of: "https://fonts.example.test/x.pbf", claims: claims).isEmpty,
        "an answer no map claims is told to none of several")
      #expect(
        MapRequestHook.claimants(of: "https://fonts.example.test/x.pbf", claims: [claims[2]])
          == [0], "and to the one map shown, where it is alone")
      #expect(MapRequestHook.claimants(of: "https://x.test/", claims: [[""]]) == [0])
      #expect(MapRequestHook.claimants(of: "https://x.test/", claims: [[""], [""]]).isEmpty)
      #expect(MapRequestHook.claimants(of: "https://x.test/", claims: []).isEmpty)
    }

    // MARK: - A credential the client no longer sends

    /// A map shown while the first session token is on its way asks for its tiles under the key
    /// alone, and an organization that requires a session refuses them once the token has landed.
    @Test("a 401 or a 403 of a request that left under a credential no longer sent is told nobody")
    func supersededRefusal() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: nil)
      let (map, renderer) = try Self.sessionMap(token)
      let events = map.events()
      let hook = MapRequestHook.shared

      let early = try #require(try Self.sent("https://tiles.example.test/v1/zones/1/1/2").url)
      token.withLock { $0 = "sess_a" }
      _ = hook.didReceive(try Self.answered(early, status: 401))
      await settled()
      #expect(!map.state.isAccessRequired, "a refusal of the key alone, which the map gave up")

      let refused = try #require(try Self.sent("https://tiles.example.test/v1/zones/1/0/0").url)
      _ = hook.didReceive(try Self.answered(refused, status: 401))
      // A 402 refuses the organization, and a missing tile is a failure, whatever credential asked.
      let unpaid = try #require(try Self.sent("https://tiles.example.test/v1/zones/1/0/1").url)
      let missing = try #require(try Self.sent("https://tiles.example.test/v1/zones/1/1/0").url)
      token.withLock { $0 = "sess_b" }
      _ = hook.didReceive(try Self.answered(unpaid, status: 402))
      _ = hook.didReceive(try Self.answered(missing, status: 404))
      // A token the client refuses now sends nothing: the one a request left with is given up.
      let forbidden = try #require(try Self.sent("https://tiles.example.test/v1/zones/1/1/1").url)
      token.withLock { $0 = "sk_live" }
      _ = hook.didReceive(try Self.answered(forbidden, status: 403))
      token.withLock { $0 = "sess_b" }
      // A request that reached no answer is a failure, and what it left with is forgotten, so a
      // later answer at its address is told as it is.
      let dropped = try #require(try Self.sent("https://tiles.example.test/v1/zones/2/0/0").url)
      _ = hook.didReceive(Self.unanswered(dropped))
      token.withLock { $0 = "sess_c" }
      _ = hook.didReceive(try Self.answered(dropped, status: 401))

      #expect(
        await Self.told(map, events: events) == [
          .accessRefused(status: 401, url: refused.absoluteString),
          .accessRefused(status: 402, url: unpaid.absoluteString),
          .failure(url: missing.absoluteString, status: 404),
          .failure(url: dropped.absoluteString, status: nil),
          .accessRefused(status: 401, url: dropped.absoluteString),
        ])
      withExtendedLifetime(renderer) {}
    }

    /// followed is the request a redirect from `previous` to `target` leads to, as the hook sends
    /// it.
    private static func followed(_ previous: URLRequest, to target: String) -> URLRequest {
      var carried = previous
      carried.url = URL(string: target)
      return MapRequestHook.shared.redirected(carried, from: previous)
    }

    @Test("a refusal after a redirect is told at the address asked, its credential read at the hop")
    func supersededAcrossRedirect() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: "sess_a")
      let (map, renderer) = try Self.sessionMap(token)
      let events = map.events()
      let hook = MapRequestHook.shared

      // A redirect within the Tile API leaves under the token read again for it, the one the
      // client sends, and its refusal is told at the address MapLibre asked for.
      let within = try Self.sent("https://tiles.example.test/v1/zones/1/2/3") as URLRequest
      token.withLock { $0 = "sess_b" }
      let landed = Self.followed(within, to: "https://tiles.example.test/v1/zones/1/2/3/moved")
      _ = hook.didReceive(try Self.answered(landed.url, status: 401))
      // So is one after a redirect to another host, which carries no credential, and after two.
      let away = try Self.sent("https://tiles.example.test/v1/zones/7/8/9") as URLRequest
      let elsewhere = Self.followed(away, to: "https://elsewhere.example.test/zones/7/8/9")
      _ = hook.didReceive(try Self.answered(elsewhere.url, status: 403))
      let twice = try Self.sent("https://tiles.example.test/v1/zones/2/2/2") as URLRequest
      let first = Self.followed(twice, to: "https://tiles.example.test/v1/hop/2/2/2")
      let second = Self.followed(first, to: "https://tiles.example.test/v1/zones/2/2/2/moved")
      _ = hook.didReceive(try Self.answered(second.url, status: 401))
      // A redirect whose token is replaced before its answer was refused under one the client no
      // longer sends, which the hook reads at the address the redirect went to.
      let next = try Self.sent("https://tiles.example.test/v1/zones/4/5/6") as URLRequest
      let moved = Self.followed(next, to: "https://tiles.example.test/v1/zones/4/5/6/moved")
      token.withLock { $0 = "sess_c" }
      _ = hook.didReceive(try Self.answered(moved.url, status: 401))

      #expect(
        await Self.told(map, events: events) == [
          .accessRefused(status: 401, url: "https://tiles.example.test/v1/zones/1/2/3"),
          .accessRefused(status: 403, url: "https://tiles.example.test/v1/zones/7/8/9"),
          .accessRefused(status: 401, url: "https://tiles.example.test/v1/zones/2/2/2"),
        ])
      withExtendedLifetime(renderer) {}
    }

    // MARK: - A burst

    /// zonesMap is a map shown alone, with no base map, drawing the source `zones` of the stub Tile
    /// API, its renderer reporting to `probe` once it draws the source.
    private static func zonesMap(_ probe: RenderProbe) async throws -> (MapEngine, MapRenderer) {
      let (map, renderer) = try Self.sessionMap(OSAllocatedUnfairLock(initialState: "sess_a"))
      renderer.probe = probe
      map.addSource(
        MapSource(
          id: "zones",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/zones/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      try #require(
        await MapWindow.until { renderer.drawn?.sources.contains { $0.id == "zones" } == true })
      return (map, renderer)
    }

    /// burstRounds is how many rounds a burst holds: a refused tile, a tile parsed, and a tile
    /// missing, each round.
    private static let burstRounds = 60

    /// burst is what a burst tells `map`, as MapLibre's threads tell it: each round, a tile of
    /// `zones` refused a 402, a tile of `zones` parsed, and a tile of `zones` answered a 404.
    private static func burst(_ round: Int) throws -> (refused: URL, missing: URL) {
      (
        try #require(try Self.sent("https://tiles.example.test/v1/zones/9/\(round)/0").url),
        try #require(try Self.sent("https://tiles.example.test/v1/zones/9/\(round)/1").url)
      )
    }

    /// burstTold is what a burst of `rounds` rounds is told, in order: each refusal, the end of it
    /// as the tile parses, and each missing tile.
    private static func burstTold(_ rounds: [(refused: URL, missing: URL)]) -> [MapEvent] {
      rounds.flatMap { round in
        [
          MapEvent.accessRefused(status: 402, url: round.refused.absoluteString),
          .accessRestored,
          .failure(url: round.missing.absoluteString, status: 404),
        ]
      }
    }

    @Test("a burst heard is handed on in one hop, in the order heard, every map's claims read once")
    func burst() async throws {
      let probe = RenderProbe()
      let hook = MapRequestHook.shared
      hook.probe = probe
      defer { hook.probe = nil }
      let (map, renderer) = try await Self.zonesMap(probe)
      let events = map.events()
      let rounds = try (0..<Self.burstRounds).map(Self.burst)
      let claims = probe["claims"]
      let hops = probe["hop"]

      // Heard as MapLibre's threads tell it, between two hops.
      for round in rounds {
        _ = hook.didReceive(try Self.answered(round.refused, status: 402))
        hook.tileParsed(source: "zones", by: renderer)
        _ = hook.didReceive(try Self.answered(round.missing, status: 404))
      }

      #expect(await Self.told(map, events: events) == Self.burstTold(rounds))
      // One hop handed on the 180 things heard, the process's other maps aside, which may hear
      // something of their own meanwhile, and the map's claims, read for the source drawn, were
      // read again for none of its 120 failures.
      #expect((1...2).contains(probe["hop"] - hops), "\(probe.counts)")
      #expect(probe["claims"] - claims <= 1, "\(probe.counts)")
      withExtendedLifetime(renderer) {}
    }

    @Test(
      "a map reads its claims once for what it draws, and again once a state drawn changes them")
    func claimsRead() async throws {
      let probe = RenderProbe()
      let (map, renderer) = try await Self.zonesMap(probe)
      let events = map.events()
      let hook = MapRequestHook.shared
      let claims = probe["claims"]

      // Three failures, each in a hop of its own.
      var missing: [URL] = []
      for round in 0..<3 {
        let url = try #require(
          try Self.sent("https://tiles.example.test/v1/zones/8/\(round)/0").url)
        missing.append(url)
        _ = hook.didReceive(try Self.answered(url, status: 404))
        await settled()
      }
      #expect(probe["claims"] - claims == 1, "\(probe.counts)")

      // A source drawn changes what the map claims: they are read once more, for the next failure.
      map.addSource(
        MapSource(
          id: "trails",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/trails/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      try #require(
        await MapWindow.until { renderer.drawn?.sources.contains { $0.id == "trails" } == true })
      let trail = try #require(try Self.sent("https://tiles.example.test/v1/trails/8/0/0").url)
      _ = hook.didReceive(try Self.answered(trail, status: 404))

      #expect(
        await Self.told(map, events: events)
          == (missing + [trail]).map { .failure(url: $0.absoluteString, status: 404) })
      #expect(probe["claims"] - claims == 2, "\(probe.counts)")
      withExtendedLifetime(renderer) {}
    }

    @Test("a burst heard on MapLibre's threads is handed on in the order heard, in few hops")
    func burstOffMain() async throws {
      let probe = RenderProbe()
      let hook = MapRequestHook.shared
      hook.probe = probe
      defer { hook.probe = nil }
      let (map, renderer) = try await Self.zonesMap(probe)
      let told = MapLibreSuites.MapRendererTests.Told(map)
      let rounds = try (0..<Self.burstRounds).map(Self.burst)
      let hops = probe["hop"]

      // Heard on a thread of its own, as MapLibre tells its delegate.
      await Task.detached {
        for round in rounds {
          let refused = MLNNetworkResponse()
          refused.response = HTTPURLResponse(
            url: round.refused, statusCode: 402, httpVersion: "HTTP/1.1", headerFields: nil)
          _ = hook.didReceive(refused)
          hook.tileParsed(source: "zones", by: renderer)
          let missing = MLNNetworkResponse()
          missing.response = HTTPURLResponse(
            url: round.missing, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)
          _ = hook.didReceive(missing)
        }
      }.value

      let expected = Self.burstTold(rounds)
      #expect(await MapWindow.until { told.events.count >= expected.count }, "\(told.events)")
      #expect(told.events == expected)
      #expect(probe["hop"] - hops >= 1)
      #expect(probe["hop"] - hops < 3 * Self.burstRounds, "\(probe.counts)")
      withExtendedLifetime(renderer) {}
    }

    /// MapLibre may never answer a request it withdrew, so the hook keeps what requests left with
    /// for at most `keptLimit` addresses: forgetting them all at once would forget the requests
    /// still on their way too, whose stale refusals would then be told.
    @Test("past the addresses the hook keeps, the oldest is forgotten first, and told as it is")
    func keptLimit() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: "sess_a")
      let (map, renderer) = try Self.sessionMap(token)
      let events = map.events()
      let hook = MapRequestHook.shared

      let first = try #require(try Self.sent("https://tiles.example.test/v1/kept/0").url)
      let second = try #require(try Self.sent("https://tiles.example.test/v1/kept/1").url)
      var last = second
      for index in 2...MapRequestHook.keptLimit {
        last = try #require(try Self.sent("https://tiles.example.test/v1/kept/\(index)").url)
      }
      token.withLock { $0 = "sess_b" }
      _ = hook.didReceive(try Self.answered(first, status: 401))
      _ = hook.didReceive(try Self.answered(second, status: 401))
      _ = hook.didReceive(try Self.answered(last, status: 401))

      #expect(
        await Self.told(map, events: events) == [
          .accessRefused(status: 401, url: first.absoluteString)
        ],
        "the oldest address alone is forgotten, and told as it is; the next, kept, was superseded")
      withExtendedLifetime(renderer) {}
    }

    @Test("what the hook keeps by address goes oldest first, an address kept again the newest")
    func keptOldestFirst() {
      var kept = MapRequestHook.KeptAddresses<Int>(limit: 3)
      kept.keep(0, at: "a")
      kept.keep(1, at: "b")
      kept.keep(2, at: "c")
      kept.keep(3, at: "a")
      kept.keep(4, at: "d")

      #expect(kept.count == 3)
      #expect(kept.take("b") == nil, "the oldest, `a` kept again since")
      #expect(kept.take("a") == 3)
      #expect(kept.take("a") == nil, "taken once")
      kept.keep(5, at: "e")
      #expect(kept.take("c") == 2)
      // A long run of keeps and takes holds the limit and the order.
      for index in 0..<10_000 {
        kept.keep(index, at: "x\(index)")
        if index.isMultiple(of: 2) {
          _ = kept.take("x\(index)")
        }
      }
      #expect(kept.count == 3)
      #expect([kept.take("x9995"), kept.take("x9997"), kept.take("x9999")] == [9995, 9997, 9999])
    }

    /// MapLibre tells a style failed apart from its answer, and its renderer finds how the hook
    /// told that answer at the style's address: a storm of refused tiles between the two, a 402 on
    /// every tile of an organization's lapsed plan, must not push it out.
    @Test("a style's failed answer is kept for its renderer whatever its tiles meanwhile")
    func styleAnswerOutlastsTiles() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: "sess_a")
      let (map, renderer) = try Self.sessionMap(token)
      let hook = MapRequestHook.shared
      let style = try #require(
        URL(string: "https://tiles.example.test/v1/terrains/kept/\(UUID().uuidString)/style"))
      // As the renderer asks MapLibre for a style, here one MapLibre is never handed.
      hook.askedStyle(style, by: renderer)

      _ = try Self.sent(style.absoluteString)
      token.withLock { $0 = "sess_b" }
      _ = hook.didReceive(try Self.answered(style, status: 401))
      for index in 0..<(2 * MapRequestHook.keptLimit) {
        let tile = try #require(
          try Self.sent("https://tiles.example.test/v1/refused/storm/\(index)").url)
        _ = hook.didReceive(try Self.answered(tile, status: 402))
      }

      #expect(hook.styleAnswer(at: style) == .dropped, "found at the style's own address")
      #expect(hook.styleAnswer(at: style) == nil, "and found once")
      let tile = try #require(URL(string: "https://tiles.example.test/v1/refused/storm/0"))
      #expect(hook.styleAnswer(at: tile) == nil, "a tile's answer is kept for nobody")
      // Asked for again, a style's answer is forgotten.
      _ = try Self.sent(style.absoluteString)
      _ = hook.didReceive(try Self.answered(style, status: 500))
      _ = try Self.sent(style.absoluteString)
      #expect(hook.styleAnswer(at: style) == nil)
      map.close()
      withExtendedLifetime(renderer) {}
    }

    /// MapLibre tells its delegate a request that reached no answer, an offline tile among them,
    /// with the address its last hop failed at.
    @Test("a request that reached no answer is told as a failure at the address MapLibre asked for")
    func unanswered() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: "sess_a")
      let (map, renderer) = try Self.sessionMap(token)
      let events = map.events()
      let hook = MapRequestHook.shared

      let offline = try #require(try Self.sent("https://tiles.example.test/v1/zones/3/1/1").url)
      _ = hook.didReceive(Self.unanswered(offline, code: NSURLErrorNotConnectedToInternet))
      // A redirect moves the address it fails at, and the map asked for the first.
      let away = try Self.sent("https://tiles.example.test/v1/zones/3/2/2") as URLRequest
      let moved = Self.followed(away, to: "https://elsewhere.example.test/zones/3/2/2")
      _ = hook.didReceive(Self.unanswered(try #require(moved.url)))
      // One MapLibre withdrew, a tile it no longer needs, is no failure.
      let withdrawn = try #require(try Self.sent("https://tiles.example.test/v1/zones/3/3/3").url)
      _ = hook.didReceive(Self.unanswered(withdrawn, code: NSURLErrorCancelled))
      // One whose session token the client refuses never leaves, and fails as it is handed back.
      token.withLock { $0 = "sk_live" }
      let refused = try #require(try Self.sent("https://tiles.example.test/v1/zones/3/4/4").url)
      token.withLock { $0 = "sess_a" }
      #expect(refused.scheme == "mountaya-refused")
      _ = hook.didReceive(Self.unanswered(refused, code: NSURLErrorUnsupportedURL))
      // One whose failure names no address is told nowhere, as no map could claim it.
      let nameless = MLNNetworkResponse()
      nameless.error = URLError(.timedOut)
      _ = hook.didReceive(nameless)

      #expect(
        await Self.told(map, events: events) == [
          .failure(url: "https://tiles.example.test/v1/zones/3/1/1", status: nil),
          .failure(url: "https://tiles.example.test/v1/zones/3/2/2", status: nil),
          .failure(url: "https://tiles.example.test/v1/zones/3/4/4", status: nil),
        ])
      withExtendedLifetime(renderer) {}
    }

    /// A request whose session token the client refuses at the read never leaves, and the failure
    /// MapLibre reports for it carries what the read threw, as `sdk-dart`'s and `sdk-kotlin`'s do.
    @Test("a request the client refused fails carrying what the read of its credential threw")
    func refusedCause() async throws {
      let token = OSAllocatedUnfairLock<String?>(initialState: "sk_live")
      let (map, renderer) = try Self.sessionMap(token)
      let events = map.events()
      let hook = MapRequestHook.shared

      let refused = try #require(try Self.sent("https://tiles.example.test/v1/zones/6/1/1").url)
      #expect(refused.scheme == "mountaya-refused")
      _ = hook.didReceive(Self.unanswered(refused, code: NSURLErrorUnsupportedURL))
      token.withLock { $0 = "sess_a" }
      let offline = try #require(try Self.sent("https://tiles.example.test/v1/zones/6/2/2").url)
      _ = hook.didReceive(Self.unanswered(offline, code: NSURLErrorNotConnectedToInternet))

      let told = await Self.told(map, events: events)
      #expect(
        told == [
          .failure(url: "https://tiles.example.test/v1/zones/6/1/1", status: nil),
          .failure(url: "https://tiles.example.test/v1/zones/6/2/2", status: nil),
        ])
      let causes = told.map { event -> (any Error)? in
        guard case .failure(_, _, let cause) = event else { return nil }
        return cause
      }
      let thrown = causes.first.flatMap { $0 } as? MountayaError
      #expect(thrown?.name == "ConfigurationError", "\(String(describing: causes.first))")
      #expect(causes.last.flatMap { $0 } == nil, "a request that left carries no cause")
      withExtendedLifetime(renderer) {}
    }

    @Test("a map claims its own sources' tile templates and its style's directory")
    func claims() throws {
      let map = MapEngine(
        client: try Self.client(.publishable(key: "pk_test_a")),
        style: URL(string: "https://tiles.example.test/v1/terrains/outdoor/light/style?lang=fr/x"),
        geolocation: InertGeolocation())
      map.addSource(
        MapSource(
          id: "zones",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/zones/{z}/{x}/{y}?key={key}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      map.addSource(
        MapSource(id: "drawn", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
      let renderer = MapRenderer(engine: map, onReady: nil)

      #expect(
        renderer.claims == [
          "https://tiles.example.test/v1/zones/",
          "https://tiles.example.test/v1/terrains/outdoor/light/",
        ])
      #expect(
        MapRenderer.directory(of: try #require(URL(string: "https://tiles.example.test"))) == nil)
      #expect(
        MapRenderer.directory(of: try #require(URL(string: "https://tiles.example.test/style")))
          == "https://tiles.example.test/")
    }

    // MARK: - Redirects

    @Test("MapLibre's requests leave on the hook's one session, which hears their redirects")
    func session() throws {
      _ = StubTileAPI.installed
      let map = Self.shown(try Self.client(.publishable(key: "pk_test_a")))
      let delegate: any MLNNetworkConfigurationDelegate = MapRequestHook.shared
      let configuration = MLNNetworkConfiguration.sharedManager

      let first = try #require(delegate.session?(for: configuration))
      #expect(delegate.session?(for: configuration) === first, "one session, asked again")
      #expect(first.delegate === MapRequestHook.shared)
      #expect(!(first.delegate is any URLSessionDataDelegate), "which MapLibre would refuse")
      #expect(
        first.configuration.protocolClasses?.contains {
          ObjectIdentifier($0) == ObjectIdentifier(StubTileAPI.self)
        } == true, "made from the configuration MapLibre holds")

      // A configuration replaced is a session made again, the one before left to finish.
      let held = try #require(configuration.sessionConfiguration)
      let replaced = URLSessionConfiguration.ephemeral
      replaced.protocolClasses = held.protocolClasses
      configuration.sessionConfiguration = replaced
      let again = try #require(delegate.session?(for: configuration))
      configuration.sessionConfiguration = held
      #expect(again !== first)
      #expect(delegate.session?(for: configuration) !== again)
      withExtendedLifetime(map) {}
    }

    @Test("a redirect to another host carries nothing of the client's, nor of the app's hook")
    func redirectElsewhere() throws {
      let map = Self.shown(
        try Self.client(.publishable(key: "pk_test_a", sessionToken: "sess_a")),
        transform: { request in
          var request = request
          request.headers["X-App"] = "app"
          request.headers["User-Agent"] = "app-agent"
          return request
        })
      let original = NSMutableURLRequest(
        url: try #require(URL(string: "https://tiles.example.test/v1/zones/1/2/3")))
      original.setValue("MapLibre", forHTTPHeaderField: "User-Agent")
      original.setValue("\"etag\"", forHTTPHeaderField: "If-None-Match")
      let signed = MapRequestHook.shared.willSend(original) as URLRequest
      #expect(signed.value(forHTTPHeaderField: "X-API-Key") == "pk_test_a")

      // The loading system follows a redirect with every header the request carried.
      var carried = signed
      carried.url = URL(string: "https://elsewhere.example.test/v1/zones/1/2/3")
      let redirect = MapRequestHook.shared.redirected(carried, from: signed)

      #expect(redirect.url?.host == "elsewhere.example.test")
      for name in ["X-API-Key", "X-Session-Token", "Accept-Language", "X-Mountaya-Client"] {
        #expect(redirect.value(forHTTPHeaderField: name) == nil, "\(name) left behind")
      }
      #expect(redirect.value(forHTTPHeaderField: "X-App") == "app", "the app's hook, applied again")
      #expect(redirect.value(forHTTPHeaderField: "User-Agent") == "app-agent")
      #expect(redirect.value(forHTTPHeaderField: "If-None-Match") == "\"etag\"", "MapLibre's own")
      withExtendedLifetime(map) {}
    }

    @Test("a redirect within the Tile API carries the credential, read again for it")
    func redirectWithin() throws {
      let token = OSAllocatedUnfairLock(initialState: "sess_a")
      let map = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_a", sessionToken: .function { token.withLock { $0 } })))
      let signed =
        MapRequestHook.shared.willSend(
          NSMutableURLRequest(
            url: try #require(URL(string: "https://tiles.example.test/v1/zones/1/2/3"))))
        as URLRequest

      token.withLock { $0 = "sess_b" }
      var carried = signed
      carried.url = URL(string: "https://tiles.example.test/v1/zones/1/2/3/moved")
      let redirect = MapRequestHook.shared.redirected(carried, from: signed)

      #expect(redirect.value(forHTTPHeaderField: "X-API-Key") == "pk_test_a")
      #expect(redirect.value(forHTTPHeaderField: "X-Session-Token") == "sess_b")
      #expect(redirect.value(forHTTPHeaderField: "Accept-Language") == "fr")
      withExtendedLifetime(map) {}
    }

    @Test("a redirect whose session token the client refuses is followed nowhere")
    func redirectRefused() throws {
      let token = OSAllocatedUnfairLock(initialState: "sess_a")
      let map = Self.shown(
        try Self.client(
          .publishable(key: "pk_test_a", sessionToken: .function { token.withLock { $0 } })))
      let signed =
        MapRequestHook.shared.willSend(
          NSMutableURLRequest(
            url: try #require(URL(string: "https://tiles.example.test/v1/zones/1/2/3"))))
        as URLRequest

      token.withLock { $0 = "sk_live" }
      var carried = signed
      carried.url = URL(string: "https://tiles.example.test/v1/zones/4/5/6")
      let redirect = MapRequestHook.shared.redirected(carried, from: signed)

      #expect(redirect.url?.scheme == "mountaya-refused")
      #expect(redirect.value(forHTTPHeaderField: "X-API-Key") == nil)
      withExtendedLifetime(map) {}
    }

    @Test("the map's own requests pass through the hook: its style is fetched with the credential")
    func throughMapLibre() async throws {
      _ = StubTileAPI.installed
      let client = try Self.client(.publishable(key: "pk_test_map", sessionToken: "sess_map"))
      let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
      let renderer = MapRenderer(engine: map, onReady: nil)
      let window = MapWindow.showing(renderer.mapView)

      #expect(
        await MapWindow.until {
          StubTileAPI.requests(to: "tiles.example.test").contains {
            $0.value(forHTTPHeaderField: "X-API-Key") == "pk_test_map"
          }
        })
      let style = StubTileAPI.requests(to: "tiles.example.test").first {
        ($0.url?.path.hasSuffix("/style") ?? false)
          && $0.value(forHTTPHeaderField: "X-API-Key") == "pk_test_map"
      }
      #expect(style?.value(forHTTPHeaderField: "X-Session-Token") == "sess_map")
      #expect(style?.value(forHTTPHeaderField: "Accept-Language") == "fr")
      #expect(Self.namesTheSdk(style?.value(forHTTPHeaderField: "X-Mountaya-Client")))
      // Once the map draws, a tile of the Tile API carries the credential, and a tile of another
      // host the style names carries nothing of it.
      #expect(
        await MapWindow.until {
          StubTileAPI.requests(to: "tiles.example.test").contains {
            !($0.url?.path.hasSuffix("/style") ?? true)
              && $0.value(forHTTPHeaderField: "X-API-Key") == "pk_test_map"
              && $0.value(forHTTPHeaderField: "X-Session-Token") == "sess_map"
          }
        }, "\(StubTileAPI.requests.compactMap(\.url))")
      #expect(
        await MapWindow.until { !StubTileAPI.requests(to: "elsewhere.example.test").isEmpty },
        "\(StubTileAPI.requests.compactMap(\.url))")
      #expect(
        StubTileAPI.requests(to: "elsewhere.example.test").allSatisfy {
          $0.value(forHTTPHeaderField: "X-API-Key") == nil
            && $0.value(forHTTPHeaderField: "X-Session-Token") == nil
            && $0.value(forHTTPHeaderField: "X-Mountaya-Client") == nil
        })
      window.isHidden = true
    }

    /// The stub answers a tile under `/moved/` with a redirect to another host, carrying every
    /// header of the request as the loading system carries them: what reaches that host is what
    /// the hook's session left on the request.
    @Test("a tile MapLibre is redirected for to another host reaches it with no credential")
    func redirectThroughMapLibre() async throws {
      _ = StubTileAPI.installed
      let client = try Self.client(.publishable(key: "pk_test_moved", sessionToken: "sess_moved"))
      let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
      let renderer = MapRenderer(engine: map, onReady: nil)
      let window = MapWindow.showing(renderer.mapView)
      map.addSource(
        MapSource(
          id: "moved",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/moved/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      map.addLayer(
        MapLayer(
          id: "moved-lines", type: .line, source: "moved", sourceLayer: "lines",
          rank: LayerRank.overlay.rank))

      #expect(
        await MapWindow.until {
          StubTileAPI.requests(to: "elsewhere.example.test").contains {
            $0.url?.path.hasPrefix("/v1/moved/") ?? false
          }
        }, "\(StubTileAPI.requests.compactMap(\.url))")
      let asked = StubTileAPI.requests(to: "tiles.example.test").filter {
        $0.url?.path.hasPrefix("/v1/moved/") ?? false
      }
      #expect(asked.allSatisfy { $0.value(forHTTPHeaderField: "X-API-Key") == "pk_test_moved" })
      let moved = StubTileAPI.requests(to: "elsewhere.example.test").filter {
        $0.url?.path.hasPrefix("/v1/moved/") ?? false
      }
      #expect(
        moved.allSatisfy {
          $0.value(forHTTPHeaderField: "X-API-Key") == nil
            && $0.value(forHTTPHeaderField: "X-Session-Token") == nil
            && $0.value(forHTTPHeaderField: "X-Mountaya-Client") == nil
            && $0.value(forHTTPHeaderField: "Accept-Language") == nil
        }, "\(moved.map { $0.allHTTPHeaderFields ?? [:] })")
      window.isHidden = true
    }
  }
}
