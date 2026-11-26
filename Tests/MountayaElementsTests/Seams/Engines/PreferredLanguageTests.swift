import Foundation
import Testing

@testable import MountayaElements

@Suite("preferredLanguage")
struct PreferredLanguageTests {
  @Test("the environment's language is the device reader's first preferred one")
  func first() {
    #expect(preferredLanguage() == Locale.preferredLanguages.first)
  }
}
