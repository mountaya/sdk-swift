import Foundation
import Network

extension SessionServer {
  /// listen serves the server on `127.0.0.1` at `port`, the loopback address alone, so nothing
  /// beyond this machine reaches it, and answers once it listens; port 0 asks the system for a free
  /// one, which a test reads off the listener. It throws where the port cannot be listened on, one
  /// another program holds among the causes.
  public func listen(port: UInt16 = SessionServer.port) async throws -> SessionListener {
    let parameters = NWParameters.tcp
    parameters.allowLocalEndpointReuse = true
    parameters.requiredLocalEndpoint = .hostPort(
      host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port) ?? .any)
    let listener = try NWListener(using: parameters)
    // Network.framework tells a listener's states and a connection's bytes on a dispatch queue it
    // is handed and on nothing else, so the server makes one, serial, for both (SPEC.md section 7).
    let queue = DispatchQueue(label: "trail-session")
    let (states, told) = AsyncStream.makeStream(of: NWListener.State.self)
    listener.stateUpdateHandler = { state in told.yield(state) }
    listener.newConnectionHandler = { [self] connection in
      connection.start(queue: queue)
      read(connection, received: Data())
    }
    listener.start(queue: queue)
    for await state in states {
      switch state {
      case .ready:
        told.finish()
        return SessionListener(listener: listener, port: listener.port?.rawValue ?? port)
      case .failed(let error), .waiting(let error):
        told.finish()
        listener.cancel()
        throw error
      case .cancelled:
        told.finish()
        throw CancellationError()
      default:
        continue
      }
    }
    throw CancellationError()
  }

  /// read reads a request off `connection` until its head and the body it announces have arrived,
  /// then answers it and closes the connection. A request that never completes, or one past
  /// `largest`, is answered 400 or 413.
  private func read(_ connection: NWConnection, received: Data) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) {
      [self] content, _, isComplete, error in
      var received = received
      if let content {
        received.append(content)
      }
      switch HTTPRequest.read(received) {
      case .complete(let request):
        Task {
          let answer = await answer(method: request.method, path: request.path)
          send(answer, on: connection)
        }
      case .incomplete where received.count > HTTPRequest.largest:
        send(
          .error(413, saying: "A request to the session server is a few lines at most."),
          on: connection)
      case .incomplete where !isComplete && error == nil:
        read(connection, received: received)
      case .incomplete, .malformed:
        send(
          .error(400, saying: "The session server reads HTTP/1.1 requests alone."), on: connection)
      }
    }
  }

  private func send(_ answer: SessionAnswer, on connection: NWConnection) {
    connection.send(
      content: answer.http, contentContext: .finalMessage, isComplete: true,
      completion: .contentProcessed { _ in connection.cancel() })
  }
}

/// SessionListener is the session server listening on the loopback address, until `cancel()`.
public struct SessionListener: Sendable {
  private let listener: NWListener

  /// port is the port it listens on.
  public let port: UInt16

  init(listener: NWListener, port: UInt16) {
    self.listener = listener
    self.port = port
  }

  /// cancel stops listening; a request being answered is answered.
  public func cancel() {
    listener.cancel()
  }
}

/// HTTPRequest is what the server reads of a request: its method and its target's path.
struct HTTPRequest: Equatable {
  let method: String
  let path: String

  /// largest is the most a request may hold, head and body: the app's posts an empty body or `{}`.
  static let largest = 65_536

  /// Read is how far a request has arrived.
  enum Read: Equatable {
    case complete(HTTPRequest)
    case incomplete
    case malformed
  }

  /// read reads `data`, the bytes received so far: complete once the head and the body its
  /// `Content-Length` announces have arrived.
  static func read(_ data: Data) -> Read {
    let separator = Data("\r\n\r\n".utf8)
    guard let end = data.range(of: separator) else { return .incomplete }
    guard let head = String(data: data[..<end.lowerBound], encoding: .utf8) else {
      return .malformed
    }
    let lines = head.components(separatedBy: "\r\n")
    let parts = lines.first?.split(separator: " ", omittingEmptySubsequences: true) ?? []
    guard parts.count == 3, parts[2].hasPrefix("HTTP/1.") else { return .malformed }
    var length = 0
    for line in lines.dropFirst() {
      let field = line.split(separator: ":", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      if field.count == 2, field[0].lowercased() == "content-length" {
        guard let stated = Int(field[1]), stated >= 0 else { return .malformed }
        length = stated
      }
    }
    guard data.count - end.upperBound >= length else { return .incomplete }
    return .complete(HTTPRequest(method: String(parts[0]), path: String(parts[1])))
  }
}
