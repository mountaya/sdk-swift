import Testing

@testable import MountayaGeo

@Suite("ThemeToken")
struct ThemeTokenTests {
  @Test("a token states its light value, and its dark one only where it has one of its own")
  func schemes() {
    let standard = ElementTokens.standard

    #expect(ThemeToken(light: 3).dark == nil)
    #expect(standard.accent.light == HexColor(hex: "#1c7ed6"))
    #expect(standard.accent.dark == nil)
    #expect(standard.controlBg.light == HexColor(hex: "#ffffff"))
    #expect(standard.controlBg.dark == HexColor(hex: "#25262b"))
    #expect(standard.profileCursorDash.light == [3, 3])
  }

  @Test("a consumer restyles a subset on a copy of the standard tokens, the rest left as they were")
  func subset() {
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
    tokens.controlBg.dark = HexColor(hex: "#000000")

    #expect(tokens != ElementTokens.standard)
    #expect(tokens.accent.light == HexColor(hex: "#e9501e"))
    #expect(tokens.controlBg.light == ElementTokens.standard.controlBg.light)
    #expect(tokens.panelBg == ElementTokens.standard.panelBg)
    #expect(ElementTokens.standard.accent.light == HexColor(hex: "#1c7ed6"))
  }

  @Test("two tokens compare their numbers as the same numbers, a dash's number by number")
  func sameValues() {
    let unknown = ThemeToken(light: [3, Double.nan])
    let signed = ThemeToken(light: [3, -Double.nan])

    #expect(unknown == signed)
    #expect(unknown.hashValue == signed.hashValue)
    #expect(ThemeToken(light: [3.0, 0]) != ThemeToken(light: [3, -0.0]))
    #expect(ThemeToken(light: 1.0, dark: .nan) == ThemeToken(light: 1.0, dark: -.nan))
    #expect(ThemeToken(light: 1.0, dark: 0) != ThemeToken(light: 1.0, dark: -0.0))
    #expect(ThemeToken(light: 1.0) != ThemeToken(light: 1.0, dark: 1.0))
    #expect(
      ThemeToken(light: HexColor(hex: "#000000", opacity: .nan))
        == ThemeToken(light: HexColor(hex: "#000000", opacity: -.nan)))
  }

  @Test("two sets of tokens holding the same numbers are one, and hash alike")
  func sameTokens() {
    var tokens = ElementTokens.standard
    tokens.profileCursorDash = ThemeToken(light: [3, .nan])
    tokens.accent = ThemeToken(light: HexColor(hex: "#1c7ed6", opacity: .nan))
    var copy = ElementTokens.standard
    copy.profileCursorDash = ThemeToken(light: [3, -.nan])
    copy.accent = ThemeToken(light: HexColor(hex: "#1c7ed6", opacity: -.nan))

    #expect(tokens == copy)
    #expect(tokens.hashValue == copy.hashValue)
    copy.profileCursorDash = ThemeToken(light: [3, .nan], dark: [-0.0])
    tokens.profileCursorDash = ThemeToken(light: [3, .nan], dark: [0])
    #expect(tokens != copy)
  }
}
