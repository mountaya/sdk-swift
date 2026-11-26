import Foundation
import GateSupport
import MountayaAdmin
import MountayaClient
import Simulation

extension PublicRunners {
  /// responseEnvelope answers with what a method returns from the case's body, sent by a scripted
  /// exchange as a 200.
  ///
  /// A REST case calls an operation by its declaration, reading `data` and `extensions.metadata`
  /// as open JSON, and writes the envelope back as it came: `extensions` beside `data` where the
  /// answer carried metadata. A REST case naming an `operation` calls that operation's generated
  /// method instead, its `request` built as a caller builds the body, read through the body type's
  /// own decoding, and answers `reads`: the envelope the method returned, written back through the
  /// generated types' own coding, read at each JSON Pointer the case asks about, a member the
  /// written envelope leaves out reading as null. A Data API case calls the generated
  /// `directions`, the operation the case names, and writes its result back as JSON.
  static let responseEnvelope = Runner(id: "transport.response.envelope", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    guard let body = input["body"] else {
      throw FixtureError(description: "the input has no `body`")
    }
    let surface = try input.string(at: "surface")
    let operation = try input.optionalString(at: "operation")
    let request = input["request"]
    let pointers = (fixtureCase.expect["reads"]?.members ?? []).map(\.key)
    return try await Simulation.run { simulation in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [.answer(status: 200, body: Scripted.json(body))]
      )
      switch surface {
      case "rest" where operation != nil:
        let client = try Scripted.client(
          simulation,
          exchange: exchange,
          credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc")
        )
        let written: OrderedJSON
        do {
          written = try await Self.envelope(
            calling: operation ?? "", request: request, on: client)
        } catch let error as MountayaError {
          return .value(
            .object([
              OrderedJSON.Member(key: "reads", value: .null),
              OrderedJSON.Member(key: "refused", value: .string(error.name)),
            ]))
        }
        return .value(
          .object([
            OrderedJSON.Member(
              key: "reads",
              value: .object(
                try pointers.map {
                  OrderedJSON.Member(key: $0, value: try Self.read(written, at: $0) ?? .null)
                })),
            OrderedJSON.Member(key: "refused", value: .null),
          ]))
      case "rest":
        let client = try Scripted.client(simulation, exchange: exchange)
        let response: Response<JSONValue, JSONValue?> = try await client.send(
          OperationDeclaration(operationId: "readEnvelope", method: "GET", idempotent: true),
          path: "/v1/things"
        )
        var envelope = [OrderedJSON.Member(key: "data", value: Scripted.ordered(response.data))]
        if let metadata = response.metadata {
          envelope.append(
            OrderedJSON.Member(
              key: "extensions",
              value: .object([
                OrderedJSON.Member(key: "metadata", value: Scripted.ordered(metadata))
              ])
            )
          )
        }
        return .value(Self.envelopeAnswer(refused: nil, returned: .object(envelope)))
      case "data":
        guard try input.string(at: "operation") == "directions" else {
          throw FixtureError(description: "the runner calls `directions` and nothing else")
        }
        let client = try Scripted.client(
          simulation,
          exchange: exchange,
          credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc")
        )
        do {
          let result = try await client.data.directions(
            input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]])
          )
          let written = try JSONEncoder().encode(result)
          return .value(
            Self.envelopeAnswer(
              refused: nil,
              returned: try OrderedJSON.parse(String(decoding: written, as: UTF8.self)))
          )
        } catch let error as MountayaError {
          return .value(Self.envelopeAnswer(refused: .string(error.name), returned: .null))
        }
      default:
        throw FixtureError(description: "no surface is called `\(surface)`")
      }
    }
  }

  /// envelope calls the generated method of `operation`, with the body `request` describes where
  /// it takes one, and returns the envelope it answered written back as JSON through the generated
  /// types' own coding.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func envelope(
    calling operation: String, request: OrderedJSON?, on client: Mountaya
  ) async throws -> OrderedJSON {
    switch operation {
    case "getOrganizationAiProviderConfig":
      return try written(
        await client.admin.organizations.getOrganizationAiProviderConfig(organization_id: "org"))
    case "patchOrganizationAiProviderConfig":
      guard let request else {
        throw FixtureError(description: "a write with no `request`")
      }
      let body = try JSONDecoder().decode(
        AdminSchema.AiProviderConfigUpdateParams.self, from: Scripted.json(request))
      return try written(
        await client.admin.organizations.patchOrganizationAiProviderConfig(
          organization_id: "org", body: body))
    case "getOrganizationWebhookEvent":
      return try written(
        await client.admin.webhooks.getOrganizationWebhookEvent(
          organization_id: "org", event_id: "019a8eed-e1ad-7753-b049-b0e20d79577b"))
    default:
      throw FixtureError(description: "the runner calls no operation called `\(operation)`")
    }
  }

  /// written writes a response back as the envelope it came in: `data`, and `extensions` holding
  /// `metadata` where the answer carried one.
  private static func written<Payload: Encodable, Metadata: Encodable>(
    _ response: Response<Payload, Metadata?>
  ) throws -> OrderedJSON {
    var members = [OrderedJSON.Member(key: "data", value: try encoded(response.data))]
    if let metadata = response.metadata {
      members.append(
        OrderedJSON.Member(
          key: "extensions",
          value: .object([OrderedJSON.Member(key: "metadata", value: try encoded(metadata))])))
    }
    return .object(members)
  }

  /// encoded writes a value as JSON through its own coding.
  private static func encoded(_ value: some Encodable) throws -> OrderedJSON {
    try OrderedJSON.parse(String(decoding: try JSONEncoder().encode(value), as: UTF8.self))
  }

  /// read returns the value at a JSON Pointer, or nil where nothing is there.
  private static func read(_ value: OrderedJSON, at pointer: String) throws -> OrderedJSON? {
    guard pointer.hasPrefix("/") else {
      throw FixtureError(description: "`\(pointer)` is no JSON Pointer")
    }
    var current: OrderedJSON? = value
    for token in pointer.dropFirst().split(separator: "/", omittingEmptySubsequences: false) {
      let key = token.replacingOccurrences(of: "~1", with: "/")
        .replacingOccurrences(of: "~0", with: "~")
      switch current {
      case .object?:
        current = current?[key]
      case .array(let elements)?:
        current = Int(key).flatMap { elements.indices.contains($0) ? elements[$0] : nil }
      default:
        return nil
      }
    }
    return current
  }

  private static func envelopeAnswer(refused: OrderedJSON?, returned: OrderedJSON) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "refused", value: refused ?? .null),
      OrderedJSON.Member(key: "returned", value: returned),
    ])
  }

  /// paginationWalk walks the case's listing through `PageWalk`, each page requested by its
  /// declaration from a scripted exchange that answers the page whose cursor the request
  /// carries.
  ///
  /// The caller's query is a query of the runner's own, which the walk fills in through the
  /// published `PagedQuery`, and every request is read back off the exchange: the `limit` and the
  /// `cursor` it carried, and the rest of its query. A row is its number in the listing, so the
  /// rows a walk answered are compared as a count where they are the listing's first, and as the
  /// numbers themselves where they are not.
  static let paginationWalk = Runner(id: "transport.pagination.walk", table: .public) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let defaults = fixture.defaults ?? .object([])
    guard
      try (fixture.constants ?? .object([])).integer(at: "maxPageSize")
        == PageWalk<ListingQuery, Int>.maxPageSize,
      try defaults.integer(at: "pageSize") == PageWalk<ListingQuery, Int>.defaultPageSize,
      try defaults.optionalInteger(at: "maxPages") == nil
    else {
      throw FixtureError(description: "the fixture's defaults are not the walk's")
    }
    let input = fixtureCase.input
    let options = input["options"] ?? .object([])
    let pageSize =
      try options.optionalInteger(at: "pageSize") ?? PageWalk<ListingQuery, Int>.defaultPageSize
    let maxPages = try options.optionalInteger(at: "maxPages")
    let abortAfter = try input.optionalInteger(at: "abortAfterRows")
    var pages: [String?: (from: Int, count: Int, next: String?)] = [:]
    for page in try input.array(at: "pages") {
      pages[try page.optionalString(at: "cursor")] = (
        try page.integer(at: "from"), try page.integer(at: "count"),
        try page.optionalString(at: "next")
      )
    }
    var written: [(String, String)] = []
    for member in (input["query"] ?? .object([])).members ?? [] {
      if let text = member.value.stringValue {
        written.append((member.key, text))
      } else if let number = member.value.numberValue, let whole = Int(exactly: number) {
        written.append((member.key, String(whole)))
      } else {
        throw FixtureError(description: "the query's `\(member.key)` is no string or whole number")
      }
    }
    var query = ListingQuery()
    for (name, value) in written {
      switch name {
      case "cursor": query.cursor = value
      case "limit": query.limit = Int(value)
      default: query.rest.append(URLQueryItem(name: name, value: value))
      }
    }
    let listing = pages
    let caller = query

    return try await Simulation.run { simulation in
      let lister = Lister(pages: listing)
      let client = try Scripted.client(simulation, exchange: lister)
      var rows: [Int] = []
      var outcome = "ended"
      do {
        let walk = try PageWalk(query: caller, pageSize: pageSize, maxPages: maxPages) {
          (query: ListingQuery) -> Response<[Int], RestSchema.ListMetadata> in
          try await client.send(
            OperationDeclaration(operationId: "listRows", method: "GET", idempotent: true),
            path: "/v1/rows",
            query: query.items
          )
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
          let collected = Shared<[Int]>([])
          group.addTask {
            for try await row in walk {
              collected.update { $0.append(row) }
              if let abortAfter, collected.value.count >= abortAfter {
                withUnsafeCurrentTask { $0?.cancel() }
              }
            }
          }
          defer { rows = collected.value }
          try await group.waitForAll()
        }
      } catch {
        outcome = Scripted.className(error)
      }
      let requests = await lister.requests
      let limits = Set(requests.map { $0.limit })
      guard limits.count <= 1 else {
        throw FixtureError(description: "the walk's requests carried different limits")
      }
      let others = Set(requests.map { $0.rest })
      guard others.count <= 1 else {
        throw FixtureError(description: "the walk's requests carried different queries")
      }
      let first = listing[caller.cursor].map { $0.from } ?? 0
      let rowsAnswered: OrderedJSON =
        first == 0 && rows == Array(0..<rows.count)
        ? .number(Double(rows.count)) : .array(rows.map { .number(Double($0)) })
      return .value(
        .object([
          OrderedJSON.Member(
            key: "cursors",
            value: .array(requests.map { $0.cursor.map(OrderedJSON.string) ?? .null })),
          OrderedJSON.Member(
            key: "limit", value: limits.first.flatMap { $0 }.map { .number(Double($0)) } ?? .null),
          OrderedJSON.Member(key: "outcome", value: .string(outcome)),
          OrderedJSON.Member(
            key: "query",
            value: .object(
              (others.first ?? []).map {
                OrderedJSON.Member(key: $0.name, value: .string($0.value))
              })
          ),
          OrderedJSON.Member(key: "rows", value: rowsAnswered),
        ])
      )
    }
  }

  /// ListingQuery is a paged listing's query as a caller writes it: the cursor and the limit the
  /// walk fills in, and the rest as written.
  struct ListingQuery: PagedQuery {
    var cursor: String?
    var limit: Int?
    var rest: [URLQueryItem] = []

    var items: [URLQueryItem] {
      var items = rest
      if let cursor {
        items.append(URLQueryItem(name: "cursor", value: cursor))
      }
      if let limit {
        items.append(URLQueryItem(name: "limit", value: String(limit)))
      }
      return items
    }
  }

  /// Lister answers each request with the page whose cursor it carries, its rows numbered from
  /// the page's first, and records what each request carried.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  actor Lister: HTTPExchange {
    /// Request is what one page's request carried under `query`.
    struct Request: Sendable, Hashable {
      let cursor: String?
      let limit: Int?
      let rest: [Item]
    }

    /// Item is one query parameter other than the cursor and the limit.
    struct Item: Sendable, Hashable {
      let name: String
      let value: String
    }

    private let pages: [String?: (from: Int, count: Int, next: String?)]
    private(set) var requests: [Request] = []

    init(pages: [String?: (from: Int, count: Int, next: String?)]) {
      self.pages = pages
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let items = URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
      let cursor = items.first { $0.name == "cursor" }?.value
      let limit = items.first { $0.name == "limit" }?.value.flatMap { Int($0) }
      let rest = items.filter { $0.name != "cursor" && $0.name != "limit" }
        .map { Item(name: $0.name, value: $0.value ?? "") }.sorted { $0.name < $1.name }
      requests.append(Request(cursor: cursor, limit: limit, rest: rest))
      guard let page = pages[cursor] else {
        throw FixtureError(description: "no page is named by the cursor `\(cursor ?? "null")`")
      }
      let rows = (page.from..<(page.from + page.count)).map { OrderedJSON.number(Double($0)) }
      let body = OrderedJSON.object([
        OrderedJSON.Member(key: "data", value: .array(rows)),
        OrderedJSON.Member(
          key: "extensions",
          value: .object([
            OrderedJSON.Member(
              key: "metadata",
              value: .object([
                OrderedJSON.Member(
                  key: "pagination",
                  value: .object([
                    OrderedJSON.Member(key: "limit", value: .number(Double(limit ?? 0))),
                    OrderedJSON.Member(
                      key: "next_cursor", value: page.next.map(OrderedJSON.string) ?? .null),
                  ])
                )
              ])
            )
          ])
        ),
      ])
      return ExchangeResponse(status: 200, body: ExchangeBody(Scripted.json(body)))
    }
  }
}

/// Unsimulated is the failure of a runner on a host with no task executors, which the
/// simulated runners need.
struct Unsimulated: Error, CustomStringConvertible {
  var description: String {
    "this runner needs task executors, which this host does not have"
  }
}
