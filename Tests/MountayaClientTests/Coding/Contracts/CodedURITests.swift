import Foundation
import Testing

@testable import MountayaClient

@Suite("CodedURI")
struct CodedURITests {
  /// A type a request carries reads an address as the wire sent it and writes one only where it
  /// has a scheme, so a body with a path or a host alone is refused before any request.
  @Test("a request's address is read as sent and written only with a scheme")
  func scheme() throws {
    let read = try ScriptedSender.decode(CodedURI.self, from: #""refuge.example/topo""#)
    #expect(read.address == URI("refuge.example/topo"))
    #expect(throws: EncodingError.self) { try ScriptedSender.json(read) }

    let sent = CodedURI(URI("https://refuge.example/topo"))
    #expect(try ScriptedSender.json(sent) == #""https://refuge.example/topo""#)
  }
}
