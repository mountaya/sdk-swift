import Foundation
import Testing

@testable import MountayaClient

@Suite("ErrorEnvelope")
struct ErrorEnvelopeTests {
  private static func read(_ text: String) -> ErrorEnvelope.Read {
    ErrorEnvelope.read(Data(text.utf8))
  }

  @Test("an entry is an object with a string message; its code and path are read where they are")
  func entries() {
    let read = Self.read(
      #"""
      {"errors": [42, {"message": "no code"}, {"extensions": {"code": "VALIDATION_FAILED"},
       "message": "Too long.", "path": ["request", "body", "waypoints", 0, "name"]},
       {"message": 7}, {"message": "odd path", "path": [true]}]}
      """#)

    #expect(read.errors.count == 3)
    #expect(read.errors[0] == ErrorEntry(message: "no code"))
    #expect(read.errors[1].code == "VALIDATION_FAILED")
    #expect(
      read.errors[1].path == [
        .key("request"), .key("body"), .key("waypoints"), .index(0), .key("name"),
      ])
    #expect(read.errors[2].path == nil)
    #expect(read.hasErrors)
  }

  @Test("errors that are no list carry no entry and still say the body carried errors")
  func errorsThatAreNoList() {
    let read = Self.read(#"{"errors": "conflict"}"#)

    #expect(read.errors.isEmpty)
    #expect(read.hasErrors)
    #expect(!Self.read(#"{"errors": null}"#).hasErrors)
  }

  @Test("the metadata is kept exactly as sent, and a body that is no JSON object carries nothing")
  func metadata() {
    let read = Self.read(#"{"errors": [], "extensions": {"metadata": {"holder": {"id": "m1"}}}}"#)

    #expect(read.metadata == ["holder": ["id": "m1"]])
    #expect(Self.read(#"{"extensions": {"metadata": null}}"#).metadata == nil)
    #expect(Self.read("not json").errors.isEmpty)
    #expect(!Self.read("[]").hasErrors)
  }
}
