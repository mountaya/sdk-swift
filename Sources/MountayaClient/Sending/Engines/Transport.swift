import Foundation

/// Transport is the pipeline every operation is sent through: the credential's headers, the
/// attempt budget, the retries and their waits, the error ladder and the decoding of a success.
///
/// It is the one implementation of `OperationSending`, and it reaches the network through an
/// `HTTPExchange` and nothing else, so a test that scripts the exchange, the clock and the draws
/// runs every rule here without a server.
struct Transport: OperationSending {
  /// Configuration is what a client is built with and every call reads.
  struct Configuration: Sendable {
    let credential: Credential
    let language: String?
    let baseUrls: BaseURLs
    let retry: RetryPolicy
    /// timeout is the client's attempt budget.
    let timeout: Duration
    let onResponse: (@Sendable (ResponseReport) -> Void)?
  }

  /// The headers the client writes itself, which no caller's header may name.
  static let clientHeaders: Set<String> = [
    CredentialHeaders.apiKey, CredentialHeaders.sessionToken, CredentialHeaders.shareToken,
    CredentialHeaders.acceptLanguage, IdempotencyKey.header, ConditionalTag.header,
    EventStreamRules.lastEventIdHeader, "Cookie", ClientIdentification.header,
  ].reduce(into: []) { $0.insert(HeaderLookup.asciiLowercase($1)) }

  let configuration: Configuration
  let exchange: any HTTPExchange
  let sleeper: any Sleeper
  let wallClock: any WallClock
  let random: any RandomSource
  /// persistedQueries is whether the Data API takes a digest alone, for the transport's
  /// lifetime: one answer of "not implemented" turns it off for every later call.
  let persistedQueries: Locked<PersistedQuerySupport>

  init(
    configuration: Configuration,
    exchange: any HTTPExchange,
    sleeper: any Sleeper,
    wallClock: any WallClock,
    random: any RandomSource
  ) {
    self.configuration = configuration
    self.exchange = exchange
    self.sleeper = sleeper
    self.wallClock = wallClock
    self.random = random
    self.persistedQueries = Locked(PersistedQuerySupport())
  }

  // MARK: - One call

  /// Call is what every attempt of one call sends the same.
  struct Call: Sendable {
    let facts: OperationFacts
    let url: URL
    /// headers is what the call carries beside the credential's: `Accept`, `Content-Type` and
    /// the caller's own.
    let headers: [String: String]
    let body: Data?
    /// idempotencyKey is the key every attempt sends, or nil where the call sends none.
    let idempotencyKey: String?
    /// ifMatch is the tag every attempt sends, or nil where the call sends none.
    let ifMatch: String?
    let policy: RetryPolicy
    /// budget is each attempt's time budget.
    let budget: Duration
    /// departed is told as each attempt is handed to the exchange, or nil where nobody waits on it.
    var departed: (@Sendable () -> Void)? = nil
  }

  /// Answer is one attempt's answer, its body read whole, and its headers folded once as it
  /// arrives, each name in lowercase (`HeaderLookup.folded(_:)`), so each header the transport
  /// reads off it is one lookup.
  struct Answer: Sendable {
    let status: Int
    let headers: [String: String]
    let body: Data

    /// Creates the answer of `status`, folding `headers`.
    init(status: Int, headers: [String: String], body: Data) {
      self.status = status
      self.headers = HeaderLookup.folded(headers)
      self.body = body
    }

    var isSuccess: Bool {
      (200...299).contains(status)
    }

    /// header returns the value of the header named `name`, in any letter case, or nil where the
    /// answer sent none. It is kept out of line, as the scan it replaced was, so the reader of each
    /// operation's answer carries a call rather than the lookup.
    @inline(never)
    func header(_ name: String) -> String? {
      HeaderLookup.value(of: name, inFolded: headers)
    }
  }

  /// Outcome is how one attempt ended.
  enum Outcome: Sendable {
    /// answered is an answer that came back.
    case answered(Answer)
    /// neverArrived is a request whose answer never came: a dropped connection, a broken body,
    /// or a budget spent, which carries no underlying error.
    case neverArrived((any Error)?)
  }

  /// Settled is what a call's reader makes of an answer.
  enum Settled<Success: Sendable>: Sendable {
    case success(Success)
    case failure(MountayaError)
  }

  /// prepare checks what a call sends and fixes what every attempt of it sends the same, or
  /// refuses it with `ConfigurationError` before any request.
  ///
  /// The checks run in this order: the credential and the language, the call's own budget, the
  /// caller's headers, a buffered request that asks for an event stream, the `If-Match`, then
  /// the `Idempotency-Key`, which is drawn last, once nothing else can refuse the call.
  func prepare(
    _ facts: OperationFacts,
    path: String,
    query: [QueryItem],
    headers callerHeaders: [HeaderField],
    body: OperationBody,
    accept: String,
    idempotencyKey: String?,
    ifMatch: String?,
    options: RequestOptions
  ) throws(MountayaError) -> Call {
    try CredentialHeaders.check(configuration.credential)
    try CredentialHeaders.checkLanguage(configuration.language)
    if let timeout = options.timeout {
      try AttemptBudget.check(timeout, as: "The call's timeout")
    }
    var headers: [String: String] = ["Accept": accept]
    for header in callerHeaders {
      guard HeaderValue.isToken(header.name) else {
        throw .configuration(
          ConfigurationError(
            message:
              "A header's name is empty or holds a character no field name holds: name it as "
              + "RFC 9110 writes one, with letters, digits and !#$%&'*+-.^_|~ or a backtick alone."
          )
        )
      }
      guard !Self.clientHeaders.contains(HeaderLookup.asciiLowercase(header.name)) else {
        throw .configuration(
          ConfigurationError(
            message:
              "`\(header.name)` is a header the client writes itself, from its credential, its "
              + "language or the call's own arguments: leave it out of the call's headers."
          )
        )
      }
      guard HeaderValue.isCarried(header.value) else {
        throw .configuration(
          ConfigurationError(
            message:
              "The header `\(header.name)` holds \(HeaderValue.uncarried)."
          )
        )
      }
      if HeaderLookup.asciiLowercase(header.name) == "accept" {
        headers["Accept"] = header.value
      } else {
        Self.replace(header.name, with: header.value, in: &headers)
      }
    }
    try StreamRefusal.check(accept == StreamRefusal.mediaType ? [:] : headers)

    var bytes: Data?
    switch body {
    case .none:
      bytes = nil
    case .json(let value):
      do {
        bytes = try JSONEncoder().encode(value)
      } catch {
        throw .configuration(
          ConfigurationError(
            message: "The request's body could not be written as JSON.", cause: error)
        )
      }
      // The body's own type stands over a caller's, whatever case the caller wrote it in.
      Self.replace("Content-Type", with: "application/json", in: &headers)
    case .multipart(let parts):
      for type in FormBody.contentTypes(parts) where !HeaderValue.isCarried(type) {
        throw .configuration(
          ConfigurationError(
            message:
              "A part's media type holds \(HeaderValue.uncarried)."
          )
        )
      }
      let form = FormBody.write(parts)
      bytes = form.bytes
      Self.replace("Content-Type", with: form.contentType, in: &headers)
    }

    let origin =
      switch facts.surface {
      case .rest: configuration.baseUrls.rest
      case .tiles: configuration.baseUrls.tiles
      case .data: configuration.baseUrls.data
      }
    guard let url = RequestAddress.url(origin: origin, path: path, query: query) else {
      throw .configuration(
        ConfigurationError(message: "`\(path)` under `\(origin)` makes no URL.")
      )
    }
    let tag = try ConditionalTag.tag(declared: facts.isConditional, given: ifMatch)
    let key = try IdempotencyKey.key(
      declared: facts.declaresIdempotencyKey,
      given: idempotencyKey,
      draw: random.cryptographicUuid
    )
    return Call(
      facts: facts,
      url: url,
      headers: headers,
      body: bytes,
      idempotencyKey: key,
      ifMatch: tag,
      policy: options.retry ?? configuration.retry,
      budget: AttemptBudget.budget(
        call: options.timeout,
        client: configuration.timeout,
        operation: facts.timeout
      )
    )
  }

  /// replace sets the header `name` to `value` in `headers`, taking off any header of that name
  /// written in another case, so one value of a name is sent: a platform that reads names without
  /// regard to case, as every HTTP stack does, would otherwise send whichever it met last.
  static func replace(_ name: String, with value: String, in headers: inout [String: String]) {
    let wanted = HeaderLookup.asciiLowercase(name)
    let stale = headers.keys.filter { $0 != name && HeaderLookup.asciiLowercase($0) == wanted }
    for held in stale {
      headers[held] = nil
    }
    headers[name] = value
  }

  /// run sends a call's attempts until one settles it, and returns what `read` makes of the
  /// answer that did.
  ///
  /// An attempt that fails is repeated where the contract repeats it and the wait its answer
  /// names fits the call's budget; otherwise the call throws the error its last attempt raised.
  /// Every error carries the call's `Idempotency-Key`, and a cancelled task throws
  /// `CancellationError` as it is, during a wait included.
  func run<Success: Sendable>(
    _ call: Call,
    read: @escaping @Sendable (Answer) -> Settled<Success>
  ) async throws -> Success {
    var attempt = 0
    var counted = 0
    var waited = Duration.zero
    while true {
      try Task.checkCancellation()
      let failure: MountayaError
      var status: Int?
      var code: APIErrorCode?
      var retryAfter: Duration?
      switch try await self.attempt(call) {
      case .answered(let answer):
        report(answer, of: call, attempt: attempt)
        switch read(answer) {
        case .success(let value):
          return value
        case .failure(let error):
          failure = error.carrying(idempotencyKey: call.idempotencyKey)
          status = answer.status
          if case .api(let apiError) = error {
            code = apiError.code
          }
          // The whole seconds the error carries, an HTTP date's distance rounded up, so the wait
          // taken is the one a caller reads off the error.
          retryAfter = AnswerError.retryAfter(in: answer.headers, now: wallClock.now)
        }
      case .neverArrived(let underlying):
        failure = .connection(
          ConnectionError(idempotencyKey: call.idempotencyKey, cause: underlying))
      }

      let keyed = call.idempotencyKey != nil
      guard
        RetryEligibility.allowsRetry(
          after: counted,
          status: status,
          code: code,
          idempotent: call.facts.idempotent,
          keyed: keyed,
          policy: call.policy
        )
      else {
        throw failure
      }
      let keyInUse = status == 409 && code == .idempotencyKeyInUse
      guard
        let wait = Backoff.delay(
          after: counted,
          policy: call.policy,
          draw: random.unitDraw(),
          retryAfter: retryAfter,
          waited: waited,
          minimum: keyInUse ? Backoff.keyInUseMinimum : .zero
        )
      else {
        throw failure
      }
      try await sleeper.sleep(for: wait)
      waited += wait
      attempt += 1
      if !keyInUse {
        counted += 1
      }
    }
  }

  /// attempt sends one attempt within the call's budget, the wait for a first session token and
  /// the read of the body included.
  func attempt(_ call: Call) async throws -> Outcome {
    let raced: Deadline.Raced<Outcome>
    do {
      raced = try await Deadline.run(within: call.budget, sleeper: sleeper) {
        let request = try await self.request(for: call)
        do {
          call.departed?()
          let response = try await self.exchange.send(request)
          let body = try await response.body.collect()
          return .answered(Answer(status: response.status, headers: response.headers, body: body))
        } catch let cancellation as CancellationError {
          // A cancellation the exchange reports, `SystemExchange`'s for a task the platform
          // cancelled included, ends the call as it is, and is never a request that never
          // arrived, which an idempotent or keyed call would repeat.
          throw cancellation
        } catch {
          try Task.checkCancellation()
          return .neverArrived(error)
        }
      }
    } catch let error as MountayaError {
      throw error.carrying(idempotencyKey: call.idempotencyKey)
    }
    switch raced {
    case .finished(let outcome): return outcome
    case .expired: return .neverArrived(nil)
    }
  }

  /// request writes one attempt of a call: the credential's headers as its session token reads
  /// now, after waiting for a first one where its source reports one on its way, and the SDK's
  /// name beside them, which every attempt of every call carries. It throws the `MountayaError`
  /// the credential is refused with, and `CancellationError` for a task cancelled while it waits.
  func request(for call: Call) async throws -> ExchangeRequest {
    let projection = try await credentialHeaders(
      for: call.facts.credentials,
      isRead: CredentialHeaders.isRead(call.facts.method, declaring: call.facts.credentials)
    )
    var headers = call.headers
    headers.merge(projection.headers) { _, credential in credential }
    headers[ClientIdentification.header] = ClientIdentification.value
    if let key = call.idempotencyKey {
      headers[IdempotencyKey.header] = key
    }
    if let tag = call.ifMatch {
      headers[ConditionalTag.header] = tag
    }
    if let cookies = projection.cookies, let cookie = cookies(call.url) {
      try CredentialHeaders.checkCookie(cookie)
      headers["Cookie"] = cookie
    }
    return ExchangeRequest(
      method: call.facts.method,
      url: call.url,
      headers: headers,
      body: call.body
    )
  }

  /// credentialHeaders projects the client's credential and language for an operation
  /// declaring `declaration`, reading its session token for this request. It throws the
  /// `MountayaError` the credential is refused with, and `CancellationError` for a task cancelled
  /// while it waits for a first token.
  func credentialHeaders(for declaration: CredentialDeclaration, isRead: Bool)
    async throws -> CredentialHeaders.Projection
  {
    var session: ResolvedSession?
    if case .publishable(_, let token?) = configuration.credential, !declaration.takesNoCredential {
      var snapshot: SessionSnapshot?
      if case .source(let source) = token, !declaration.requiresSecretKey {
        snapshot = try await ResolvedSession.awaitingFirstToken(from: source)
      }
      session = try ResolvedSession.reading(token, snapshot: snapshot)
    }
    return try CredentialHeaders.project(
      configuration.credential,
      session: session,
      language: configuration.language,
      for: declaration,
      isRead: isRead
    )
  }

  /// report tells the client's hook of an attempt an answer came back to.
  func report(_ answer: Answer, of call: Call, attempt: Int) {
    guard let onResponse = configuration.onResponse else { return }
    onResponse(
      ResponseReport(
        operationId: call.facts.operationId,
        surface: call.facts.surface,
        status: answer.status,
        attempt: attempt,
        isReplayed: answer.header("Idempotent-Replayed")
          .map(HeaderLookup.asciiLowercase) == "true",
        requestId: answer.header(AnswerError.requestIdHeader),
        rateLimit: AnswerError.rateLimit(in: answer.headers)
      )
    )
  }

  /// failure is the error a failing answer raises, its body read for what it carries unless the
  /// caller read it already, `envelope`.
  func failure(_ answer: Answer, of call: Call, envelope: ErrorEnvelope.Read? = nil)
    -> MountayaError
  {
    .api(
      AnswerError.error(
        status: answer.status,
        headers: answer.headers,
        envelope: envelope ?? ErrorEnvelope.read(answer.body),
        now: wallClock.now,
        idempotencyKey: call.idempotencyKey,
        declaration: NextStep.Declaration(call.facts.credentials)
      )
    )
  }

  /// undecodable is the error a success whose body does not decode raises: the base `APIError`
  /// with the decoder's error riding along. The contract names no class for it yet (SPEC.md
  /// section 1), and this is the one place that raises it.
  func undecodable(_ answer: Answer, of call: Call, cause error: any Error) -> MountayaError {
    .api(
      APIError(
        kind: .other,
        status: answer.status,
        requestId: answer.header(AnswerError.requestIdHeader),
        rateLimit: AnswerError.rateLimit(in: answer.headers),
        idempotencyKey: call.idempotencyKey,
        cause: error
      )
    )
  }

  // MARK: - OperationSending

  func envelope<Value: Decodable & Sendable, Metadata: Decodable & Sendable>(
    _ request: OperationRequest,
    options: RequestOptions
  ) async throws -> Response<Value, Metadata> {
    let call = try prepare(request, accept: "application/json", options: options)
    return try await run(call) { answer in
      guard answer.isSuccess else { return .failure(self.failure(answer, of: call)) }
      do {
        let read = try Envelope.rest(Value.self, metadata: Metadata.self, from: answer.body)
        return .success(
          Response(
            data: read.data,
            metadata: read.metadata,
            status: answer.status,
            requestId: answer.header(AnswerError.requestIdHeader),
            location: answer.header("Location"),
            etag: answer.header(AnswerError.etagHeader),
            headers: answer.headers
          )
        )
      } catch {
        return .failure(self.undecodable(answer, of: call, cause: error))
      }
    }
  }

  func binary(_ request: OperationRequest, options: RequestOptions) async throws
    -> BinaryResponse
  {
    let call = try prepare(request, accept: "*/*", options: options)
    return try await run(call) { answer in
      guard answer.isSuccess else { return .failure(self.failure(answer, of: call)) }
      return .success(
        BinaryResponse(
          bytes: answer.body,
          contentType: answer.header("Content-Type")
            ?? "application/octet-stream",
          status: answer.status,
          requestId: answer.header(AnswerError.requestIdHeader)
        )
      )
    }
  }

  func events<Event: StreamedEvent>(
    _ request: OperationRequest,
    options: RequestOptions
  ) throws -> EventStream<Event> {
    let call = try prepare(request, accept: StreamRefusal.mediaType, options: options)
    return EventStream { member in
      EventStreamReader<Event>(transport: self, call: call, member: member).makeIterator()
    }
  }

  func query<Input: Encodable & Sendable, Result: Decodable & Sendable>(
    _ operation: DataOperation,
    facts: OperationFacts,
    input: Input,
    select: FieldSelection?,
    options: RequestOptions
  ) async throws -> Result {
    let document = try operation.document(selecting: select)
    let digest = PersistedQueryDigest.digest(of: document)
    var attempt = persistedQueries.value.firstAttempt(digest: digest)
    while true {
      let body = DataRequest(
        query: attempt.sendsDocument ? document : nil,
        input: input,
        digest: attempt.digest
      )
      let call = try prepare(
        facts,
        path: facts.path,
        query: [],
        headers: [],
        body: .json(body),
        accept: "application/json",
        idempotencyKey: nil,
        ifMatch: nil,
        options: options
      )
      let sent = attempt
      let answered: DataOutcome<Result> = try await run(call) { answer in
        self.readData(answer, of: call, operation: operation, attempt: sent)
      }
      switch answered {
      case .result(let result):
        return result
      case .resend(let next):
        attempt = next
      }
    }
  }

  /// DataOutcome is what a Data API answer makes of the call: its result, or the attempt the
  /// persisted-query protocol asks for next.
  enum DataOutcome<Result: Sendable>: Sendable {
    case result(Result)
    case resend(PersistedQueryAttempt)
  }

  /// readData reads a Data API answer: a refusal of the digest it sent before the rule that a
  /// success carrying errors is a failure, then the operation's own field.
  ///
  /// A failing status is read for that refusal too, before it makes the answer a failure: the Data
  /// API with the extension turned off answers a digest-only attempt `GRAPHQL_VALIDATION_FAILED`
  /// under 422, or 400 under `application/graphql-response+json`, where a digest it does not hold
  /// yet is answered under 200.
  func readData<Result: Decodable & Sendable>(
    _ answer: Answer,
    of call: Call,
    operation: DataOperation,
    attempt: PersistedQueryAttempt
  ) -> Settled<DataOutcome<Result>> {
    guard answer.isSuccess else {
      if let next = resend(after: ErrorEnvelope.read(answer.body).errors, answering: attempt) {
        return .success(.resend(next))
      }
      return .failure(failure(answer, of: call))
    }
    let read: Envelope.DataAnswer<Result>
    do {
      read = try Envelope.data(Result.self, operation: operation.name, from: answer.body)
    } catch {
      return .failure(undecodable(answer, of: call, cause: error))
    }
    if read.read.hasErrors {
      if let next = resend(after: read.read.errors, answering: attempt) {
        return .success(.resend(next))
      }
      return .failure(failure(answer, of: call, envelope: read.read))
    }
    guard let result = read.result else {
      return .failure(
        .api(
          AnswerError.error(
            status: answer.status,
            headers: answer.headers,
            envelope: read.read,
            now: wallClock.now,
            idempotencyKey: nil,
            declaration: NextStep.Declaration(call.facts.credentials)
          )
        )
      )
    }
    return .success(.result(result))
  }

  /// resend returns the attempt the persisted-query protocol asks for once `errors` answered
  /// `attempt`, or nil where none of them refuses its digest: the document alone where the server
  /// declines the protocol, which declines it for the transport's lifetime, and the document beside
  /// the digest where the server asks to have it registered.
  func resend(after errors: [ErrorEntry], answering attempt: PersistedQueryAttempt)
    -> PersistedQueryAttempt?
  {
    let refusal = persistedQueries.withLock { support in
      support.read(errors, answering: attempt)
    }
    switch refusal {
    case .unsupported: return PersistedQueryAttempt(digest: nil, sendsDocument: true)
    case .register: return PersistedQueryAttempt(digest: attempt.digest, sendsDocument: true)
    case nil: return nil
    }
  }

  /// prepare checks and fixes a REST or Tile request.
  func prepare(_ request: OperationRequest, accept: String, options: RequestOptions)
    throws(MountayaError) -> Call
  {
    var call = try prepare(
      request.facts,
      path: request.path,
      query: request.query,
      headers: request.headers,
      body: request.body,
      accept: accept,
      idempotencyKey: request.idempotencyKey,
      ifMatch: request.ifMatch,
      options: options
    )
    call.departed = request.departed
    return call
  }
}

/// DataRequest is the body of a Data API request: the document, where the attempt sends it, its
/// one `input`, and the persisted query's digest, where the attempt sends one.
struct DataRequest<Input: Encodable & Sendable>: Encodable, Sendable {
  let query: String?
  let input: Input
  let digest: String?

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: WireKey.self)
    try container.encodeIfPresent(query, forKey: "query")
    var variables = container.nestedContainer(keyedBy: WireKey.self, forKey: "variables")
    try variables.encode(input, forKey: "input")
    if let digest {
      var extensions = container.nestedContainer(keyedBy: WireKey.self, forKey: "extensions")
      var persisted = extensions.nestedContainer(keyedBy: WireKey.self, forKey: "persistedQuery")
      try persisted.encode(PersistedQueryDigest.version, forKey: "version")
      try persisted.encode(digest, forKey: "sha256Hash")
    }
  }
}
