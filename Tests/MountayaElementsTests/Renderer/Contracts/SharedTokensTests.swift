import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("SharedTokens", .serialized)
@MainActor
struct SharedTokensTests {
  /// accented is the standard tokens with their accent `hex`, made anew at each call, as an app's
  /// body makes the tokens it states each time it draws.
  static func accented(_ hex: String) -> ElementTokens {
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: hex))
    return tokens
  }

  @Test("a token reads off the reference as off the tokens it holds")
  func reads() {
    let tokens = SharedTokens(Self.accented("#e9501e"))

    #expect(tokens.accent == ThemeToken(light: HexColor(hex: "#e9501e")))
    #expect(tokens.controlFg == ElementTokens.standard.controlFg)
    #expect(tokens.value == Self.accented("#e9501e"))
  }

  @Test("two references holding equal tokens are equal, and two holding others are not")
  func equality() {
    #expect(SharedTokens(Self.accented("#e9501e")) == SharedTokens(Self.accented("#e9501e")))
    #expect(SharedTokens(Self.accented("#e9501e")) != SharedTokens(Self.accented("#000000")))
    #expect(SharedTokens.standard == SharedTokens(.standard))
    #expect(SharedTokens.standard.value == .standard)
  }

  @Test("the environment holds its tokens by one reference, the standard one where none is stated")
  func environment() {
    var values = EnvironmentValues()
    #expect(values.sharedTokens === SharedTokens.standard)

    values.mountayaTokens = Self.accented("#e9501e")
    #expect(values.sharedTokens.value == Self.accented("#e9501e"))
    #expect(values.mountayaTokens == Self.accented("#e9501e"))
  }

  /// Reader reads the tokens of its environment by reference, as the elements' views read them,
  /// and reports each evaluation of its body.
  private struct Reader: View {
    let probe: RenderProbe
    @Environment(\.sharedTokens) private var tokens

    var body: some View {
      let _ = probe.report("Reader")
      Color.clear.frame(width: 1, height: 1)
        .accessibilityLabel(Text(verbatim: tokens.accent.light.hex))
    }
  }

  /// ValueReader reads the tokens of its environment whole, as an app's view reads them, and
  /// reports each evaluation of its body. SwiftUI compares a value that size as it chooses, and
  /// draws such a view again for some statements of equal tokens, as it did before the tokens were
  /// held by reference, so the test asks of it only that a change reaches it.
  private struct ValueReader: View {
    let probe: RenderProbe
    @Environment(\.mountayaTokens) private var tokens

    var body: some View {
      let _ = probe.report("ValueReader")
      Color.clear.frame(width: 1, height: 1)
        .accessibilityLabel(Text(verbatim: tokens.accent.light.hex))
    }
  }

  /// Restated is an app's view stating its tokens anew each time it draws, which it does each time
  /// the test moves `redraws`, over the two readers.
  private struct Restated: View {
    let redraws: Held<Int>
    let accent: Held<String>
    let probe: RenderProbe

    var body: some View {
      let drawn = redraws.value
      let _ = probe.report("Restated")
      VStack {
        Text(verbatim: "\(drawn)")
        Reader(probe: probe)
        ValueReader(probe: probe)
      }
      .mountayaTokens(SharedTokensTests.accented(accent.value))
    }
  }

  @Test("tokens stated again equal draw no view reading them by reference, and a change draws all")
  func restated() async throws {
    let probe = RenderProbe()
    let redraws = Held(0)
    let accent = Held("#e9501e")
    let (host, window) = Hosted.showing(Restated(redraws: redraws, accent: accent, probe: probe))
    try #require(
      await MapWindow.until { probe["Reader"] >= 1 && probe["ValueReader"] >= 1 }, "\(probe.counts)"
    )
    _ = await MapWindow.until(0.3) { false }
    let before = probe.counts

    // Twenty redraws of the app's view, each stating tokens equal to the last, made anew.
    for redraw in 1...20 {
      let restated = probe["Restated"]
      redraws.value = redraw
      #expect(await MapWindow.until { probe["Restated"] > restated }, "redraw \(redraw)")
    }
    _ = await MapWindow.until(0.3) { false }
    #expect(probe["Restated"] - before["Restated", default: 0] >= 20)
    // The view reading the tokens by reference, as the elements' views read them, is not drawn
    // again: the reference made anew compares as the tokens it holds do.
    #expect(probe["Reader"] == before["Reader"], "\(probe.counts)")

    // Tokens that change draw both again.
    accent.value = "#000000"
    #expect(await MapWindow.until { probe["Reader"] > before["Reader", default: 0] })
    #expect(await MapWindow.until { probe["ValueReader"] > before["ValueReader", default: 0] })
    window.isHidden = true
    _ = host
  }
}
