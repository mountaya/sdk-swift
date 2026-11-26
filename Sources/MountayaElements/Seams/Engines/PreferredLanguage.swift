import Foundation

/// preferredLanguage is the language the device's reader prefers first, a language tag, or nil
/// where the platform names none: the environment a map's labels fall back to where neither the
/// map nor its client names a language (`geo.style.label-language`).
func preferredLanguage() -> String? {
  Locale.preferredLanguages.first
}
