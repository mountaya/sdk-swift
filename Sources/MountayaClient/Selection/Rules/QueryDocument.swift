/// QueryDocument prints the GraphQL document of a Data API operation for a selection.
///
/// The bytes are contract, since the persisted-query digest is taken over them: two spaces to
/// a level and one field to a line, the operation named after its field with the first letter
/// upper-cased, and a single newline at the end.
enum QueryDocument {
  /// print returns the document that selects `selection` from the operation `name`, whose
  /// `input` argument has the GraphQL type `inputType`.
  static func print(name: String, inputType: String, selection: FieldSelection) -> String {
    var text = "query \(name.prefix(1).uppercased())\(name.dropFirst())($input: \(inputType)) {\n"
    text += "  \(name)(input: $input) {\n"
    write(selection, depth: 2, into: &text)
    text += "  }\n}\n"
    return text
  }

  private static func write(_ selection: FieldSelection, depth: Int, into text: inout String) {
    guard case .fields(let fields) = selection.node else { return }
    let indent = String(repeating: "  ", count: depth)
    for field in fields {
      if case .fields = field.selection.node {
        text += "\(indent)\(field.name) {\n"
        write(field.selection, depth: depth + 1, into: &text)
        text += "\(indent)}\n"
      } else {
        text += "\(indent)\(field.name)\n"
      }
    }
  }
}
