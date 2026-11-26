import Foundation
import Testing

@testable import MountayaClient

@Suite("BaseURLs")
struct BaseURLsTests {
  @Test("each surface defaults to Mountaya's own origin")
  func defaultsToMountaya() {
    let urls = BaseURLs()

    #expect(urls.data.absoluteString == "https://data.mountaya.com")
    #expect(urls.rest.absoluteString == "https://api.mountaya.com")
    #expect(urls.tiles.absoluteString == "https://tiles.mountaya.com")
    #expect(urls == .standard)
  }

  @Test("overriding one surface leaves the others where they were")
  func overridesIndependently() throws {
    let proxy = try #require(URL(string: "https://proxy.example.com/mountaya"))

    let data = BaseURLs(data: proxy)
    let rest = BaseURLs(rest: proxy)
    let tiles = BaseURLs(tiles: proxy)

    #expect(data.data == proxy)
    #expect(data.rest == BaseURLs.standard.rest)
    #expect(data.tiles == BaseURLs.standard.tiles)
    #expect(rest.rest == proxy)
    #expect(rest.data == BaseURLs.standard.data)
    #expect(tiles.tiles == proxy)
    #expect(tiles.data == BaseURLs.standard.data)
  }
}
