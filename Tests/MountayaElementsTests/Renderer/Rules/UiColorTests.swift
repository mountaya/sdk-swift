import Testing
import UIKit

@testable import MountayaElements

@Suite("uiColor")
struct UiColorTests {
  private static func components(_ color: UIColor?) -> [Int]? {
    var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
    guard let color, color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return nil
    }
    return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
  }

  @Test("a CSS hexadecimal colour of three, six or eight digits, in either case")
  func colours() {
    #expect(Self.components(uiColor("#e03131")) == [224, 49, 49, 255])
    #expect(Self.components(uiColor("#E03131")) == [224, 49, 49, 255])
    #expect(Self.components(uiColor("#fff")) == [255, 255, 255, 255])
    #expect(Self.components(uiColor("#00000080")) == [0, 0, 0, 128])
    #expect(Self.components(uiColor("#ffffff", opacity: 0.5)) == [255, 255, 255, 128])
  }

  @Test("anything else is no colour")
  func refused() {
    for written in ["e03131", "#e0313", "#e031311", "#ggg", "red", "", "#", "#\u{FF11}23"] {
      #expect(uiColor(written) == nil, "\(written)")
    }
  }
}
