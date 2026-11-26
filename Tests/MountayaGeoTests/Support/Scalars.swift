/// scalars is a text's Unicode scalars, by value, so a test compares two texts exactly: Swift's
/// `String` equality is canonical equivalence, under which `é` and `e` with a combining acute are
/// one text.
func scalars(_ text: String) -> [UInt32] {
  text.unicodeScalars.map(\.value)
}
