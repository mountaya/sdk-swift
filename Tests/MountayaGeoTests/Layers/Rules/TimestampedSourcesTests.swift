import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("timestampedSources")
struct TimestampedSourcesTests {
  /// instant is 2026-03-14T09:26:53.900Z.
  private static let instant = Date(timeIntervalSince1970: 1_773_480_413.9)
  private static let stamp = "timestamp=2026-03-14T09%3A26%3A53.900Z"

  /// overlay is the classic overlay `slug`, stamped by the server where `server` says so, drawn
  /// from one source of each list of `tiles`.
  private static func overlay(_ slug: String, server: Bool = true, tiles: [[String]])
    -> TileSchema.Overlay
  {
    var overlay = TileFixtures.overlay(slug)
    overlay.capabilities.server.timestamp = server
    overlay.sources = tiles.enumerated().map { index, addresses in
      var source = TileFixtures.source([])
      source.id = "\(slug)-\(index)"
      source.tiles = addresses
      return source
    }
    return overlay
  }

  private static func catalogue(
    _ overlays: [TileSchema.Overlay], enrichments: [TileSchema.Overlay] = []
  )
    -> TileSchema.Layers
  {
    TileFixtures.layers([
      TileFixtures.category("conditions", children: overlays),
      TileFixtures.category(enrichmentCategorySlug, children: enrichments),
    ])
  }

  /// stamped is what the rule answers for one address of the stamped overlay `snow-depth`.
  private static func stamped(_ address: String) -> [String] {
    let sources = timestampedSources(
      catalogue([overlay("snow-depth", tiles: [[address]])]), overlay: "snow-depth",
      at: instant)
    return sources.flatMap(\.tiles)
  }

  @Test("each source of the overlay the server stamps asks for the instant, in its order")
  func sources() {
    let found = timestampedSources(
      Self.catalogue([
        Self.overlay(
          "snow-depth",
          tiles: [["https://t/a/{z}/{x}/{y}?key=k"], ["https://t/b/{z}", "https://t/c/{z}"]])
      ]), overlay: "snow-depth", at: Self.instant)

    #expect(
      found == [
        TimestampedSource(
          sourceId: "snow-depth-0", tiles: ["https://t/a/{z}/{x}/{y}?key=k&\(Self.stamp)"]),
        TimestampedSource(
          sourceId: "snow-depth-1",
          tiles: ["https://t/b/{z}?\(Self.stamp)", "https://t/c/{z}?\(Self.stamp)"]),
      ])
  }

  @Test("nothing is asked of no overlay, one held by no classic category, or one not stamped")
  func nothingAsked() {
    let catalogue = Self.catalogue(
      [Self.overlay("slopes", server: false, tiles: [["https://t/s/{z}"]])],
      enrichments: [Self.overlay("radar", tiles: [["https://t/r/{z}"]])])

    #expect(timestampedSources(catalogue, overlay: nil, at: Self.instant).isEmpty)
    #expect(timestampedSources(catalogue, overlay: "avalanche", at: Self.instant).isEmpty)
    #expect(timestampedSources(catalogue, overlay: "slopes", at: Self.instant).isEmpty)
    #expect(
      timestampedSources(catalogue, overlay: "radar", at: Self.instant).isEmpty,
      "an enrichment the server stamps is never asked")
  }

  @Test("an instant that names no moment asks nothing")
  func noMoment() {
    let catalogue = Self.catalogue([Self.overlay("snow-depth", tiles: [["https://t/{z}"]])])

    #expect(
      timestampedSources(catalogue, overlay: "snow-depth", at: Date(timeIntervalSince1970: .nan))
        .isEmpty)
    #expect(
      timestampedSources(catalogue, overlay: "snow-depth", at: Date(timeIntervalSince1970: 9e12))
        .isEmpty)
  }

  @Test("the instant is written in UTC to the millisecond, its colons encoded")
  func written() {
    let whole = timestampedSources(
      Self.catalogue([Self.overlay("snow-depth", tiles: [["https://t/{z}"]])]),
      overlay: "snow-depth", at: Date(timeIntervalSince1970: 1_773_478_800))

    #expect(whole.flatMap(\.tiles) == ["https://t/{z}?timestamp=2026-03-14T09%3A00%3A00.000Z"])
  }

  @Test("a timestamp pair is replaced where it stands, the others and the empty pairs dropped")
  func replaced() {
    #expect(
      Self.stamped("https://t/{z}?timestamp=2026-01-01T00%3A00%3A00Z&key=k")
        == ["https://t/{z}?\(Self.stamp)&key=k"])
    #expect(
      Self.stamped("https://t/{z}?&timestamp=a&&key=k&timestamp=b&")
        == ["https://t/{z}?\(Self.stamp)&key=k"])
    #expect(
      Self.stamped("https://t/{z}?t%69mestamp=a&key=k") == ["https://t/{z}?\(Self.stamp)&key=k"])
    #expect(Self.stamped("https://t/{z}?timestamp&key=k") == ["https://t/{z}?\(Self.stamp)&key=k"])
    #expect(
      Self.stamped("https://t/{z}?time+stamp=a") == ["https://t/{z}?time+stamp=a&\(Self.stamp)"])
  }

  @Test("a name in other letters, or one whose escape names no byte, is another parameter")
  func otherNames() {
    #expect(
      Self.stamped("https://t/{z}?Timestamp=a&key=k")
        == ["https://t/{z}?Timestamp=a&key=k&\(Self.stamp)"])
    #expect(
      Self.stamped("https://t/{z}?%zz=1&key=k") == ["https://t/{z}?%zz=1&key=k&\(Self.stamp)"])
    #expect(Self.stamped("https://t/{z}?%7=1") == ["https://t/{z}?%7=1&\(Self.stamp)"])
  }

  @Test("every other part is kept byte for byte, the fragment after the query")
  func kept() {
    #expect(
      Self.stamped("https://t/{z}/{x}/{y}?sig=a%2Fb%7Bc%7D&key=k#layer")
        == ["https://t/{z}/{x}/{y}?sig=a%2Fb%7Bc%7D&key=k&\(Self.stamp)#layer"])
    #expect(
      Self.stamped("https://t/caf\u{E9}/{z}.pbf") == ["https://t/caf\u{E9}/{z}.pbf?\(Self.stamp)"])
    #expect(Self.stamped("https://t/{z}#a?b") == ["https://t/{z}?\(Self.stamp)#a?b"])
  }

  @Test("an address with no scheme is kept as it is")
  func noScheme() {
    #expect(Self.stamped("/v1/overlays/{z}?key=k") == ["/v1/overlays/{z}?key=k"])
    #expect(Self.stamped("1http://t/{z}") == ["1http://t/{z}"])
    #expect(Self.stamped("ht tp://t/{z}") == ["ht tp://t/{z}"])
    #expect(Self.stamped("a+b-c.d://t/{z}") == ["a+b-c.d://t/{z}?\(Self.stamp)"])
  }
}
