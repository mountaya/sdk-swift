import Testing

@testable import MountayaNavigation

@Suite("LocationAuthorization")
struct LocationAuthorizationTests {
  @Test("the authorizations are the five a platform states, in the order a reader grants them")
  func cases() {
    #expect(
      LocationAuthorization.allCases == [.notDetermined, .restricted, .denied, .whenInUse, .always])
  }
}
