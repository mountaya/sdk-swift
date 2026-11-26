import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchBranchError")
struct SearchBranchErrorTests {
  @Test("a failure holds its branch, its code and its sentence, none stated by default")
  func members() {
    let failure = SearchBranchError(target: .pois, code: .badGateway, message: "unreachable")

    #expect(failure.target == .pois)
    #expect(failure.code == .badGateway)
    #expect(failure.message == "unreachable")
    #expect(SearchBranchError(target: .zones).code == nil)
    #expect(SearchBranchError(target: .zones).message == nil)
  }

  @Test("two failures are equal where they say the same, each text by its scalars")
  func equality() {
    #expect(SearchBranchError(target: .pois) == SearchBranchError(target: .pois))
    #expect(SearchBranchError(target: .pois) != SearchBranchError(target: .zones))
    #expect(
      SearchBranchError(target: .pois, message: "\u{E9}")
        != SearchBranchError(target: .pois, message: "e\u{301}"))
    #expect(
      SearchBranchError(target: .pois, code: .badGateway)
        != SearchBranchError(target: .pois, code: nil))
  }
}
