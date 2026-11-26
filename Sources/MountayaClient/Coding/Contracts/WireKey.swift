/// WireKey is a member name as the wire spells it, which is how every generated type names the
/// keys it reads and writes.
///
/// A generated type's keys are the contract's names verbatim, and a string literal carries any
/// of them, where an enum of keys would need each one to be a Swift identifier.
package struct WireKey: CodingKey, Hashable, ExpressibleByStringLiteral {
  package let stringValue: String

  package var intValue: Int? {
    nil
  }

  package init(stringValue: String) {
    self.stringValue = stringValue
  }

  package init?(intValue: Int) {
    nil
  }

  package init(stringLiteral value: String) {
    self.stringValue = value
  }
}
