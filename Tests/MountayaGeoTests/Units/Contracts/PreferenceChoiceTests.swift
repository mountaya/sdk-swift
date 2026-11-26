import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferenceChoice")
struct PreferenceChoiceTests {
  @Test("a choice holds its field and its options in order")
  func members() {
    let options = [
      PreferenceOption(value: .slope(.degrees), label: .word("degrees"), isChecked: true),
      PreferenceOption(
        value: .slope(.percentage), label: .word("percentage"), isChecked: false),
    ]
    let choice = PreferenceChoice(field: .slope, options: options)

    #expect(choice.field == .slope)
    #expect(choice.options == options)
    #expect(choice != PreferenceChoice(field: .slope, options: options.reversed()))
  }
}
