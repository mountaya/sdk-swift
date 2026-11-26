import MountayaClient

/// SearchFetch is how one request of a search reaches the Data API: the app's call that answers a
/// search input with a search result, `client.data.search(input:)` in one line, or a call through a
/// transport of its own.
///
/// It is the seam that keeps one search: the engine holds the whole of a round above it, the typing
/// pause, the request per branch, the abandon of a round a later one replaced, the fall back from
/// the visible area and the rows, whoever makes the request. A request a round abandons is
/// withdrawn by cancelling its task, which a call through the client hands its transport.
public typealias SearchFetch =
  @Sendable (DataSchema.SearchInput) async throws -> DataSchema.SearchResult
