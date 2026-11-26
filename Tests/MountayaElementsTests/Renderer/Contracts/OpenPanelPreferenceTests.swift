import SwiftUI
import Testing

@testable import MountayaElements

@Suite("OpenPanelPreference")
@MainActor
struct OpenPanelPreferenceTests {
  @Test("no panel is open until a toggle tells one, and the first told stands")
  func reduce() {
    #expect(OpenPanelPreference.defaultValue == nil)
    var value = OpenPanelPreference.defaultValue
    OpenPanelPreference.reduce(value: &value) { nil }
    #expect(value == nil)
  }
}
