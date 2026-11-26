import Foundation

/// Mountaya is the client, and the root of every operation the contract publishes:
/// `studio.itineraries.getItinerary(itinerary_id:)`, `tiles.getZonesSpecification()`,
/// `data.directions(input:)`.
///
/// It is immutable: its stored properties are constants of `Sendable` types, which is what makes
/// it `Sendable` without an actor. Where its credential carries a session source, the client
/// holds a subscription to it for as long as it lives, so a headless app that never renders
/// still keeps its session fresh.
public final class Mountaya: Sendable {
  /// sender is the seam every operation is sent through, the core's printed methods' and the
  /// admin unit's, which reaches it as a `package` declaration (SPEC.md section 2).
  package let sender: any OperationSending
  /// subscription keeps a session source's minting running for the client's lifetime.
  private let subscription: AsyncStream<SessionSnapshot>?
  /// mapCredential is the credential and the Tile API's origin a map's own requests are read
  /// against, or nil for a client built over a seam of its own, which a map sends nothing for.
  private let mapCredential: (credential: Credential, tiles: URL)?
  /// timing is the clock the client measures every wait and every budget on and its attempt
  /// budget, or nil for a client built over a seam of its own.
  private let timing: (sleeper: any Sleeper, timeout: Duration)?

  /// language is the language every request carries as `Accept-Language`, or nil where the client
  /// asks for none in particular. A map given no label language of its own labels in this one,
  /// so the labels on a map and the words the API answers in are one language.
  public let language: String?

  /// baseUrls is the address each surface is reached at, as the client was built with them, which
  /// a map tells a refusal of the layers manifest at, since the client's refusal carries a status
  /// and no address.
  public let baseUrls: BaseURLs

  /// Creates a client that sends every operation through `sender`.
  init(sender: any OperationSending) {
    self.sender = sender
    self.subscription = nil
    self.mapCredential = nil
    self.timing = nil
    self.language = nil
    self.baseUrls = .standard
  }

  /// Creates a client for `credential`.
  ///
  /// `language` rides every request as `Accept-Language`, and no method takes one; a client
  /// given none asks for no language in particular, never for the device's. `retry` and
  /// `timeout` are the client's retry policy and attempt budget, which a call's `options` may
  /// override. `onResponse` is told of every attempt an answer came back to, and nothing it does
  /// changes what a call answers.
  ///
  /// The last four are seams, each the platform's where none is given: `exchange` is what every
  /// attempt leaves through, a `SystemExchange` over `URLSession` by default; `clock` is what
  /// every wait and every budget is measured on; `random` is what every wait's jitter and every
  /// drawn `Idempotency-Key` come from; and `wallClock` is what the current instant is read from,
  /// which a `Retry-After` date, a spent monthly allowance's renewal and an event stream's token
  /// expiry are read against.
  ///
  /// It throws `ConfigurationError` for a credential or a language no request could carry, for a
  /// base URL with no scheme, which names no place without a page, and for a timeout of zero or
  /// less.
  public init(
    credential: Credential,
    language: String? = nil,
    baseUrls: BaseURLs = .standard,
    retry: RetryPolicy = .standard,
    timeout: Duration = .seconds(30),
    onResponse: (@Sendable (ResponseReport) -> Void)? = nil,
    exchange: (any HTTPExchange)? = nil,
    clock: (any Clock<Duration>)? = nil,
    random: (any RandomSource)? = nil,
    wallClock: (any WallClock)? = nil
  ) throws(MountayaError) {
    try CredentialHeaders.check(credential)
    try CredentialHeaders.checkLanguage(language)
    try baseUrls.check()
    try AttemptBudget.check(timeout, as: "The client's timeout")
    self.language = language
    self.baseUrls = baseUrls
    self.mapCredential = (credential, baseUrls.tiles)
    let sleeper: any Sleeper = clock.map { ClockSleeper(clock: $0) } ?? TaskSleeper()
    self.timing = (sleeper, timeout)
    self.sender = Transport(
      configuration: Transport.Configuration(
        credential: credential,
        language: language,
        baseUrls: baseUrls,
        retry: retry,
        timeout: timeout,
        onResponse: onResponse
      ),
      exchange: exchange ?? SystemExchange(),
      sleeper: sleeper,
      wallClock: wallClock ?? SystemWallClock(),
      random: random ?? SystemRandomSource()
    )
    if case .publishable(_, .source(let source)?) = credential {
      self.subscription = source.subscribe()
    } else {
      self.subscription = nil
    }
  }

  /// mapRequestHeaders returns the headers a request a map renderer makes for itself carries, for
  /// a tile, a style, a sprite or a glyph, where `url` is the Tile API's, and nil where it is not:
  /// a request bound for any other host a style names is sent no credential at all.
  ///
  /// The headers are the client's credential as a tile route declares one, every route a map
  /// fetches for itself declaring the same: the publishable key with the session token as it reads
  /// now, or the share token alone with the visitor's `Cookie` where its source answers one, and
  /// the client's language as `Accept-Language`, `*` where it names none, as a call carries it,
  /// with `X-Mountaya-Client` naming this SDK and its version beside them. A session token is read
  /// and never waited for, since a renderer asks for a request's headers on a thread of its own and
  /// cannot await, so a tile asked for while a first token is on its way goes out under the key
  /// alone.
  ///
  /// It throws `ConfigurationError` where the session token read now cannot be sent, where the
  /// visitor's cookie holds a character outside printable ASCII, and for a secret key, which
  /// authenticates no route a map fetches.
  public func mapRequestHeaders(for url: URL) throws(MountayaError) -> [String: String]? {
    guard let mapCredential, isTileRequest(url, tiles: mapCredential.tiles) else { return nil }
    var session: ResolvedSession?
    if case .publishable(_, let token?) = mapCredential.credential {
      session = try ResolvedSession.reading(token, snapshot: nil)
    }
    let projection = try CredentialHeaders.project(
      mapCredential.credential,
      session: session,
      language: language,
      for: Self.mapRoute,
      isRead: true
    )
    var headers = projection.headers
    if let cookies = projection.cookies, let cookie = cookies(url) {
      try CredentialHeaders.checkCookie(cookie)
      headers["Cookie"] = cookie
    }
    headers[ClientIdentification.header] = ClientIdentification.value
    return headers
  }

  /// mapRoute is what every route a map fetches for itself declares, the model's `templates`:
  /// it acts as nobody, takes a share token on its own, and requires no session token.
  private static let mapRoute = CredentialDeclaration(acceptsShareToken: true)

  /// mapRouteBudget is the most the Tile API spends on a route a map fetches for itself before it
  /// answers a 504 itself, every template's `x-timeout-ms`.
  private static let mapRouteBudget: Duration = .milliseconds(30_000)

  /// publishableKey is the publishable key the client holds, which a map reads its organization
  /// with (`map.organization.read`), or nil for a client holding a share token, a secret key or a
  /// seam of its own, which reads none.
  package var publishableKey: String? {
    guard case .publishable(let key, _)? = mapCredential?.credential else { return nil }
    return key
  }

  /// organizationLookupBudget is the time budget of one attempt of `postOrganizationLookup` as the
  /// client sends it (`sdk/SPEC.md` §2), the larger of its attempt budget and the operation's own
  /// plus the margin, 35 seconds for a client stating none: a map draws its watermark once a read of
  /// its organization has gone this long with no answer (`geo.organization.watermark`). It is nil
  /// for a client built over a seam of its own, which reads no organization.
  package var organizationLookupBudget: Duration? {
    timing.map {
      AttemptBudget.budget(
        call: nil, client: $0.timeout, operation: OperationFacts.postOrganizationLookup.timeout)
    }
  }

  /// wait suspends the calling task for `duration` on the clock the client measures every wait and
  /// every budget on, the one it was built with, so a map's waits run on a test's clock as the
  /// client's do. It throws `CancellationError` as soon as the task is cancelled, and returns at once
  /// for a client built over a seam of its own.
  package func wait(for duration: Duration) async throws {
    guard let timing else { return }
    try await timing.sleeper.sleep(for: duration)
  }

  /// mapFile fetches the file of the Tile API at `url`, an address the API itself handed a map,
  /// such as the elevation source's TileJSON document or one of its tiles, through the client's
  /// transport under the credential a map's own requests carry: its retries, its budget, the
  /// credential's refusals and the error ladder, `operationId` naming the route
  /// (`map.readout.open`). Its path, as `url` encodes it, and its query are read off `url` past the
  /// Tile API's address. `departed` is told as each attempt is handed to the client's exchange, so a
  /// caller sending several files can send each once the one before it has left.
  ///
  /// It throws `ConfigurationError` where `url` is not the Tile API's, which no credential of the
  /// client is sent to, and what the transport throws.
  package func mapFile(
    at url: URL, operationId: String, departed: (@Sendable () -> Void)? = nil
  ) async throws -> BinaryResponse {
    guard let mapCredential, isTileRequest(url, tiles: mapCredential.tiles),
      let request = URLComponents(url: url, resolvingAgainstBaseURL: true),
      let base = URLComponents(url: mapCredential.tiles, resolvingAgainstBaseURL: true)
    else {
      throw MountayaError.configuration(
        ConfigurationError(message: "`\(url)` is no address of the Tile API's."))
    }
    var basePath = Substring(base.percentEncodedPath)
    while basePath.last == "/" {
      basePath.removeLast()
    }
    let path = String(request.percentEncodedPath.dropFirst(basePath.count))
    let facts = OperationFacts(
      surface: .tiles, operationId: operationId, method: "GET",
      path: path, idempotent: true,
      credentials: Self.mapRoute, timeout: Self.mapRouteBudget, declaresIdempotencyKey: false,
      isConditional: false, answersNotModified: false, pagination: nil, success: .binary,
      successResponses: [], errorStatuses: [], tasks: [])
    let query = (request.queryItems ?? []).map { QueryItem(name: $0.name, value: $0.value ?? "") }
    var file = OperationRequest(
      facts: facts, query: query, headerFields: [], body: .none, idempotencyKey: nil,
      ifMatch: nil)
    file.departed = departed
    return try await sender.binary(file, options: RequestOptions())
  }

  /// send calls an operation this build prints no method for, by what it declares, and returns
  /// its envelope with `data` read as `Value` and `extensions.metadata` as `Metadata`.
  ///
  /// The call is held to every rule a printed method is: its credential's refusals, its
  /// `Idempotency-Key` and `If-Match`, its budget, its retries and the error ladder. `path` is
  /// the path the request goes to under its surface's origin, already filled in, and `headers`
  /// are the caller's own, which may name none the client writes itself, `X-Mountaya-Client`
  /// among them. `body` is sent in the media type it names, a value as JSON or a form as
  /// `multipart/form-data`, with the `Content-Type` that says so. A request whose `Accept` asks
  /// for `text/event-stream` is refused before any attempt: a stream is opened with
  /// `events(_:path:query:options:)`.
  public func send<Value: Decodable & Sendable, Metadata: Decodable & Sendable>(
    _ operation: OperationDeclaration,
    path: String,
    query: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: RequestBody? = nil,
    idempotencyKey: String? = nil,
    ifMatch: String? = nil,
    options: RequestOptions = RequestOptions()
  ) async throws -> Response<Value, Metadata> {
    let request = OperationRequest(
      facts: OperationFacts(operation, path: path),
      query: query.map { QueryItem(name: $0.name, value: $0.value ?? "") },
      headerFields: headers.sorted { $0.key < $1.key }.map {
        HeaderField(name: $0.key, value: $0.value)
      },
      body: body?.payload ?? .none,
      idempotencyKey: idempotencyKey,
      ifMatch: ifMatch
    )
    return try await sender.envelope(request, options: options)
  }

  /// walk walks a listing this build prints no method for, by what its operation declares, one row
  /// at a time, each read as `Row`, requesting a page only as the rows before it are read
  /// (`transport.pagination.walk`).
  ///
  /// A listing this build prints is walked through its own method, `walk` before its operation's
  /// name, `studio.itineraries.walkGetItineraries()`. Every request of this one sends `query` with
  /// its `limit` replaced by `pageSize`, from 1 to 100, and its `cursor` by the one the walk has
  /// reached, starting from the `cursor` `query` names, so a walk resumes where an earlier one
  /// stopped, and every other name and value as given, each request held to every rule `send` is,
  /// `headers` among them. It reads the next cursor from the envelope's `pagination.next_cursor`,
  /// follows every page for as long as one is named, an empty page included, and stops where none
  /// is, at `maxPages` requests, which raises nothing, or at a cursor it has already sent, which
  /// raises the base `APIError`.
  ///
  /// It is synchronous, as every walk is: it throws `ConfigurationError` here, before any request,
  /// for a `pageSize` or a `maxPages` out of its range, and hands back a stream that requests its
  /// first page as its first row is read. A reading task that is cancelled requests no further page,
  /// and the stream ends as every stream does then.
  public func walk<Row: Decodable & Sendable>(
    _ operation: OperationDeclaration,
    path: String,
    query: [URLQueryItem] = [],
    headers: [String: String] = [:],
    pageSize: Int = 50,
    maxPages: Int? = nil,
    options: RequestOptions = RequestOptions()
  ) throws(MountayaError) -> AsyncThrowingStream<Row, any Error> {
    let walk = try PageWalk(query: DeclaredQuery(query), pageSize: pageSize, maxPages: maxPages) {
      (page: DeclaredQuery) async throws -> Response<[Row], DeclaredPage> in
      let answer: Response<[Row], JSONValue?> = try await self.send(
        operation, path: path, query: page.items, headers: headers, options: options)
      return Response(
        data: answer.data, metadata: DeclaredPage(answer.metadata), status: answer.status,
        requestId: answer.requestId, location: answer.location, etag: answer.etag,
        headers: answer.headers)
    }
    return walk.rows()
  }

  /// query calls a Data API operation this build prints no method for, by what it declares,
  /// with `input`, and returns the operation's own field read as `Result`.
  ///
  /// The call is held to every rule a printed method of `data` is: the session token every Data
  /// API request carries, the persisted query's digest, its budget, its retries and the error
  /// ladder. `select` narrows the document sent, as a printed method's does, and a field outside
  /// the operation's tree is refused with `SelectionError` before any request; an answer that
  /// lacks the operation's field is a `DataError`.
  public func query<Input: Encodable & Sendable, Result: Decodable & Sendable>(
    _ operation: DataOperation,
    input: Input,
    select: FieldSelection? = nil,
    options: RequestOptions = RequestOptions()
  ) async throws -> Result {
    try await sender.query(
      operation,
      facts: OperationFacts(declaring: operation),
      input: input,
      select: select,
      options: options
    )
  }

  /// events opens an event stream this build prints no method for, by what its operation
  /// declares, and returns its records.
  ///
  /// The client knows no event of such a stream, so it reads it as a feed: no event ends it, it
  /// is opened again after every close and every drop on a collaboration feed's schedule,
  /// resuming from the last record's id, and it ends on a failure that would repeat itself, or
  /// when the iterating task lets it go. It awaits nothing, since the stream opens as its first
  /// record is asked for, and throws only what it refuses before any request.
  public func events(
    _ operation: OperationDeclaration,
    path: String,
    query: [URLQueryItem] = [],
    options: RequestOptions = RequestOptions()
  ) throws -> EventStream<EventRecord> {
    let request = OperationRequest(
      facts: OperationFacts(operation, path: path, success: .eventStream),
      query: query.map { QueryItem(name: $0.name, value: $0.value ?? "") }
    )
    return try sender.events(request, options: options)
  }
}
