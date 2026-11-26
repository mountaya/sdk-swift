import Testing

@testable import MountayaGeo

@Suite("NavigationProgress")
struct NavigationProgressTests {
  private func progress(_ along: Double, next: Int? = 1) -> NavigationProgress {
    NavigationProgress(
      along: along, step: 0, next: next,
      toManeuver: NavigationRemainder(distance: 100, duration: 60),
      toArrival: NavigationRemainder(distance: 300, duration: 120))
  }

  @Test("two readings are equal where every member is, and hash alike")
  func equality() {
    #expect(progress(200) == progress(200))
    #expect(progress(200).hashValue == progress(200).hashValue)
    #expect(progress(.nan) == progress(.nan))
    #expect(progress(.nan).hashValue == progress(.nan).hashValue)
    #expect(progress(0) != progress(-0.0))
    #expect(progress(200) != progress(200, next: nil))
  }
}
