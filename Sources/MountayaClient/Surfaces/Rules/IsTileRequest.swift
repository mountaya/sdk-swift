import Foundation

/// isTileRequest tells whether `url` is a request to the Tile API that `tiles` reaches: an `http`
/// or `https` URL of the same origin, its scheme and host read without regard to case and its port
/// with the scheme's default filled in, with no user and no password in it, whose path, its dot
/// segments resolved, is the base URL's own path or lies under it at a segment boundary.
///
/// So under the default base, `https://tiles.mountaya.com/v1/zones/12/2093/1425` is one, and
/// `https://tiles.mountaya.com.example.net/v1/zones` is not; under `https://example.com/tiles`,
/// `https://example.com/tiles/v1/zones` is one, and `https://example.com/tiles-private` is not. A
/// trailing slash on the base is nothing. It is how a map's request hook sends a credential to the
/// Tile API and to no other host a style names (`sdk/SPEC.md` §1).
func isTileRequest(_ url: URL, tiles: URL) -> Bool {
  guard
    let request = URLComponents(url: url.standardized, resolvingAgainstBaseURL: true),
    let base = URLComponents(url: tiles.standardized, resolvingAgainstBaseURL: true),
    let scheme = request.scheme?.lowercased(), scheme == "http" || scheme == "https",
    base.scheme?.lowercased() == scheme,
    request.user == nil, request.password == nil,
    let host = request.percentEncodedHost?.lowercased(), !host.isEmpty,
    host == base.percentEncodedHost?.lowercased(),
    portOf(request, scheme: scheme) == portOf(base, scheme: scheme)
  else { return false }
  var basePath = Substring(base.percentEncodedPath)
  while basePath.last == "/" {
    basePath.removeLast()
  }
  // A percent-encoded path is ASCII, compared byte for byte.
  let path = request.percentEncodedPath.utf8
  return basePath.isEmpty || path.elementsEqual(basePath.utf8)
    || path.starts(with: (basePath + "/").utf8)
}

/// portOf is the port a URL reaches, its scheme's default where it names none.
private func portOf(_ components: URLComponents, scheme: String) -> Int {
  components.port ?? (scheme == "https" ? 443 : 80)
}
