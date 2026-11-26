/// ErrorCodePrinter prints `APIErrorCode`, the one open vocabulary an error's code is typed by on
/// every surface: the union of the codes each surface declares, the Map Studio API's
/// `ErrorExtensionsCode`, the Tile API's `ErrorExtensionsCode` and the Data API's `ErrorCode`, as the
/// model names them (`sdk/SPEC.md` §3).
///
/// The two REST vocabularies sit inline in each surface's error envelope, which no printed type
/// holds, so the union is the one type their codes are printed as. It is printed at the core's
/// module scope, as the registry's `swift` column names it, an open set as every enum the model
/// declares is (SPEC.md section 3): a code a later release of the API sends is kept as sent.
struct ErrorCodePrinter {
  let printer: Printer

  /// name is the type's name, Swift's spelling of the contract's one name for it.
  static let name = "APIErrorCode"
  /// restVocabulary is the name the model gives each REST surface's inline vocabulary.
  static let restVocabulary = "ErrorExtensionsCode"
  /// dataVocabulary is the name of the Data API's enum of codes.
  static let dataVocabulary = "ErrorCode"

  /// Source is one surface's vocabulary, under the name a member's doc comment gives the surface.
  private struct Source {
    let surface: String
    let codes: [String]
  }

  func printAll() throws(PrinterError) {
    let sources = [
      Source(
        surface: "the Map Studio API",
        codes: try Self.vocabulary(of: printer.model.rest, in: "rest")),
      Source(
        surface: "the Tile API",
        codes: try Self.vocabulary(of: printer.model.tiles, in: "tiles")),
      Source(surface: "the Data API", codes: try dataCodes()),
    ]
    var codes: [String] = []
    for source in sources {
      for code in source.codes where !codes.contains(code) {
        codes.append(code)
      }
    }
    let members = try codes.map { code throws(PrinterError) in
      let surfaces = sources.filter { $0.codes.contains(code) }.map(\.surface)
      return Layout.EnumValue(
        source: code,
        name: try MemberWords.data(code, of: Self.name, in: "MountayaClient"),
        literal: SwiftText.literal(code),
        doc: "`\(code)`, as the wire spells it, which \(Self.prose(surfaces)) "
          + (surfaces.count == 1 ? "declares." : "declare."),
        deprecation: nil
      )
    }
    try printer.emit("\(Self.name).swift", unit: .core) { writer throws(PrinterError) in
      try Layout.enumeration(
        &writer,
        name: Self.name,
        in: "MountayaClient",
        doc: "\(Self.name) is the code an error carries, on the error and on each of its entries: "
          + "the one vocabulary of every surface, the union of the Map Studio API's and the Tile "
          + "API's `\(Self.restVocabulary)` and the Data API's `\(Self.dataVocabulary)`.\n\n"
          + "A program branches on it, never on an entry's `message`, which is written for a "
          + "person and free to change.",
        valueType: "string",
        members: members
      )
    }
  }

  /// vocabulary is the codes a REST surface declares: every value of every inline vocabulary the
  /// model names `ErrorExtensionsCode` in its components, in the model's order. A surface that
  /// declares none is refused, since the union would then lose its codes without a word.
  private static func vocabulary(of surface: Surface, in name: String) throws(PrinterError)
    -> [String]
  {
    var codes: [String] = []
    var found = false
    for schema in surface.schemas {
      guard case .object(let properties, _, _, _) = schema.kind else { continue }
      for property in properties {
        for values in inlineVocabularies(in: property.type) {
          found = true
          for value in values where !codes.contains(value) {
            codes.append(value)
          }
        }
      }
    }
    guard found else {
      throw PrinterError(
        "\(name): declares no `\(restVocabulary)`, and \(Self.name) is the union of every "
          + "surface's codes")
    }
    return codes
  }

  /// inlineVocabularies is the values of every inline vocabulary named `ErrorExtensionsCode` a type
  /// holds, however deep.
  private static func inlineVocabularies(in node: TypeNode) -> [[String]] {
    switch node.kind {
    case .string(_, _, let inlineEnum?) where inlineEnum.name == restVocabulary:
      return [inlineEnum.values]
    case .array(let items):
      return inlineVocabularies(in: items)
    case .map(let values, _):
      return inlineVocabularies(in: values)
    case .object(let object):
      return object.properties.flatMap { inlineVocabularies(in: $0.type) }
    case .union(_, let members):
      return members.flatMap(inlineVocabularies)
    default:
      return []
    }
  }

  /// dataCodes is the members of the Data API's `ErrorCode`, in the model's order.
  private func dataCodes() throws(PrinterError) -> [String] {
    guard let codes = printer.model.data.enums.first(where: { $0.name == Self.dataVocabulary })
    else {
      throw PrinterError(
        "data: declares no `\(Self.dataVocabulary)`, and \(Self.name) is the union of every "
          + "surface's codes")
    }
    return codes.members.map(\.name)
  }

  /// prose writes surfaces as a sentence lists them: `a`, `a and b`, or `a, b and c`.
  private static func prose(_ surfaces: [String]) -> String {
    guard let last = surfaces.last, surfaces.count > 1 else { return surfaces.joined() }
    return surfaces.dropLast().joined(separator: ", ") + " and " + last
  }
}
