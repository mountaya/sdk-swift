import Foundation
import MountayaGeo

/// MapRequest is a request a map's renderer makes for itself, for its style, a tile, a sprite or a
/// glyph, as an app's own hook reads and rewrites it before the client's credential is attached:
/// the URL it goes to and the headers it carries.
///
/// A header's name is read without regard to case where the request is sent, so a name the hook
/// writes in another case is the same header. Two requests are equal where they go to the same URL
/// and carry the same headers, each name and value by its scalars.
public struct MapRequest: Sendable, Equatable {
  /// url is where the request goes.
  public var url: URL
  /// headers is every header the request carries, by name.
  public var headers: [String: String]

  /// Creates a request to `url` carrying `headers`.
  public init(url: URL, headers: [String: String] = [:]) {
    self.url = url
    self.headers = headers
  }

  /// Two requests are equal where their URLs and their headers are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.url == rhs.url && lhs.headers.count == rhs.headers.count
      && lhs.headers.allSatisfy { name, value in
        rhs.headers.contains { sameText($0.key, name) && sameText($0.value, value) }
      }
  }
}

extension MapRequest: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
  /// description is the request as a log may show it, `MapRequest(https://…, headers=[X-API-Key])`:
  /// its URL and the names of its headers, never a value, since the client's key and session token
  /// ride there.
  public var description: String {
    "MapRequest(\(url.absoluteString), headers=[\(headers.keys.sorted().joined(separator: ", "))])"
  }

  /// debugDescription is the same text, so a debugger shows no more than a log.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` and a debugger's variable view print the description
  /// rather than the headers' values.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
