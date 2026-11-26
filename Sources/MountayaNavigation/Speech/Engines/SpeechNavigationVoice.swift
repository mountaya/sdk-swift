#if os(iOS)
  internal import AVFoundation
  internal import Foundation
  import MountayaGeo
  internal import os

  /// SpeechNavigationVoice says each maneuver through the system's speech synthesizer, in the
  /// host's words and in the language it names, lowering the audio other apps play while it
  /// speaks and interrupting the spoken audio they play, such as a podcast.
  ///
  /// `words` turns an instruction, a copy key and its arguments, into the sentence said, from the
  /// host's own strings: an instruction it answers nil for, or an empty sentence, is not said.
  /// `language` is a BCP 47 tag naming the voice, `fr-FR`, always the host's, never a platform's
  /// default. Where the device holds no voice for it, the sentence is said in `fallbackLanguage`,
  /// and where it holds none for that either, or no fallback is named, in the system's own voice.
  ///
  /// Each sentence is said after those before it. `hush()` stops what is being said at once and
  /// drops every sentence handed over before it, one whose voice is still being looked up
  /// included, so a stop is never outrun by the prompt before it, and the first prompt of a new
  /// route is never cut off by the hush that came before it. The system taking the audio, for a
  /// call or an alarm, hushes it too. The voice of the host's language is looked up off the main
  /// actor, since the system's catalogue can take seconds to read the first time, and `prepare()`
  /// looks it up ahead of the first sentence. `close()` ends the voice: the app that made it closes
  /// it, and the engine it is handed to closes nothing it was given.
  ///
  /// The audio session is taken as each sentence is handed over, where the voice does not hold it
  /// already. The system refuses it to an app in the background that declares no `audio` mode under
  /// `UIBackgroundModes`, which is how a navigation goes silent with the screen off: each refusal is
  /// told to `onError` as a `SpeechError` of kind `audioRefused`, carrying the audio session's own
  /// error, on the main actor, before the sentence is handed to the synthesizer all the same, and
  /// none is told after `close()`. With no `onError`, each is dropped, and a debug build prints it
  /// once, where a developer reads the console. The system's synthesizer always starts, so this
  /// voice never tells `engineUnavailable`.
  ///
  /// It is an iPhone's, an iPad's and a Mac Catalyst app's, where the audio session it takes as a
  /// voice prompt is the platform's: a native macOS app holds none, and an app on any other
  /// platform says each maneuver through a `NavigationVoice` of its own. It is bound to the main
  /// actor, as every voice is.
  @MainActor
  public final class SpeechNavigationVoice: NavigationVoice {
    /// Speaker is what the voice asks of the system's speech synthesizer, which
    /// `AVSpeechSynthesizer` is: an utterance said after those before it, everything stopped at
    /// once, and whether anything is still being said.
    @MainActor
    protocol Speaker: AnyObject {
      var isSpeaking: Bool { get }
      func speak(_ utterance: AVSpeechUtterance)
      @discardableResult func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
    }

    private let words: (NavigationInstruction) -> String?
    /// onError is told each refusal of the audio session, a `SpeechError`, on the main actor.
    private let onError: (@MainActor (any Error) -> Void)?
    /// languages is the languages a sentence's voice is looked for in, in order: the host's, then
    /// its fallback where it names another.
    private let languages: [String]
    /// voices finds the device's voice for a language, or answers nil where it holds none.
    private let voices: @Sendable (String) -> AVSpeechSynthesisVoice?
    /// speaker is the synthesizer every sentence is handed to, until `close()` lets it go.
    private var speaker: (any Speaker)?
    private let notifications: NotificationCenter
    /// preparing is where a sentence's voice is looked up and the audio session taken and let go,
    /// in the order the sentences and the hushes came: each is a call that blocks its thread for as
    /// long as the system takes, which a thread of Swift's cooperative pool must never be held for,
    /// so the queue is the voice's own (SPEC.md section 8).
    private let preparing = DispatchQueue(label: "com.mountaya.navigation.speech")
    private let focus: AudioFocus
    private let interruptions = Interruptions()
    /// generation counts the hushes, so a sentence handed over before one is never said after it.
    private var generation: UInt64 = 0
    /// preparations counts the sentences whose voice is being looked up.
    private var preparations = 0
    /// release lets the audio session go once the voice is quiet.
    private var release: Task<Void, Never>?
    private var closed = false

    /// Creates a voice that says each maneuver in the words `words` gives, in `language`, or in
    /// `fallbackLanguage` where the device holds no voice for `language`, and in the system's own
    /// voice where it holds none for either, telling `onError` each refusal of the audio session.
    public init(
      language: String, fallbackLanguage: String? = nil,
      onError: (@MainActor (any Error) -> Void)? = nil,
      words: @escaping (NavigationInstruction) -> String?
    ) {
      self.words = words
      self.onError = onError
      languages = Self.languages(language, fallback: fallbackLanguage)
      voices = { AVSpeechSynthesisVoice(language: $0) }
      speaker = AVSpeechSynthesizer()
      notifications = .default
      focus = AudioFocus(take: { try SpeechNavigationVoice.takeVoicePrompt() })
      listen()
    }

    /// Creates a voice that says each sentence through `speaker`, looks each language's voice up
    /// through `voices`, hears the audio session's interruptions on `notifications`, and takes the
    /// audio session through `takeSession`.
    init(
      language: String, fallbackLanguage: String? = nil,
      onError: (@MainActor (any Error) -> Void)? = nil,
      words: @escaping (NavigationInstruction) -> String?, speaker: any Speaker,
      voices: @escaping @Sendable (String) -> AVSpeechSynthesisVoice? = {
        AVSpeechSynthesisVoice(language: $0)
      },
      notifications: NotificationCenter,
      takeSession: @escaping @Sendable () throws -> Void = {
        try SpeechNavigationVoice.takeVoicePrompt()
      }
    ) {
      self.words = words
      self.onError = onError
      languages = Self.languages(language, fallback: fallbackLanguage)
      self.voices = voices
      self.speaker = speaker
      self.notifications = notifications
      focus = AudioFocus(take: takeSession)
      listen()
    }

    /// prepare looks the voice of the host's language up ahead of the first sentence, off the main
    /// actor, so the first sentence is not held while the system reads its catalogue of voices,
    /// which can take seconds the first time. It returns once the voice is found, or known to be
    /// missing, its fallback's then looked up too. After `close()` it does nothing.
    public func prepare() async {
      guard !closed else { return }
      let languages = languages
      let voices = voices
      await withCheckedContinuation { (prepared: CheckedContinuation<Void, Never>) in
        preparing.async {
          _ = Self.voice(for: languages, in: voices)
          prepared.resume()
        }
      }
    }

    /// say says the host's sentence for `instruction`, after anything said before it. After
    /// `close()` it does nothing.
    public func say(_ instruction: NavigationInstruction) {
      guard !closed, let text = words(instruction), !text.isEmpty else { return }
      release?.cancel()
      release = nil
      preparations += 1
      let generation = self.generation
      let languages = languages
      let voices = voices
      let focus = self.focus
      preparing.async { [weak self] in
        let refusal: (any Error)?
        do {
          try focus.take()
          refusal = nil
        } catch {
          // The sentence is said over other apps' audio rather than not at all, and the refusal
          // told.
          refusal = error
        }
        // A language the device holds no voice for falls back, then on the system's own voice.
        let voice = Self.voice(for: languages, in: voices)
        DispatchQueue.main.async { [weak self] in
          MainActor.assumeIsolated {
            self?.speak(text, in: voice, handedOver: generation, refusal: refusal)
          }
        }
      }
    }

    /// hush stops what is being said, and drops what waits to be. After `close()` it does nothing.
    public func hush() {
      guard !closed else { return }
      generation &+= 1
      speaker?.stopSpeaking(at: .immediate)
      release?.cancel()
      release = nil
      let focus = self.focus
      preparing.async { focus.release() }
    }

    /// close stops what is being said, drops what waits to be, lets the audio session go and the
    /// synthesizer with it, and stops hearing the system take the audio: nothing is said after it.
    /// Closing twice does nothing more.
    public func close() {
      guard !closed else { return }
      hush()
      closed = true
      speaker = nil
      notifications.removeObserver(
        interruptions, name: AVAudioSession.interruptionNotification, object: nil)
    }

    /// listen hushes the voice as `notifications` tells of the system taking the audio, while the
    /// voice lives.
    private func listen() {
      interruptions.began = { [weak self] in self?.hush() }
      notifications.addObserver(
        interruptions, selector: #selector(Interruptions.interrupted(_:)),
        name: AVAudioSession.interruptionNotification, object: nil)
    }

    /// speak tells `onError` the `refusal` of the audio session the sentence met, as an
    /// `audioRefused`, unless the voice is closed, and says `text` in `voice`, or in the system's
    /// own where it is nil, unless a hush came after the sentence was handed over.
    private func speak(
      _ text: String, in voice: AVSpeechSynthesisVoice?, handedOver generation: UInt64,
      refusal: (any Error)?
    ) {
      preparations -= 1
      if let refusal, !closed {
        tell(SpeechError(kind: .audioRefused, cause: refusal))
      }
      if generation == self.generation, let speaker {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        speaker.speak(utterance)
      }
      releaseWhenQuiet()
    }

    /// tell hands `failure` to `onError`, or drops it where the voice was given none, and a debug
    /// build prints it then, once, where a developer reads the console.
    private func tell(_ failure: SpeechError) {
      guard let onError else {
        #if DEBUG
          print("SpeechNavigationVoice dropped a failure, having no onError: \(failure)")
        #endif
        return
      }
      onError(failure)
    }

    /// releaseWhenQuiet lets the audio session go once nothing is being said and no sentence is on
    /// its way, half a second at least after the last was handed to the synthesizer.
    private func releaseWhenQuiet() {
      guard preparations == 0, !closed else { return }
      release?.cancel()
      release = Task { [weak self] in
        repeat {
          try? await Task.sleep(for: .milliseconds(500))
        } while !Task.isCancelled && self?.speaker?.isSpeaking == true
        guard !Task.isCancelled, let self else { return }
        release = nil
        let focus = self.focus
        preparing.async { focus.release() }
      }
    }

    /// takeVoicePrompt makes the shared audio session a voice prompt's, lowering other apps' audio
    /// and interrupting the spoken audio they play, and throws what the session refuses.
    nonisolated static func takeVoicePrompt() throws {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback, mode: .voicePrompt,
        options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
      try session.setActive(true)
    }

    /// languages is `language`, then `fallback` where it names another.
    private static func languages(_ language: String, fallback: String?) -> [String] {
      guard let fallback, !fallback.unicodeScalars.elementsEqual(language.unicodeScalars) else {
        return [language]
      }
      return [language, fallback]
    }

    /// voice is the device's voice for the first of `languages` it holds one for, or nil, the
    /// system's own voice, where it holds none.
    private nonisolated static func voice(
      for languages: [String], in voices: @Sendable (String) -> AVSpeechSynthesisVoice?
    ) -> AVSpeechSynthesisVoice? {
      for language in languages {
        if let voice = voices(language) { return voice }
      }
      return nil
    }
  }

  extension AVSpeechSynthesizer: SpeechNavigationVoice.Speaker {}

  /// AudioFocus is the audio session held for a voice prompt: taken before a sentence is said,
  /// lowering other apps' audio and interrupting the spoken audio they play, and let go once the
  /// voice is quiet, telling them to resume.
  ///
  /// It is Sendable: it is touched on the voice's own queue, but for its last release, which it
  /// makes as it goes wherever that is, so what it holds sits behind a lock.
  private final class AudioFocus: Sendable {
    private let held = OSAllocatedUnfairLock(initialState: false)
    /// takeSession makes the session the voice prompt's, and throws what the session refuses.
    private let takeSession: @Sendable () throws -> Void

    /// Creates the focus, taking the session through `take`.
    init(take: @escaping @Sendable () throws -> Void) {
      takeSession = take
    }

    /// take makes the session the voice prompt's, where it is not already, and throws what the
    /// session refuses, the next sentence trying again.
    func take() throws {
      let takeSession = takeSession
      try held.withLock { held in
        guard !held else { return }
        try takeSession()
        held = true
      }
    }

    /// release lets the session go and tells other apps to resume, where it was taken.
    func release() {
      held.withLock { held in
        guard held else { return }
        do {
          try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
          held = false
        } catch {
          // The session still plays; the next release tries again.
        }
      }
    }

    deinit {
      release()
    }
  }

  /// Interruptions hears the audio session's interruptions, kept apart so the voice publishes no
  /// Objective-C method. It is bound to the main actor, where the voice lives: the system posts an
  /// interruption on the main thread, and one posted elsewhere is heard on the main actor in a
  /// task, since a hush needs no order.
  @MainActor
  private final class Interruptions: NSObject {
    var began: () -> Void = {}

    @objc nonisolated func interrupted(_ notification: Notification) {
      guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
        AVAudioSession.InterruptionType(rawValue: raw) == .began
      else { return }
      if Thread.isMainThread {
        MainActor.assumeIsolated { began() }
      } else {
        Task { @MainActor [weak self] in
          self?.began()
        }
      }
    }
  }
#endif
