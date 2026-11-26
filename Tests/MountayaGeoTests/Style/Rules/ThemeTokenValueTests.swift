import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("themeTokenValue")
struct ThemeTokenValueTests {
  @Test("a token reads its light value under the light scheme and its dark one under the dark")
  func schemes() {
    let standard = ElementTokens.standard

    #expect(themeTokenValue(standard.controlBg, in: .light) == HexColor(hex: "#ffffff"))
    #expect(themeTokenValue(standard.controlBg, in: .dark) == HexColor(hex: "#25262b"))
    // The table states no dark accent, so the dark scheme reads the light one.
    #expect(themeTokenValue(standard.accent, in: .dark) == HexColor(hex: "#1c7ed6"))
    #expect(
      themeTokenValue(standard.profileNavigatorVeil, in: .dark)
        == HexColor(hex: "#000000", opacity: 0.55))
    #expect(
      themeTokenValue(standard.profileNavigatorVeil, in: .light)
        == HexColor(hex: "#ffffff", opacity: 0.62))
    #expect(
      themeTokenValue(standard.profileLitFill, in: .dark)
        == HexColor(hex: "#e9501e", opacity: 0.12))
    #expect(themeTokenValue(standard.profileCursorDash, in: .dark) == [3, 3])
    #expect(
      themeTokenValue(standard.controlShadow, in: .dark)
        == [HexColor(hex: "#000000", opacity: 0.05), HexColor(hex: "#000000", opacity: 0.1)])
  }

  @Test("a consumer's value stands in both schemes, and leaves every other token the table's")
  func consumer() {
    var tokens = ElementTokens.standard
    tokens.controlBg = ThemeToken(light: HexColor(hex: "#000000"))
    tokens.tooltipBg = ThemeToken(light: HexColor(hex: "#000000", opacity: 0.8))
    tokens.profileCursorDash = ThemeToken(light: [4, 2])

    #expect(themeTokenValue(tokens.controlBg, in: .light) == HexColor(hex: "#000000"))
    #expect(themeTokenValue(tokens.controlBg, in: .dark) == HexColor(hex: "#000000"))
    #expect(
      themeTokenValue(tokens.tooltipBg, in: .dark) == HexColor(hex: "#000000", opacity: 0.8))
    #expect(themeTokenValue(tokens.profileCursorDash, in: .dark) == [4, 2])
    #expect(themeTokenValue(tokens.panelBg, in: .dark) == HexColor(hex: "#25262b"))
  }

  @Test("a consumer may state its own value under each scheme")
  func bothSchemes() {
    let token = ThemeToken(light: HexColor(hex: "#ffffff"), dark: HexColor(hex: "#101010"))

    #expect(themeTokenValue(token, in: .light) == HexColor(hex: "#ffffff"))
    #expect(themeTokenValue(token, in: .dark) == HexColor(hex: "#101010"))
  }
}
