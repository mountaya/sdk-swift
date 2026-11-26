import Testing

@testable import MountayaGeo

@Suite("WaypointField")
struct WaypointFieldTests {
  @Test("two fields are equal where every text is written alike, or absent on both")
  func equality() {
    let field = WaypointField(
      key: "page", label: "Page", value: "https://a.example", href: "https://a.example")
    #expect(
      field
        == WaypointField(
          key: "page", label: "Page", value: "https://a.example", href: "https://a.example"))
    #expect(field != WaypointField(key: "page", label: "Page", value: "https://a.example"))
    #expect(WaypointField(key: "k", label: "l", value: "v").href == nil)
    #expect(
      field.hashValue
        == WaypointField(
          key: "page", label: "Page", value: "https://a.example", href: "https://a.example"
        ).hashValue)
  }
}
