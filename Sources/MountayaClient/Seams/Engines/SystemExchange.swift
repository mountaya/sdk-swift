import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// SystemExchange sends every attempt through `URLSession`, and is the exchange a client is
/// built with where it is given none.
///
/// It moves bytes and decides nothing. Its session holds no cookie, no cached answer and no
/// HTTP credential, so nothing the platform keeps rides a request; it follows no redirect, and a
/// `3xx` is answered as it arrived; and the platform's own timeouts are set out of the way, so the
/// client's deadlines are the only ones an attempt has. A body arrives a chunk at a time as the
/// platform reads it, an event stream's included, and a body nobody reads to its end any longer
/// is let go, its connection with it.
///
/// The platform writes the headers that carry the request itself, `Host`, `Content-Length`,
/// `Accept-Encoding`, whose coding it undoes, and `User-Agent`. It never writes a language: the
/// client's every request names one, `*` where the client is given none, since the platform would
/// otherwise send the device's languages, or the process's locale on Linux.
///
/// Every exchange built with `init()` shares one session, so every client of a process shares
/// its connections. Wrapping one in an exchange of its own is how a consumer watches its
/// traffic, since the client itself records nothing.
public struct SystemExchange: HTTPExchange {
  let loader: Loader

  /// Creates the exchange, over the one session every client of the process shares.
  public init() {
    loader = Loader.shared
  }

  /// Creates an exchange over a session of its own, built from `configuration` with this
  /// exchange's rules written over it, such as a test's own protocol classes.
  init(configuration: URLSessionConfiguration) {
    loader = Loader(configuration: configuration)
  }

  /// send sends one attempt and returns its answer as soon as its status and headers have
  /// arrived, its body following as it is read.
  ///
  /// It throws the platform's error for a request that never arrived, and `CancellationError`
  /// once the calling task is cancelled, the platform's `URLError(.cancelled)` included.
  public func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
    try await loader.send(Self.urlRequest(for: request))
  }

  /// idleAllowance is how long the platform lets an attempt sit idle, or last, before it gives
  /// up on its own: a week, so that every budget the client holds runs out first.
  static let idleAllowance: TimeInterval = 7 * 24 * 60 * 60

  /// configured writes this exchange's rules over a session configuration: no cookie storage
  /// and cookies off, no cache, no stored HTTP credential, no wait for connectivity the client's
  /// own retries do not decide, and the platform's timeouts set out of the way.
  static func configured(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration {
    configuration.httpCookieStorage = nil
    configuration.httpCookieAcceptPolicy = .never
    configuration.httpShouldSetCookies = false
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCredentialStorage = nil
    #if !canImport(FoundationNetworking)
      // FoundationNetworking never waits for connectivity, and publishes no such setting.
      configuration.waitsForConnectivity = false
    #endif
    configuration.timeoutIntervalForRequest = idleAllowance
    configuration.timeoutIntervalForResource = idleAllowance
    return configuration
  }

  /// urlRequest writes an attempt as the platform sends it: the method, the address, every
  /// header the client wrote, the body, and cookie handling off.
  static func urlRequest(for request: ExchangeRequest) -> URLRequest {
    var urlRequest = URLRequest(
      url: request.url,
      cachePolicy: .reloadIgnoringLocalCacheData,
      timeoutInterval: idleAllowance
    )
    urlRequest.httpMethod = request.method
    for (name, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: name)
    }
    urlRequest.httpBody = request.body
    urlRequest.httpShouldHandleCookies = false
    return urlRequest
  }

  /// reading is the error a platform failure stands for: `CancellationError` for a task the
  /// platform reports cancelled, and the failure as it is otherwise.
  static func reading(_ error: any Error) -> any Error {
    if let urlError = error as? URLError, urlError.code == .cancelled {
      return CancellationError()
    }
    let reported = error as NSError
    if reported.domain == NSURLErrorDomain, reported.code == NSURLErrorCancelled {
      return CancellationError()
    }
    return error
  }
}

extension SystemExchange {
  /// Loader is one session and the deliveries of its tasks. It is Sendable: its stored properties
  /// are constants of Sendable types.
  final class Loader: Sendable {
    static let shared = Loader(configuration: .ephemeral)

    let session: URLSession
    let deliveries: Deliveries

    init(configuration: URLSessionConfiguration) {
      let deliveries = Deliveries()
      self.deliveries = deliveries
      session = URLSession(
        configuration: SystemExchange.configured(configuration),
        delegate: deliveries,
        delegateQueue: nil
      )
    }

    deinit {
      // A session holds its delegate until it is invalidated. The tasks a body still reads run
      // to their end first.
      session.finishTasksAndInvalidate()
    }

    func send(_ request: URLRequest) async throws -> ExchangeResponse {
      try Task.checkCancellation()
      let task = session.dataTask(with: request)
      let (chunks, continuation) = AsyncThrowingStream<Data, any Error>.makeStream()
      continuation.onTermination = { termination in
        if case .cancelled = termination {
          task.cancel()
        }
      }
      let head = try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (head: CheckedContinuation<Head, any Error>) in
          deliveries.register(task, delivery: Delivery(head: head, chunks: continuation))
          task.resume()
        }
      } onCancel: {
        task.cancel()
      }
      let hold = Hold(task)
      return ExchangeResponse(
        status: head.status,
        headers: head.headers,
        body: ExchangeBody {
          // The body holds the task: once nothing reads it, the task is cancelled.
          try await hold.next(from: chunks)
        }
      )
    }
  }

  /// Head is the status and the headers of an answer.
  struct Head: Sendable {
    let status: Int
    let headers: [String: String]
  }

  /// Delivery is what one task's answer is handed to: its head once, then its chunks.
  struct Delivery: Sendable {
    var head: CheckedContinuation<Head, any Error>?
    let chunks: AsyncThrowingStream<Data, any Error>.Continuation
  }

  /// Hold keeps a task while its body is read, and cancels it once nothing holds the body. It is
  /// Sendable: it holds one constant, the task.
  final class Hold: Sendable {
    let task: URLSessionDataTask

    init(_ task: URLSessionDataTask) {
      self.task = task
    }

    deinit {
      task.cancel()
    }

    func next(from chunks: AsyncThrowingStream<Data, any Error>) async throws -> Data? {
      var iterator = chunks.makeAsyncIterator()
      if let chunk = try await iterator.next() {
        return chunk
      }
      try Task.checkCancellation()
      return nil
    }
  }

  /// Deliveries is the session's delegate: it hands each task's answer to the call that sent it,
  /// and follows no redirect. It is Sendable: its pending deliveries sit behind a lock, since the
  /// session calls it on threads of its own.
  final class Deliveries: NSObject, URLSessionDataDelegate, Sendable {
    private let pending = Locked<[Int: Delivery]>([:])

    func register(_ task: URLSessionTask, delivery: Delivery) {
      let identifier = task.taskIdentifier
      pending.withLock { $0[identifier] = delivery }
    }

    /// count is how many tasks are still being delivered.
    var count: Int {
      pending.withLock { $0.count }
    }

    func urlSession(
      _ session: URLSession,
      dataTask: URLSessionDataTask,
      didReceive response: URLResponse,
      completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
      let identifier = dataTask.taskIdentifier
      let head = pending.withLock { pending in
        let head = pending[identifier]?.head
        pending[identifier]?.head = nil
        return head
      }
      guard let http = response as? HTTPURLResponse else {
        head?.resume(throwing: URLError(.badServerResponse))
        completionHandler(.cancel)
        return
      }
      var headers: [String: String] = [:]
      for (name, value) in http.allHeaderFields {
        if let name = name as? String, let value = value as? String {
          headers[name] = value
        }
      }
      head?.resume(returning: Head(status: http.statusCode, headers: headers))
      completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
      let identifier = dataTask.taskIdentifier
      let chunks = pending.withLock { $0[identifier]?.chunks }
      chunks?.yield(data)
    }

    func urlSession(
      _ session: URLSession,
      task: URLSessionTask,
      didCompleteWithError error: (any Error)?
    ) {
      let identifier = task.taskIdentifier
      guard let delivery = pending.withLock({ $0.removeValue(forKey: identifier) }) else {
        return
      }
      if let error {
        let failure = SystemExchange.reading(error)
        delivery.head?.resume(throwing: failure)
        delivery.chunks.finish(throwing: failure)
      } else {
        delivery.head?.resume(throwing: URLError(.badServerResponse))
        delivery.chunks.finish()
      }
    }

    func urlSession(
      _ session: URLSession,
      task: URLSessionTask,
      willPerformHTTPRedirection response: HTTPURLResponse,
      newRequest request: URLRequest,
      completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
      // A redirect is answered as it arrived: the client reads a `3xx` as the error it is.
      completionHandler(nil)
    }
  }
}
