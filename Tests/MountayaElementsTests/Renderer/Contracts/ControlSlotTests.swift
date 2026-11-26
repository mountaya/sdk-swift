import Testing

@testable import MountayaElements

@Suite("ControlSlot")
struct ControlSlotTests {
  @Test("the stack reads zoom, the panel toggles as a group, the app's own, geolocate, the compass")
  func order() {
    #expect(
      ControlSlot.stack(
        zoom: true, layers: true, pois: true, preferences: true, geolocate: true, compass: true)
        == [.zoom, .panels([.layers, .pois, .preferences]), .content, .geolocate, .compass])
  }

  @Test("each control is off until its flag turns it on, the app's own standing whatever")
  func flags() {
    #expect(
      ControlSlot.stack(
        zoom: false, layers: false, pois: false, preferences: false, geolocate: false,
        compass: false) == [.content])
    #expect(
      ControlSlot.stack(
        zoom: false, layers: false, pois: true, preferences: false, geolocate: false,
        compass: true) == [.panels([.pois]), .content, .compass])
    #expect(
      ControlSlot.stack(
        zoom: true, layers: false, pois: false, preferences: true, geolocate: true,
        compass: false) == [.zoom, .panels([.preferences]), .content, .geolocate])
  }
}
