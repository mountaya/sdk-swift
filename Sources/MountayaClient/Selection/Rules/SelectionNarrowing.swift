/// SelectionNarrowing holds a caller's field selection to an operation's field tree.
///
/// A selection is checked against the tree rather than against the result type, so a field
/// outside it fails where the caller wrote it instead of as a server error. `true` selects a field
/// whole: a value, or an object with every field the tree holds beneath it (`sdk/SPEC.md` §5).
enum SelectionNarrowing {
  /// narrow returns the part of `tree` that `selection` names, in the tree's order, or throws
  /// `SelectionError` naming the first field the tree does not allow.
  static func narrow(_ tree: FieldSelection, to selection: FieldSelection) throws(MountayaError)
    -> FieldSelection
  {
    try narrow(tree, to: selection, at: [])
  }

  private static func narrow(
    _ tree: FieldSelection,
    to selection: FieldSelection,
    at path: [String]
  ) throws(MountayaError) -> FieldSelection {
    guard case .fields(let allowed) = tree.node else {
      return tree
    }
    guard case .fields(let selected) = selection.node, !selected.isEmpty else {
      throw refusal(
        at: path,
        message: path.isEmpty
          ? "the selection names no field; leave it out to select every field"
          : "this selection names no field beneath it: name one, or select it whole with `true`"
      )
    }
    for field in selected where !allowed.contains(where: { $0.name == field.name }) {
      let names = allowed.map { "`\($0.name)`" }.joined(separator: ", ")
      throw refusal(at: path + [field.name], message: "no such field; the fields here are \(names)")
    }

    var narrowed: [FieldSelection.Field] = []
    for field in allowed {
      guard let chosen = selected.first(where: { $0.name == field.name }) else { continue }
      if case .fields = field.selection.node {
        guard chosen.selection.node != .whole else {
          // `true` on an object selects its whole subtree, as the tree holds it.
          narrowed.append(field)
          continue
        }
        let beneath = try narrow(field.selection, to: chosen.selection, at: path + [field.name])
        narrowed.append(FieldSelection.Field(name: field.name, selection: beneath))
      } else {
        guard chosen.selection.node == .whole else {
          throw refusal(
            at: path + [field.name],
            message: "this field has no fields beneath it: select it with `true`"
          )
        }
        narrowed.append(field)
      }
    }
    return FieldSelection(node: .fields(narrowed))
  }

  private static func refusal(at path: [String], message: String) -> MountayaError {
    .selection(SelectionError(path: path, message: message))
  }
}
