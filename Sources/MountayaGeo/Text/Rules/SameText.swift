/// sameText tells whether two texts are written with the same scalars, in the same order.
///
/// Swift's `String` equality is canonical equivalence, so `é` and an `e` with a combining acute are
/// one string there, where every other SDK compares the code points as written. A rule that tells
/// two texts apart as the contract's other SDKs do compares them here. It is the package's, so a
/// value of the map, its state among them, compares its texts as every Geo value does, and no
/// consumer's: every value that holds a text is `Hashable` by it.
package func sameText(_ a: String, _ b: String) -> Bool {
  a.unicodeScalars.elementsEqual(b.unicodeScalars)
}

/// sameText tells whether two texts a value may leave absent are the same: both absent, or both
/// present and written with the same scalars, as `sameText(_:_:)` reads two texts.
package func sameText(_ a: String?, _ b: String?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return sameText(a, b)
  default: return false
  }
}

/// sameText tells whether two values of an open vocabulary the client generates spell the same
/// word: their raw values written with the same scalars, as `sameText(_:_:)` reads two texts.
/// The generated `==` compares the raw values by canonical equivalence.
package func sameText<Word: RawRepresentable>(_ a: Word, _ b: Word) -> Bool
where Word.RawValue == String {
  sameText(a.rawValue, b.rawValue)
}

/// sameText tells whether two words of an open vocabulary a value may leave absent are the same:
/// both absent, or both present and spelled with the same scalars.
func sameText<Word: RawRepresentable>(_ a: Word?, _ b: Word?) -> Bool
where Word.RawValue == String {
  sameText(a?.rawValue, b?.rawValue)
}

/// sameText tells whether two lists of words of an open vocabulary are the same: as long as each
/// other, and word for word the same scalars, in order.
func sameText<Word: RawRepresentable>(_ a: [Word], _ b: [Word]) -> Bool
where Word.RawValue == String {
  a.count == b.count && zip(a, b).allSatisfy { sameText($0.rawValue, $1.rawValue) }
}

/// sameText tells whether two tables of texts hold the same entries: as many, and each key of one
/// held by the other under a key of the same scalars, with a value of the same scalars.
///
/// A `Dictionary` looks a key up by canonical equivalence, and holds no two keys it calls equal, so
/// the key it finds is the one entry that could match, and its own scalars are held to the key
/// looked for.
func sameText(_ a: [String: String], _ b: [String: String]) -> Bool {
  guard a.count == b.count else { return false }
  for (key, value) in a {
    guard let index = b.index(forKey: key), sameText(b[index].key, key),
      sameText(b[index].value, value)
    else { return false }
  }
  return true
}
