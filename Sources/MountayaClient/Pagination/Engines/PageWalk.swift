/// PageWalk reads a listing paged by cursor one row at a time, requesting a page only as the
/// rows before it are read.
///
/// The first request carries the caller's own `cursor`, where its query holds one, so a walk
/// resumes where an earlier one stopped; each later one carries the `next_cursor` the page before
/// it named. A page may hold fewer rows than it was asked for, or none, and is followed by its
/// cursor all the same: only a null `next_cursor` ends a listing. The walk stops at that page, at
/// the ceiling on requests the caller states, which leaves the rest unread and raises nothing,
/// or at a cursor it has already sent, which it refuses to follow and raises the base `APIError`
/// for, since following it would read the listing again without end and stopping there would
/// answer part of a listing as if it were the whole.
///
/// A cancelled task requests no further page, and the walk ends with `CancellationError`, never
/// as a listing read to its end. A page that throws `CancellationError` while its task runs on,
/// a request the platform cancelled, ends the walk the same way: a later `next()` returns nil and
/// requests nothing.
public struct PageWalk<Query: PagedQuery, Row: Sendable>: AsyncSequence, Sendable {
  /// Element is one row.
  public typealias Element = Row

  /// defaultPageSize is how many rows a page is asked for where the caller names none.
  public static var defaultPageSize: Int {
    50
  }

  /// maxPageSize is the most rows the API puts on a page.
  public static var maxPageSize: Int {
    100
  }

  private let query: Query
  private let pageSize: Int
  private let maxPages: Int?
  private let page: @Sendable (Query) async throws -> Page

  /// Page is one page as the walk reads it.
  struct Page: Sendable {
    let rows: [Row]
    let nextCursor: String?
    let status: Int
    let requestId: String?
  }

  /// Creates a walk over the listing `page` requests, from the caller's `query`.
  ///
  /// `pageSize` is how many rows each request asks for, from 1 to 100, and `maxPages` the most
  /// requests the walk makes, at least 1, or nil for none: the listing is then read to its last
  /// page. Either out of its range throws `ConfigurationError`, before any request.
  public init<Metadata: PageMetadata>(
    query: Query,
    pageSize: Int = PageWalk.defaultPageSize,
    maxPages: Int? = nil,
    page: @escaping @Sendable (Query) async throws -> Response<[Row], Metadata>
  ) throws(MountayaError) {
    guard (1...Self.maxPageSize).contains(pageSize) else {
      throw .configuration(
        ConfigurationError(
          message: "A page holds from 1 to \(Self.maxPageSize) rows, and \(pageSize) is asked for."
        )
      )
    }
    if let maxPages, maxPages < 1 {
      throw .configuration(
        ConfigurationError(
          message: "A walk makes at least one request, and a ceiling of \(maxPages) allows none."
        )
      )
    }
    self.query = query
    self.pageSize = pageSize
    self.maxPages = maxPages
    self.page = { query in
      let response = try await page(query)
      return Page(
        rows: response.data,
        nextCursor: response.metadata.nextCursor,
        status: response.status,
        requestId: response.requestId
      )
    }
  }

  /// makeAsyncIterator starts a walk from the caller's query.
  public func makeAsyncIterator() -> Iterator {
    Iterator(walk: self)
  }

  /// Iterator is one walk of the listing.
  public struct Iterator: AsyncIteratorProtocol, Sendable {
    private let walk: PageWalk
    private var place: Place

    init(walk: PageWalk) {
      self.walk = walk
      self.place = Place(cursor: walk.query.cursor)
    }

    /// next returns the next row, requesting the page that holds it where it is not yet read.
    public mutating func next() async throws -> Row? {
      try await walk.row(after: &place)
    }
  }

  /// Place is where one walk of the listing stands: the rows of the page read and not yet handed
  /// on, the cursor the next page is asked from, every cursor sent, the requests made, whether the
  /// listing is over, and the refusal raised once the rows before it are handed on.
  struct Place: Sendable {
    var rows: ArraySlice<Row> = []
    var cursor: String?
    var sent: Set<String> = []
    var requested = 0
    var isOver = false
    var refusal: MountayaError?
  }

  /// row answers the next row of a walk standing at `place`, requesting the page that holds it
  /// where it is not yet read, and moves `place` on.
  func row(after place: inout Place) async throws -> Row? {
    while true {
      if let row = place.rows.popFirst() {
        return row
      }
      if let refusal = place.refusal {
        place.refusal = nil
        place.isOver = true
        throw refusal
      }
      if place.isOver {
        return nil
      }
      if let maxPages, place.requested >= maxPages {
        place.isOver = true
        return nil
      }
      try Task.checkCancellation()
      var query = self.query
      query.cursor = place.cursor
      query.limit = pageSize
      if let cursor = place.cursor {
        place.sent.insert(cursor)
      }
      let page: Page
      do {
        page = try await self.page(query)
      } catch let cancellation as CancellationError {
        place.isOver = true
        throw cancellation
      }
      place.requested += 1
      place.rows = page.rows[...]
      guard let next = page.nextCursor else {
        place.isOver = true
        continue
      }
      if place.sent.contains(next) {
        place.refusal = .api(
          APIError(kind: .other, status: page.status, requestId: page.requestId, cause: nil))
        continue
      }
      place.cursor = next
    }
  }

  /// rows is the walk as a stream that requests each page only as the rows before it are read, from
  /// the caller's query, for a walk whose query is no type of the caller's. The stream ends where
  /// the walk does, with its refusal where it raises one, and with nothing more once the reading
  /// task is cancelled, as every stream ends: no page is requested after it.
  func rows() -> AsyncThrowingStream<Row, any Error> {
    let reader = Reader(walk: self)
    return AsyncThrowingStream { try await reader.next() }
  }

  /// Reader holds one walk's place between the rows a stream hands on, each asked for in turn. It
  /// is an actor: the stream's `@Sendable` closure moves its place across an await, which no lock
  /// can hold.
  actor Reader {
    private let walk: PageWalk
    private var place: Place

    init(walk: PageWalk) {
      self.walk = walk
      self.place = Place(cursor: walk.query.cursor)
    }

    /// next answers the walk's next row, requesting the page that holds it where it is not yet
    /// read.
    func next() async throws -> Row? {
      var place = self.place
      defer { self.place = place }
      return try await walk.row(after: &place)
    }
  }
}
