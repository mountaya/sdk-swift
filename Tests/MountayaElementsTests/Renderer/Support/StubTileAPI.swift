import Foundation
import MapLibre
import UIKit
import os

/// StubTileAPI is the Tile API and another tile host, as MapLibre's own loader reaches them in
/// these tests: a stub of each served through MapLibre's network configuration, which records every
/// request it is sent, so no test reaches the network and each reads what a request carried.
///
/// `https://tiles.example.test` is the Tile API the tests' clients name, and
/// `https://elsewhere.example.test` a host a style names that is not Mountaya's. The base map's
/// style is served at `StubTileAPI.styleUrl`, and at any other address ending in `/style`, its own
/// tiles under the directory it is served from; every tile is answered with no content, but
/// anything under `/refused/`, a style included, which is refused a 402, as is every tile under
/// `/closed/`, a style there served. Anything under `/missing/`, a style included, is not found, a
/// 404, and anything under `/broken/` fails, a 500. Anything under `/session/` is refused a 401
/// where the request carries no `X-Session-Token`, as an organization that requires a session
/// refuses the key alone, and anything under `/revoked/` is refused a 401 whatever it carries.
/// Anything of the Tile API under `/moved/` is redirected to the same path on the other host, and
/// anything under `/bounce/` to the Tile API's own path with `/landed/` in its place, each carrying
/// every header the request carried, as the loading system carries them across a redirect, and
/// answered there by the rules above.
public final class StubTileAPI: URLProtocol {
  /// tiles is the Tile API's origin the tests' clients reach.
  public static let tiles = URL(string: "https://tiles.example.test")
  /// styleUrl is the base map's style document, on the Tile API.
  public static let styleUrl = URL(
    string: "https://tiles.example.test/v1/terrains/outdoor/light/style")

  private static let seen = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])

  /// style is the base map: a background, a fill and a label of its own vector tiles on the Tile
  /// API, and a raster of another host's tiles.
  public static let style = #"""
    {"version": 8, "name": "stub",
     "sources": {
       "base": {"type": "vector", "tiles": ["https://tiles.example.test/v1/terrains/outdoor/light/{z}/{x}/{y}"], "minzoom": 0, "maxzoom": 14},
       "elsewhere": {"type": "raster", "tiles": ["https://elsewhere.example.test/{z}/{x}/{y}.png"], "tileSize": 256, "attribution": "<a href=\"https://elsewhere.example.test/\" target=\"_blank\">&copy; Elsewhere</a>"}
     },
     "layers": [
       {"id": "base-background", "type": "background", "paint": {"background-color": "#ffffff"}},
       {"id": "base-elsewhere", "type": "raster", "source": "elsewhere"},
       {"id": "base-water", "type": "fill", "source": "base", "source-layer": "water", "paint": {"fill-color": "#0000ff"}},
       {"id": "base-labels", "type": "symbol", "source": "base", "source-layer": "place", "layout": {"text-field": ["get", "name"]}}
     ]}
    """#

  /// installed hands MapLibre the stub before its first map, once for the process.
  @MainActor
  public static let installed: Void = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubTileAPI.self] + (configuration.protocolClasses ?? [])
    MLNNetworkConfiguration.sharedManager.sessionConfiguration = configuration
  }()

  /// requests is every request the stub was sent, in order.
  public static var requests: [URLRequest] {
    seen.withLock { $0 }
  }

  /// requests returns every request the stub was sent to `host`.
  public static func requests(to host: String) -> [URLRequest] {
    requests.filter { $0.url?.host == host }
  }

  /// canInit claims every request MapLibre makes, so none reaches the network: one to a host of
  /// neither stub fails at once, as an offline one does, its failure naming the address it failed
  /// at as the loading system's own does, and is recorded with the rest.
  public override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  /// canonicalRequest answers `request` as it is, since the stub tells no two requests alike.
  public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  /// startLoading records the request and answers it by the stub's rules: a host of neither stub
  /// fails at once, a request the Tile API moves is redirected, and every other is answered its
  /// status, a style with its document.
  public override func startLoading() {
    let sent = request
    Self.seen.withLock { $0.append(sent) }
    guard let url = sent.url, url.host?.hasSuffix("example.test") ?? false else {
      let failing: [String: Any] =
        sent.url.map {
          [NSURLErrorFailingURLErrorKey: $0, NSURLErrorFailingURLStringErrorKey: $0.absoluteString]
        } ?? [:]
      client?.urlProtocol(
        self, didFailWithError: URLError(.notConnectedToInternet, userInfo: failing))
      return
    }
    if let moved = Self.redirect(of: url),
      let redirect = HTTPURLResponse(
        url: url, statusCode: 302, httpVersion: "HTTP/1.1",
        headerFields: ["Location": moved.absoluteString])
    {
      var next = sent
      next.url = moved
      client?.urlProtocol(self, wasRedirectedTo: next, redirectResponse: redirect)
      return
    }
    let isStyle = url.path.hasSuffix("/style")
    let status = Self.status(of: sent, at: url, isStyle: isStyle)
    let response = HTTPURLResponse(
      url: url, statusCode: status, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": isStyle ? "application/json" : "application/x-protobuf"])
    if let response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    if isStyle, status == 200 {
      client?.urlProtocol(self, didLoad: Data(Self.styleDocument(servedAt: url).utf8))
    }
    client?.urlProtocolDidFinishLoading(self)
  }

  /// redirect is where the stub sends a request of the Tile API to `url` on: under `/moved/`, the
  /// same path on the other host, under `/bounce/`, the Tile API's own path with `/landed/` in its
  /// place, and nowhere for any other address.
  private static func redirect(of url: URL) -> URL? {
    guard url.host == "tiles.example.test" else { return nil }
    if url.path.contains("/moved/") {
      return URL(string: "https://elsewhere.example.test\(url.path)")
    }
    if url.path.contains("/bounce/") {
      let landed = url.path.replacingOccurrences(of: "/bounce/", with: "/landed/")
      return URL(string: "https://tiles.example.test\(landed)")
    }
    return nil
  }

  /// status is what the stub answers `sent`, a request to `url`: nothing under `/missing/` is
  /// found, and anything under `/broken/` fails; anything under `/revoked/`, and anything under
  /// `/session/` carrying no session token, is refused its credential; anything under `/refused/`
  /// is refused for want of an entitlement, as the Tile API refuses one, and so is every tile under
  /// `/closed/`; a style is served, and a tile answered with no content.
  private static func status(of sent: URLRequest, at url: URL, isStyle: Bool) -> Int {
    let path = url.path
    if path.contains("/missing/") {
      return 404
    }
    if path.contains("/broken/") {
      return 500
    }
    if path.contains("/revoked/")
      || (path.contains("/session/") && sent.value(forHTTPHeaderField: "X-Session-Token") == nil)
    {
      return 401
    }
    if path.contains("/refused/") || (path.contains("/closed/") && !isStyle) {
      return 402
    }
    return isStyle ? 200 : 204
  }

  /// styleDocument is the base map's style as it is served at `url`: its own tiles under the
  /// directory the style is served from.
  private static func styleDocument(servedAt url: URL) -> String {
    guard let directory = url.absoluteString.split(separator: "?").first,
      let slash = directory.lastIndex(of: "/")
    else { return style }
    return style.replacingOccurrences(
      of: "https://tiles.example.test/v1/terrains/outdoor/light/",
      with: String(directory[...slash]))
  }

  /// stopLoading does nothing: every answer is sent whole as loading starts.
  public override func stopLoading() {}
}

/// MapWindow is a window a map is drawn in, as an app shows one, on the scene the test runs in.
@MainActor
public enum MapWindow {
  /// showing returns a window showing `view`, kept for as long as the window is held.
  public static func showing(_ view: UIView) -> UIWindow {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    let window =
      scene.map { UIWindow(windowScene: $0) }
      ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    view.frame = window.bounds
    window.addSubview(view)
    window.isHidden = false
    return window
  }

  /// until waits on the main actor until `condition` holds, for at most `seconds`, and tells
  /// whether it did.
  public static func until(_ seconds: Double = 20, condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + .seconds(seconds)
    while ContinuousClock.now < deadline {
      if condition() {
        return true
      }
      try? await Task.sleep(for: .milliseconds(20))
    }
    return condition()
  }
}
