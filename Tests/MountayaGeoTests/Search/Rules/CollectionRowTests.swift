import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("collectionRow")
struct CollectionRowTests {
  @Test("a collection counts its itineraries and carries its fields")
  func collection() throws {
    let row = try #require(
      collectionRow(
        DataSchema.CollectionSearchResult {
          $0.id = "col-1"
          $0.name = "Alpine Classics"
          $0.isPrivate = true
          $0.count = DataSchema.CollectionCount { $0.itineraries = 7 }
        }, query: "classic"))
    #expect(row.id == "collection:col-1")
    #expect(utf16(row.matched, in: row.title) == [7..<14])
    #expect(row.secondary == .count(itineraries: 7))
    #expect(
      row.payload
        == .collection(
          collectionId: "col-1", name: "Alpine Classics", description: nil, isPrivate: true))
    #expect(collectionRow(DataSchema.CollectionSearchResult { $0.name = "x" }, query: "") == nil)
  }
}
