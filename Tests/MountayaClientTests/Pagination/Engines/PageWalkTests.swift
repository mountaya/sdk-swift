import Testing

@testable import MountayaClient

@Suite("PageWalk")
struct PageWalkTests {
  private struct Query: PagedQuery {
    var cursor: String?
    var limit: Int?
    var role = "admin"
  }

  /// Listing answers each page by its cursor and records every query it was sent.
  private actor Listing {
    private let pages: [String?: (rows: [Int], next: String?)]
    private(set) var queries: [Query] = []

    init(_ pages: [String?: (rows: [Int], next: String?)]) {
      self.pages = pages
    }

    func page(_ query: Query) throws -> Response<[Int], RestSchema.ListMetadata> {
      queries.append(query)
      let page = pages[query.cursor] ?? ([], nil)
      return Response(
        data: page.rows,
        metadata: RestSchema.ListMetadata(
          pagination: RestSchema.PaginationMetadata(limit: query.limit ?? 0, next_cursor: page.next)
        ))
    }
  }

  @Test("rows are read through every page, an empty one included, each request carrying the rest")
  func walks() async throws {
    let listing = Listing([nil: ([0, 1], "c2"), "c2": ([], "c2x"), "c2x": ([2], nil)])
    let walk = try PageWalk(query: Query(limit: 9), pageSize: 2) { try await listing.page($0) }
    var rows: [Int] = []
    for try await row in walk {
      rows.append(row)
    }

    #expect(rows == [0, 1, 2])
    #expect(await listing.queries.map(\.cursor) == [nil, "c2", "c2x"])
    #expect(await listing.queries.allSatisfy { $0.limit == 2 && $0.role == "admin" })
  }

  @Test("a page is requested only as the rows before it are read, up to the ceiling")
  func lazyAndBounded() async throws {
    let listing = Listing([nil: ([0], "c1"), "c1": ([1], "c2"), "c2": ([2], nil)])
    let walk = try PageWalk(query: Query(cursor: nil), maxPages: 2) { try await listing.page($0) }
    var iterator = walk.makeAsyncIterator()

    #expect(try await iterator.next() == 0)
    #expect(await listing.queries.count == 1)
    #expect(try await iterator.next() == 1)
    #expect(try await iterator.next() == nil)
    #expect(await listing.queries.count == 2)
  }

  @Test("a cursor sent before is refused with the base APIError once its page is read")
  func repeatedCursor() async throws {
    let listing = Listing(["c5": ([5], "c6"), "c6": ([6], "c5")])
    let walk = try PageWalk(query: Query(cursor: "c5")) { try await listing.page($0) }
    var rows: [Int] = []

    await #expect(throws: MountayaError.self) {
      for try await row in walk {
        rows.append(row)
      }
    }
    #expect(rows == [5, 6])
  }

  @Test("a page size or a ceiling out of its range is refused before any request")
  func refused() {
    for (size, ceiling) in [(0, nil), (101, nil), (50, 0)] as [(Int, Int?)] {
      #expect(throws: MountayaError.self) {
        try PageWalk(query: Query(), pageSize: size, maxPages: ceiling) {
          (_: Query) -> Response<[Int], RestSchema.ListMetadata> in
          throw CancellationError()
        }
      }
    }
  }

  @Test("a cancelled task requests no further page and ends the walk with CancellationError")
  func cancelled() async throws {
    let listing = Listing([nil: ([0], "c1"), "c1": ([1], nil)])
    let walk = try PageWalk(query: Query()) { try await listing.page($0) }
    let task = Task {
      var iterator = walk.makeAsyncIterator()
      _ = try await iterator.next()
      withUnsafeCurrentTask { $0?.cancel() }
      return try await iterator.next()
    }
    let result = await task.result

    #expect(throws: CancellationError.self) { try result.get() }
    #expect(await listing.queries.count == 1)
  }

  /// The transport throws the cancellation its exchange reports as it is, so a page's request the
  /// platform cancelled reaches the walk as `CancellationError` while its task runs on.
  @Test("a cancellation a page throws ends the walk as it is, and no further page is requested")
  func pageCancelled() async throws {
    let listing = Listing([nil: ([0], "c1"), "c1": ([1], "c2"), "c2": ([2], nil)])
    let walk = try PageWalk(query: Query()) {
      (query: Query) -> Response<[Int], RestSchema.ListMetadata> in
      if query.cursor == "c1" {
        _ = try await listing.page(query)
        throw CancellationError()
      }
      return try await listing.page(query)
    }
    var iterator = walk.makeAsyncIterator()

    #expect(try await iterator.next() == 0)
    await #expect(throws: CancellationError.self) { _ = try await iterator.next() }
    #expect(try await iterator.next() == nil)
    #expect(await listing.queries.map(\.cursor) == [nil, "c1"])
  }
}
