import Foundation

/// WireCoded is a type the wire carries in a form of its own: a timestamp as the anchored
/// string, an address a request carries as the string it is held to a scheme as, and a collection
/// of either as a collection of those forms.
///
/// A generated type reads and writes such a property through its wire form, so its coding is
/// the same under every encoder and decoder, a consumer's included.
package protocol WireCoded {
  /// Wire is the form the wire carries.
  associatedtype Wire: Codable

  /// Creates the value its wire form carries.
  init(wire: Wire)

  /// wire is the value's wire form.
  var wire: Wire { get }
}

extension Date: WireCoded {
  package init(wire: CodedTimestamp) {
    self = wire.date
  }

  package var wire: CodedTimestamp {
    CodedTimestamp(self)
  }
}

extension URI: WireCoded {
  package init(wire: CodedURI) {
    self = wire.address
  }

  package var wire: CodedURI {
    CodedURI(self)
  }
}

extension Optional: WireCoded where Wrapped: WireCoded {
  package init(wire: Wrapped.Wire?) {
    self = wire.map(Wrapped.init(wire:))
  }

  package var wire: Wrapped.Wire? {
    map(\.wire)
  }
}

extension Array: WireCoded where Element: WireCoded {
  package init(wire: [Element.Wire]) {
    self = wire.map(Element.init(wire:))
  }

  package var wire: [Element.Wire] {
    map(\.wire)
  }
}

extension Dictionary: WireCoded where Key: Codable, Value: WireCoded {
  package init(wire: [Key: Value.Wire]) {
    self = wire.mapValues(Value.init(wire:))
  }

  package var wire: [Key: Value.Wire] {
    mapValues(\.wire)
  }
}
