import Testing

@testable import MountayaNavigation

@Suite("LocationStanding")
struct LocationStandingTests {
  @Test("two standings are equal where both members are")
  func equality() {
    let granted = LocationStanding(authorization: .whenInUse, accuracy: .full)
    #expect(granted == LocationStanding(authorization: .whenInUse, accuracy: .full))
    #expect(
      granted.hashValue == LocationStanding(authorization: .whenInUse, accuracy: .full).hashValue)
    #expect(granted != LocationStanding(authorization: .always, accuracy: .full))
    #expect(granted != LocationStanding(authorization: .whenInUse, accuracy: .reduced))
  }

  @Test("positions are read only with access granted, while in use or always, at full accuracy")
  func readable() {
    for authorization in LocationAuthorization.allCases {
      for accuracy in LocationAccuracy.allCases {
        let readable = LocationStanding(authorization: authorization, accuracy: accuracy).isReadable
        let granted = authorization == .whenInUse || authorization == .always
        #expect(readable == (granted && accuracy == .full), "\(authorization) at \(accuracy)")
      }
    }
  }
}
