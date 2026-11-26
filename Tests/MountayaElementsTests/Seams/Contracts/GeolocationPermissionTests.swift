import MountayaElements
import Testing

@Suite("GeolocationPermission")
struct GeolocationPermissionTests {
  @Test("a permission is denied, granted, to prompt for, or unknown")
  func spellings() {
    #expect(
      GeolocationPermission.allCases.map(\.rawValue) == ["denied", "granted", "prompt", "unknown"])
  }
}
