import Testing

@testable import MountayaGeo

@Suite("cameraForBounds")
struct CameraForBoundsTests {
  private static let world = ZoomBounds(minZoom: -2, maxZoom: 22)
  private static let valley: [Double] = [6.8, 45.8, 6.95, 45.9]

  private static func near(_ actual: Double, _ expected: Double) -> Bool {
    abs(actual - expected) <= 1e-9
  }

  @Test("the worked example: the height binds, and the centre is the box's projected middle")
  func workedExample() throws {
    let fitted = try #require(
      cameraForBounds(
        Self.valley, canvas: [800, 600], padding: PixelPadding(48), maxZoom: 15,
        window: Self.world))
    #expect(Self.near(fitted.zoom, 11.269337026503), "\(fitted.zoom)")
    #expect(Self.near(fitted.center[0], 6.875))
    #expect(Self.near(fitted.center[1], 45.850022473736), "\(fitted.center)")
    let unpadded = try #require(
      cameraForBounds(Self.valley, canvas: [800, 600], window: Self.world))
    #expect(Self.near(unpadded.zoom, 11.520875793499), "no padding frames closer")
  }

  @Test("the fit's ceiling holds first, then the window, whose ceiling holds under a higher one")
  func ceilings() throws {
    let short: [Double] = [6.864, 45.828, 6.866, 45.8295]
    #expect(
      cameraForBounds(
        short, canvas: [800, 600], padding: PixelPadding(20), maxZoom: 15, window: Self.world)?
        .zoom == 15)
    #expect(
      cameraForBounds(
        short, canvas: [800, 600], padding: PixelPadding(10), maxZoom: 20,
        window: ZoomBounds(minZoom: -2, maxZoom: 16))?.zoom == 16)
    // A box of one point fits at every zoom, so it is framed at the ceiling, on its point.
    let point = try #require(
      cameraForBounds(
        [6.86, 45.83, 6.86, 45.83], canvas: [800, 600], window: ZoomBounds(minZoom: -2, maxZoom: 18)
      ))
    #expect(point.zoom == 18)
    #expect(Self.near(point.center[0], 6.86) && Self.near(point.center[1], 45.83), "\(point)")
  }

  @Test("the window's floor holds a box too wide")
  func floor() throws {
    let fitted = try #require(
      cameraForBounds(
        [-10, 35, 30, 60], canvas: [400, 300], window: ZoomBounds(minZoom: 6, maxZoom: 22)))
    #expect(fitted.zoom == 6)
    #expect(Self.near(fitted.center[1], 49.040931781425), "\(fitted.center)")
  }

  @Test("uneven padding moves the centre by half the difference, at the zoom the camera lands at")
  func unevenPadding() throws {
    let fitted = try #require(
      cameraForBounds(
        Self.valley, canvas: [1000, 600],
        padding: PixelPadding(top: 20, right: 20, bottom: 200, left: 300), maxZoom: 16,
        window: Self.world))
    #expect(Self.near(fitted.zoom, 10.861912711334))
    #expect(Self.near(fitted.center[0], 6.822106897827), "\(fitted.center)")
    #expect(Self.near(fitted.center[1], 45.826333220768), "\(fitted.center)")
    // At the window's floor the offset is the floor's, not the zoom the box would fit at.
    let held = try #require(
      cameraForBounds(
        [-10, 35, 30, 60], canvas: [400, 300],
        padding: PixelPadding(top: 10, right: 20, bottom: 90, left: 120),
        window: ZoomBounds(minZoom: 6, maxZoom: 22)))
    #expect(held.zoom == 6)
    #expect(Self.near(held.center[0], 9.45068359375), "\(held.center)")
    #expect(Self.near(held.center[1], 48.752026937686), "\(held.center)")
    // At the window's ceiling, under a higher ceiling of the fit's own, the same.
    let capped = try #require(
      cameraForBounds(
        [6.864, 45.828, 6.866, 45.8295], canvas: [800, 600],
        padding: PixelPadding(top: 20, right: 100, bottom: 160, left: 20), maxZoom: 20,
        window: ZoomBounds(minZoom: -2, maxZoom: 16)))
    #expect(capped.zoom == 16)
    #expect(Self.near(capped.center[0], 6.865429153442), "\(capped.center)")
    #expect(Self.near(capped.center[1], 45.828226688918), "\(capped.center)")
  }

  @Test("a box across the antimeridian is centred past 180, and a southern box on its middle")
  func hemispheres() throws {
    let across = try #require(
      cameraForBounds([179.8, -17, 180.1, -16], canvas: [800, 600], window: Self.world))
    #expect(Self.near(across.center[0], 179.95))
    #expect(Self.near(across.center[1], -16.500646259183))
    #expect(Self.near(across.zoom, 8.659981770471))
    let south = try #require(
      cameraForBounds(
        [-70.2, -33.6, -70, -33.3], canvas: [640, 480], padding: PixelPadding(40),
        window: Self.world))
    #expect(Self.near(south.center[1], -33.450129715122))
    #expect(Self.near(south.zoom, 9.611426075196))
  }

  @Test("a padding that leaves no room, or a box or canvas of the wrong length, frames nothing")
  func noRoom() {
    #expect(
      cameraForBounds(
        Self.valley, canvas: [800, 600], padding: PixelPadding(300), window: Self.world)
        == nil)
    #expect(
      cameraForBounds(
        Self.valley, canvas: [800, 600],
        padding: PixelPadding(top: 0, right: 400, bottom: 0, left: 400),
        window: Self.world) == nil)
    #expect(
      cameraForBounds(
        Self.valley, canvas: [800, 600], padding: PixelPadding(.nan), window: Self.world)
        == nil)
    #expect(cameraForBounds([6.8, 45.8, 6.95], canvas: [800, 600], window: Self.world) == nil)
    #expect(cameraForBounds(Self.valley, canvas: [800], window: Self.world) == nil)
    #expect(cameraForBounds(Self.valley, canvas: [0, 600], window: Self.world) == nil)
  }

  @Test("an edge that is no number is kept unknown")
  func unknownEdge() throws {
    let fitted = try #require(
      cameraForBounds([.nan, 45.8, 6.95, 45.9], canvas: [800, 600], window: Self.world))
    #expect(fitted.zoom.isNaN)
    #expect(fitted.center[0].isNaN)
  }
}
