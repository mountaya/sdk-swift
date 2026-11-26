import Foundation

#if !canImport(Darwin)
  import CoreFoundation
#endif

/// How many formatters the cache holds before it is emptied.
private let dateFormatterLimit = 64

/// One formatter per locale, shape and zone, built once and never changed after. Foundation's
/// `DateFormatter` formats from any thread once it is configured, and is `Sendable` on every
/// platform this SDK builds for.
private let dateFormatters = Locked<[String: DateFormatter]>([:])

/// localeDateText is an instant in the time zone the IANA name `timeZone` names, written by the
/// platform's locale services for `languageTag` in the Gregorian calendar: its date at
/// `dateLength`, its time of day at `timeLength`, or both, joined as the locale joins a date of
/// that length and a time. The fields, their order, its words, its digits and the hour cycle are
/// the locale's. Nil where the platform's zone data holds no zone of that name (`formatterLoads`).
///
/// The locale, as `platformLocale(_:)` reads it, and the zone are always the ones named, never the
/// platform's defaults, and the calendar is always the Gregorian one, whatever calendar the locale
/// keeps or a `-u-ca-` extension of the tag names (`sdk/SPEC.md` §7): Thai (`th-TH`) writes the year
/// 2026 and never the Buddhist 2569, naming the Christian era as its Gregorian long date does,
/// `14 มีนาคม ค.ศ. 2026`. The locale is read from the tag alone, so it carries none of the
/// preferences `Locale.current` carries, the person's 12- or 24-hour setting among them: a time is
/// on the locale's own clock, `13:00` in German and `오후 1:00` in Korean, whatever the device is
/// set to.
///
/// It is Foundation's `DateFormatter` at the styles of the two lengths, because Foundation's date
/// format style writes its short and medium dates from a field template rather than the locale's
/// own style (`3/14/2026` and `14. März 2026`, where the styles write `3/14/26` and `14.03.2026`),
/// and a length means the locale's own style of that length in every SDK. Where both lengths are
/// nil, the styles write nothing.
func localeDateText(
  _ instant: Date, languageTag: String, timeZone: String, dateLength: DateLength?,
  timeLength: TimeLength?
) -> String? {
  formatted(
    instant, languageTag: languageTag, timeZone: timeZone,
    shape: .styles(date: dateLength, time: timeLength))
}

/// localeMomentText is an instant as a time slider's readout writes it (`geo.layers.time-readout`):
/// its weekday, day, month, hour and minute in the time zone the IANA name `timeZone` names,
/// written by the platform's locale services for `languageTag` in the Gregorian calendar, the
/// fields, their order, the hour's cycle and the words the locale's own, `Sat 14 Mar, 09:26` in
/// British English. Nil where the platform's zone data holds no zone of that name.
package func localeMomentText(_ instant: Date, languageTag: String, timeZone: String) -> String? {
  formatted(instant, languageTag: languageTag, timeZone: timeZone, shape: .moment)
}

/// What a cached formatter writes.
private enum Shape {
  /// An instant's date, its time of day or both, each at the locale's own style of its length.
  case styles(date: DateLength?, time: TimeLength?)
  /// A time slider's moment, from its template.
  case moment

  /// The part of a formatter's key that tells it from the formatters of the other shapes.
  var key: String {
    switch self {
    case .styles(let date, let time): "\(date?.rawValue ?? "-")|\(time?.rawValue ?? "-")"
    case .moment: "moment"
    }
  }
}

/// formatted writes `instant` through the formatter cached for `languageTag`, `shape` and
/// `timeZone`, made over the locale, the Gregorian calendar and the zone the first time it is asked
/// for, or nil where the platform's zone data holds no zone of that name.
private func formatted(
  _ instant: Date, languageTag: String, timeZone: String, shape: Shape
) -> String? {
  let key = "\(languageTag)|\(shape.key)|\(timeZone)"
  if let cached = dateFormatters.withLock({ $0[key] }) {
    return cached.string(from: instant)
  }
  guard let zone = TimeZone(identifier: timeZone), formatterLoads(zone) else { return nil }
  let formatter = DateFormatter()
  formatter.locale = platformLocale(languageTag)
  // After the locale, which would set its own calendar over one set first. The calendar keeps the
  // zone written in, never the process's own, which a formatter on Linux loads by its name too and
  // traps on where its data is missing, as a server whose zone is set to `US/Eastern` has it
  // (`formatterLoads`).
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = zone
  formatter.calendar = calendar
  formatter.timeZone = zone
  switch shape {
  case .styles(let date, let time):
    formatter.dateStyle = date.map(style(of:)) ?? .none
    formatter.timeStyle = time.map(style(of:)) ?? .none
  case .moment:
    // After the locale, whose fields the template is read in.
    formatter.setLocalizedDateFormatFromTemplate("EEEdMMMjjmm")
  }
  dateFormatters.withLock { formatters in
    if formatters.count >= dateFormatterLimit {
      formatters.removeAll()
    }
    formatters[key] = formatter
  }
  return formatter.string(from: instant)
}

/// formatterLoads is whether the zone data a formatter writes from holds `zone`, so that the
/// formatter can be handed it.
///
/// On Apple platforms it holds every zone `TimeZone(identifier:)` answers, a legacy name the tz
/// database keeps in its `backward` file included: `Asia/Calcutta` writes as `Asia/Kolkata` does.
/// Elsewhere Foundation is swift-corelibs-foundation, whose `TimeZone` answers a name from ICU's
/// data while its `DateFormatter` hands CoreFoundation the zone by that name, which CoreFoundation
/// loads from the system's zone files and traps where it loads none: a Linux image with `tzdata`
/// and no `tzdata-legacy`, the Swift images among them, holds no file for `Asia/Calcutta` or
/// `US/Eastern`, and a formatter handed either stops the process. So a zone is handed to a
/// formatter only where CoreFoundation creates it by that name, the call the formatter makes, and
/// a zone it cannot create writes nothing, as `sdk/SPEC.md` §7 has a zone the SDK's data lacks.
/// No list of names stands in for the data, which a host's own packages decide.
private func formatterLoads(_ zone: TimeZone) -> Bool {
  #if canImport(Darwin)
    return true
  #else
    let name = CFStringCreateWithCString(
      nil, zone.identifier, CFStringBuiltInEncodings.UTF8.rawValue)
    return CFTimeZoneCreateWithName(nil, name, true) != nil
  #endif
}

/// Foundation's style of a date length.
private func style(of length: DateLength) -> DateFormatter.Style {
  switch length {
  case .short: return .short
  case .medium: return .medium
  case .long: return .long
  case .full: return .full
  }
}

/// Foundation's style of a time length.
private func style(of length: TimeLength) -> DateFormatter.Style {
  switch length {
  case .short: return .short
  case .medium: return .medium
  }
}
