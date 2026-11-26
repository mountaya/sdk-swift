import MountayaElements
import Testing

@Suite("InertGeolocation")
@MainActor
struct InertGeolocationTests {
  @Test("an inert geolocation never locates, and reads its permission as denied")
  func inert() async {
    let geolocation = InertGeolocation()
    #expect(await geolocation.locate() == .refused(.noApi))
    #expect(await geolocation.permission() == .denied)
  }
}
