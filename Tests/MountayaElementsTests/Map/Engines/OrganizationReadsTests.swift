import Foundation
import MountayaClient
import Testing

@testable import MountayaElements

@Suite("OrganizationReads")
@MainActor
struct OrganizationReadsTests {
  /// Lookups answers every lookup with an organization, or a 404, and counts them.
  private actor Lookups: HTTPExchange {
    let refuses: Bool
    private(set) var sent: [ExchangeRequest] = []

    init(refuses: Bool = false) {
      self.refuses = refuses
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      if refuses {
        return ExchangeResponse(
          status: 404, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(Data(#"{"errors": [{"code": "NOT_FOUND", "message": "no"}]}"#.utf8)))
      }
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(OrganizationReadsTests.body.utf8)))
    }
  }

  nonisolated static let body = #"""
    {"data": {"id": "org", "name": "Alps Huts", "etag": "e", "awaiting_agreement": false,
      "created_at": "2026-03-14T09:26:53Z", "updated_at": "2026-03-14T09:26:53Z",
      "white_label": true,
      "settings": {"etag": "s",
        "default_props": {"preferred_language": "fr", "preferred_theme": "auto",
          "preferred_unit_length": "metric", "preferred_unit_pace": "per-time",
          "preferred_unit_slope": "degrees", "preferred_unit_temperature": "celsius",
          "segments_color": "#1c7ed6", "terrain": "", "terrain_variant": "light",
          "with_access_restrictions": true, "with_collection_itineraries": true,
          "with_collection_zones": true, "with_directions_control": true,
          "with_download_control": true, "with_navigation_control": true, "with_overlays": [],
          "with_overlays_control": false, "with_preferences_control": true,
          "with_profile_analysis": true, "with_profile_characteristics": true,
          "with_profile_elevation": true, "with_profile_pace_control": true,
          "with_streetview_control": false, "with_terrains": []},
        "safety_rules": {"boundaries": [], "domains": [], "require_session_token": false,
          "with_collection_itineraries": true, "with_collection_zones": true, "with_overlays": [],
          "with_overlays_control": true, "with_profile_analysis": true,
          "with_profile_elevation": true, "zoom_max": 22, "zoom_min": 0},
        "theme": {"colors": {"ui": []}}}}}
    """#

  @Test("one read per key, its answer kept and sent under no credential")
  func kept() async throws {
    let lookups = Lookups()
    let client = try Mountaya(credential: .publishable(key: "pk_a"), exchange: lookups)
    let reads = OrganizationReads()

    let first = try await reads.read("pk_a", through: client)
    let second = try await reads.read("pk_a", through: client)

    #expect(first.id == "org" && second.white_label)
    #expect(
      reads.organization("pk_a", origin: BaseURLs.standard.rest.absoluteString)?.id == "org")
    let sent = await lookups.sent
    #expect(sent.count == 1)
    #expect(sent.first?.header("X-API-Key") == nil)
    let body = String(decoding: sent.first?.body ?? Data(), as: UTF8.self)
    #expect(body.contains("pk_a"))
  }

  @Test("a read that fails is kept by nobody, so the next asks again")
  func failed() async throws {
    let lookups = Lookups(refuses: true)
    let client = try Mountaya(
      credential: .publishable(key: "pk_b"), retry: try RetryPolicy(maxRetries: 0),
      exchange: lookups)
    let reads = OrganizationReads()

    await #expect(throws: MountayaError.self) { try await reads.read("pk_b", through: client) }
    await #expect(throws: MountayaError.self) { try await reads.read("pk_b", through: client) }
    #expect(reads.organization("pk_b", origin: BaseURLs.standard.rest.absoluteString) == nil)
    #expect(await lookups.sent.count == 2)
  }

  @Test("a key is read apart on each Map Studio API origin, and shared on one")
  func keptByOrigin() async throws {
    let lookups = Lookups()
    let staging = try #require(URL(string: "https://api.staging.mountaya.test"))
    let production = try Mountaya(credential: .publishable(key: "pk_c"), exchange: lookups)
    let stagingClient = try Mountaya(
      credential: .publishable(key: "pk_c"), baseUrls: BaseURLs(rest: staging), exchange: lookups)
    let stagingAgain = try Mountaya(
      credential: .publishable(key: "pk_c"), baseUrls: BaseURLs(rest: staging), exchange: lookups)
    let reads = OrganizationReads()

    _ = try await reads.read("pk_c", through: production)
    #expect(reads.organization("pk_c", origin: staging.absoluteString) == nil)
    _ = try await reads.read("pk_c", through: stagingClient)
    _ = try await reads.read("pk_c", through: stagingAgain)

    let sent = await lookups.sent
    #expect(sent.count == 2)
    #expect(sent.map { $0.url.host() } == ["api.mountaya.com", "api.staging.mountaya.test"])
  }
}
