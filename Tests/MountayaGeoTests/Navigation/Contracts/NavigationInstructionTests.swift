import Testing

@testable import MountayaGeo

@Suite("NavigationInstruction")
struct NavigationInstructionTests {
  @Test("two instructions are equal where the key and its arguments are, and hash alike")
  func equality() {
    let exit = NavigationInstruction(key: .roundaboutExit, name: "Avenue Michel Croz", exit: 2)

    #expect(
      exit == NavigationInstruction(key: .roundaboutExit, name: "Avenue Michel Croz", exit: 2))
    #expect(
      exit.hashValue
        == NavigationInstruction(key: .roundaboutExit, name: "Avenue Michel Croz", exit: 2)
        .hashValue)
    #expect(
      exit != NavigationInstruction(key: .roundaboutExit, name: "Avenue Michel Croz", exit: 3))
    #expect(
      NavigationInstruction(key: .turnLeftPlain) != NavigationInstruction(key: .turnRightPlain))
    #expect(
      NavigationInstruction(key: .turnLeft, name: "Pr\u{E9}")
        != NavigationInstruction(key: .turnLeft, name: "Pre\u{301}"))
  }
}
