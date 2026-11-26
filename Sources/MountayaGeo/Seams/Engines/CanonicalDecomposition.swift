import Foundation

/// canonicalDecomposition is a text in Unicode's canonical decomposition, NFD: each composed letter
/// written as its base and its combining marks in canonical order, so `É` is `E` and a combining
/// acute. Foundation's canonical mapping writes it, on Apple platforms and on Linux, from the
/// platform's own character database.
func canonicalDecomposition(_ text: String) -> String {
  text.decomposedStringWithCanonicalMapping
}
