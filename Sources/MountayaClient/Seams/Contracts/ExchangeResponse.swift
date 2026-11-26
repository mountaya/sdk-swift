/// ExchangeResponse is the answer to one attempt: its status and headers as soon as they have
/// arrived, and its body as it is read.
public struct ExchangeResponse: Sendable {
  /// status is the HTTP status.
  public var status: Int
  /// headers is every header of the answer. A header that arrived more than once holds its
  /// values joined by a comma and a space, as HTTP reads it.
  public var headers: [String: String]
  /// body is the answer's body, read as it arrives.
  public var body: ExchangeBody

  /// Creates an answer, such as a test's stand-in for one the API sent.
  public init(status: Int, headers: [String: String] = [:], body: ExchangeBody = ExchangeBody()) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  /// header returns the value of a header, its name read in any letter case, or nil where the
  /// answer sent none.
  public func header(_ name: String) -> String? {
    HeaderLookup.value(of: name, in: headers)
  }
}

/// An answer prints its status alone, however it is printed, as an attempt prints no header: a
/// header of the answer may carry what a log should not hold.
extension ExchangeResponse: CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{
  /// description is the answer as a log may show it, `ExchangeResponse(200)`.
  public var description: String {
    "ExchangeResponse(\(status))"
  }

  /// debugDescription is the same text, so a debugger shows no more than a log.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` and a debugger's variable view print the
  /// description rather than the headers and the body.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
