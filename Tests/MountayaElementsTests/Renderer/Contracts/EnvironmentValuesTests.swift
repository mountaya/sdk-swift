import Foundation
import MountayaClient
import MountayaGeo
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("EnvironmentValues")
@MainActor
struct EnvironmentValuesTests {
  /// Seen holds what a probe read of its environment as it was drawn.
  @MainActor
  final class Seen {
    var scope: ElementsScope?
    var tokens: ElementTokens?
  }

  /// Probe reads its environment as it is drawn.
  struct Probe: View {
    let seen: Seen
    @Environment(\.mountayaScope) private var scope
    @Environment(\.mountayaTokens) private var tokens

    var body: some View {
      seen.scope = scope
      seen.tokens = tokens
      return Color.red.frame(width: 1, height: 1)
    }
  }

  /// drawn draws `view` once, which runs its body.
  private static func drawn(_ view: some View) {
    _ = ImageRenderer(content: view).uiImage
  }

  @Test("a view with no scope or tokens stated reads the standard ones, and no stack's panel")
  func defaults() {
    let values = EnvironmentValues()

    #expect(values.mountayaScope == .standard)
    #expect(values.mountayaTokens == .standard)
    #expect(values.mountayaOpenPanel == nil)
  }

  /// Stopped is a clock of a host's own, stopped at one instant.
  struct Stopped: WallClock {
    let now: Date
  }

  @Test("a view with no clock stated reads the system's wall clock, and one stated reads that")
  func clock() {
    let read = EnvironmentValues().mountayaClock.now.timeIntervalSince(Date())
    #expect(abs(read) < 60, "the system's clock reads the present")

    var values = EnvironmentValues()
    values.mountayaClock = Stopped(now: Date(timeIntervalSince1970: 1_773_480_413.9))
    #expect(values.mountayaClock.now == Date(timeIntervalSince1970: 1_773_480_413.9))
  }

  @Test("a scope stated nests in the one around it, every setting it leaves out inherited")
  func nested() {
    let seen = Seen()
    Self.drawn(
      Probe(seen: seen)
        .mountayaScope(
          ElementsScopeStatement(words: .bySection(["controls": ["zoomOut": "Moins"]]))
        )
        .mountayaScope(ElementsScopeStatement(language: .fr, locale: "fr-CH")))

    let scope = scopeOf(
      scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-CH")),
      stating: ElementsScopeStatement(words: .bySection(["controls": ["zoomOut": "Moins"]])))
    #expect(seen.scope == scope)
    #expect(seen.scope?.locale == "fr-CH")
    #expect(seen.scope?.word("controls.zoomIn") == "Zoom avant")
    #expect(seen.scope?.word("controls.zoomOut") == "Moins")
  }

  @Test("the tokens stated reach every view under them")
  func tokens() {
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
    let seen = Seen()
    Self.drawn(Probe(seen: seen).mountayaTokens(tokens))

    #expect(seen.tokens == tokens)
  }
}
