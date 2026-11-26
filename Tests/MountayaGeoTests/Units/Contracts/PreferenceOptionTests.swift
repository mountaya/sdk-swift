import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferenceOption")
struct PreferenceOptionTests {
  @Test("an option holds its value, its label and whether it is checked")
  func members() {
    let option = PreferenceOption(
      value: .length(.metric), label: .word("metric"), isChecked: true)

    #expect(option.value == .length(.metric))
    #expect(option.label == .word("metric"))
    #expect(option.isChecked)
    #expect(
      option
        != PreferenceOption(
          value: .length(.metric), label: .word("metric"), isChecked: false))
  }
}
