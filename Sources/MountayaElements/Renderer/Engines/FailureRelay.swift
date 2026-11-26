#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo

  /// FailureRelay hands each failure a data element's itinerary resource shows to the `onError`
  /// the element was drawn with last, once, and nothing else. A failure that replaces a failure is
  /// handed on too: a read asked again after an invalidation fails while the failure before it is
  /// still shown, so whether the element shows a failure never changes.
  ///
  /// It follows the engine's states through `subscribe()`, which yields each state that differs
  /// from the one before it, in order, so two failures landing between two drawings are each
  /// handed on, and one landing while the element is off the screen is handed on as it lands. An
  /// element follows its engine before it first asks it, so no failure lands unfollowed, and
  /// follows the engine an app hands it in place of another from then on. It is bound to the main
  /// actor, where SwiftUI draws the element and the engine shows its states.
  @MainActor
  final class FailureRelay {
    /// onError is the handler a failure reaches: the one the element was drawn with last.
    private(set) var onError: ((any Error) -> Void)?
    /// following is the task handing on what the followed engine shows, nil until it follows one.
    private var following: Task<Void, Never>?
    /// followed is the engine followed, nil until it follows one.
    private var followed: ObjectIdentifier?

    deinit {
      // A relay let go of stops following, so its task outlives it by no state.
      following?.cancel()
    }

    /// hold holds `onError` as the handler a failure reaches.
    func hold(_ onError: ((any Error) -> Void)?) {
      self.onError = onError
    }

    /// follow follows `engine`: each failure it shows, from the state it shows now on, is handed to
    /// the handler held as the failure lands. A relay already following it does nothing, and one
    /// following another engine lets that one go.
    func follow(_ engine: ItineraryResourceEngine) {
      guard followed != ObjectIdentifier(engine) else { return }
      following?.cancel()
      followed = ObjectIdentifier(engine)
      let states = engine.subscribe()
      following = Task { [weak self] in
        for await state in states {
          guard let self else { return }
          if case .failed(let error) = state {
            self.onError?(error)
          }
        }
      }
    }
  }
#endif
