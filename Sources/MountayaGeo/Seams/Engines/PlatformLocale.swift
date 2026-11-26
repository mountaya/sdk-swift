import Foundation

/// The numbering systems the platform's locale services carry, read once.
private let availableNumberingSystems = Set(Locale.NumberingSystem.availableNumberingSystems)

/// How many locales the cache holds before it is emptied.
private let localeLimit = 64

/// Every locale a tag was read into, by its tag, each parsed once and kept under a lock, since a
/// rule formats from whatever thread it is called on and cannot await.
private let parsedLocales = Locked<[String: Locale]>([:])

/// platformLocale is the `Locale` a language tag names, built from its parsed components and never
/// from the platform's default: its language, script, region, calendar, numbering system and the
/// rest of its `-u-` keywords.
///
/// It is built from `Locale.Components`, never `Locale(identifier:)`, because Foundation on macOS
/// 27 reads a `nu` value equal to the language's script code as that script and drops it:
/// `bn-BD-u-nu-beng`, `th-TH-u-nu-thai` and `en-US-u-nu-latn` each leave no system at all
/// (`bn-BD-u-nu`), whatever digits the locale writes by default, where `en-US-u-nu-arab` and
/// `bn-BD-u-nu-deva` are kept. Its formatters then write nothing, and `DateFormatter` on Linux
/// traps on `bn-BD-u-nu-beng`. A numbering system the platform does not carry, `en-u-nu-xxxx`, is
/// dropped, so the locale writes its own digits, as `java.text` reads such a tag: Foundation's
/// formatters write nothing for one on Apple platforms, and `DateFormatter` traps on one on Linux.
///
/// A tag is parsed once, `parsedLocale(_:)`, and its locale kept in a cache of 64 under a lock, as
/// the date formatters are, so a list of figures in one language parses its tag once rather than
/// at every number.
func platformLocale(_ languageTag: String) -> Locale {
  cachedLocale(languageTag, in: parsedLocales, limit: localeLimit, parse: parsedLocale)
}

/// parsedLocale is the `Locale` `languageTag` names, parsed afresh from its components, a
/// numbering system the platform does not carry dropped, as `platformLocale(_:)` describes.
func parsedLocale(_ languageTag: String) -> Locale {
  var components = Locale.Components(identifier: languageTag)
  if let system = components.numberingSystem, !availableNumberingSystems.contains(system) {
    components.numberingSystem = nil
  }
  return Locale(components: components)
}

/// cachedLocale is the locale `cache` holds for `languageTag`, or the one `parse` reads, which
/// `cache` then keeps, emptied first where it holds `limit` locales already. `parse` runs outside
/// the lock, so two threads that ask for one tag at once may each parse it, and both answer the
/// same locale.
func cachedLocale(
  _ languageTag: String, in cache: Locked<[String: Locale]>, limit: Int,
  parse: (String) -> Locale
) -> Locale {
  if let held = cache.withLock({ $0[languageTag] }) {
    return held
  }
  let locale = parse(languageTag)
  cache.withLock { locales in
    if locales.count >= limit {
      locales.removeAll()
    }
    locales[languageTag] = locale
  }
  return locale
}
