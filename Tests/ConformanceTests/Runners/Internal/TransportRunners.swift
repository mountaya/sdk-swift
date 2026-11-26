import Foundation
import GateSupport
import Simulation

@testable import MountayaClient

extension InternalRunners {
  /// retryTimeout sends one call on a simulation's clock with the client's budget, the operation
  /// declaring none of its own, and answers with how many attempts were sent, how much time the
  /// call took and how it settled.
  ///
  /// A keyed case declares the `Idempotency-Key` header, so the client draws one. A case that
  /// cancels the call does it from a task beside it, at the case's instant, which is the task
  /// cancellation the contract's abort stands for (SPEC.md section 9).
  static let retryTimeout = Runner(id: "transport.retry.timeout", table: .internal) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    guard
      try OrderedJSON.milliseconds(AttemptBudget.clientDefault)
        == .number((fixture.defaults ?? .object([])).number(at: "timeoutMs"))
    else {
      throw FixtureError(description: "the fixture's default budget is not the client's")
    }
    let input = fixtureCase.input
    let timeout = try input.optionalNumber(at: "timeoutMs").map { Duration.milliseconds($0) }
    let reply: Scripted.Reply =
      try input.optionalNumber(at: "answersAfterMs").map {
        .answer(status: 200, body: Scripted.emptySuccess, after: .milliseconds($0))
      } ?? .never
    let abortAfter = try input.optionalNumber(at: "abortAfterMs").map { Duration.milliseconds($0) }
    let declaration = OperationDeclaration(
      operationId: "callThing",
      method: "POST",
      idempotent: try input.flag(at: "idempotent"),
      declaresIdempotencyKey: try input.flag(at: "keyed")
    )
    let policy = try RetryPolicy(
      maxRetries: try input.integer(at: "maxRetries"), baseDelay: .zero, maxDelay: .zero)
    let (outcome, attempts, elapsed) = try await Simulation.run {
      simulation -> (String, Int, Duration) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: [], exhausted: reply)
      let client =
        try timeout.map {
          try Scripted.client(simulation, exchange: exchange, retry: policy, timeout: $0)
        } ?? Scripted.client(simulation, exchange: exchange, retry: policy)
      let outcome = await withTaskGroup(of: String?.self) { group in
        group.addTask {
          do {
            let _: Response<JSONValue, JSONValue?> = try await client.send(
              declaration, path: "/v1/things")
            return "answered"
          } catch {
            return Scripted.className(error)
          }
        }
        if let abortAfter {
          group.addTask {
            try? await simulation.clock.sleep(for: abortAfter)
            return nil
          }
        }
        while let next = await group.next() {
          if let outcome = next {
            group.cancelAll()
            return outcome
          }
          group.cancelAll()
        }
        return "unsettled"
      }
      return (outcome, await exchange.sent.count, simulation.elapsed)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "attempts", value: .number(Double(attempts))),
        OrderedJSON.Member(key: "elapsedMs", value: .milliseconds(elapsed)),
        OrderedJSON.Member(key: "outcome", value: .string(outcome)),
      ])
    )
  }

  /// requestFormParts writes the case's parts through the transport's own `multipart/form-data`
  /// writer, then reads the body back as a server reads it, part by part, and answers each part's
  /// `Content-Disposition` as written and its `Content-Type`, null where it carries none, keyed by
  /// the form field its disposition names.
  ///
  /// A text part is `MultipartPart.Content.text`; a file part is `.file` holding the file's text as
  /// its bytes, with the file name and the media type the case gives it, nil where it gives none.
  static let requestFormParts = Runner(id: "transport.request.form-parts", table: .internal) {
    _, fixtureCase in
    let parts = try fixtureCase.input.array(at: "parts").map {
      part throws(FixtureError) -> MultipartPart in
      let name = try part.string(at: "name")
      if let text = try part.optionalString(at: "text") {
        return MultipartPart(name: name, content: .text(text))
      }
      return MultipartPart(
        name: name,
        content: .file(
          Data(try part.string(at: "file").utf8),
          filename: try part.optionalString(at: "filename"),
          contentType: try part.optionalString(at: "contentType")
        )
      )
    }
    let written = FormBody.write(parts)
    guard let boundary = written.contentType.components(separatedBy: "; boundary=").last,
      written.contentType.hasPrefix("multipart/form-data; boundary=")
    else {
      throw FixtureError(description: "the body's type names no boundary: \(written.contentType)")
    }
    let body = String(decoding: written.bytes, as: UTF8.self)
    var read: [OrderedJSON.Member] = []
    for section in body.components(separatedBy: "--\(boundary)").dropFirst() {
      guard section.hasPrefix("\r\n") else {
        guard section == "--\r\n" else {
          throw FixtureError(description: "the body does not end with its closing boundary")
        }
        break
      }
      // `\r\n` is one character to Swift, so the line break is dropped by its own count.
      let afterBreak = section.dropFirst("\r\n".count)
      guard let head = afterBreak.components(separatedBy: "\r\n\r\n").first else {
        throw FixtureError(description: "a part holds no blank line ending its headers")
      }
      var headers: [String: String] = [:]
      for line in head.components(separatedBy: "\r\n") {
        guard let colon = line.firstIndex(of: ":") else {
          throw FixtureError(description: "a part's header `\(line)` holds no colon")
        }
        let value = line[line.index(after: colon)...].drop { $0 == " " }
        headers[line[..<colon].lowercased()] = String(value)
      }
      guard let disposition = headers["content-disposition"],
        let named = disposition.firstRange(of: "name=\""),
        let close = disposition[named.upperBound...].firstIndex(of: "\"")
      else {
        throw FixtureError(description: "a part names no form field")
      }
      let field = String(disposition[named.upperBound..<close])
      guard !read.contains(where: { $0.key == field }) else {
        throw FixtureError(description: "two parts fill the form field `\(field)`")
      }
      read.append(
        OrderedJSON.Member(
          key: field,
          value: .object([
            OrderedJSON.Member(
              key: "contentType", value: headers["content-type"].map { .string($0) } ?? .null),
            OrderedJSON.Member(key: "disposition", value: .string(disposition)),
          ])))
    }
    return .value(.object([OrderedJSON.Member(key: "parts", value: .object(read))]))
  }

  /// browserCookieMode answers whether a request under the case's credential to an operation
  /// declaring the case's facts asks for the visitor's cookies, a share token that asks for them
  /// carrying a cookie source.
  static let browserCookieMode = Runner(id: "transport.browser.cookie-mode", table: .internal) {
    _, fixtureCase in
    try cookieMode(fixtureCase.input)
  }

  private static func cookieMode(_ input: OrderedJSON) throws -> RunnerOutcome {
    let parts = input["credential"] ?? .object([])
    let credential: Credential
    if let share = try parts.optionalString(at: "shareToken") {
      var cookies: CookieSource?
      if try parts.flag(at: "cookie") {
        cookies = { _ in "session=visitor" }
      }
      credential = .share(token: share, cookies: cookies)
    } else if let secret = try parts.optionalString(at: "secretKey") {
      credential = try Credential(secretKey: secret)
    } else {
      var token: SessionToken?
      if let minted = parts["sessionToken"]?["token"]?.stringValue {
        token = .minted(
          RestSchema.Session(
            expires_at: Date(timeIntervalSince1970: 0),
            user_id: parts["sessionToken"]?["userId"]?.stringValue,
            token: minted
          )
        )
      } else if let value = try parts.optionalString(at: "sessionToken") {
        token = .value(value)
      }
      credential = .publishable(key: try parts.string(at: "publishableKey"), sessionToken: token)
    }
    let actingUserText = try input.optionalString(at: "actingUser") ?? "none"
    guard let actingUser = CredentialDeclaration.ActingUser(rawValue: actingUserText) else {
      throw FixtureError(description: "no acting user is called `\(actingUserText)`")
    }
    let declaration = CredentialDeclaration(
      actingUser: actingUser,
      acceptsShareToken: try input.flag(at: "acceptsShareToken"),
      requiresSession: try input.flag(at: "requiresSession"),
      requiresSecretKey: try input.flag(at: "requiresSecretKey"),
      takesNoCredential: try input.flag(at: "takesNoCredential"),
      isRead: try input.flag(at: "read")
    )
    let mode = CookieMode.mode(credential, for: declaration)
    // The projection a request makes agrees: cookies ride exactly where the mode includes them.
    let isRead = CredentialHeaders.isRead(try input.string(at: "method"), declaring: declaration)
    var session: ResolvedSession?
    if case .publishable(_, let token?) = credential {
      session = try ResolvedSession.reading(token, snapshot: nil)
    }
    let projection = try CredentialHeaders.project(
      credential, session: session, language: nil, for: declaration, isRead: isRead)
    guard (projection.cookies != nil) == (mode == .include) else {
      throw FixtureError(description: "the projection and the mode disagree about cookies")
    }
    return .value(.string(mode.rawValue))
  }
}
