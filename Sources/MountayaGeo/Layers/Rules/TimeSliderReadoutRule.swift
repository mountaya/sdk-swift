/// timeSliderReadout answers what a time slider's thumb reads at the stop `value` of `window`'s
/// track (`geo.layers.time-readout`): the instant the stop stands for, and its offset from the stop
/// of the clock's reading, in hours.
///
/// No offset reads `layers.timeNow`. An offset under a day reads its whole hours,
/// `layers.timeHoursAhead` or `layers.timeHoursAgo`, and one of a day or more its whole days,
/// truncated toward the clock's reading, `layers.timeDaysAhead` or `layers.timeDaysAgo`, so 47 hours
/// ahead reads one day ahead: a day here is 24 stops, never a calendar day, which is why the words
/// are counted ones, "in 1 day", and never a platform's relative words, "tomorrow". A stop that
/// stands for no instant reads its offset alone.
///
/// A slider writes it as the instant through the locale services, the reader's weekday, day,
/// month, hour and minute in the device's time zone, then ` · `, then the offset's word.
public func timeSliderReadout(_ window: TimeSliderWindow, at value: Int) -> TimeSliderReadout {
  let instant = window.date(at: value)
  let hours = value - window.nowValue
  guard hours != 0 else {
    return TimeSliderReadout(instant: instant, word: "layers.timeNow", count: nil)
  }
  // Truncated toward the clock's reading: 47 hours is one day, either way.
  let days = hours / timeSliderDayStops
  if days != 0 {
    return TimeSliderReadout(
      instant: instant, word: days > 0 ? "layers.timeDaysAhead" : "layers.timeDaysAgo",
      count: abs(days))
  }
  return TimeSliderReadout(
    instant: instant, word: hours > 0 ? "layers.timeHoursAhead" : "layers.timeHoursAgo",
    count: abs(hours))
}
