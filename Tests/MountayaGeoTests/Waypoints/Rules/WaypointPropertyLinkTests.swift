import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointPropertyLink")
struct WaypointPropertyLinkTests {
  @Test("a url field links where its trimmed value is a web address, and no other field does")
  func links() {
    let page = WaypointDetails.Property(
      key: "page", label: "Page", value: " https://refuge.example/page ", format: "url")
    #expect(waypointPropertyLink(page) == "https://refuge.example/page")
    let script = WaypointDetails.Property(
      key: "s", label: "S", value: "javascript:alert(1)", format: "url")
    #expect(waypointPropertyLink(script) == nil)
    let text = WaypointDetails.Property(
      key: "t", label: "T", value: "https://refuge.example/page", format: "text")
    #expect(waypointPropertyLink(text) == nil)
    #expect(
      waypointPropertyLink(
        WaypointDetails.Property(key: "n", label: "N", value: "https://a.example")) == nil)
  }
}
