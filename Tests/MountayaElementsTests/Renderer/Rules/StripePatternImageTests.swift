import MountayaGeo
import RendererSupport
import Testing
import UIKit

@testable import MountayaElements

@Suite("stripePatternImage")
@MainActor
struct StripePatternImageTests {
  @Test(
    "a restricted stretch's tile is 16 points square, its stripes in its kind's colour on white")
  func tile() throws {
    let image = stripePatternImage(roadAccessStripePattern(.permit))
    let stripe = Pixels.Pixel(red: 0x9c, green: 0x36, blue: 0xb5, alpha: 255)
    let ground = Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)

    #expect(image.size == CGSize(width: 16, height: 16))
    #expect(image.renderingMode == .alwaysOriginal)
    // On the stripe through the tile, its corner to corner diagonal, and on the half past each
    // corner, which completes the next tile's.
    #expect(Pixels.pixel(image, at: CGPoint(x: 8, y: 8))?.isNear(stripe) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 0.2, y: 0.2))?.isNear(stripe) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 15.8, y: 15.8))?.isNear(stripe) == true)
    // Between the stripes, the white ground.
    #expect(Pixels.pixel(image, at: CGPoint(x: 4, y: 4))?.isNear(ground) == true)
    #expect(Pixels.pixel(image, at: CGPoint(x: 12, y: 12))?.isNear(ground) == true)
  }

  @Test("a pattern with no ground leaves its gaps clear")
  func noGround() throws {
    let pattern = StripePattern(
      size: 16, width: 4, color: "#f03e3e", ground: nil, lineCap: .round,
      segments: [[[0, 16], [16, 0]]])
    let image = stripePatternImage(pattern)

    #expect(Pixels.pixel(image, at: CGPoint(x: 8, y: 8))?.alpha == 255)
    #expect(Pixels.pixel(image, at: CGPoint(x: 2, y: 2))?.alpha == 0)
  }
}
