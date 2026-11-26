import Testing

@testable import MountayaNavigation

@Suite("SpeechError")
struct SpeechErrorTests {
  private struct Refused: Error, CustomStringConvertible {
    var description: String { "the session is held elsewhere" }
  }

  @Test("each kind is named as every SDK names it, and the set is open")
  func kinds() {
    #expect(SpeechError.Kind.engineUnavailable.rawValue == "engineUnavailable")
    #expect(SpeechError.Kind.audioRefused.rawValue == "audioRefused")
    #expect(SpeechError.Kind(rawValue: "audioRefused") == .audioRefused)
    #expect(SpeechError.Kind.engineUnavailable != .audioRefused)
    #expect("\(SpeechError.Kind.audioRefused)" == "audioRefused")
    let later = SpeechError.Kind(rawValue: "voiceMissing")
    #expect(later != .engineUnavailable && later != .audioRefused)
    #expect(SpeechError(kind: later).description.contains("voiceMissing"))
  }

  @Test("a failure carries what the platform threw, and says what to do")
  func described() {
    let refused = SpeechError(kind: .audioRefused, cause: Refused())
    #expect(refused.cause is Refused)
    #expect(refused.description.contains("the session is held elsewhere"))
    #expect(refused.description.contains("`audio`"))
    #expect(SpeechError(kind: .engineUnavailable).cause == nil)
    #expect(SpeechError(kind: .engineUnavailable).description.contains("NavigationVoice"))
  }
}
