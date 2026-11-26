/// Shape is a contract type as Swift spells it: the type a declaration names, and whether it
/// travels on the wire in a form of its own.
struct Shape: Sendable {
  /// swift is the Swift type, written in full from the module's scope.
  let swift: String
  /// wired is true where the type is read and written through `WireCoded`, which is a
  /// timestamp, or a collection holding one.
  let wired: Bool
  /// text turns a value of the type into the string a query or a form carries, or is nil where
  /// the type has no such string.
  let text: (@Sendable (String) -> String)?
  /// isList is true for an array, which a query or a form carries as one item per element.
  let isList: Bool

  static func direct(_ swift: String, text: (@Sendable (String) -> String)? = nil) -> Shape {
    Shape(swift: swift, wired: false, text: text, isList: false)
  }
}

/// Presence is how a property is present on the wire, which decides its Swift type and its
/// coding.
enum Presence: Sendable {
  /// required is a property always present and never null: `T`.
  case required
  /// nullableRequired is a property always present that may be null: `T?`, written as `null`.
  case nullableRequired
  /// optional is a property that may be absent, or null where the contract allows it: `T?`,
  /// left out when nil.
  case optional
  /// merge is a property a merge body declares optional and nullable: `T??`, whose
  /// `.some(nil)` is written as `null`.
  case merge

  /// declared is the type a property of this presence is declared as.
  func declared(_ shape: Shape) -> String {
    switch self {
    case .required: shape.swift
    case .nullableRequired, .optional: optionalType(shape.swift)
    case .merge: optionalType(optionalType(shape.swift))
    }
  }

  /// isInitializerArgument is true where a caller must give the property to build the value.
  var isInitializerArgument: Bool {
    switch self {
    case .required, .nullableRequired: true
    case .optional, .merge: false
    }
  }

  /// encodeMethod is the container method writing the property.
  func encodeMethod(_ shape: Shape) -> String {
    let wired = shape.wired ? "Wired" : ""
    switch self {
    case .required: return "encode\(wired)"
    case .nullableRequired: return shape.wired ? "encodeWiredNullable" : "encodeNullable"
    case .optional: return "encode\(wired)IfPresent"
    case .merge: return shape.wired ? "encodeWiredMerge" : "encodeMerge"
    }
  }
}

/// optional spells `T?`, wrapping a type that would otherwise bind wrongly.
func optionalType(_ swift: String) -> String {
  swift.hasPrefix("any ") || swift.contains("->") ? "(\(swift))?" : "\(swift)?"
}
