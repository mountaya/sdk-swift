import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapOrganizationRead answers how maps read their organization, played as a script over an
  /// exchange that holds every read until a step settles it: `map` makes a map over a client of
  /// its own holding the case's publishable key, or a share token where it names none, whose
  /// attempts are never repeated; `load` is a call of `loadOrganization()` nobody waits on, its
  /// outcome the read whose organization it answered, `no-key` for nil, `closed` for a `MapError`
  /// of kind `closed` and `failed` for any other; `answer` lets a read answer an organization whose
  /// id names it, `fail` answer a 404, `timeout` fail as an attempt the platform gave up on at its
  /// time budget, and `close` is `close()`. Every call runs in a task preferring the main queue,
  /// and each step settles before the next.
  ///
  /// The reads are shared for as long as the process lives, by key and Map Studio API origin, so
  /// each case's clients send to an origin of the case's own, numbered in the order the cases run,
  /// and no case reads another's answer under the keys every case names. `held` is each map's
  /// `organization`, and `reads` each read's whole body as it was sent; a read carrying a
  /// credential fails the case.
  static let mapOrganizationRead = Runner(id: "map.organization.read", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapOrganizationScripts.read(try fixtureCase.input.array(at: "steps"))
  }
}

/// MapOrganizationScripts plays the organization's scripts.
@MainActor
enum MapOrganizationScripts {
  /// Outcomes is what each load got, written as the fixture expects it.
  final class Outcomes {
    var values: [OrderedJSON] = []
  }

  /// played counts the cases played in the process, which numbers each case's origin.
  private static var played = 0

  /// credentialHeaders is every header a credential rides in, in lowercase, none of which a read of
  /// an organization sends.
  static let credentialHeaders: Set<String> = [
    "x-api-key", "x-session-token", "x-share-token", "authorization", "cookie",
  ]

  /// origin is a Map Studio API origin of the case played `number`th.
  static func origin(_ number: Int) throws -> BaseURLs {
    guard let rest = URL(string: "https://organization-read-\(number).conformance.test") else {
      throw FixtureError(description: "case \(number) names no origin")
    }
    return BaseURLs(rest: rest)
  }

  /// read plays `map.organization.read`'s steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func read(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let held = MapFixtures.Held()
    played += 1
    let baseUrls = try origin(played)
    var maps: [MapEngine] = []
    let loads = Outcomes()
    func readOf(_ organization: RestSchema.Organization?) -> OrderedJSON {
      guard let id = organization?.id, id.hasPrefix("read-"), let read = Int(id.dropFirst(5))
      else { return .null }
      return .number(Double(read))
    }
    func progress() -> [OrderedJSON] {
      [.array(loads.values), .array(maps.map { readOf($0.organization) })]
        + held.progress.map { .number(Double($0)) }
    }
    for step in steps {
      switch try step.string(at: "step") {
      case "map":
        let key = try step.optionalString(at: "key")
        let client = try MapFixtures.client(
          credential: key.map { .publishable(key: $0) } ?? .share(token: "share_conformance"),
          baseUrls: baseUrls, retry: try RetryPolicy(maxRetries: 0), exchange: held)
        maps.append(MapEngine(client: client, geolocation: InertGeolocation()))
      case "load":
        let map = maps[try step.integer(at: "map")]
        let index = loads.values.count
        loads.values.append(.null)
        _ = MainQueue.run {
          do {
            let organization = try await map.loadOrganization()
            loads.values[index] = organization == nil ? .string("no-key") : readOf(organization)
          } catch let refusal as MapError where refusal.kind == .closed {
            loads.values[index] = .string("closed")
          } catch {
            loads.values[index] = .string("failed")
          }
        }
      case "answer":
        let read = try step.integer(at: "read")
        try held.answer(
          read,
          body: MapOrganizationFixtures.body(
            id: "read-\(read)", whiteLabel: try step.flag(at: "whiteLabel")))
      case "fail":
        try held.fail(try step.integer(at: "read"))
      case "timeout":
        try held.timeOut(try step.integer(at: "read"))
      case "close":
        maps[try step.integer(at: "map")].close()
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      await MainQueue.settle { progress() }
    }
    // Each read's whole body, as sent, and none of them carrying a credential.
    let reads = try held.reads.map { read -> OrderedJSON in
      let credentials = read.request.headers.keys.filter {
        credentialHeaders.contains($0.lowercased())
      }
      guard credentials.isEmpty else {
        throw FixtureError(
          description: "a read of the organization sent a credential: \(credentials.sorted())")
      }
      return try OrderedJSON.parse(String(decoding: read.request.body ?? Data(), as: UTF8.self))
    }
    let holding = maps.map { readOf($0.organization) }
    let outcomes = loads.values
    held.release()
    await MainQueue.settle { progress() }
    for map in maps {
      map.close()
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "held", value: .array(holding)),
        OrderedJSON.Member(key: "loads", value: .array(outcomes)),
        OrderedJSON.Member(key: "reads", value: .array(reads)),
      ]))
  }
}

/// MapOrganizationFixtures builds the organizations a lookup answers.
enum MapOrganizationFixtures {
  /// organization is an organization as the API serves it, of id `id`, holding white label or not,
  /// its settings a new organization's.
  static func organization(id: String, whiteLabel: Bool) -> String {
    """
    {"id": "\(id)", "name": "Alps Huts", "etag": "\\"e1\\"", "awaiting_agreement": false,
      "created_at": "2026-03-14T09:26:53Z", "updated_at": "2026-03-14T09:26:53Z",
      "white_label": \(whiteLabel),
      "settings": {"etag": "\\"s1\\"",
        "default_props": \(defaultProps),
        "safety_rules": {"boundaries": [], "domains": [], "require_session_token": false,
          "with_collection_itineraries": true, "with_collection_zones": true,
          "with_overlays": [], "with_overlays_control": true, "with_profile_analysis": true,
          "with_profile_elevation": true, "zoom_max": 22, "zoom_min": 0},
        "theme": {"colors": {"ui": []}}}}
    """
  }

  /// defaultProps is a new organization's embed defaults.
  static let defaultProps = """
    {"preferred_language": "en", "preferred_theme": "auto", "preferred_unit_length": "metric",
      "preferred_unit_pace": "per-time", "preferred_unit_slope": "degrees",
      "preferred_unit_temperature": "celsius", "segments_color": "#1c7ed6", "terrain": "",
      "terrain_variant": "light", "with_access_restrictions": true,
      "with_collection_itineraries": true, "with_collection_zones": true,
      "with_directions_control": true, "with_download_control": true,
      "with_navigation_control": true, "with_overlays": [], "with_overlays_control": false,
      "with_preferences_control": true, "with_profile_analysis": true,
      "with_profile_characteristics": true, "with_profile_elevation": true,
      "with_profile_pace_control": true, "with_streetview_control": false, "with_terrains": []}
    """

  /// body is the envelope a lookup answers with an organization of id `id`.
  static func body(id: String, whiteLabel: Bool) -> Data {
    Data(#"{"data": \#(organization(id: id, whiteLabel: whiteLabel))}"#.utf8)
  }
}
