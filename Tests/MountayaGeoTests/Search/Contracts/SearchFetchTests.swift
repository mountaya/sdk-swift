import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchFetch")
struct SearchFetchTests {
  @Test("a nonisolated fetch of an app's own answers the input it is handed")
  func answers() async throws {
    let fetch: SearchFetch = { input in
      DataSchema.SearchResult { $0.query = input.query }
    }

    let result = try await fetch(
      DataSchema.SearchInput(query: "chamonix", targets: DataSchema.SearchTargetsInput()))
    #expect(result.query == "chamonix")
  }
}
