import MountayaClient
import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("PreferencesPanel")
@MainActor
struct PreferencesPanelTests {
  /// Held holds the app's preference set, as an app's state does.
  @MainActor
  final class Held {
    var set = UnitPreferences(language: "de")

    var binding: Binding<UnitPreferences> {
      Binding(get: { self.set }, set: { self.set = $0 })
    }
  }

  @Test("a press writes the whole set back with one preference changed, the map's labels kept")
  func unit() throws {
    let held = Held()
    let map = try Maps.engine()
    let labels = map.state.labelLanguage

    PreferencesPanel.select(.length(.imperial), in: held.binding, relabelling: map)

    #expect(held.set == UnitPreferences(language: "de", length: .imperial))
    #expect(map.state.labelLanguage == labels)
  }

  @Test("a press on a language writes it back and relabels the map")
  func language() throws {
    let held = Held()
    let map = try Maps.engine()

    PreferencesPanel.select(.language(.fr), in: held.binding, relabelling: map)

    #expect(held.set.language == "fr")
    #expect(map.state.labelLanguage == .fr)
  }

  @Test("a unit is labelled by the scope's word, and a language by its own name")
  func labels() {
    #expect(PreferencesPanel.label(.word("metric"), in: .standard) == "Metric")
    #expect(PreferencesPanel.label(.word("perDistance"), in: .standard) == "Pace")
    #expect(PreferencesPanel.label(.name("Deutsch"), in: .standard) == "Deutsch")
  }

  @Test("the panel draws on the panel's ground under the scheme in force")
  func drawn() throws {
    let held = Held()
    let light = try #require(Controls.drawn(PreferencesPanel(preferences: held.binding)))
    let dark = try #require(
      Controls.drawn(PreferencesPanel(preferences: held.binding), scheme: .dark))

    #expect(Pixels.pixel(light, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#ffffff")) == true)
    #expect(Pixels.pixel(dark, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#25262b")) == true)
  }
}
