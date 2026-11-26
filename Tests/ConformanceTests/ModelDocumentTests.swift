import Foundation
import GateSupport
import MountayaClient
import Testing

/// The document printer against every document `sdk/model.json` carries. The model is where the
/// contract writes the full selection's bytes once for every SDK, and the persisted-query digest
/// is taken over them, so a printer that differed by one space would send a digest the server
/// never stored.
@Suite("Model documents")
struct ModelDocumentTests {
  @Test("every Data API operation prints the full document the model carries")
  func printsTheModelsDocuments() throws {
    guard let checkout = try Conformance.contract.get()?.checkout else { return }
    let url = checkout.directory.appendingPathComponent("sdk/model.json")
    let text = try #require(SourceTree.read(url), "sdk/model.json cannot be read")
    let model = try OrderedJSON.parse(text)
    let operations = try #require(model["data"]?["operations"]?.elements)
    try #require(!operations.isEmpty)

    for operation in operations {
      let name = try operation.string(at: "name")
      let printed = DataOperation(
        name: name,
        inputType: try operation.string(at: "inputType"),
        selection: try Self.tree(operation.array(at: "selection"))
      )

      #expect(printed.document == (try operation.string(at: "document")), "\(name)")
      #expect(try printed.document(selecting: printed.selection) == printed.document, "\(name)")
    }
  }

  /// tree reads the model's field tree, an array of fields each carrying its own `fields`
  /// where it is an object.
  private static func tree(_ fields: [OrderedJSON]) throws -> FieldSelection {
    var selected: [(String, FieldSelection)] = []
    for field in fields {
      let name = try field.string(at: "name")
      if field["fields"] != nil {
        selected.append((name, try tree(field.array(at: "fields"))))
      } else {
        selected.append((name, true))
      }
    }
    return FieldSelection(selected)
  }
}
