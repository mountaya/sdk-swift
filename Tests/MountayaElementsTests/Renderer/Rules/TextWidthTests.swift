import SwiftUI
import Testing
import UIKit

@testable import MountayaElements

@Suite("textWidth")
struct TextWidthTests {
  @Test("a longer name is wider, no name has no width, and a larger style is wider")
  func widths() {
    #expect(textWidth("", style: .caption2) == 0)
    #expect(textWidth("Col de Balme", style: .caption2) > textWidth("Col", style: .caption2))
    #expect(textWidth("Col", style: .title1) > textWidth("Col", style: .caption2))
    #expect(
      textWidth("Col", style: .caption2, size: .accessibility3)
        > textWidth("Col", style: .caption2, size: .large),
      "a text size handed over is the one measured")
  }
}
