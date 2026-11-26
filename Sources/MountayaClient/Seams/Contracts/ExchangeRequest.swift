import Foundation

/// ExchangeRequest is one attempt as it leaves the client: every header it carries is already
/// written, the credential's among them.
public struct ExchangeRequest: Sendable, Hashable {
  /// method is the HTTP method, uppercase.
  public var method: String
  /// url is the whole address, the query included.
  public var url: URL
  /// headers is every header the attempt carries, each name in the spelling the client writes.
  public var headers: [String: String]
  /// body is what the attempt carries, or nil where it carries nothing.
  public var body: Data?

  /// Creates an attempt, such as a test's own.
  public init(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) {
    self.method = method
    self.url = url
    self.headers = headers
    self.body = body
  }

  /// header returns the value of a header, its name read in any letter case, or nil where the
  /// attempt carries none.
  public func header(_ name: String) -> String? {
    HeaderLookup.value(of: name, in: headers)
  }
}

/// An attempt prints its method and its address alone, however it is printed: in a string, in a
/// debugger's description, or through `dump`. Its headers carry the credential, and an attempt is
/// what an exchange that wraps `SystemExchange` to trace every request is most likely to log.
extension ExchangeRequest: CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{
  /// description is the attempt as a log may show it, `ExchangeRequest(GET https://…)`.
  public var description: String {
    "ExchangeRequest(\(method) \(url.absoluteString))"
  }

  /// debugDescription is the same text, so a debugger shows no more than a log.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` and a debugger's variable view print the
  /// description rather than the headers.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
