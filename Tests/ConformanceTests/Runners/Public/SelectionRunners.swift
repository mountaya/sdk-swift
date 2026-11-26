import GateSupport
import MountayaClient

extension PublicRunners {
  /// dataSelection builds the case's `operation`, with its `inputType`, from its field tree and
  /// answers with the document a call sends for the case's selection, `FULL` standing for the
  /// operation's own full document, or with the class it is refused with.
  ///
  /// The tree, `fields`, is written as `sdk/model.json` writes an operation's `selection`, an array
  /// of fields in the tree's order, and the caller's `select` as an object whose key order says
  /// nothing, which the document never follows.
  static let dataSelection = Runner(id: "transport.data.selection", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let operation = DataOperation(
      name: try input.string(at: "operation"),
      inputType: try input.string(at: "inputType"),
      selection: try tree(input.array(at: "fields"))
    )
    var selecting: FieldSelection?
    if let select = fixtureCase.input["select"], !select.isNull {
      selecting = try fieldSelection(select)
    }

    do throws(MountayaError) {
      let document = try operation.document(selecting: selecting)
      let isFull = selecting == nil && document == operation.document
      return .value(.string(isFull ? "FULL" : document))
    } catch {
      return .refused(error.name)
    }
  }

  /// tree reads a field tree as the model writes one: an array of fields, each its `name` and,
  /// where it holds fields, its own `fields`.
  static func tree(_ fields: [OrderedJSON]) throws(FixtureError) -> FieldSelection {
    var selected: [(String, FieldSelection)] = []
    for field in fields {
      let name = try field.string(at: "name")
      if field["fields"] != nil {
        selected.append((name, try tree(try field.array(at: "fields"))))
      } else {
        selected.append((name, true))
      }
    }
    return FieldSelection(selected)
  }

  /// fieldSelection reads a caller's selection written as the fixtures write one: an object per
  /// level, `true` for a field selected whole.
  static func fieldSelection(_ json: OrderedJSON) throws(FixtureError) -> FieldSelection {
    if let selected = json.boolValue {
      return FieldSelection(booleanLiteral: selected)
    }
    guard let members = json.members else {
      throw FixtureError(description: "a selection is an object or a boolean")
    }
    var fields: [(String, FieldSelection)] = []
    for member in members {
      fields.append((member.key, try fieldSelection(member.value)))
    }
    return FieldSelection(fields)
  }
}
