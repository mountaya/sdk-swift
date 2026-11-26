import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GeolocateControlState")
struct GeolocateControlStateTests {
  @Test("a state shows nothing until told, and two are equal where every flag is")
  func flags() {
    #expect(
      GeolocateControlState()
        == GeolocateControlState(isBusy: false, isBlocked: false, isLive: false))
    #expect(GeolocateControlState(isBusy: true) != GeolocateControlState())
    #expect(GeolocateControlState(isBlocked: true) != GeolocateControlState(isLive: true))
  }
}
