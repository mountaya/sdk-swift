import Foundation
import Testing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import MountayaClient

/// StubLoading answers the requests of a test's `URLSession` by the script of their host, so the
/// platform's own loader runs under a test, on macOS and on Linux, with no network.
///
/// Each test takes a host of its own, `<uuid>.stub.test`, which is what lets the suites run in
/// parallel through one registry.
final class StubLoading: URLProtocol {
  /// Script is how one request is answered.
  enum Script: Sendable {
    /// answer sends a status, headers and the chunks of a body, then ends as `ending` says.
    case answer(
      Int, headers: [String: String] = [:], chunks: [String] = [], ending: Ending = .finishes)
    /// redirect answers a `3xx` pointing elsewhere, which the loader asks its delegate about.
    case redirect(Int, location: String)
    /// fail is a request that never arrived.
    case fail(URLError)
    /// silent is a request nothing ever answers.
    case silent
  }

  /// Ending is how a body ends once its chunks are sent.
  enum Ending: Sendable {
    case finishes
    case staysOpen
    case breaksOff(URLError)
  }

  /// Seen is one request as the loader handed it over.
  struct Seen: Sendable {
    let method: String
    let url: URL?
    let headers: [String: String]
    let body: Data?
    let handlesCookies: Bool

    /// header returns a header's value, its name read in any letter case.
    func header(_ name: String) -> String? {
      HeaderLookup.value(of: name, in: headers)
    }
  }

  /// Stage is one host's script, what it has seen and how many loads were stopped.
  private struct Stage: Sendable {
    var scripts: [Script]
    var seen: [Seen] = []
    var stops = 0
  }

  private static let stages = Locked<[String: Stage]>([:])

  /// host returns a host of its own, whose requests are answered by `scripts` in turn and by
  /// `.silent` once they run out.
  static func host(_ scripts: [Script]) -> String {
    let host = "\(UUID().uuidString.lowercased()).stub.test"
    stages.withLock { $0[host] = Stage(scripts: scripts) }
    return host
  }

  /// url returns an address under a host.
  static func url(_ host: String, path: String = "/") throws -> URL {
    try #require(URL(string: "https://\(host)\(path)"))
  }

  /// seen is every request a host has been sent, in order.
  static func seen(_ host: String) -> [Seen] {
    stages.withLock { $0[host]?.seen ?? [] }
  }

  /// stops is how many of a host's loads the loader has stopped.
  static func stops(_ host: String) -> Int {
    stages.withLock { $0[host]?.stops ?? 0 }
  }

  /// configuration is a session configuration whose requests this stub answers.
  static func configuration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubLoading.self]
    return configuration
  }

  /// exchange is the platform's exchange over a session this stub answers.
  static func exchange() -> SystemExchange {
    SystemExchange(configuration: configuration())
  }

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host?.hasSuffix(".stub.test") == true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let url = request.url, let host = url.host else { return }
    let seen = Seen(
      method: request.httpMethod ?? "GET",
      url: url,
      headers: request.allHTTPHeaderFields ?? [:],
      body: Self.body(of: request),
      handlesCookies: request.httpShouldHandleCookies
    )
    let script = Self.stages.withLock { stages -> Script in
      stages[host]?.seen.append(seen)
      guard let next = stages[host]?.scripts.first else { return .silent }
      stages[host]?.scripts.removeFirst()
      return next
    }
    switch script {
    case .answer(let status, let headers, let chunks, let ending):
      // Apple's loader holds back the head of an answer that names no content type until it has
      // read enough to guess one, as the API's answers always name theirs.
      var named = headers
      if !HeaderLookup.contains("Content-Type", in: named) {
        named["Content-Type"] = "application/json"
      }
      guard
        let response = HTTPURLResponse(
          url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: named)
      else { return }
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      for chunk in chunks {
        client?.urlProtocol(self, didLoad: Data(chunk.utf8))
      }
      switch ending {
      case .finishes: client?.urlProtocolDidFinishLoading(self)
      case .staysOpen: break
      case .breaksOff(let failure): client?.urlProtocol(self, didFailWithError: failure)
      }
    case .redirect(let status, let location):
      guard
        let response = HTTPURLResponse(
          url: url, statusCode: status, httpVersion: "HTTP/1.1",
          headerFields: ["Location": location]),
        let target = URL(string: location, relativeTo: url)
      else { return }
      #if !canImport(FoundationNetworking)
        // FoundationNetworking traps on a protocol that redirects, so only Apple's loader is
        // asked; the delegate's answer is held on every host by calling it directly.
        client?.urlProtocol(
          self, wasRedirectedTo: URLRequest(url: target), redirectResponse: response)
      #endif
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocolDidFinishLoading(self)
    case .fail(let failure):
      client?.urlProtocol(self, didFailWithError: failure)
    case .silent:
      break
    }
  }

  override func stopLoading() {
    guard let host = request.url?.host else { return }
    Self.stages.withLock { $0[host]?.stops += 1 }
  }

  /// body reads a request's body, which Apple's loader hands a protocol as a stream.
  private static func body(of request: URLRequest) -> Data? {
    if let body = request.httpBody {
      return body
    }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }
    var bytes = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      guard count > 0 else { break }
      bytes.append(contentsOf: buffer[..<count])
    }
    return bytes
  }
}

/// eventually waits until `condition` holds, for up to five seconds of the host's own time, and
/// answers whether it came to hold.
func eventually(_ condition: @Sendable () -> Bool) async throws -> Bool {
  for _ in 0..<500 {
    if condition() {
      return true
    }
    try await Task.sleep(for: .milliseconds(10))
  }
  return condition()
}
