/// timeSliderRelease answers what a release of a time slider's thumb on the stop `value` of
/// `window`'s track commits (`geo.layers.time-slider`): the instant the stop stands for as the pin,
/// or no pin on the stop of the clock's reading, so every surface that reads the time follows the
/// clock again rather than holding the moment it read at the release.
///
/// Nil where the release commits nothing: on a track of no instant, and for a value that is no stop
/// of the track, which name no time to show.
///
/// ```swift
/// if let released = timeSliderRelease(timeSliderWindow(now: clock.now), at: value) {
///   layers.setInstant(released.pin)
/// }
/// ```
public func timeSliderRelease(_ window: TimeSliderWindow, at value: Int) -> TimeSliderRelease? {
  guard let instant = window.date(at: value) else { return nil }
  return TimeSliderRelease(pin: value == window.nowValue ? nil : instant)
}
