import MountayaClient

/// The keys a fold never writes, each the name of a member every JavaScript object has: an override
/// read from JSON that states one is left out there, and here, so a word lands in every SDK alike.
/// A map's paint leaves a rank band of one of these names out for the same reason (`MapPaint`).
let prototypeKeys: Set<String> = ["__proto__", "constructor", "prototype"]

/// resolveBundle is the words `bundle` resolves to for `language`, three layers folded innermost
/// first:
///
/// 1. the base, the translation for the language: one the host handed over among `handedOver`
///    ahead of one the bundle carries, and the bundle's English where neither stands, so a surface
///    in a language nobody translated reads English rather than nothing;
/// 2. the bundle's partial layer for the language, so a language partly translated reads its own
///    words where it has them;
/// 3. the consumer's `overrides`, keyed by section for whichever language is selected, or keyed by
///    language and folded for that language alone.
///
/// A word is a leaf and replaces, a list replaces too, and two sections merge, at any depth; a word
/// written `null` is a word left out, so the one beneath it stands, and a key naming a JavaScript
/// prototype member (`__proto__`, `constructor`, `prototype`) is left out in every SDK. A layer
/// that changes no word folds nothing, and the answer is then the tree beneath it.
public func resolveBundle(
  _ bundle: WordBundle,
  language: RestSchema.Language = .en,
  overrides: WordOverrides? = nil,
  handedOver: [RestSchema.Language: [String: JSONValue]] = [:]
) -> [String: JSONValue] {
  let base = handedOver[language] ?? bundle.translations[language] ?? bundle.english
  var patch: [String: JSONValue]?
  switch overrides {
  case .bySection(let words)?: patch = words
  case .byLanguage(let words)?: patch = words[language]
  case nil: patch = nil
  }
  return [bundle.partial[language], patch].compactMap { $0 }.reduce(base) { resolved, layer in
    changesNothing(folding: layer, onto: resolved) ? resolved : fold(layer, onto: resolved)
  }
}

/// changesNothing is whether folding `patch` onto `base` would change no word.
private func changesNothing(
  folding patch: [String: JSONValue], onto base: [String: JSONValue]
) -> Bool {
  patch.allSatisfy { key, value in
    if case .null = value { return true }
    if prototypeKeys.contains(key) { return true }
    guard let held = base[key] else { return false }
    if sameJson(held, value) { return true }
    guard case .object(let heldSection) = held, case .object(let section) = value else {
      return false
    }
    return changesNothing(folding: section, onto: heldSection)
  }
}

/// fold is `base` with each word and section `patch` states folded on.
private func fold(_ patch: [String: JSONValue], onto base: [String: JSONValue]) -> [String:
  JSONValue]
{
  var section = base
  for (key, value) in patch {
    if case .null = value { continue }
    if prototypeKeys.contains(key) { continue }
    if case .object(let current)? = section[key], case .object(let incoming) = value {
      section[key] = .object(fold(incoming, onto: current))
    } else {
      section[key] = value
    }
  }
  return section
}
