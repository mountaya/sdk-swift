import Testing

@testable import MountayaGeo

@Suite("NavigationInstructionArgument")
struct NavigationInstructionArgumentTests {
  @Test("an instruction takes an exit and a name")
  func exitAndName() {
    #expect(NavigationInstructionArgument.allCases.map(\.id) == ["exit", "name"])
  }
}
