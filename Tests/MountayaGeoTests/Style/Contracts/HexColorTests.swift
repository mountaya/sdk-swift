import Testing

@testable import MountayaGeo

@Suite("HexColor")
struct HexColorTests {
  @Test("a colour given no opacity is opaque, and two colours are one where both parts are")
  func opacity() {
    let opaque = HexColor(hex: "#1c7ed6")
    let veiled = HexColor(hex: "#1c7ed6", opacity: 0.12)

    #expect(opaque.opacity == 1)
    #expect(opaque == HexColor(hex: "#1c7ed6", opacity: 1))
    #expect(opaque != veiled)
    #expect(Set([opaque, veiled, HexColor(hex: "#1c7ed6")]).count == 2)
  }

  @Test("two colours compare their digits by scalars and their opacity as the same number")
  func sameValues() {
    let unknown = HexColor(hex: "#1c7ed6", opacity: .nan)
    let payload = HexColor(hex: "#1c7ed6", opacity: Double(bitPattern: 0x7ff8_0000_0000_0001))
    let clear = HexColor(hex: "#1c7ed6", opacity: 0)
    let negativeClear = HexColor(hex: "#1c7ed6", opacity: -0.0)

    #expect(unknown == HexColor(hex: "#1c7ed6", opacity: .nan))
    #expect(unknown == payload)
    #expect(unknown.hashValue == payload.hashValue)
    #expect(Set([unknown, payload]).count == 1)
    #expect(clear != negativeClear)
    #expect(Set([clear, negativeClear]).count == 2)
    #expect(HexColor(hex: "#\u{E9}") != HexColor(hex: "#e\u{301}"))
  }

  @Test("the printed tokens write every colour as six lowercase digits, opaque or between 0 and 1")
  func printed() {
    let standard = ElementTokens.standard
    let colors = ElementTokens.colorTokens.values.flatMap { path in
      [standard[keyPath: path].light] + [standard[keyPath: path].dark].compactMap { $0 }
    }
    let lowercase = Set("#0123456789abcdef")

    #expect(colors.count >= 25)
    for color in colors {
      #expect(color.hex.count == 7 && color.hex.allSatisfy(lowercase.contains), "\(color.hex)")
      #expect(color.opacity > 0 && color.opacity <= 1, "\(color.hex)")
    }
  }
}
