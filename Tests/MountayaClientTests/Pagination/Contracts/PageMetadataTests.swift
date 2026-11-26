import Testing

@testable import MountayaClient

@Suite("PageMetadata")
struct PageMetadataTests {
  @Test("a listing's metadata names the cursor of the page after it, none on the last")
  func nextCursor() {
    let more = RestSchema.ListMetadata(
      pagination: RestSchema.PaginationMetadata(limit: 50, next_cursor: "c50"))
    let last = RestSchema.ListMetadata(
      pagination: RestSchema.PaginationMetadata(limit: 50, next_cursor: nil))

    #expect(more.nextCursor == "c50")
    #expect(last.nextCursor == nil)
  }
}
