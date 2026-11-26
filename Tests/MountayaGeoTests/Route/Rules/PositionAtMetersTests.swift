import Testing

@testable import MountayaGeo

@Suite("positionAtMeters")
struct PositionAtMetersTests {
  private let route: [[Double]] = [
    [6.8652, 45.9237], [6.8752, 45.9287], [6.8852, 45.9337], [6.8952, 45.9387], [6.9052, 45.9437],
    [6.9152, 45.9487], [6.9271, 45.9682],
  ]

  private func position(_ actual: [Double], _ expected: [Double]) -> Bool {
    areClose(actual, expected, within: 1e-9)
  }

  @Test("a distance is interpolated between the two vertices that bracket it")
  func interpolated() {
    #expect(
      position(
        positionAtMeters(route, meters: 3_558.7542541420835),
        [6.902563628035973, 45.942381814017985]))
    let equator: [[Double]] = [[0, 0], [1, 0], [2, 0]]
    #expect(position(positionAtMeters(equator, meters: 1.5 * metersPerDegreeMeanSphere), [1.5, 0]))
    #expect(position(positionAtMeters(equator, meters: metersPerDegreeMeanSphere), [1, 0]))
  }

  @Test("a distance is held to the line")
  func held() {
    #expect(positionAtMeters(route, meters: 0) == [6.8652, 45.9237])
    #expect(positionAtMeters(route, meters: -50) == [6.8652, 45.9237])
    #expect(positionAtMeters(route, meters: -.infinity) == [6.8652, 45.9237])
    #expect(positionAtMeters(route, meters: 1e9) == [6.9271, 45.9682])
    #expect(positionAtMeters(route, meters: .infinity) == [6.9271, 45.9682])
  }

  /// Its longitude continues from the leg's first vertex: past 180 eastward, below -180 westward.
  @Test("a leg across the antimeridian is interpolated the short way round")
  func antimeridian() {
    let eastward: [[Double]] = [[179.9, -16.8], [-179.9, -16.8]]
    let westward: [[Double]] = [[-179.9, -16.8], [179.9, -16.8]]
    #expect(position(positionAtMeters(eastward, meters: 15_967.360018304962), [180.05, -16.8]))
    #expect(position(positionAtMeters(westward, meters: 15_967.360018304962), [-180.05, -16.8]))
    #expect(position(positionAtMeters(eastward, meters: 21_289.81335773995 / 2), [180, -16.8]))
  }

  @Test("an altitude is not carried, and a vertex that names no place is bridged")
  func altitudeAndBridge() {
    #expect(positionAtMeters([[6, 45, 1_000], [7, 45]], meters: 0) == [6, 45])
    let bridged: [[Double]] = [[0, 0], [.nan, 0], [5], [2, 0]]
    #expect(position(positionAtMeters(bridged, meters: metersPerDegreeMeanSphere), [1, 0]))
  }

  @Test("a line of one place is that place")
  func onePlace() {
    #expect(positionAtMeters([[6, 45]], meters: 100) == [6, 45])
    #expect(positionAtMeters([[6, 45], [6, 45]], meters: 100) == [6, 45])
  }

  @Test("a line that names no place, or a distance at no number, has no position")
  func noPosition() {
    let nowhere: [Double] = [.nan, .nan]
    #expect(sameNumbers(positionAtMeters([], meters: 0), nowhere))
    #expect(sameNumbers(positionAtMeters([[6], [.nan, 45]], meters: 0), nowhere))
    #expect(sameNumbers(positionAtMeters(route, meters: .nan), nowhere))
  }

  /// lines is every line the route's reading is held to the line's own on: places, a vertex at no
  /// number and one short of a latitude, an altitude, legs across the antimeridian both ways, a line
  /// of one place, of one place twice, and one of none.
  private var lines: [[[Double]]] {
    [
      route,
      [[0, 0], [.nan, 0], [5], [2, 0]],
      [[6, 45, 1_000], [7, 45], [7.5, 45.2, 900]],
      [[179.9, -16.8], [-179.9, -16.8], [-179.7, -16.9]],
      [[-179.9, -16.8], [179.9, -16.8], [.infinity, 3], [179.7, -16.7]],
      [[6, 45]],
      [[6, 45], [6, 45]],
      [[.nan, .nan], [4]],
    ]
  }

  @Test("a followed route is read where its line is read, to the last digit, at every distance")
  func followedRoute() throws {
    for line in lines {
      let followed = try #require(followedRouteOf(NavigationRoute(line: line)))
      let total = routeLengthMeters(line)
      var distances = [0, -0.0, -1, .nan, .infinity, -.infinity, total, total / 3, total * 0.37]
      distances += followed.measured + followed.measured.map { $0.nextUp }
      distances += followed.measured.map { $0.nextDown } + followed.measured.map { $0 + 0.5 }
      for meters in distances {
        let read = positionAtMeters(followed, meters: meters)
        let own = positionAtMeters(line, meters: meters)
        // NaN is no number equal to itself: compared by its bits.
        #expect(read.map(\.bitPattern) == own.map(\.bitPattern), "\(line) at \(meters) m")
      }
    }
  }

  @Test("a followed route is read off its measure, and measures nothing")
  func routeMeasuresNothing() throws {
    let followed = try #require(followedRouteOf(NavigationRoute(line: route)))
    let probe = MeasureProbe()

    let read = MeasureProbe.$current.withValue(probe) {
      (0...60).map { positionAtMeters(followed, meters: 50 * Double($0)) }
    }
    #expect(probe.lines.isEmpty, "\(probe.lines.count) measurements")
    // The control: the line's own reading measures it at every distance.
    let own = MeasureProbe.$current.withValue(probe) {
      (0...60).map { positionAtMeters(route, meters: 50 * Double($0)) }
    }
    #expect(probe.lines.count == 61)
    #expect(read == own)
  }
}
