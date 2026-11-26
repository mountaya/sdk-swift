import Testing

@testable import MountayaGeo

@Suite("boundsWithPixelPadding")
struct BoundsWithPixelPaddingTests {
  private let box: [Double] = [6, 45, 8, 46]

  /// A pixel of longitude is 360 / (512 * 2^zoom) degrees at every latitude, and a pixel of
  /// latitude that span times the cosine of the centre latitude.
  @Test("each edge grows by its padding in the degrees a pixel spans")
  func grows() {
    #expect(
      areClose(
        boundsWithPixelPadding(box, padding: PixelPadding(100), zoom: 12, centerLatitude: 45.5),
        [5.9828338623046875, 44.987968095057106, 8.017166137695312, 46.012031904942894],
        within: 1e-12))
    #expect(
      areClose(
        boundsWithPixelPadding(
          box, padding: PixelPadding(top: 56, right: 56, bottom: 250, left: 56), zoom: 12,
          centerLatitude: 45.5),
        [5.990386962890625, 44.969920237642775, 8.009613037109375, 46.00673786676802],
        within: 1e-12))
    #expect(
      areClose(
        boundsWithPixelPadding(
          [-1, -1, 1, 1], padding: PixelPadding(100), zoom: 8, centerLatitude: 0),
        [-1.274658203125, -1.274658203125, 1.274658203125, 1.274658203125], within: 1e-12))
  }

  @Test("one zoom out doubles the degrees")
  func zoomOut() {
    let near = boundsWithPixelPadding(
      box, padding: PixelPadding(100), zoom: 12, centerLatitude: 45.5)
    let far = boundsWithPixelPadding(
      box, padding: PixelPadding(100), zoom: 11, centerLatitude: 45.5)
    #expect(isClose(6 - far[0], (6 - near[0]) * 2, within: 1e-12))
    #expect(isClose(far[3] - 46, (near[3] - 46) * 2, within: 1e-12))
  }

  @Test("the centre latitude is held within the projection's limit")
  func centreHeld() {
    func padded(_ latitude: Double) -> [Double] {
      boundsWithPixelPadding(box, padding: PixelPadding(100), zoom: 6, centerLatitude: latitude)
    }
    #expect(padded(89) == padded(85.051129))
    #expect(padded(120) == padded(85.051129))
    #expect(padded(-89) == padded(-85.051129))
  }

  @Test("the edges move as written")
  func asWritten() {
    #expect(
      areClose(
        boundsWithPixelPadding(
          [179.5, 45, 180.5, 46], padding: PixelPadding(100), zoom: 12, centerLatitude: 45.5),
        [179.4828338623047, 44.987968095057106, 180.5171661376953, 46.012031904942894],
        within: 1e-12))
    // A padding under zero insets the box; nothing is reordered.
    #expect(
      areClose(
        boundsWithPixelPadding(box, padding: PixelPadding(-100), zoom: 12, centerLatitude: 45.5),
        [6.0171661376953125, 45.012031904942894, 7.9828338623046875, 45.987968095057106],
        within: 1e-12))
  }

  @Test("a zoom that is no finite number leaves the box as written")
  func noZoom() {
    #expect(
      boundsWithPixelPadding(box, padding: PixelPadding(100), zoom: .nan, centerLatitude: 45.5)
        == box)
    #expect(
      boundsWithPixelPadding(box, padding: PixelPadding(100), zoom: .infinity, centerLatitude: 45.5)
        == box)
    #expect(
      boundsWithPixelPadding(box, padding: PixelPadding(0), zoom: 12, centerLatitude: 45.5) == box)
  }

  @Test("nothing is refused")
  func nothingRefused() {
    let unplaced = boundsWithPixelPadding(
      box, padding: PixelPadding(100), zoom: 12, centerLatitude: .nan)
    let placed = boundsWithPixelPadding(
      box, padding: PixelPadding(100), zoom: 12, centerLatitude: 45.5)
    // A pixel of longitude spans the same degrees at every latitude, so only the latitudes are lost.
    #expect([unplaced[0], unplaced[2]] == [placed[0], placed[2]])
    #expect(unplaced[1].isNaN && unplaced[3].isNaN)
    #expect(
      sameNumbers(
        boundsWithPixelPadding(
          [6, 45], padding: PixelPadding(100), zoom: 12, centerLatitude: 45.5),
        [.nan, .nan, .nan, .nan]))
  }
}
