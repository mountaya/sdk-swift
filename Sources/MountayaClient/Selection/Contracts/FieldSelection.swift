/// FieldSelection is a set of fields of a Data API result, each selected whole or with the
/// fields selected beneath it.
///
/// It is written the way the contract writes one, `true` selecting a field whole:
///
///     let selection: FieldSelection = [
///       "routes": [
///         "distance": true,
///         "analysis": ["elevations": true],
///       ]
///     ]
///
/// A field set to `false` is not selected. The order a selection is written in decides
/// nothing: the document is printed in the order of the operation's field tree, so two
/// selections of the same fields send the same bytes.
public struct FieldSelection: Sendable, Hashable, ExpressibleByDictionaryLiteral,
  ExpressibleByBooleanLiteral
{
  /// Field is one selected field and what is selected beneath it.
  struct Field: Sendable, Hashable {
    let name: String
    let selection: FieldSelection
  }

  /// Node is what a selection holds.
  enum Node: Sendable, Hashable {
    /// whole selects a field with nothing beneath it, written `true`.
    case whole
    /// excluded selects nothing, written `false`.
    case excluded
    /// fields selects these fields beneath an object, in the order they were given.
    case fields([Field])
  }

  let node: Node

  init(node: Node) {
    self.node = node
  }

  /// Creates a selection of these fields, each with what is selected beneath it. A field
  /// named twice takes the selection given last, and a field set to `false` is left out.
  public init(_ fields: [(String, FieldSelection)]) {
    var selected: [Field] = []
    for (name, selection) in fields {
      selected.removeAll { $0.name == name }
      if selection.node != .excluded {
        selected.append(Field(name: name, selection: selection))
      }
    }
    self.init(node: .fields(selected))
  }

  /// Creates a selection of the fields a dictionary literal names.
  public init(dictionaryLiteral elements: (String, FieldSelection)...) {
    self.init(elements)
  }

  /// Creates the selection of a field whole, for `true`, or of nothing, for `false`.
  public init(booleanLiteral value: Bool) {
    self.init(node: value ? .whole : .excluded)
  }
}
