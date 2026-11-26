/// timeSliderDayStops is how many stops of a time slider's track make a day: one an hour
/// (`geo.layers.time-slider`).
let timeSliderDayStops = 24

/// timeSliderLabelledDays is the days, counted from the stop of the clock's reading, whose ticks
/// carry a word, with the path of that word: two days back, the reading itself, two days ahead and
/// five days ahead, fixed anchors a reader scrubs by, the days between them bare, since the thumb's
/// readout states the exact moment.
let timeSliderLabelledDays: [(days: Int, word: String)] = [
  (-2, "layers.timeMinus2d"), (0, "layers.timeNow"), (2, "layers.timePlus2d"),
  (5, "layers.timePlus5d"),
]

/// timeSliderTicks answers the ticks a time slider marks on `window`'s track
/// (`geo.layers.time-slider`): the stop of the clock's reading and every whole day either side of
/// it as far as the track runs, in the track's order, the ticks two days back, at the reading, two
/// days ahead and five days ahead carrying `layers.timeMinus2d`, `layers.timeNow`,
/// `layers.timePlus2d` and `layers.timePlus5d`, and the others bare.
///
/// The track's stops are hours and its length is no clock's, so a track of no instant is ticked as
/// any other.
public func timeSliderTicks(_ window: TimeSliderWindow) -> [TimeSliderTick] {
  var ticks: [TimeSliderTick] = []
  var value = window.nowValue % timeSliderDayStops
  while value <= window.maxValue {
    var word: String?
    for labelled in timeSliderLabelledDays
    where window.nowValue + labelled.days * timeSliderDayStops == value {
      word = labelled.word
    }
    ticks.append(TimeSliderTick(value: value, word: word))
    value += timeSliderDayStops
  }
  return ticks
}
