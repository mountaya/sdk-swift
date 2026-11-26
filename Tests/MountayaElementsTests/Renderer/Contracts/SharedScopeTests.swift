import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("SharedScope", .serialized)
@MainActor
struct SharedScopeTests {
  /// french is the standard scope nested in French, made anew at each call, as an app's body states
  /// the scope it nests each time it draws.
  static func french() -> ElementsScope {
    scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-CH"))
  }

  @Test("a setting and a word read off the reference as off the scope it holds")
  func reads() {
    let scope = SharedScope(Self.french())

    #expect(scope.language == .fr)
    #expect(scope.locale == "fr-CH")
    #expect(scope.controlGlyphs == .control)
    #expect(scope.word("controls.zoomIn") == Self.french().word("controls.zoomIn"))
    #expect(scope.value == Self.french())
  }

  @Test("two references holding equal scopes are equal, and two holding others are not")
  func equality() {
    #expect(SharedScope(Self.french()) == SharedScope(Self.french()))
    #expect(SharedScope(Self.french()) != SharedScope(.standard))
    #expect(SharedScope.standard == SharedScope(.standard))
    #expect(SharedScope.standard.value == .standard)
  }

  @Test("the environment holds its scope by one reference, the standard one where none is stated")
  func environment() {
    var values = EnvironmentValues()
    #expect(values.sharedScope === SharedScope.standard)

    values.mountayaScope = Self.french()
    #expect(values.sharedScope.value == Self.french())
    #expect(values.mountayaScope == Self.french())
  }

  /// Reader reads the scope of its environment by reference, as the elements' views read it, and
  /// reports each evaluation of its body.
  private struct Reader: View {
    let probe: RenderProbe
    @Environment(\.sharedScope) private var scope

    var body: some View {
      let _ = probe.report("Reader")
      Color.clear.frame(width: 1, height: 1)
        .accessibilityLabel(Text(verbatim: scope.word("controls.zoomIn")))
    }
  }

  /// Restated is an app's view nesting its scope anew each time it draws, which it does each time
  /// the test moves `redraws`, over the reader.
  private struct Restated: View {
    let redraws: Held<Int>
    let locale: Held<String>
    let probe: RenderProbe

    var body: some View {
      let drawn = redraws.value
      let _ = probe.report("Restated")
      VStack {
        Text(verbatim: "\(drawn)")
        Reader(probe: probe)
      }
      .mountayaScope(ElementsScopeStatement(language: .fr, locale: locale.value))
    }
  }

  @Test("a scope stated again equal draws no view reading it by reference, and a change draws it")
  func restated() async throws {
    let probe = RenderProbe()
    let redraws = Held(0)
    let locale = Held("fr-CH")
    let (host, window) = Hosted.showing(Restated(redraws: redraws, locale: locale, probe: probe))
    try #require(await MapWindow.until { probe["Reader"] >= 1 }, "\(probe.counts)")
    _ = await MapWindow.until(0.3) { false }
    let before = probe.counts

    // Twenty redraws of the app's view, each nesting a scope equal to the last, made anew.
    for redraw in 1...20 {
      let restated = probe["Restated"]
      redraws.value = redraw
      #expect(await MapWindow.until { probe["Restated"] > restated }, "redraw \(redraw)")
    }
    _ = await MapWindow.until(0.3) { false }
    #expect(probe["Restated"] - before["Restated", default: 0] >= 20)
    // The view reading the scope by reference is not drawn again: the reference made anew compares
    // as the scope it holds does.
    #expect(probe["Reader"] == before["Reader"], "\(probe.counts)")

    // A scope that changes draws it again.
    locale.value = "fr-BE"
    #expect(await MapWindow.until { probe["Reader"] > before["Reader", default: 0] })
    window.isHidden = true
    _ = host
  }
}
