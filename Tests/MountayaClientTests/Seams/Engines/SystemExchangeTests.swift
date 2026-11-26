import Foundation
import Testing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import MountayaClient

/// The platform's exchange, over `URLSession` with a stub answering its requests: what an
/// attempt carries out, what its answer carries back, and when the platform's task is let go.
@Suite("SystemExchange", .timeLimit(.minutes(1)))
struct SystemExchangeTests {
  @Test("an attempt leaves as the client wrote it, its language the client's alone")
  func attemptLeavesAsWritten() async throws {
    let host = StubLoading.host([.answer(200), .answer(200)])
    let exchange = StubLoading.exchange()
    let body = Data(#"{"name":"Tour du Mont Blanc"}"#.utf8)
    _ = try await exchange.send(
      ExchangeRequest(
        method: "POST",
        url: try StubLoading.url(host, path: "/v1/itineraries?limit=2"),
        headers: [
          "Accept": "application/json", "Content-Type": "application/json", "X-API-Key": "pk_a",
        ],
        body: body
      )
    )
    _ = try await exchange.send(
      ExchangeRequest(
        method: "GET",
        url: try StubLoading.url(host),
        headers: ["Accept-Language": "fr-CH, fr;q=0.9"]
      )
    )

    let seen = StubLoading.seen(host)
    try #require(seen.count == 2)
    #expect(seen[0].method == "POST")
    #expect(seen[0].url?.path == "/v1/itineraries")
    #expect(seen[0].url?.query == "limit=2")
    #expect(seen[0].header("accept") == "application/json")
    #expect(seen[0].header("content-type") == "application/json")
    #expect(seen[0].header("x-api-key") == "pk_a")
    #expect(seen[0].header("accept-language") == nil, "the exchange writes no language its own")
    #expect(seen[0].body == body)
    #expect(seen[1].method == "GET")
    #expect(seen[1].header("accept-language") == "fr-CH, fr;q=0.9")
    #expect(seen[1].body?.isEmpty != false)
  }

  /// `URL.path` and `URL.query` read decoded or normalised parts, so the address is compared as the
  /// text it is: a `%2F` inside a segment, UTF-8 bytes, an encoded comma, space and ampersand, and
  /// an empty value each reach the platform's loader exactly as the client encoded them.
  @Test("an address leaves exactly as the client encoded it")
  func addressAsEncoded() async throws {
    let host = StubLoading.host([.answer(204)])
    let target = "/v1/things/a%2Fb?q=caf%C3%A9&ids=1%2C2&tag=a%20b%26c&empty="
    let url = try #require(
      RequestAddress.url(
        origin: try StubLoading.url(host),
        path: OperationPath.substitute("/v1/things/{id}", with: ["id": "a/b"]),
        query: [
          QueryItem(name: "q", value: "café"), QueryItem(name: "ids", value: "1,2"),
          QueryItem(name: "tag", value: "a b&c"), QueryItem(name: "empty", value: ""),
        ]
      ))
    _ = try await StubLoading.exchange().send(ExchangeRequest(method: "GET", url: url))

    let seen = StubLoading.seen(host)
    try #require(seen.count == 1)
    #expect(url.absoluteString == "https://\(host)\(target)")
    #expect(seen[0].url?.absoluteString == "https://\(host)\(target)")
  }

  @Test("an answer arrives with its status and headers, and its body a chunk at a time")
  func answerArrives() async throws {
    let host = StubLoading.host([
      .answer(
        201,
        headers: ["Location": "/v1/itineraries/it", "X-Request-Id": "req_1"],
        chunks: ["{\"data\":", "{}}"]
      )
    ])
    let response = try await StubLoading.exchange().send(
      ExchangeRequest(method: "POST", url: try StubLoading.url(host)))

    #expect(response.status == 201)
    #expect(response.header("location") == "/v1/itineraries/it")
    #expect(response.header("x-request-id") == "req_1")
    #expect(try await response.body.collect() == Data(#"{"data":{}}"#.utf8))
  }

  @Test("no cookie is kept or sent, the one the client writes aside")
  func noAmbientCookie() async throws {
    let host = StubLoading.host([
      .answer(200, headers: ["Set-Cookie": "session=abc; Path=/"]), .answer(200), .answer(200),
    ])
    let exchange = StubLoading.exchange()
    let url = try StubLoading.url(host)
    _ = try await exchange.send(ExchangeRequest(method: "GET", url: url))
    _ = try await exchange.send(ExchangeRequest(method: "GET", url: url))
    _ = try await exchange.send(
      ExchangeRequest(method: "GET", url: url, headers: ["Cookie": "visitor=v1"]))

    let seen = StubLoading.seen(host)
    try #require(seen.count == 3)
    #expect(seen[1].header("cookie") == nil)
    #expect(seen[2].header("cookie") == "visitor=v1")
    #expect(seen.allSatisfy { !$0.handlesCookies })
  }

  @Test("the session keeps nothing for a request, and its own timeouts stand out of the way")
  func configuration() {
    let configuration = SystemExchange.configured(.ephemeral)

    #expect(configuration.httpCookieStorage == nil)
    #expect(configuration.httpCookieAcceptPolicy == .never)
    #expect(!configuration.httpShouldSetCookies)
    #expect(configuration.urlCache == nil)
    #expect(configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
    #expect(configuration.urlCredentialStorage == nil)
    #if !canImport(FoundationNetworking)
      #expect(!configuration.waitsForConnectivity)
    #endif
    #expect(configuration.timeoutIntervalForRequest == SystemExchange.idleAllowance)
    #expect(configuration.timeoutIntervalForResource == SystemExchange.idleAllowance)
    #expect(SystemExchange.idleAllowance >= 7 * 24 * 60 * 60)
  }

  @Test(
    "an attempt is written with cookies off, no cache and the platform's timeout out of the way")
  func urlRequest() throws {
    let request = SystemExchange.urlRequest(
      for: ExchangeRequest(
        method: "DELETE",
        url: try StubLoading.url("api.stub.test", path: "/v1/zones/zo"),
        headers: ["If-Match": "\"t1\"", "Accept-Language": "*"]
      )
    )

    #expect(request.httpMethod == "DELETE")
    #expect(!request.httpShouldHandleCookies)
    #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    #expect(request.timeoutInterval == SystemExchange.idleAllowance)
    #expect(request.value(forHTTPHeaderField: "If-Match") == "\"t1\"")
    #expect(request.value(forHTTPHeaderField: "Accept-Language") == "*")
    #expect(request.httpBody == nil)
  }

  @Test("a redirect is never followed")
  func redirectRefused() async throws {
    let session = URLSession(configuration: .ephemeral)
    let url = try StubLoading.url("api.stub.test")
    let task = session.dataTask(with: url)
    let response = try #require(
      HTTPURLResponse(
        url: url, statusCode: 307, httpVersion: "HTTP/1.1", headerFields: ["Location": "/b"]))
    let next = URLRequest(url: try StubLoading.url("api.stub.test", path: "/b"))
    let followed = await withCheckedContinuation { continuation in
      SystemExchange.Deliveries().urlSession(
        session,
        task: task,
        willPerformHTTPRedirection: response,
        newRequest: next
      ) { continuation.resume(returning: $0) }
    }
    session.invalidateAndCancel()

    #expect(followed == nil)
  }

  #if !canImport(FoundationNetworking)
    @Test("a redirect is answered as it arrived, and nothing is sent to where it points")
    func redirectAnswered() async throws {
      let host = StubLoading.host([.redirect(302, location: "/elsewhere"), .answer(200)])
      let response = try await StubLoading.exchange().send(
        ExchangeRequest(method: "GET", url: try StubLoading.url(host, path: "/v1/things")))

      #expect(response.status == 302)
      #expect(response.header("location") == "/elsewhere")
      #expect(StubLoading.seen(host).count == 1)
    }
  #endif

  @Test("a request that never arrived throws the platform's failure, and never a cancellation")
  func neverArrived() async throws {
    let host = StubLoading.host([
      .fail(URLError(.notConnectedToInternet)),
      .answer(200, chunks: ["{"], ending: .breaksOff(URLError(.networkConnectionLost))),
    ])
    let exchange = StubLoading.exchange()
    let url = try StubLoading.url(host)

    do {
      _ = try await exchange.send(ExchangeRequest(method: "GET", url: url))
      Issue.record("a request that never arrived answered")
    } catch {
      #expect(!(error is CancellationError))
      #expect((error as NSError).code == NSURLErrorNotConnectedToInternet)
    }
    // A body that breaks off at once may be reported before its head, so the failure is read
    // wherever it lands.
    do {
      let broken = try await exchange.send(ExchangeRequest(method: "GET", url: url))
      _ = try await broken.body.collect()
      Issue.record("a body that broke off ended")
    } catch {
      #expect(!(error is CancellationError))
      #expect((error as NSError).code == NSURLErrorNetworkConnectionLost)
    }
  }

  @Test("the platform's cancelled task is a CancellationError, at the answer and in the body")
  func platformCancellation() async throws {
    let host = StubLoading.host([
      .fail(URLError(.cancelled)),
      .answer(200, ending: .breaksOff(URLError(.cancelled))),
    ])
    let exchange = StubLoading.exchange()
    let url = try StubLoading.url(host)

    await #expect(throws: CancellationError.self) {
      _ = try await exchange.send(ExchangeRequest(method: "GET", url: url))
    }
    await #expect(throws: CancellationError.self) {
      let response = try await exchange.send(ExchangeRequest(method: "GET", url: url))
      _ = try await response.body.collect()
    }
    #expect(SystemExchange.reading(URLError(.cancelled)) is CancellationError)
    #expect(!(SystemExchange.reading(URLError(.timedOut)) is CancellationError))
  }

  @Test("a task cancelled before it sends sends nothing, and one cancelled waiting is let go")
  func cancelledWhileWaiting() async throws {
    let host = StubLoading.host([.silent])
    let exchange = StubLoading.exchange()
    let url = try StubLoading.url(host)

    let early = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try await exchange.send(ExchangeRequest(method: "GET", url: url))
    }
    await #expect(throws: CancellationError.self) { try await early.value }
    #expect(StubLoading.seen(host).isEmpty)

    let waiting = Task { try await exchange.send(ExchangeRequest(method: "GET", url: url)) }
    #expect(try await eventually { StubLoading.seen(host).count == 1 })
    waiting.cancel()

    await #expect(throws: CancellationError.self) { try await waiting.value }
    #expect(try await eventually { StubLoading.stops(host) == 1 })
    #expect(try await eventually { exchange.loader.deliveries.count == 0 })
  }

  @Test("a body read its task gives up throws CancellationError, and its stream is let go")
  func cancelledReading() async throws {
    let host = StubLoading.host([.answer(200, chunks: ["data: one\n\n"], ending: .staysOpen)])
    let exchange = StubLoading.exchange()
    let response = try await exchange.send(
      ExchangeRequest(method: "GET", url: try StubLoading.url(host)))

    #expect(try await response.body.next() == Data("data: one\n\n".utf8))
    let reading = Task { try await response.body.next() }
    reading.cancel()

    await #expect(throws: CancellationError.self) { try await reading.value }
    #expect(try await eventually { StubLoading.stops(host) == 1 })
  }

  @Test("a stream nobody reads any longer lets its connection go")
  func droppedBody() async throws {
    let host = StubLoading.host([.answer(200, chunks: ["data: one\n\n"], ending: .staysOpen)])
    let exchange = StubLoading.exchange()
    do {
      let response = try await exchange.send(
        ExchangeRequest(method: "GET", url: try StubLoading.url(host)))
      #expect(try await response.body.next() == Data("data: one\n\n".utf8))
    }

    #expect(try await eventually { StubLoading.stops(host) == 1 })
    #expect(try await eventually { exchange.loader.deliveries.count == 0 })
  }

  @Test("every exchange built plainly shares the one session of the process")
  func sharedSession() {
    #expect(SystemExchange().loader === SystemExchange().loader)
    #expect(StubLoading.exchange().loader !== SystemExchange().loader)
  }
}
