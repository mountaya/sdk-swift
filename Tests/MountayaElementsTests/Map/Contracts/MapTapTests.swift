import MountayaElements
import Testing

@Suite("MapTap")
struct MapTapTests {
  @Test("a tap is the place, the point and the marker tapped, each compared as Geo's values are")
  func equality() {
    let tap = MapTap(position: [6.86, 45.83], point: [120, 340], marker: "hut")

    #expect(tap.marker == "hut")
    #expect(tap == MapTap(position: [6.86, 45.83], point: [120, 340], marker: "hut"))
    #expect(tap != MapTap(position: [6.86, 45.83], point: [120, 340]))
    #expect(tap != MapTap(position: [6.86, 45.83], point: [121, 340], marker: "hut"))
    #expect(
      MapTap(position: [.nan, 0], point: [0, 0]) == MapTap(position: [.nan, 0], point: [0, 0]))
    #expect(
      MapTap(position: [0, 0], point: [0, 0]) != MapTap(position: [-0.0, 0], point: [0, 0]))
  }
}
