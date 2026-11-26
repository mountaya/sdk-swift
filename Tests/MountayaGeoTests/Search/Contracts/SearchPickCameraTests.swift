import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchPickCamera")
struct SearchPickCameraTests {
  @Test("two moves are equal where they are of one kind holding the same numbers")
  func equality() {
    #expect(SearchPickCamera.fit(bounds: [6, 45, 7, .nan]) == .fit(bounds: [6, 45, 7, .nan]))
    #expect(SearchPickCamera.fit(bounds: [0, 45, 7, 46]) != .fit(bounds: [-0.0, 45, 7, 46]))
    #expect(SearchPickCamera.fly(center: [6, 45], zoom: 13) == .fly(center: [6, 45], zoom: 13))
    #expect(SearchPickCamera.fly(center: [6, 45], zoom: 13) != .fly(center: [6, 45], zoom: 12))
    #expect(
      SearchPickCamera.fly(center: [6, 45, 7, 46], zoom: 13) != .fit(bounds: [6, 45, 7, 46]))
    #expect(
      SearchPickCamera.fly(center: [6, 45], zoom: .nan).hashValue
        == SearchPickCamera.fly(center: [6, 45], zoom: .nan).hashValue)
  }
}
