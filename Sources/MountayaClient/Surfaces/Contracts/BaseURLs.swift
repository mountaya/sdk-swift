import Foundation

/// BaseURLs is where the client sends each surface's requests.
///
/// Each surface has its own origin, and each is overridden on its own: pointing the Data API at
/// a proxy leaves the REST API and the tiles where they were. Each is an absolute address: a
/// client is refused one with no scheme as it is built, since an address relative to a page is a
/// browser's alone, and an app or a server has no page to read it against.
public struct BaseURLs: Sendable, Hashable {
  /// standard is the origins Mountaya serves its public surfaces from.
  public static let standard = BaseURLs(
    data: origin("https://data.mountaya.com"),
    rest: origin("https://api.mountaya.com"),
    tiles: origin("https://tiles.mountaya.com")
  )

  /// data is the Data API's origin.
  public var data: URL
  /// rest is the REST API's origin.
  public var rest: URL
  /// tiles is the Tile API's origin.
  public var tiles: URL

  /// Creates a set of origins, each one left out being Mountaya's own.
  public init(
    data: URL = BaseURLs.standard.data,
    rest: URL = BaseURLs.standard.rest,
    tiles: URL = BaseURLs.standard.tiles
  ) {
    self.data = data
    self.rest = rest
    self.tiles = tiles
  }

  /// check refuses, with `ConfigurationError`, a base URL with no scheme, a path a page would read
  /// against its own origin or a host alone, which names no place where there is no page
  /// (`sdk/SPEC.md` §1). The Data API's is checked first, then the REST API's, then the tiles'.
  func check() throws(MountayaError) {
    let surfaces = [("Data API", data), ("REST API", rest), ("Tile API", tiles)]
    for (surface, url) in surfaces where (url.scheme ?? "").isEmpty {
      throw .configuration(
        ConfigurationError(
          message:
            "The \(surface)'s base URL `\(url.relativeString)` names no scheme: give an absolute "
            + "address, such as `https://\(surface == "Tile API" ? "tiles" : "api").example.com`, "
            + "since an address relative to a page is a browser's alone."
        )
      )
    }
  }

  private static func origin(_ text: String) -> URL {
    guard let url = URL(string: text) else {
      preconditionFailure("`\(text)` is not a URL")
    }
    return url
  }
}
