import Testing

@testable import MountayaGeo

@Suite("ProfileClass")
struct ProfileClassTests {
  @Test("two classified stretches are equal where their ends, colour and word are")
  func equality() {
    let path = ProfileClass(from: 0, to: 500, color: "#2f9e44", label: "Path")
    #expect(path == ProfileClass(from: 0, to: 500, color: "#2f9e44", label: "Path"))
    #expect(
      path.hashValue == ProfileClass(from: 0, to: 500, color: "#2f9e44", label: "Path").hashValue)
    #expect(path != ProfileClass(from: 0, to: 500, color: "#2f9e44", label: "Trail"))
    #expect(path != ProfileClass(from: 0, to: 501, color: "#2f9e44", label: "Path"))
  }
}
