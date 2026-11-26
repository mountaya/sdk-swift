import Testing

@testable import MountayaClient

@Suite("OperationDeclaration")
struct OperationDeclarationTests {
  @Test("a fact left out is the one no operation states by default")
  func defaults() {
    let declaration = OperationDeclaration(operationId: "readThing", method: "GET")

    #expect(declaration.surface == .rest)
    #expect(!declaration.idempotent)
    #expect(declaration.timeout == nil)
    #expect(!declaration.declaresIdempotencyKey)
    #expect(!declaration.isConditional)
    #expect(declaration.credentials == CredentialDeclaration())
  }

  @Test("the facts a declaration states are the ones the transport reads, its path the caller's")
  func facts() {
    let declaration = OperationDeclaration(
      surface: .tiles,
      operationId: "getThing",
      method: "PATCH",
      idempotent: true,
      timeout: .seconds(55),
      declaresIdempotencyKey: true,
      isConditional: true
    )
    let facts = OperationFacts(declaration, path: "/v1/things/th")

    #expect(facts.surface == .tiles)
    #expect(facts.operationId == "getThing")
    #expect(facts.method == "PATCH")
    #expect(facts.path == "/v1/things/th")
    #expect(facts.idempotent)
    #expect(facts.timeout == .seconds(55))
    #expect(facts.declaresIdempotencyKey)
    #expect(facts.isConditional)
    #expect(facts.success == .envelope)
    #expect(facts.pagination == nil)
  }
}
