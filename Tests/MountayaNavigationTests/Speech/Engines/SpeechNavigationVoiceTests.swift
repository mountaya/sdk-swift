import AVFoundation
import Foundation
import MountayaClient
import MountayaGeo
import Testing
import os

@testable import MountayaNavigation

/// The voice over the system's speech synthesizer, on the device it speaks on: it says the host's
/// words for each instruction, in order, and says nothing the host has no words for; a hush stops
/// it at once and drops every sentence handed over before it, and only those.
@Suite("SpeechNavigationVoice")
@MainActor
struct SpeechNavigationVoiceTests {
  /// RecordingSpeaker keeps each sentence the voice hands the synthesizer, the voice it is said
  /// in, and each stop.
  @MainActor
  private final class RecordingSpeaker: SpeechNavigationVoice.Speaker {
    var spoken: [String] = []
    var voices: [AVSpeechSynthesisVoice?] = []
    var stops = 0
    let isSpeaking = false

    func speak(_ utterance: AVSpeechUtterance) {
      spoken.append(utterance.speechString)
      voices.append(utterance.voice)
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
      stops += 1
      return true
    }
  }

  private static let depart = stepInstruction(
    NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Chemin"))
  private static let turn = stepInstruction(
    NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .turnLeft, name: "Sentier"))
  private static let goal = stepInstruction(
    NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal))

  /// frenchVoice is a voice in French over `speaker`, which says each instruction as its key and
  /// hears interruptions on `notifications`, a center of the test's own, since the tests run side by
  /// side and an interruption told on the process's center hushes every voice alive.
  private func frenchVoice(
    over speaker: RecordingSpeaker, hearing notifications: NotificationCenter = NotificationCenter()
  ) -> SpeechNavigationVoice {
    SpeechNavigationVoice(
      language: "fr-FR", words: { "\($0.key)" }, speaker: speaker, notifications: notifications)
  }

  /// spoken waits until `speaker` has said `count` sentences, each one's voice looked up off the
  /// main actor, for thirty seconds at most, and answers every sentence it said.
  private func spoken(by speaker: RecordingSpeaker, count: Int) async -> [String] {
    let deadline = ContinuousClock.now + .seconds(30)
    while speaker.spoken.count < count, ContinuousClock.now < deadline {
      try? await Task.sleep(for: .milliseconds(10))
    }
    return speaker.spoken
  }

  @Test("each instruction is worded by the host, and one it has no words for is not said")
  func hostsWords() {
    var asked: [NavigationInstructionKey] = []
    let voice = SpeechNavigationVoice(language: "fr-FR") { instruction in
      asked.append(instruction.key)
      return instruction.key == .turnLeft ? "Tournez à gauche sur \(instruction.name ?? "")" : nil
    }

    voice.say(Self.turn)
    voice.say(Self.goal)
    voice.hush()
    voice.hush()

    #expect(asked == [.turnLeft, .goalPlain])
  }

  @Test("a language the device holds no voice for is spoken in the system's own")
  func unknownLanguage() {
    let voice = SpeechNavigationVoice(language: "not a tag") { _ in "Continuez" }

    voice.say(
      stepInstruction(NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .continue)))
    voice.hush()
  }

  @Test("sentences are said in the order they were handed over")
  func inOrder() async {
    let speaker = RecordingSpeaker()
    let voice = frenchVoice(over: speaker)

    let instructions = [Self.depart, Self.turn, Self.goal]
    for instruction in instructions {
      voice.say(instruction)
    }

    let said = await spoken(by: speaker, count: 3)
    #expect(said == instructions.map { "\($0.key)" })
  }

  /// A new route hushes the voice, then hands it the departure: the hush has stopped what was
  /// being said before it returns, so it never lands after the departure and cuts it off.
  @Test("a hush stops the synthesizer at once, and drops what was handed over before it alone")
  func hushDropsWhatCameBefore() async {
    let speaker = RecordingSpeaker()
    let voice = frenchVoice(over: speaker)

    voice.say(Self.turn)
    voice.hush()
    #expect(speaker.stops == 1, "the synthesizer is stopped before the hush returns")
    voice.say(Self.depart)

    // Sentences are prepared and said in the order they were handed over, so once the departure
    // is said, the turn handed over before the hush was dropped rather than said.
    let said = await spoken(by: speaker, count: 1)
    #expect(said == ["\(Self.depart.key)"])
  }

  @Test("the system taking the audio hushes the voice, and giving it back hushes nothing")
  func interruptionHushes() async {
    let speaker = RecordingSpeaker()
    let notifications = NotificationCenter()
    let voice = frenchVoice(over: speaker, hearing: notifications)

    voice.say(Self.turn)
    notifications.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
    #expect(speaker.stops == 1)
    voice.say(Self.depart)
    notifications.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue])
    #expect(speaker.stops == 1, "an interruption that ends stops nothing")

    let said = await spoken(by: speaker, count: 1)
    #expect(said == ["\(Self.depart.key)"])
  }

  /// The voices a device holds are the test's: `romansh` stands for a voice the device holds,
  /// known by its identity, so no simulator's catalogue decides the outcome.
  @Test(
    "a language the device holds no voice for is said in the fallback, then in the system's own")
  func fallsBack() async {
    let romansh = AVSpeechSynthesisVoice()
    let german = AVSpeechSynthesisVoice()
    let looked = OSAllocatedUnfairLock<[String]>(initialState: [])
    func voice(
      _ language: String, fallback: String?, holding held: [String: AVSpeechSynthesisVoice],
      over speaker: RecordingSpeaker
    ) -> SpeechNavigationVoice {
      SpeechNavigationVoice(
        language: language, fallbackLanguage: fallback, words: { "\($0.key)" }, speaker: speaker,
        voices: { language in
          looked.withLock { $0.append(language) }
          return held[language]
        }, notifications: NotificationCenter())
    }

    // Each voice is held while its sentence is on its way: a voice let go of says nothing more.
    let own = RecordingSpeaker()
    let ownVoice = voice(
      "rm-CH", fallback: "de-CH", holding: ["rm-CH": romansh, "de-CH": german], over: own)
    ownVoice.say(Self.turn)
    _ = await spoken(by: own, count: 1)
    #expect(own.voices.count == 1 && own.voices[0] === romansh, "the language's own voice")

    let fallen = RecordingSpeaker()
    let fallenVoice = voice("rm-CH", fallback: "de-CH", holding: ["de-CH": german], over: fallen)
    fallenVoice.say(Self.turn)
    _ = await spoken(by: fallen, count: 1)
    #expect(fallen.voices.count == 1 && fallen.voices[0] === german, "the fallback's voice")

    let system = RecordingSpeaker()
    let systemVoice = voice("rm-CH", fallback: "de-CH", holding: [:], over: system)
    systemVoice.say(Self.turn)
    _ = await spoken(by: system, count: 1)
    #expect(system.voices.count == 1 && system.voices[0] == nil, "the system's own voice")

    looked.withLock { $0 = [] }
    let same = RecordingSpeaker()
    let sameVoice = voice("rm-CH", fallback: "rm-CH", holding: [:], over: same)
    sameVoice.say(Self.turn)
    _ = await spoken(by: same, count: 1)
    #expect(looked.withLock { $0 } == ["rm-CH"], "a fallback that is the language is no fallback")
    #expect(same.voices.count == 1 && same.voices[0] == nil)
    for held in [ownVoice, fallenVoice, systemVoice, sameVoice] {
      held.close()
    }
  }

  /// The system refuses the audio session to an app in the background that declares no `audio`
  /// mode: the refusal is the app's to hear, and the sentence is still handed to the synthesizer.
  @Test(
    "a refusal of the audio session is told as audioRefused, and the sentence said all the same")
  func sessionRefused() async {
    struct Refused: Error {}
    let speaker = RecordingSpeaker()
    let asked = OSAllocatedUnfairLock(initialState: 0)
    var told: [any Error] = []
    let voice = SpeechNavigationVoice(
      language: "fr-FR", onError: { told.append($0) }, words: { "\($0.key)" }, speaker: speaker,
      notifications: NotificationCenter(),
      takeSession: {
        asked.withLock { $0 += 1 }
        throw Refused()
      })

    voice.say(Self.turn)
    voice.say(Self.goal)
    let said = await spoken(by: speaker, count: 2)

    #expect(said == ["\(Self.turn.key)", "\(Self.goal.key)"])
    #expect(told.count == 2, "each sentence tries the session again, and each refusal is told")
    #expect(told.allSatisfy { ($0 as? SpeechError)?.kind == .audioRefused }, "\(told)")
    #expect(
      told.allSatisfy { ($0 as? SpeechError)?.cause is Refused }, "the session's own error")
    #expect(asked.withLock { $0 } == 2)
    voice.close()
  }

  @Test(
    "with no onError, a refusal of the audio session is dropped, the sentence said all the same")
  func sessionRefusedUnheard() async {
    struct Refused: Error {}
    let speaker = RecordingSpeaker()
    let voice = SpeechNavigationVoice(
      language: "fr-FR", words: { "\($0.key)" }, speaker: speaker,
      notifications: NotificationCenter(), takeSession: { throw Refused() })

    voice.say(Self.turn)

    #expect(await spoken(by: speaker, count: 1) == ["\(Self.turn.key)"])
    voice.close()
  }

  @Test("a session taken once is held, and nothing is told")
  func sessionTaken() async {
    let speaker = RecordingSpeaker()
    let asked = OSAllocatedUnfairLock(initialState: 0)
    var told: [any Error] = []
    let voice = SpeechNavigationVoice(
      language: "fr-FR", onError: { told.append($0) }, words: { "\($0.key)" }, speaker: speaker,
      notifications: NotificationCenter(), takeSession: { asked.withLock { $0 += 1 } })

    voice.say(Self.turn)
    voice.say(Self.goal)
    _ = await spoken(by: speaker, count: 2)

    #expect(told.isEmpty)
    #expect(asked.withLock { $0 } == 1, "the session held is not taken again")
    voice.close()
  }

  @Test("prepare looks the voice up ahead of the first sentence, and says nothing")
  func prepares() async {
    let speaker = RecordingSpeaker()
    let looked = OSAllocatedUnfairLock<[String]>(initialState: [])
    let voice = SpeechNavigationVoice(
      language: "rm-CH", fallbackLanguage: "de-CH", words: { "\($0.key)" }, speaker: speaker,
      voices: { language in
        looked.withLock { $0.append(language) }
        return nil
      }, notifications: NotificationCenter())

    await voice.prepare()
    #expect(looked.withLock { $0 } == ["rm-CH", "de-CH"], "the language, then its fallback")
    #expect(speaker.spoken.isEmpty, "preparing says nothing")

    voice.close()
    await voice.prepare()
    #expect(looked.withLock { $0 } == ["rm-CH", "de-CH"], "a closed voice prepares nothing")
  }

  @Test("a close stops the synthesizer, and nothing is said, hushed or prepared after it")
  func closes() async {
    let speaker = RecordingSpeaker()
    let notifications = NotificationCenter()
    var worded: [NavigationInstructionKey] = []
    let voice = SpeechNavigationVoice(
      language: "fr-FR",
      words: { instruction in
        worded.append(instruction.key)
        return "\(instruction.key)"
      }, speaker: speaker, notifications: notifications)

    voice.say(Self.turn)
    voice.close()
    #expect(speaker.stops == 1, "what is said is stopped as the voice closes")

    voice.say(Self.depart)
    voice.hush()
    voice.close()
    notifications.post(
      name: AVAudioSession.interruptionNotification, object: nil,
      userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
    await voice.prepare()
    #expect(worded == [.turnLeft], "nothing is worded after a close")
    #expect(
      speaker.stops == 1, "nothing is hushed after a close, the system taking the audio included")
  }
}
