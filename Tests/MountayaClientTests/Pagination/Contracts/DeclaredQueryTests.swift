import Foundation
import Testing

@testable import MountayaClient

@Suite("DeclaredQuery")
struct DeclaredQueryTests {
  @Test("the caller's names and values are sent in order, then the walk's cursor and limit")
  func items() {
    var query = DeclaredQuery([
      URLQueryItem(name: "sort", value: "-updated_at"), URLQueryItem(name: "limit", value: "9"),
      URLQueryItem(name: "status", value: "draft"), URLQueryItem(name: "cursor", value: "c1"),
      URLQueryItem(name: "flag", value: nil),
    ])

    #expect(query.cursor == "c1")
    #expect(query.limit == 9)
    query.cursor = "c2"
    query.limit = 2
    #expect(
      query.items == [
        URLQueryItem(name: "sort", value: "-updated_at"),
        URLQueryItem(name: "status", value: "draft"), URLQueryItem(name: "flag", value: nil),
        URLQueryItem(name: "cursor", value: "c2"), URLQueryItem(name: "limit", value: "2"),
      ])
  }

  @Test("the first cursor and the first limit the caller names are the walk's, and no other")
  func firstNamed() {
    let query = DeclaredQuery([
      URLQueryItem(name: "cursor", value: "first"), URLQueryItem(name: "cursor", value: "second"),
      URLQueryItem(name: "limit", value: "ten"), URLQueryItem(name: "limit", value: "3"),
    ])

    #expect(query.cursor == "first")
    #expect(query.limit == nil, "a limit that is no number is none")
    #expect(DeclaredQuery([]).items.isEmpty)
    #expect(DeclaredQuery([]).cursor == nil)
  }

  @Test("a page names the next cursor where its metadata states one as text, and none otherwise")
  func nextCursor() {
    let named: JSONValue = .object(["pagination": .object(["next_cursor": .string("c2")])])

    #expect(DeclaredPage(named).nextCursor == "c2")
    #expect(DeclaredPage(nil).nextCursor == nil)
    let null: JSONValue = .object(["pagination": .object(["next_cursor": .null])])
    let number: JSONValue = .object(["pagination": .object(["next_cursor": .number(2)])])
    #expect(DeclaredPage(null).nextCursor == nil)
    #expect(DeclaredPage(number).nextCursor == nil)
    #expect(DeclaredPage(.object(["next_cursor": .string("c2")])).nextCursor == nil)
  }
}
