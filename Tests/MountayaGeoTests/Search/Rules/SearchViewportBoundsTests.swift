import Testing

@testable import MountayaGeo

@Suite("searchViewportBounds")
struct SearchViewportBoundsTests {
  private func expectBox(
    expected: [Double], actual: [Double], sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(actual.count == 4, sourceLocation: sourceLocation)
    for (want, got) in zip(expected, actual) {
      #expect(abs(want - got) <= 1e-9, "\(got) is not \(want)", sourceLocation: sourceLocation)
    }
  }

  @Test("the box is the centre widened by the zoom's span")
  func widened() {
    expectBox(
      expected: [-0.703125, -0.703125, 0.703125, 0.703125],
      actual: searchViewportBounds(center: [0, 0], zoom: 8))
    expectBox(
      expected: [6.821254687499959, 45.893130951161474, 6.909145312499959, 45.95426904883852],
      actual: searchViewportBounds(center: [6.8652, 45.9237], zoom: 12))
  }

  @Test("each span is capped at ninety degrees")
  func capped() {
    expectBox(
      expected: [-38.13480000000004, 14.620993989349468, 51.86519999999996, 77.22640601065052],
      actual: searchViewportBounds(center: [6.8652, 45.9237], zoom: 1))
    // Below zoom 0 the span would pass a turn; it is still ninety degrees.
    expectBox(
      expected: [-45, -45, 45, 45], actual: searchViewportBounds(center: [0, 0], zoom: -3))
    #expect(searchBoundsMaxSpanDegrees == 90)
    #expect(searchBoundsCosineFloor == 0.05)
  }

  @Test("the box never crosses the antimeridian or a pole")
  func held() {
    expectBox(
      expected: [-162.67578125, 44.87570388611955, -162.32421875, 45.12429611388045],
      actual: searchViewportBounds(center: [197.5, 45], zoom: 10))
    expectBox(
      expected: [177.08749999999998, -19.689607126146036, 180, -14.310392873853964],
      actual: searchViewportBounds(center: [179.9, -17], zoom: 6))
    expectBox(
      expected: [17.1875, 89.759375, 22.8125, 90],
      actual: searchViewportBounds(center: [20, 89.9], zoom: 6))
    // A latitude past the pole is held at it first.
    expectBox(
      expected: [17.1875, 89.859375, 22.8125, 90],
      actual: searchViewportBounds(center: [20, 95], zoom: 6))
  }

  /// The altitude is no part of the place; a centre that names none, and a zoom that is no number,
  /// answer NaN.
  @Test("a centre that names no place, and a zoom that is no number, answer NaN")
  func nan() {
    expectBox(
      expected: [-0.703125, -0.703125, 0.703125, 0.703125],
      actual: searchViewportBounds(center: [0, 0, 1200], zoom: 8))
    #expect(searchViewportBounds(center: [6], zoom: 8).allSatisfy { $0.isNaN })
    #expect(searchViewportBounds(center: [.nan, 45], zoom: 8).allSatisfy { $0.isNaN })
    let noZoom = searchViewportBounds(center: [6, 45], zoom: .nan)
    #expect(noZoom.count == 4 && noZoom.allSatisfy { $0.isNaN })
  }
}
