import Foundation
import Testing

@testable import MountayaClient

@Suite("Envelope")
struct EnvelopeTests {
  @Test("the envelope is read whole, a null data and absent metadata included")
  func rest() throws {
    let read = try Envelope.rest(
      JSONValue.self, metadata: [String: JSONValue]?.self,
      from: Data(#"{"data": null}"#.utf8))
    let paged = try Envelope.rest(
      [Int].self, metadata: RestSchema.ListMetadata.self,
      from: Data(
        #"{"data": [1], "extensions": {"metadata": {"pagination": {"limit": 50, "next_cursor": "c1"}}}}"#
          .utf8))

    #expect(read.data == .null)
    #expect(read.metadata == nil)
    #expect(paged.data == [1])
    #expect(paged.metadata.nextCursor == "c1")
  }

  @Test("metadata the operation declares is refused where the answer carries none")
  func declaredMetadataIsRequired() {
    #expect(throws: DecodingError.self) {
      try Envelope.rest(
        [Int].self, metadata: RestSchema.ListMetadata.self, from: Data(#"{"data": []}"#.utf8))
    }
  }

  @Test("a Data API answer is read for its operation's field, and for its entries")
  func data() throws {
    let answer = try Envelope.data(
      [String: Int].self, operation: "directions",
      from: Data(#"{"data": {"directions": {"routes": 2}}}"#.utf8))
    let missing = try Envelope.data(
      [String: Int].self, operation: "directions", from: Data(#"{"data": {}}"#.utf8))
    let failed = try Envelope.data(
      [String: Int].self, operation: "directions",
      from: Data(#"{"data": null, "errors": [{"message": "Limit must be at most 50."}]}"#.utf8))

    #expect(answer.result == ["routes": 2])
    #expect(missing.result == nil)
    #expect(failed.result == nil)
    #expect(failed.read.errors.first?.message == "Limit must be at most 50.")
  }

  @Test("a Data API answer's entries and metadata are what the whole body says of them")
  func dataRead() throws {
    let bodies = [
      #"{"data": {"directions": {"routes": 2}}}"#,
      #"{"data": {"directions": {"routes": 2}}, "extensions": {"metadata": {"cost": 3}}}"#,
      #"{"data": {"directions": null}, "extensions": {"metadata": null}, "errors": null}"#,
      #"{"data": null, "errors": [{"message": "a", "extensions": {"code": "NOT_FOUND"}}, 1]}"#,
      #"{"data": {"directions": {"routes": 1}}, "errors": "none", "extensions": [1]}"#,
      #"{"errors": [{"message": "b", "path": ["input", 0]}], "extensions": {"metadata": [2]}}"#,
    ]
    for body in bodies {
      let read = try Envelope.data(
        [String: Int].self, operation: "directions", from: Data(body.utf8)
      ).read
      let whole = ErrorEnvelope.read(Data(body.utf8))

      #expect(read.errors == whole.errors, "\(body)")
      #expect(read.hasErrors == whole.hasErrors, "\(body)")
      #expect(read.metadata == whole.metadata, "\(body)")
    }
  }

  /// A number past a `Double`'s range is no JSON value the client reads, so a body read whole as
  /// JSON values first refuses it wherever it stands. The operation's field is read as its type
  /// alone, which reads only the members it declares.
  @Test("a Data API answer's field is read as its type alone, never as JSON values first")
  func dataReadOnce() throws {
    let answer = try Envelope.data(
      [String: Int].self, operation: "directions",
      from: Data(#"{"data": {"directions": {"routes": 2}, "unread": 1e400}}"#.utf8))

    #expect(answer.result == ["routes": 2])
    #expect(answer.read.hasErrors == false)
  }
}
