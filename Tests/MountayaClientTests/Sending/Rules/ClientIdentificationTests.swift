import Testing

@testable import MountayaClient

@Suite("ClientIdentification")
struct ClientIdentificationTests {
  @Test("a request names the Swift SDK and the package's own version")
  func value() {
    let version = ClientIdentification.version
    let parts = version.split(separator: ".", omittingEmptySubsequences: false)

    #expect(ClientIdentification.header == "X-Mountaya-Client")
    #expect(ClientIdentification.value == "mountaya-swift/\(version)")
    #expect(
      parts.count == 3
        && parts.allSatisfy { part in
          !part.isEmpty && part.allSatisfy { ("0"..."9").contains($0) }
            && (part == "0" || part.first != "0")
        },
      "\(version) is no MAJOR.MINOR.PATCH")
  }

  @Test("it is a header the client writes itself, which no caller's header may name")
  func writtenByTheClient() {
    #expect(Transport.clientHeaders.contains("x-mountaya-client"))
  }
}
