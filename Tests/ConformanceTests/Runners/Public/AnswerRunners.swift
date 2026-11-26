import Foundation
import GateSupport
import MountayaClient
import Simulation

extension PublicRunners {
  /// noRetries is a policy that repeats nothing, so a runner reads the error the first answer
  /// raises.
  static let noRetries: RetryPolicy = {
    guard let policy = try? RetryPolicy(maxRetries: 0, baseDelay: .zero, maxDelay: .zero) else {
      preconditionFailure("a policy of no retries is one")
    }
    return policy
  }()

  /// twoQuickRetries is the fixtures' policy: two attempts after the first, and no wait of its
  /// own.
  static let twoQuickRetries: RetryPolicy = {
    guard let policy = try? RetryPolicy(maxRetries: 2, baseDelay: .zero, maxDelay: .zero) else {
      preconditionFailure("a policy of two quick retries is one")
    }
    return policy
  }()

  /// aRead is an idempotent read that takes a publishable key, by its declaration.
  static let aRead = OperationDeclaration(operationId: "readThing", method: "GET", idempotent: true)

  /// FixedWallClock is a wall clock that reads one instant, the one a case says its answer
  /// arrived at.
  struct FixedWallClock: WallClock {
    let now: Date
  }

  /// errorsEnvelope answers with what the error a failed answer raises carries, read off a
  /// scripted answer of the case's status, headers and body by a call that repeats nothing.
  ///
  /// A case about the Data API calls the generated `directions`; every other case calls a read
  /// by its declaration, which declares what the case's `declares` names: a call acting as a
  /// member, sent with a session token, and the one a secret key authenticates, sent with one. The
  /// client's wall clock reads the case's `answeredAtMs` where it names one. `nextStep` is what the
  /// error's description carries after the API's own words, the status, the code and the first
  /// entry's message, and null where it carries nothing more. A case that names codes under
  /// `hasCode` is answered, for each, whether any entry carries it, through `APIError.hasCode(_:)`.
  static let errorsEnvelope = Runner(id: "transport.errors.envelope", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let declares = input["declares"] ?? .object([])
    let actsAsMember = try declares.optionalString(at: "actingUser")
    guard [nil, "required", "optional", "none"].contains(actsAsMember) else {
      throw FixtureError(description: "no acting user is called `\(actsAsMember ?? "")`")
    }
    let mints = try declares.flag(at: "requiresSecretKey")
    let answeredAt = try input.optionalNumber(at: "answeredAtMs").map {
      Date(timeIntervalSince1970: $0 / 1000)
    }
    let status = try input.integer(at: "status")
    var headers: [String: String] = [:]
    for member in (input["headers"] ?? .object([])).members ?? [] {
      guard let value = member.value.stringValue else {
        throw FixtureError(description: "the header `\(member.key)` is no string")
      }
      headers[member.key] = value
    }
    var body: [OrderedJSON.Member] = []
    if let errors = input["errors"] {
      body.append(OrderedJSON.Member(key: "errors", value: errors))
    }
    if let extensions = input["extensions"] {
      body.append(OrderedJSON.Member(key: "extensions", value: extensions))
    }
    let bytes = body.isEmpty ? Data() : Scripted.json(.object(body))
    let sentHeaders = headers
    let surface = try input.optionalString(at: "surface")
    guard [nil, "data"].contains(surface) else {
      throw FixtureError(description: "no surface is called `\(surface ?? "")`")
    }
    let error = try await Simulation.run { simulation -> MountayaError in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [.answer(status: status, headers: sentHeaders, body: bytes)]
      )
      do {
        if surface == "data" {
          let client = try Scripted.client(
            simulation,
            exchange: exchange,
            credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
            retry: noRetries
          )
          _ = try await client.data.directions(
            input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]])
          )
        } else {
          var declaration = aRead
          var credential = Credential.publishable(key: "pk_test_abc")
          if mints {
            declaration.method = "POST"
            declaration.credentials = CredentialDeclaration(requiresSecretKey: true)
            credential = .secret(key: "sk_test_abc")
          } else if let actsAsMember,
            let actingUser = CredentialDeclaration.ActingUser(
              rawValue: actsAsMember)
          {
            declaration.credentials = CredentialDeclaration(
              actingUser: actingUser, requiresSession: true)
            credential = .publishable(key: "pk_test_abc", sessionToken: "sess_abc")
          }
          let client = try Mountaya(
            credential: credential,
            retry: noRetries,
            timeout: .seconds(30),
            exchange: exchange,
            clock: simulation.clock,
            wallClock: answeredAt.map { FixedWallClock(now: $0) }
              ?? Scripted.Wall(clock: simulation.clock, start: HeldSeams.epoch)
          )
          let _: Response<JSONValue, JSONValue?> = try await client.send(
            declaration, path: "/v1/things")
        }
      } catch let error as MountayaError {
        return error
      }
      throw FixtureError(description: "the answer raised nothing")
    }
    guard case .api(let apiError) = error else {
      throw FixtureError(
        description: "the answer raised \(error.name), which the API did not answer")
    }
    var answer = [
      OrderedJSON.Member(key: "class", value: .string(error.name)),
      OrderedJSON.Member(
        key: "nextStep", value: nextStep(of: apiError).map(OrderedJSON.string) ?? .null),
      OrderedJSON.Member(
        key: "code", value: apiError.code.map { .string($0.rawValue) } ?? .null),
      OrderedJSON.Member(key: "errors", value: .array(apiError.errors.map(entry))),
      OrderedJSON.Member(
        key: "metadata", value: apiError.metadata.map(Scripted.ordered) ?? .null),
      OrderedJSON.Member(key: "rateLimit", value: rateLimit(apiError.rateLimit)),
      OrderedJSON.Member(
        key: "requestId", value: apiError.requestId.map(OrderedJSON.string) ?? .null),
      OrderedJSON.Member(
        key: "retryAfter", value: apiError.retryAfter.map(OrderedJSON.seconds) ?? .null),
      OrderedJSON.Member(key: "status", value: .number(Double(apiError.status))),
    ]
    // A case that asks `hasCode` names the codes it asks of every entry, and is answered each.
    if let codes = input["hasCode"] {
      guard let listed = codes.elements else {
        throw FixtureError(description: "`hasCode` is no list of codes")
      }
      var asked: [OrderedJSON.Member] = []
      for code in listed {
        guard let text = code.stringValue else {
          throw FixtureError(description: "`hasCode` holds a code that is no string")
        }
        asked.append(
          OrderedJSON.Member(
            key: text, value: .bool(apiError.hasCode(APIErrorCode(rawValue: text))))
        )
      }
      answer.append(OrderedJSON.Member(key: "hasCode", value: .object(asked)))
    }
    return .value(.object(answer))
  }

  /// nextStep is what an error's description carries after the API's own words, the status, the
  /// code and the first entry's message, or nil where it carries nothing more.
  static func nextStep(of error: APIError) -> String? {
    var words = "\(error.status)"
    if let code = error.code {
      words += " \(code.rawValue)"
    }
    if let message = error.errors.first?.message, !message.isEmpty {
      words += ": \(message)"
    }
    let description = error.description
    guard description != words else { return nil }
    let ended = words.last.map { ".!?".contains($0) } ?? false
    let lead = words + (ended ? " " : ". ")
    guard description.hasPrefix(lead) else { return description }
    return String(description.dropFirst(lead.count))
  }

  /// entry writes an envelope entry back in the wire's shape.
  static func entry(_ entry: ErrorEntry) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if let code = entry.code {
      members.append(
        OrderedJSON.Member(
          key: "extensions",
          value: .object([OrderedJSON.Member(key: "code", value: .string(code.rawValue))])
        )
      )
    }
    members.append(OrderedJSON.Member(key: "message", value: .string(entry.message)))
    if let path = entry.path {
      members.append(
        OrderedJSON.Member(
          key: "path",
          value: .array(
            path.map { step in
              switch step {
              case .key(let key): .string(key)
              case .index(let index): .number(Double(index))
              }
            }
          )
        )
      )
    }
    return .object(members)
  }

  /// rateLimit writes a rate-limit state in the fixtures' shape, or null for none.
  static func rateLimit(_ state: RateLimitState?) -> OrderedJSON {
    guard let state else { return .null }
    return .object([
      OrderedJSON.Member(
        key: "policies",
        value: .array(
          state.policies.map { policy in
            .object([
              OrderedJSON.Member(key: "name", value: .string(policy.name)),
              OrderedJSON.Member(key: "quota", value: .number(Double(policy.quota))),
              OrderedJSON.Member(
                key: "remaining", value: policy.remaining.map { .number(Double($0)) } ?? .null),
              OrderedJSON.Member(
                key: "resetSeconds", value: policy.reset.map(OrderedJSON.seconds) ?? .null),
              OrderedJSON.Member(
                key: "windowSeconds", value: policy.window.map(OrderedJSON.seconds) ?? .null),
            ])
          }
        )
      )
    ])
  }

  /// errorsRequestId sends the case's call through a scripted exchange that answers each attempt
  /// as the case says, and answers with what the `onResponse` hook was told and the request id
  /// the error carries.
  ///
  /// A REST case calls an idempotent read by its declaration, a Data API case the generated
  /// `directions`, and a stream case opens the generated collaboration feed of an itinerary.
  static let errorsRequestId = Runner(id: "transport.errors.request-id", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let surface = try input.string(at: "surface")
    var replies: [Scripted.Reply] = []
    for answer in try input.array(at: "answers") {
      guard let status = try answer.optionalInteger(at: "status") else {
        replies.append(.drop())
        continue
      }
      var headers: [String: String] = [:]
      if let requestId = try answer.optionalString(at: "requestId") {
        headers["X-Request-Id"] = requestId
      }
      let code = try answer.optionalString(at: "code")
      let body: Data
      if let code {
        body = Scripted.errorBody(code: code)
      } else if surface == "data" {
        body = Data(#"{"data":{"directions":{"routes":[]}}}"#.utf8)
      } else {
        body = Scripted.emptySuccess
      }
      replies.append(.answer(status: status, headers: headers, body: body))
    }
    let scripted = replies
    let (reports, error) = try await Simulation.run {
      simulation -> ([ResponseReport], MountayaError?) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock, replies: scripted, exhausted: .drop())
      let reports = Scripted.Reports()
      let session = Credential.publishable(key: "pk_test_abc", sessionToken: "sess_abc")
      do {
        switch surface {
        case "rest":
          let client = try Scripted.client(
            simulation, exchange: exchange, retry: twoQuickRetries, reports: reports)
          let _: Response<JSONValue, JSONValue?> = try await client.send(aRead, path: "/v1/things")
        case "data":
          let client = try Scripted.client(
            simulation, exchange: exchange, credential: session, retry: twoQuickRetries,
            reports: reports)
          _ = try await client.data.directions(
            input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]])
          )
        case "stream":
          let client = try Scripted.client(
            simulation, exchange: exchange, credential: session, retry: twoQuickRetries,
            reports: reports)
          for try await _ in try client.studio.collab.getItineraryEvents(itinerary_id: "it") {
          }
        default:
          throw FixtureError(description: "no surface is called `\(surface)`")
        }
        return (reports.all, nil)
      } catch let error as MountayaError {
        return (reports.all, error)
      }
    }
    var requestId: String?
    switch error {
    case .api(let apiError)?: requestId = apiError.requestId
    default: requestId = nil
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "error",
          value: error.map { error in
            .object([
              OrderedJSON.Member(key: "class", value: .string(error.name)),
              OrderedJSON.Member(
                key: "requestId", value: requestId.map(OrderedJSON.string) ?? .null),
            ])
          } ?? .null
        ),
        OrderedJSON.Member(
          key: "reported",
          value: .array(
            reports.map { report in
              .object([
                OrderedJSON.Member(key: "attempt", value: .number(Double(report.attempt))),
                OrderedJSON.Member(
                  key: "requestId", value: report.requestId.map(OrderedJSON.string) ?? .null),
                OrderedJSON.Member(key: "status", value: .number(Double(report.status))),
              ])
            }
          )
        ),
      ])
    )
  }

  /// errorsIdempotencyKey sends a call whose every attempt fails as the case says, and answers
  /// with the class of the error it raised and the key that error carries, written `drawn` where
  /// it is the key the client's random source drew and every attempt sent.
  ///
  /// A failure `before` the first attempt is a credential that refuses it, a session token read
  /// per request with the wrong prefix, or a source that reports a token on its way and hands none
  /// within the call's budget; no attempt is sent, so the key is held to the one the random source
  /// draws, the same at every draw.
  static let errorsIdempotencyKey = Runner(id: "transport.errors.idempotency-key", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let failure = input["failure"] ?? .object([])
    let before = try failure.optionalString(at: "before")
    let reply: Scripted.Reply
    if let status = try failure.optionalInteger(at: "status") {
      reply = .answer(
        status: status, body: Scripted.errorBody(code: try failure.optionalString(at: "code")))
    } else {
      reply = .drop()
    }
    guard [nil, "credential", "first-token"].contains(before) else {
      throw FixtureError(description: "no failure before an attempt is called `\(before ?? "")`")
    }
    let declaration = OperationDeclaration(
      operationId: "writeThing",
      method: try input.string(at: "method"),
      idempotent: try input.flag(at: "idempotent"),
      declaresIdempotencyKey: try input.flag(at: "declaresKey")
    )
    let given = try input.optionalString(at: "idempotencyKey")
    let keys = input["randomSource"]?.boolValue ?? true
    let drawnKey = Scripted.key(0x6472_6177_6e00)
    let (error, sent) = try await Simulation.run { simulation -> (MountayaError, [String?]) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: [], exhausted: reply)
      let credential: Credential
      switch before {
      case "credential":
        credential = .publishable(key: "pk_test_abc", sessionToken: .function { "tok_abc" })
      case "first-token":
        credential = .publishable(
          key: "pk_test_abc",
          sessionToken: .source(ScriptedSource(SessionSnapshot(isMinting: true))))
      default:
        credential = .publishable(key: "pk_test_abc")
      }
      let client = try Scripted.client(
        simulation,
        exchange: exchange,
        credential: credential,
        retry: twoQuickRetries,
        random: Scripted.Random(keys: keys, key: drawnKey)
      )
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          declaration, path: "/v1/things", idempotencyKey: given)
      } catch let error as MountayaError {
        return (error, await exchange.sent.map { $0.request.header("Idempotency-Key") })
      }
      throw FixtureError(description: "the call raised nothing")
    }
    if before != nil, !sent.isEmpty {
      throw FixtureError(description: "an attempt left, where the case refuses the first")
    }
    let carried: OrderedJSON
    if let key = error.idempotencyKey {
      guard sent.allSatisfy({ $0 == key }) else {
        throw FixtureError(description: "the error carries a key some attempt did not send")
      }
      if key == given {
        carried = .string(key)
      } else if key == drawnKey.uuidString.lowercased() {
        carried = .string("drawn")
      } else {
        throw FixtureError(description: "the error carries a key nobody gave or drew")
      }
    } else {
      carried = .null
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "class", value: .string(error.name)),
        OrderedJSON.Member(key: "idempotencyKey", value: carried),
      ])
    )
  }

  /// errorsStructural builds each value as a type of the runner's own, which no constructor of
  /// the SDK's made, as a second copy of the SDK or code that never linked it would hand one over:
  /// a `NamedError` declaring the case's name as data, `declares` or `name`, and carrying its
  /// status and entries, or an error declaring no name at all. It answers with what the published
  /// predicates read off it.
  static let errorsStructural = Runner(id: "transport.errors.structural", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let entries = try (input["errors"]?.elements ?? []).map { member -> ErrorEntry in
      guard let message = member["message"]?.stringValue else {
        throw FixtureError(description: "an entry with no message")
      }
      return ErrorEntry(
        message: message,
        code: member["extensions"]?["code"]?.stringValue.map(APIErrorCode.init(rawValue:)))
    }
    let status = try input.optionalInteger(at: "status")
    let value: any Error
    if let declared = try input.optionalString(at: "declares") ?? input.optionalString(at: "name") {
      value = Declared(name: declared, status: status, errors: entries)
    } else {
      value = Undeclared(status: status, errors: entries)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "api", value: .bool(isAPIError(value))),
        OrderedJSON.Member(
          key: "class",
          value: isMountayaError(value)
            ? (value as? any NamedError).map { .string($0.name) } ?? .null : .null),
        OrderedJSON.Member(key: "family", value: .bool(isMountayaError(value))),
      ])
    )
  }

  /// Declared is an error of the runner's own that declares a name as data, carrying a status and
  /// entries of its own.
  struct Declared: NamedError {
    let name: String
    let status: Int?
    let errors: [ErrorEntry]
  }

  /// Undeclared is an error of the runner's own that declares no name, carrying a status and
  /// entries of its own.
  struct Undeclared: Error {
    let status: Int?
    let errors: [ErrorEntry]
  }

  /// ratelimitParse reads the state the case's headers describe where the case asks for it: off
  /// the `onResponse` hook for a 200, or off the error an answer of the case's status raises.
  static let ratelimitParse = Runner(id: "transport.ratelimit.parse", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    var headers: [String: String] = [:]
    for member in (input["headers"] ?? .object([])).members ?? [] {
      guard let value = member.value.stringValue else {
        throw FixtureError(description: "the header `\(member.key)` is no string")
      }
      headers[member.key] = value
    }
    let ask = try input.string(at: "ask")
    let status: Int
    switch ask {
    case "response": status = 200
    case "error": status = try input.integer(at: "status")
    default: throw FixtureError(description: "no ask is called `\(ask)`")
    }
    let body = status == 200 ? Scripted.emptySuccess : Scripted.errorBody(code: "TOO_MANY_REQUESTS")
    let sentHeaders = headers
    let state = try await Simulation.run { simulation -> RateLimitState? in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [.answer(status: status, headers: sentHeaders, body: body)])
      let reports = Scripted.Reports()
      let client = try Scripted.client(
        simulation, exchange: exchange, retry: noRetries, reports: reports)
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(aRead, path: "/v1/things")
        guard ask == "response", let report = reports.all.first else {
          throw FixtureError(description: "the answer was reported to no hook")
        }
        return report.rateLimit
      } catch let error as MountayaError {
        guard ask == "error", case .api(let apiError) = error else {
          throw FixtureError(description: "the call raised \(error.name)")
        }
        guard reports.all.first?.rateLimit == apiError.rateLimit else {
          throw FixtureError(description: "the hook and the error were told different states")
        }
        return apiError.rateLimit
      }
    }
    return .value(rateLimit(state))
  }
}
