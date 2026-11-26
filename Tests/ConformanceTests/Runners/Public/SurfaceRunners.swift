import Foundation
import GateSupport
import MountayaClient

extension PublicRunners {
  /// baseUrls answers with the origin a request on the case's surface goes to, from a client
  /// built with the case's `overrides`, each one moving its own surface and no other, or with the
  /// class the client is refused with as it is built, which an override with no scheme is.
  static let baseUrls = Runner(id: "transport.base-urls", table: .public) { _, fixtureCase in
    let overrides = fixtureCase.input["overrides"] ?? .object([])
    guard let members = overrides.members else {
      throw FixtureError(description: "the input's `overrides` is not an object")
    }
    var urls = BaseURLs()
    for member in members {
      guard let text = member.value.stringValue, let url = URL(string: text) else {
        throw FixtureError(description: "the override for `\(member.key)` is not a URL")
      }
      switch member.key {
      case "data": urls.data = url
      case "rest": urls.rest = url
      case "tiles": urls.tiles = url
      case let other: throw FixtureError(description: "no surface is called `\(other)`")
      }
    }
    let client: Mountaya
    do throws(MountayaError) {
      client = try HeldSeams.client(
        credential: .publishable(key: "pk_test_abc"), baseUrls: urls,
        exchange: MapFixtures.Recording(answer: .failing))
    } catch {
      return .refused(error.name)
    }
    let url: URL
    switch try fixtureCase.input.string(at: "surface") {
    case "data": url = client.baseUrls.data
    case "rest": url = client.baseUrls.rest
    case "tiles": url = client.baseUrls.tiles
    case let other: throw FixtureError(description: "no surface is called `\(other)`")
    }
    return .value(.string(url.absoluteString))
  }
}
