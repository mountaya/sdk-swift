// swift-format-ignore-file
// Printed from README.md by BoundaryTests. Never edit it: edit the document, then run
//   MOUNTAYA_README=write swift test --disable-xctest --filter ConsumerPackageTests
// and the diff is the review.
//
// 35 snippets compiled, 18 skipped.
// Skipped: a manifest, which Tests/Consumer/Package.swift declares the same way.
// Skipped: a manifest fragment, which Tests/Consumer/Package.swift declares the same way.
// Skipped: it needs an iOS build, whose voice speaks, which Tests/Consumer/Sources/Consumer/Navigation.swift compiles it in.
// Skipped: a manifest fragment, which Tests/MountayaElementsTests/Renderer/Package.swift declares the same way.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Search.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.
// Skipped: it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in.

import MountayaClient
import Foundation
import MountayaAdmin
import MountayaGeo
import MountayaElements

/// ReadmeSnippets is every Swift snippet of README.md, each in a function of its own, written
/// as a consumer pastes it.
enum ReadmeSnippets {
  static func snippet1() async throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"),
      language: "fr"
    )
    let itinerary = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
    print(itinerary.data.name, itinerary.status, itinerary.requestId ?? "")
  }

  static func snippet2() async throws {
    // The contract tag this build speaks, and the digest of the files it was printed from.
    print(schemaVersion, modelDigest)

    // A client pointed at another environment, its Map Studio API at a staging origin.
    if let origin = URL(string: "https://api.staging.example.com") {
      let staging = try Mountaya(
        credential: .publishable(key: "pk_test_0a1b"), baseUrls: BaseURLs(rest: origin))
      print(staging.baseUrls)
    }
  }

  static func snippet3() async throws {
    // In an app: a publishable key, and a session token your own backend mints with its secret key.
    let engine = SessionTokenEngine {
      try await fetchSessionFromYourBackend()
    }
    let app = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: .source(engine)))

    // For a visitor holding a share link: the share token replaces the key.
    let visitor = try Mountaya(credential: .share(token: "share_6a7b"))

    // From parts held apart, a key from your configuration and a token from a link.
    let linked = try Mountaya(
      credential: Credential(publishableKey: "pk_live_0a1b", shareToken: "share_6a7b"))

    print(app, visitor, linked)
  }

  static func snippet4() async throws {
    // On a server: a session token for the user your backend has signed in, for the app to use.
    #if os(macOS) || os(Linux)
      func mintSession(forUser user: String) async throws -> RestSchema.Session {
        let server = try Mountaya(credential: .secret(key: "sk_live_0a1b"))
        let minted = try await server.admin.sessions.postSession(
          body: .init(publishable_key: "pk_live_0a1b") { $0.user_id = user })
        return minted.data
      }
    #endif
  }

  static func snippet5() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))
    let zone = try await client.studio.zones.getZone(zone_id: "zon_8c9d")

    let renamed = try await client.studio.zones.patchZone(
      zone_id: "zon_8c9d",
      body: .init { $0.name = "Vallée Blanche" },
      idempotencyKey: "rename-zon_8c9d-1",
      ifMatch: zone.data.etag,
      options: RequestOptions(timeout: .seconds(10))
    )
    print(renamed.status, renamed.data.name, renamed.etag ?? "")
  }

  static func snippet6() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b"))
    do {
      _ = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
    } catch let error as MountayaError {
      switch error {
      case .api(let apiError) where apiError.kind == .notFound:
        print("gone", apiError.requestId ?? "")
      case .api(let apiError):
        print(apiError.kind.name, apiError.code?.rawValue ?? "", apiError.retryAfter ?? .zero)
      case .connection(let connection):
        print(connection.message, "after every retry it was owed")
      case .configuration(let configuration):
        print(configuration.message)
      case .selection(let selection):
        print(selection.path)
      case .webhookSignature(let refusal):
        print(refusal.reason)
      @unknown default:
        print(error)
      }
    }
  }

  static func snippet7() async throws {
    // The contract's schedule with a longer budget of waits for this client, and no retry for one call.
    let client = try Mountaya(
      credential: .publishable(key: "pk_live_0a1b"),
      retry: try RetryPolicy(waitBudget: .seconds(120))
    )
    do {
      _ = try await client.studio.activities.getActivities(
        options: RequestOptions(retry: try RetryPolicy(maxRetries: 0), timeout: .seconds(10)))
    } catch {
      // Whether an error is one of the family, and whether the API answered it.
      print(isMountayaError(error), isAPIError(error))
    }

    // A call you withdraw throws `CancellationError`, never an error of the ladder.
    let call = Task { try await client.studio.activities.getActivities() }
    call.cancel()
    do {
      _ = try await call.value
    } catch is CancellationError {
      print("withdrawn")
    }
  }

  static func snippet8() async throws {
    func describe(_ error: APIError) -> String {
      if error.code == .limitReached { return "a ceiling, which no wait lifts" }
      // Any entry, the first or another: one refusal may name several codes.
      if error.hasCode(.validationFailed) {
        return error.errors.filter { $0.code == .validationFailed }.map(\.message)
          .joined(separator: "\n")
      }
      return error.code?.rawValue ?? "\(error.status)"
    }
  }

  static func snippet9() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

    // A listing is read a page at a time, each page requested as the rows before it are read.
    let itineraries = try client.studio.itineraries.walkGetItineraries(
      query: .init { $0.status = .published }, maxPages: 10)
    for try await itinerary in itineraries {
      print(itinerary.name)
    }

    // An event stream reopens, waits and resumes on the contract's schedule, and ends on `done`. It
    // opens as its first frame is asked for, so its method awaits nothing.
    for try await frame in try client.agent.runs.getAgentRunEvents(run_id: "run_0f1e") {
      if case .AgentMessageEvent(let message) = frame.event {
        print(message.content)
      }
    }

    // An editor stream is read as its member's user, which a session token given as a value does not
    // name, so that member's own arrival is not read as the stream moving on.
    let editors = try client.studio.collab.getItineraryEvents(itinerary_id: "itn_8f14")
    for try await frame in editors.reading(asUser: "usr_7a4e") {
      if case .CollabPresenceJoinEvent(let join) = frame.event {
        print(join.user_id)
      }
    }

    // A Data API call narrows its document to the fields it selects.
    let places = try await client.data.geocode(
      input: .init(query: "Chamonix"),
      select: ["places": ["name": true, "point": true]]
    )
    print(places.places?.first?.name ?? "")
  }

  static func snippet10() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

    // A read this build prints no method for, by what the contract declares of it.
    let getThing = OperationDeclaration(
      operationId: "getThing", method: "GET", idempotent: true,
      credentials: CredentialDeclaration(requiresSession: true))
    let thing: Response<JSONValue, [String: JSONValue]?> = try await client.send(
      getThing, path: "/v1/things/thg_1a2b")
    print(thing.data)

    // A listing, walked a page at a time: the walk writes the cursor and the page size into your query.
    let getThings = OperationDeclaration(operationId: "getThings", method: "GET", idempotent: true)
    let things: AsyncThrowingStream<JSONValue, any Error> = try client.walk(
      getThings, path: "/v1/things", query: [URLQueryItem(name: "sort", value: "name")], maxPages: 5)
    for try await row in things {
      print(row)
    }

    // A Data API operation, by its name, its input's type and its field tree.
    let input: JSONValue = ["near": [6.86, 45.83]]
    let nearby: JSONValue = try await client.query(
      DataOperation(name: "things", inputType: "ThingsInput!", selection: ["things": ["name": true]]),
      input: input)
    print(nearby)

    // A stream, read as a feed of records.
    let getThingEvents = OperationDeclaration(operationId: "getThingEvents", method: "GET")
    for try await frame in try client.events(getThingEvents, path: "/v1/things/thg_1a2b/events") {
      print(frame.event.event ?? "", frame.event.data)
    }
  }

  static func snippet11() async throws {
    // On a server: the body exactly as it arrived, and its `Mountaya-Signature` header, in; the
    // status to answer the delivery with, out.
    #if os(macOS) || os(Linux)
      func receive(body: Data, signature: String?) -> Int {
        let event: WebhookEvent
        do {
          event = try constructWebhookEvent(
            rawBody: body, signatureHeader: signature, secret: webhookSecret)
        } catch MountayaError.webhookSignature(let refusal) {
          print(refusal.reason)
          return 400
        } catch {
          return 500
        }

        // Each event arrives at least once: act on its `id` once.
        print(event.id, event.type.rawValue, event.created_at)
        switch event {
        case .organizationMemberUpdated(let event):
          // The membership as it is now, and the role it held before the change.
          print(event.data.object.role.rawValue, event.data.previous_attributes?.role?.rawValue ?? "")
        case .collectionDeleted(let event):
          print("collection \(event.data.object.id) deleted")
        default:
          break
        }
        return 204
      }
    #endif
  }

  static func snippet12() async throws {
    struct Answered: HTTPExchange {
      func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
        ExchangeResponse(status: 200, body: ExchangeBody(Data(#"{"data": []}"#.utf8)))
      }
    }

    let client = try Mountaya(credential: .publishable(key: "pk_test_0a1b"), exchange: Answered())
    let activities = try await client.studio.activities.getActivities()
    print(activities.data.count)
  }

  static func snippet13() async throws {
    let client = try Mountaya(
      credential: .publishable(key: "pk_live_0a1b"),
      onResponse: { report in
        print(
          report.operationId, report.status, "attempt", report.attempt, report.requestId ?? "",
          report.rateLimit?.policies.map(\.remaining) ?? [])
      }
    )
    _ = try await client.studio.activities.getActivities()
  }

  static func snippet14() async throws {
    // A rule is a function over the wire's own values: a position is `[longitude, latitude]`.
    let line: [[Double]] = [[6.8652, 45.9237], [6.8752, 45.9287], [6.9271, 45.9682]]
    let meters = routeLengthMeters(line)

    // A value is written for its reader, in their language and their units, never the device's.
    let units = UnitPreferences(language: "fr-FR", length: .metric)
    print(formatDistance(meters, units: units), formatLngLat(line[0]) ?? "")

    // A time of day is the locale's own, on its own clock, in the zone you name: 오후 1:00 in Korean.
    let arrival = Date(timeIntervalSince1970: 1_773_446_400)
    print(
      formatDateTime(arrival, locale: "ko-KR", timeZone: "Pacific/Auckland", timeLength: .short) ?? "")
  }

  static func snippet15() async throws {
    // The tiles the terrain at a point is read off, by their address.
    let source = ElevationSource(encoding: .mapbox, tileSize: 512, zoom: 15)
    let needed = elevationTilesAt([6.8652, 45.9237], source: source)

    // A pixel's height, and the direction a bearing faces.
    let sea = decodeElevation([1, 134, 160], encoding: .mapbox)
    let facing = aspectCardinal(236.3)

    // A depth of snow in inches for an imperial reader, a humidity in a French one's pattern.
    let imperial = UnitPreferences(language: "en", length: .imperial)
    print(
      needed.count, sea ?? 0, facing?.rawValue ?? "", formatSnowfall(35, units: imperial),
      formatHumidity(54.6, units: UnitPreferences(language: "fr")))
  }

  static func snippet16() async throws {
    // The elements' words in French, with one of your own folded over them.
    let words = resolveBundle(
      .elements, language: .fr,
      overrides: .bySection(["controls": ["close": "Fermer la carte"]]))

    // The standard colours, the accent restyled and every other token as the contract states it.
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))

    // A glyph's markup, read into the shapes a view draws, each painted as its set paints it.
    let pin = parseGlyph(GlyphSet.marker.markup["map-pin"] ?? "")
    let paints = pin.map { glyphPaint($0, in: .marker) }

    // A licensed set of your own, its missing glyphs drawn from the bundled marker set.
    let licensed = GlyphSet(
      name: "licensed", paint: .stroke, markup: ["refuge": #"<path d="M3 21h18"/>"#])
    let markers = licensed.flatMap { GlyphSet(chaining: [$0, .marker]) } ?? .marker
    print(words.keys.sorted(), tokens.accent.light.hex, paints.count, markers.markup.count)
  }

  static func snippet17() async throws {
    // Every member you leave is the contract's; a band of your own sits between two of the map's.
    var paint = MapPaint.standard
    paint.itinerary.casingColor = "#1b1b1b"
    paint.layerRanks["acme_avalanche"] = LayerRank.poi.rank + 2

    let hut = poiStyleOf(.hut)
    print(paint.itinerary.lineWidthStops, hut?.glyph ?? "", hut?.color.hex ?? "")
  }

  static func snippet18() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b"))

    // One cache per client: every element reading through it shares its reads.
    let itineraries = await ItineraryResourceCache { id, surface in
      try await client.studio.itineraries.getItinerary(
        itinerary_id: id, query: .init { $0.surface = surface }
      ).data
    }

    // An element handed an id shows every projection at once, once its answer lands.
    let profile = await ItineraryResourceEngine(cache: itineraries, itineraryId: "itn_4e5f")
    for await resource in await profile.subscribe() {
      guard case .resolved(let itinerary) = resource else { continue }
      print(itinerary.legs.map(\.name), itinerary.waypoints.compactMap(\.name))
      break
    }

    // Once your app has saved the itinerary, every element over it reads it again.
    await itineraries.invalidate(itineraryId: "itn_4e5f")
  }

  static func snippet19() async throws {
    // Every engine is bound to the main actor, and so is a test of one.
    try await MainActor.run {
      let navigation = ScriptedNavigationEngine<String>()
      navigation.start("Refuge du Couvercle")
      try navigation.sent[0].answer(
        NavigationRoute(line: [[6.8652, 45.9237], [6.9271, 45.9682]], duration: 5_400))

      try navigation.setPosition([6.9271, 45.9682])
      print(navigation.state.status)  // arrived
    }
  }

  static func snippet20() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))
    let itinerary = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
    let route = readItineraryRoute(itinerary.data.segments, waypoints: itinerary.data.waypoints)

    // Your words: a waypoint is a place passed on the way, never the arrival.
    func sentence(for instruction: NavigationInstruction) -> String {
      switch instruction.key {
      case .waypoint: "Pass \(instruction.name ?? "the waypoint")"
      case .waypointPlain: "Pass the waypoint"
      case .goal, .goalPlain: "You have arrived"
      default: instruction.name.map { "Continue onto \($0)" } ?? "Continue"
      }
    }
    print(route?.steps.map { sentence(for: stepInstruction($0)) } ?? [])
  }

  static func snippet21() async throws {
    @MainActor
    func showTrip(on map: MapEngine, itinerary itineraryId: String) async throws {
      // An itinerary by id, the camera framing it once it is drawn; a later call takes its place.
      try await map.setItinerary(itineraryId, fit: CameraFit(padding: PixelPadding(48)))
      // The zones of your credential's scope, each layer at the rank its source layer declares.
      try await map.setZones(true)

      map.addSource(MapSource(id: "trail", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
      map.addLayer(
        MapLayer(
          id: "trail", type: .line, source: "trail",
          rank: LayerRank.poi.rank + 2, paint: ["line-color": "#e64980", "line-width": 4]))
      // A member set to a value replaces the one held, JSON's null included; one left nil is kept.
      try map.editLayer("trail", paint: ["line-color": "#228be6", "line-width": nil])
    }
  }

  static func snippet22() async throws {
    // The mark's frame on a map whose safe area starts `top` and `left` inside its edges.
    func markFrame(top: Double, left: Double) -> (x: Double, y: Double, width: Double, height: Double) {
      (left + watermarkInset, top + watermarkInset, watermarkWidth, watermarkHeight)
    }

    // Where a bar of yours across the top of the safe area starts: 8 points below the mark's frame
    // while the map's read holds it, and at the safe area's top once the read answers white label.
    func barTop(safeAreaTop top: Double, read: OrganizationRead) -> Double {
      isWatermarkKeptClear(read) ? top + watermarkClearance + 8 : top
    }
  }

  static func snippet23() async throws {
    @MainActor
    func brand(_ map: MapEngine) async throws -> String {
      // One read per publishable key and origin, shared by every map; nil for a client holding none.
      let organization = try await map.loadOrganization()
      return [organization?.name ?? "", map.organization?.white_label == true ? "white label" : ""]
        .joined(separator: " ")
    }
  }

  static func snippet24() async throws {
    @MainActor
    func showSnow(on map: MapEngine) async throws {
      let catalogue = try await map.loadLayers()
      print(catalogue.terrains.map(\.slug))
      try await map.setOverlay("snow-depth")
      try await map.addEnrichment("avalanche-risk")
      map.setLayerVisibility("avalanche-risk-fills", visible: false)
      for key in map.drawnLayerKeys() where key == "labels" {
        map.setKeyVisibility(key, visible: false)
      }
      map.setAccessRestrictionsVisibility(false)
    }
  }

  static func snippet25() async throws {
    @MainActor
    func forecast(on map: MapEngine) async throws {
      try await map.setOverlay("snow-forecast")
      map.setInstant(Date(timeIntervalSinceNow: 6 * 3600))
      print(map.instant?.description ?? "none pinned")
      map.setInstant(nil)
    }
  }

  static func snippet26() async throws {
    @MainActor
    func showReach(on map: MapEngine) async throws {
      let reach = try await map.addIsochrones(
        DataSchema.IsochronesInput(
          activity: .hikingAndTrail, locations: [[6.8652, 45.9237]], range: [1_800, 3_600],
          rangeType: .time))
      try await map.editIsochrones(reach.id, patch: { $0.range = [900, 1_800] })
      map.removeAnalysis(reach.id)

      map.setGeometry(.point(GeoJSONPoint(coordinates: [6.8652, 45.9237])), in: .highlight)
      map.clearGeometry(in: .highlight)
    }
  }

  static func snippet27() async throws {
    @MainActor
    func showHut(on map: MapEngine) throws {
      try map.addMarker(MapMarker(id: "hut", position: [6.8652, 45.9237], glyph: "hut", label: "Refuge"))
      // A member left nil keeps the one the marker holds, and the marker keeps its place.
      try map.editMarker("hut", color: "#e64980")
      // [west, south, east, north]: the camera stays within it, and nil lifts it.
      try map.setMaxBounds([6.7, 45.8, 7.0, 46.0])
      // A limit left out is kept, and one released goes back to MapLibre's own, 0 and 25.5.
      try map.setZoomBounds(min: 8, max: 17)
      try map.setZoomBounds(max: .released)
    }
  }

  static func snippet28() async throws {
    @MainActor
    func frameValley(on map: MapEngine) async throws {
      try map.ease(to: CameraTarget(center: [6.8652, 45.9237], zoom: 13))
      try map.fitBounds([6.8, 45.8, 6.95, 45.9], with: CameraFit(padding: PixelPadding(48), maxZoom: 15))
      map.zoomIn()
      map.resetNorth()
      // A refusal names its reason, `denied`, `noApi` or `unavailable`, and moves nothing.
      _ = try await map.locate()
    }
  }

  static func snippet29() async throws {
    @MainActor
    func listen(to map: MapEngine) async {
      for await event in map.events() {
        switch event {
        case .featureTap(_, let features):
          print(features.map(\.layer))
        case .accessRefused(let status, _):
          print("access refused: \(status)")
        case .failure(let url, _, let cause?):
          print("never left: \(url), \(cause)")
        case .layersChange(let catalogue):
          print(catalogue?.terrains.map(\.slug) ?? [])
        default:
          break
        }
      }
    }
  }

  static func snippet30() async throws {
    @MainActor
    func placeWaypoint(on map: MapEngine, along line: [[Double]]) throws -> WaypointEdit? {
      map.setActiveSegments([line])
      try map.beginWaypointEdit("w1")
      // MapView places it at each tap; a map drawn some other way hands its own projection.
      try map.placeWaypoint(
        at: [6.86, 45.83], through: ScreenProjection(point: { $0 }, position: { $0 }))
      return map.endWaypointEdit()
    }
  }

  static func snippet31() async throws {
    func controlWords() -> [String] {
      // A scope nested in another takes every setting it does not state from it.
      let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-CH"))
      var tokens = ElementTokens.standard
      tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
      let results: JSONValue = ["one": "{count} résultat", "other": "{count} résultats"]
      return [
        french.word("controls.zoomIn"),
        themeTokenValue(tokens.controlBg, in: .dark).hex,
        countedText(results, count: 1_234, language: .fr) ?? "",
      ]
    }
  }

  static func snippet32() async throws {
    @MainActor
    func slide(_ layers: LayersSelectionEngine, now: Date, to value: Int) -> String {
      let track = timeSliderWindow(now: now)
      let ticks = timeSliderTicks(track).compactMap(\.word)
      if let released = timeSliderRelease(track, at: value) {
        layers.setInstant(released.pin)
      }
      let readout = timeSliderReadout(track, at: track.value(at: layers.state.instant))
      return "\(ticks) \(readout.word) \(readout.count ?? 0)"
    }
  }

  static func snippet33() async throws {
    @MainActor
    func searchHuts(through mountaya: Mountaya) async -> [String] {
      // The engine waits for the typing to pause, asks one request per branch and keeps the latest.
      let search = SearchEngine(
        configuration: SearchConfiguration(
          fetch: { try await mountaya.data.search(input: $0) }, language: dataLanguageFor("fr-CH"),
          targets: [.pois, .places]))
      search.setQuery("refuge")
      for await state in search.subscribe() where state.isSettled {
        search.close()
        // What a list shows under a filter, and what picking a row does to a map.
        return searchListState(state, filter: .places).rows.map { row in
          "\(row.title): \(pickTarget(row.payload).mark == nil ? "unmarked" : "marked")"
        }
      }
      return []
    }
  }

  static func snippet34() async throws {
    @MainActor
    func mark(_ row: SearchRow, on map: MapEngine, tokens: ElementTokens, scheme: ThemeScheme) {
      map.setSearchHighlight(
        pickTarget(row.payload).mark, accent: themeTokenValue(tokens.accent, in: scheme))
    }
  }

  static func snippet35() async throws {
    func roadbook(_ itinerary: RestSchema.ItineraryWithDetails) -> [String] {
      // The projections every data element reads, and the rows a segment table states.
      let resolved = ResolvedItinerary(itinerary)
      let series = buildElevationSeries(resolved.geometry)
      let units = UnitPreferences(language: "fr")
      return itinerarySegmentRows(series, legs: resolved.legs).map { row in
        let band = formatAltitudeRange(min: row.metrics.altitudeMin, max: row.metrics.altitudeMax, units: units)
        return "\(row.name): \(formatDistance(row.metrics.sectionDistance, units: units)), \(band)"
      }
    }
  }
}
