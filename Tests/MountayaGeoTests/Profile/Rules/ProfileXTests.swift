import Testing

@testable import MountayaGeo

@Suite("profileX")
struct ProfileXTests {
  @Test("the square, its insets and its baseline are the contract's")
  func constants() {
    #expect(profileViewBox == 100 && profileTopInset == 6 && profileBottomInset == 4)
    #expect(profileBaseline == 96)
  }

  @Test("a distance runs from the window's start at 0 to its end at 100")
  func across() {
    #expect(profileX(500, totalDistance: 1_000) == 50)
    #expect(profileX(1_000, totalDistance: 3_000) == 33.333)
    #expect(profileX(450, totalDistance: 1_000, window: ProfileRange(from: 200, to: 700)) == 50)
    #expect(profileX(325, totalDistance: 1_000, window: ProfileRange(from: 700, to: 200)) == 25)
  }

  @Test("a distance outside the window is held to the frame")
  func held() {
    #expect(profileX(100, totalDistance: 1_000, window: ProfileRange(from: 200, to: 700)) == 0)
    #expect(profileX(900, totalDistance: 1_000, window: ProfileRange(from: 200, to: 700)) == 100)
    #expect(profileX(-5, totalDistance: 1_000) == 0)
  }

  @Test("an itinerary or a window of no length draws at the origin")
  func noLength() {
    #expect(profileX(0, totalDistance: 0) == 0)
    #expect(profileX(300, totalDistance: 1_000, window: ProfileRange(from: 300, to: 300)) == 0)
    #expect(profileX(300, totalDistance: .nan) == 0)
  }

  @Test("an unclamped projection leaves the frame, rounded to a thousandth a half up")
  func projected() {
    let span = ProfileRange(from: 250, to: 450)
    #expect(projectX(200, span: span) == -25)
    #expect(projectX(500, span: span) == 125)
    #expect(projectX(1, span: ProfileRange(from: 0, to: 0)) == 0)
    #expect(plotUnit(-25.0005) == -25)
    #expect(plotUnit(25.0005) == 25.001)
  }
}
