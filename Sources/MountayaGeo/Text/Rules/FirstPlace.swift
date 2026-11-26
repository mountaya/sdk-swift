/// firstPlace is the place of the first run of `pattern` in `scalars` at or after `from`, or `nil`
/// where none stands there, compared scalar by scalar.
///
/// It reads scalars, never `Character`s: `String.range(of:)` compares graphemes under canonical
/// equivalence, so it would find an `e` inside a precomposed `é` and refuse a match that ends
/// inside a grapheme, where every other SDK compares the code points as written.
func firstPlace(of pattern: [Unicode.Scalar], in scalars: [Unicode.Scalar], from: Int) -> Int? {
  guard !pattern.isEmpty else { return nil }
  var at = max(from, 0)
  while at <= scalars.count - pattern.count {
    if scalars[at..<(at + pattern.count)].elementsEqual(pattern) { return at }
    at += 1
  }
  return nil
}
