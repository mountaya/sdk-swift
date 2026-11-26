import Foundation

/// canonicalComposition is a text in Unicode's canonical composition, NFC: decomposed, then each
/// base and the marks that compose with it written as the one letter they make, so `E` and a
/// combining acute are `É`, and two Hangul jamo one syllable. Foundation's canonical mapping writes
/// it, on Apple platforms and on Linux, from the platform's own character database.
///
/// Two texts it answers are compared by their scalars, never by `==`: Swift's `String` equality is
/// canonical equivalence, under which a text and its composition are always equal.
func canonicalComposition(_ text: String) -> String {
  text.precomposedStringWithCanonicalMapping
}
