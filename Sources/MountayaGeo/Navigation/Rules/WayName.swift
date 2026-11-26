/// unnamedWay is the name the API writes for a way that has none.
private let unnamedWay = "-"

/// wayName answers the name of the way a step follows, or nil where the way has none: an empty
/// name and the `-` the API writes for an unnamed way are no name, and any other is kept as
/// written, white space included.
func wayName(_ name: String?) -> String? {
  guard let name, !name.isEmpty, !sameText(name, unnamedWay) else { return nil }
  return name
}
