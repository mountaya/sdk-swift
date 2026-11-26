import Foundation

/// RequestAddress writes the address one request goes to: its surface's origin, the path, and
/// the query, each value percent-encoded.
enum RequestAddress {
  /// url returns the address of `path` under `origin` with `query`, or nil where it is no URL.
  ///
  /// An origin may carry a path of its own, such as a proxy's prefix, which the request's path
  /// follows. Only RFC 3986's unreserved characters stay as they are in a query name or value,
  /// so a `+`, a `&` or a `=` inside a value stays inside it.
  static func url(origin: URL, path: String, query: [QueryItem]) -> URL? {
    var text = origin.absoluteString
    while text.hasSuffix("/") {
      text.removeLast()
    }
    text += path.hasPrefix("/") ? path : "/" + path
    if !query.isEmpty {
      text += "?"
      text += query.map {
        OperationPath.segment($0.name) + "=" + OperationPath.segment($0.value)
      }.joined(separator: "&")
    }
    return URL(string: text)
  }
}
