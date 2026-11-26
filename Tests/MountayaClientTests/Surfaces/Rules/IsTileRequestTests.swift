import Foundation
import Testing

@testable import MountayaClient

@Suite("isTileRequest")
struct IsTileRequestTests {
  private static func url(_ text: String) throws -> URL {
    try #require(URL(string: text))
  }

  private static func claims(_ request: String, base: String = "https://tiles.mountaya.com")
    throws -> Bool
  {
    isTileRequest(try url(request), tiles: try url(base))
  }

  /// written tells whether the text of a request is one, where it is a URL at all: a text
  /// Foundation reads as no URL is no request a renderer can make, so it is none.
  private static func written(_ request: String, base: String = "https://tiles.mountaya.com")
    throws -> Bool
  {
    guard let requested = URL(string: request) else { return false }
    return isTileRequest(requested, tiles: try url(base))
  }

  @Test("a request to the Tile API's origin is one, a style, a sprite and a glyph as a tile is")
  func origin() throws {
    #expect(try Self.claims("https://tiles.mountaya.com/v1/zones/12/2093/1425"))
    #expect(try Self.claims("https://tiles.mountaya.com/v1/terrains/outdoor/light/style"))
    #expect(try Self.claims("https://tiles.mountaya.com/v1/glyphs/Inter%20Regular/0-255"))
    #expect(try Self.claims("https://tiles.mountaya.com"))
    #expect(try Self.claims("https://tiles.mountaya.com/v1/zones/1/2/3?share_token=share_a#top"))
  }

  @Test("the host's case, a default port and dot segments are nothing")
  func readAsTheOriginIs() throws {
    #expect(try Self.claims("https://TILES.Mountaya.com/v1/zones/1/2/3"))
    #expect(try Self.claims("https://tiles.mountaya.com:443/v1/zones/1/2/3"))
    #expect(try Self.claims("HTTPS://tiles.mountaya.com/v1/zones/1/2/3"))
    #expect(
      try Self.claims(
        "https://tiles.example.com/tiles/x/../v1/zones", base: "https://tiles.example.com/tiles"))
    #expect(
      try Self.claims(
        "https://tiles.example.com/./tiles/v1", base: "https://tiles.example.com/tiles"))
    #expect(
      try !Self.claims(
        "https://tiles.example.com/tiles/../private", base: "https://tiles.example.com/tiles"))
  }

  @Test("another host, scheme or port is not one, a host the origin's name begins included")
  func otherOrigins() throws {
    #expect(try !Self.claims("https://tiles.mountaya.com.example.net/v1/zones/1/2/3"))
    #expect(try !Self.claims("https://example.com/v1/zones/1/2/3"))
    #expect(try !Self.claims("http://tiles.mountaya.com/v1/zones/1/2/3"))
    #expect(try !Self.claims("https://tiles.mountaya.com:8443/v1/zones/1/2/3"))
    #expect(try !Self.claims("file:///v1/zones/1/2/3"))
    #expect(try !Self.claims("asset://tiles.mountaya.com/v1/zones"))
    #expect(try !Self.written("https://tiles.mountaya.com:port/v1/zones"))
    #expect(try !Self.claims("mailto:tiles@tiles.mountaya.com"))
  }

  @Test("a request naming a user or a password is never one")
  func credentials() throws {
    #expect(try !Self.claims("https://user@tiles.mountaya.com/v1/zones/1/2/3"))
    #expect(try !Self.claims("https://user:secret@tiles.mountaya.com/v1/zones/1/2/3"))
    #expect(try !Self.claims("https://tiles.mountaya.com@example.com/v1/zones/1/2/3"))
  }

  @Test(
    "under a base with a path, the path is claimed at a segment boundary, a trailing slash nothing")
  func basePath() throws {
    let base = "https://example.com/tiles/"
    #expect(try Self.claims("https://example.com/tiles", base: base))
    #expect(try Self.claims("https://example.com/tiles/v1/zones/1/2/3", base: base))
    #expect(try !Self.claims("https://example.com/tiles-private/v1/zones", base: base))
    #expect(try !Self.claims("https://example.com/anything-else", base: base))
    #expect(try Self.claims("http://localhost:8080/v1/zones/1/2/3", base: "http://localhost:8080"))
    #expect(try !Self.claims("http://localhost:8081/v1/zones/1/2/3", base: "http://localhost:8080"))
    #expect(try Self.claims("http://[::1]:8080/v1/zones", base: "http://[::1]:8080"))
    #expect(try !Self.claims("http://[::1]:8081/v1/zones", base: "http://[::1]:8080"))
  }
}
