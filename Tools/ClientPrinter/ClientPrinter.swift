import Foundation

/// GeneratedFile is one printed file, at its path under its target's generated directory.
package struct GeneratedFile: Sendable, Equatable {
  package let path: String
  package let text: String
}

/// ClientPrinter prints the client's generated surface from the model, each unit's into its own
/// target: the core's into `MountayaClient` and the admin unit's into `MountayaAdmin`, split by the
/// `unit` the model states and by no list of its own (SPEC.md section 3).
///
/// It prints final bytes: no formatter runs between it and the file, so no formatter release
/// moves the output, and the bytes are laid out the way the repository's formatter keeps them.
/// It decides only what a language decides: the Swift type for each shape, how a name is
/// cased and escaped, where a file goes.
package enum ClientPrinter {
  /// directory is where a unit's printed files live, from the package root.
  package static func directory(of unit: ClientUnit) -> String {
    "Sources/\(unit.module)/Generated"
  }

  /// files prints the model, each unit's files in path order, each naming `digest`, the model's
  /// digest (`ModelDigest`), in its header and the core's beside `schemaVersion` as `modelDigest`.
  package static func files(for model: Model, digest: String) throws(PrinterError)
    -> [ClientUnit: [GeneratedFile]]
  {
    guard ClientPrinter.isDigest(digest) else {
      throw PrinterError("`\(digest)` is no model digest, 64 lowercase hexadecimal digits")
    }
    let printer = Printer(model: model, digest: digest)
    try printer.printAll()
    var units: [ClientUnit: [GeneratedFile]] = [:]
    for unit in ClientUnit.allCases {
      units[unit] = (printer.files[unit] ?? []).sorted { $0.path < $1.path }
    }
    return units
  }

  /// isDigest is true of a SHA-256 written as `sdk/SPEC.md` section 11 writes the model's digest,
  /// 64 lowercase hexadecimal digits.
  package static func isDigest(_ text: String) -> Bool {
    text.utf8.count == 64
      && text.utf8.allSatisfy { (0x30...0x39).contains($0) || (0x61...0x66).contains($0) }
  }
}

/// Namespace is the caseless enum one unit prints a surface's components in, and every component of
/// the surface, both units', which a type it prints may name.
struct Namespace {
  let name: String
  /// unit is the unit the namespace's types are printed in.
  let unit: ClientUnit
  let schemas: [String: Schema]
  /// spaces is the namespace each unit prints the surface's components in.
  let spaces: [ClientUnit: String]

  /// qualified is a component's name as a type of this namespace writes it: in the namespace its
  /// own unit prints it in, so the admin unit names a core component `RestSchema.Language`.
  ///
  /// A component of the admin unit is refused where the core names it, since the core compiles
  /// without the admin unit: the contract keeps every component the core names in the core
  /// (`CORE_SCHEMAS`), and a core that names one is a defect mended there.
  func qualified(_ component: String) throws(PrinterError) -> String {
    guard let schema = schemas[component] else {
      throw PrinterError("\(name): `\(component)` names no component")
    }
    guard unit != .core || schema.unit == .core else {
      throw PrinterError(
        "\(name): the core names `\(component)`, a component of the admin unit, which the core "
          + "compiles without")
    }
    guard let space = spaces[schema.unit] else {
      throw PrinterError(
        "\(name): `\(component)` is the \(schema.unit.rawValue) unit's, which prints none")
    }
    return "\(space).\(component)"
  }

  /// printing is the namespace another unit prints the same surface's components in.
  func printing(in unit: ClientUnit) -> Namespace {
    Namespace(name: spaces[unit] ?? name, unit: unit, schemas: schemas, spaces: spaces)
  }
}

/// InlineType is a type the model writes inline and names from where it sits.
enum InlineType {
  /// object is an object the model writes inline, and `form` the media type of each part the
  /// model's encoding names, by its property, where it is a `multipart/form-data` body.
  case object(InlineObject, usage: [String], form: [String: String]?)
  case enumeration(InlineEnum)
  case union(name: String, members: [TypeNode])
}

/// Printer is one run over the model. It is not Sendable: one run of the printer reads and writes
/// it on the one thread the tool runs on, and no task shares it.
final class Printer {
  let model: Model
  /// digest is the model's digest, which every printed file's header names.
  let digest: String
  /// files is each unit's printed files, in the order printed.
  var files: [ClientUnit: [GeneratedFile]] = [:]
  /// inline is each namespace's inline types, by name, as the walk meets them.
  var inline: [String: [String: InlineType]] = [:]

  /// Names the printed code uses unqualified inside a namespace, which no component may take.
  static let reservedNames: Set<String> = [
    "Bool", "CodingKey", "CodingKeyRepresentable", "Codable", "Date", "Decoder", "Double",
    "Encoder", "ExpressibleByIntegerLiteral", "ExpressibleByStringLiteral", "Foundation",
    "Hashable", "Int", "Int64", "JSONValue", "MountayaClient", "MultipartPart", "OperationBody",
    "Optional", "QueryItem", "RawRepresentable", "Self", "Sendable", "String", "Swift",
    "Timestamp", "URI", "URL", "Void", "WireKey",
    // The admin unit's types name the core's components through their namespace, and its own
    // through `AdminSchema`, inside the module the unit compiles in.
    "AdminSchema", "MountayaAdmin", "RestSchema",
  ]

  init(model: Model, digest: String) {
    self.model = model
    self.digest = digest
  }

  /// header is what every printed file of a unit starts with: the admin unit's imports the core,
  /// whose types and transport it names.
  func header(for unit: ClientUnit) -> String {
    let imports = ["Foundation"] + (unit == .core ? [] : [ClientUnit.core.module])
    return """
      // Printed by `swift run GenerateClient` from `sdk/model.json`, contract \(model.contract),
      // model digest \(digest).
      // Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
      // again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

      \(imports.map { "import \($0)" }.joined(separator: "\n"))

      """
  }

  /// emit prints one file into a unit's target.
  func emit(
    _ path: String, unit: ClientUnit, body: (inout SourceWriter) throws(PrinterError) -> Void
  ) throws(PrinterError) {
    var writer = SourceWriter()
    for line in header(for: unit).split(separator: "\n", omittingEmptySubsequences: false) {
      writer.line(String(line))
    }
    try body(&writer)
    guard !(files[unit] ?? []).contains(where: { $0.path == path }) else {
      throw PrinterError("two printed files at `\(unit.module)/\(path)`")
    }
    files[unit, default: []].append(GeneratedFile(path: path, text: writer.text))
  }

  func printAll() throws(PrinterError) {
    let rest = try namespace(
      "RestSchema", of: model.rest, spaces: [.core: "RestSchema", .admin: "AdminSchema"])
    let admin = rest.printing(in: .admin)
    let tiles = try namespace("TileSchema", of: model.tiles, spaces: [.core: "TileSchema"])
    try checkUnits()

    try emit("SchemaVersion.swift", unit: .core) { writer throws(PrinterError) in
      writer.doc(
        "schemaVersion is the contract tag this client was printed from, which is the tag its "
          + "behaviour is proven against."
      )
      writer.line("public let schemaVersion = \(SwiftText.literal(model.contract))")
      writer.line()
      writer.doc(
        "modelDigest is the digest of the files this client was printed from, `sdk/model.json` and "
          + "the elements' data, as `sdk/SPEC.md` section 11 defines it: the exact surface a build "
          + "speaks, which `schemaVersion` cannot name for a build printed between two tags."
      )
      writer.line("public let modelDigest = \(SwiftText.literal(digest))")
    }

    try printNamespace(
      rest,
      surface: model.rest,
      doc:
        "RestSchema is every type the REST API sends or receives but the admin unit's own, which "
        + "`MountayaAdmin` declares in `AdminSchema`, named as the contract names it."
    )
    try printNamespace(
      admin,
      surface: model.rest,
      doc:
        "AdminSchema is every type of the REST API that only the admin unit's operations and the "
        + "webhook events send or receive, named as the contract names it; a type of the core they "
        + "carry stays in `RestSchema`."
    )
    try printNamespace(
      tiles,
      surface: model.tiles,
      doc:
        "TileSchema is every type the Tile API sends or receives, named as the contract names it."
    )
    guard model.tiles.webhooks.isEmpty else {
      throw PrinterError("tiles.webhooks: webhooks on a surface this printer prints none for")
    }
    let received = model.rest.webhooks.first?.unit ?? .admin
    try WebhookPrinter(printer: self, space: received == .core ? rest : admin)
      .printAll(model.rest.webhooks)
    try DataPrinter(printer: self).printAll()
    try ErrorCodePrinter(printer: self).printAll()
    try OperationPrinter(printer: self, rest: rest, admin: admin, tiles: tiles).printAll()
  }

  /// checkUnits refuses what the two units cannot be printed as, before a line is printed: the
  /// Tile API's operations, templates and components in the admin unit, since the Tile API is the
  /// core's alone, a template of the REST API there too, since the templates print in the core, a
  /// group whose operations span both units, since its accessor is printed in one, and webhook
  /// events of both units, since the event they are delivered as is printed in one.
  private func checkUnits() throws(PrinterError) {
    for operation in model.tiles.operations + model.tiles.templates + model.rest.templates
    where operation.unit != .core {
      throw PrinterError(
        "\(operation.operationId): the admin unit's, and the Tile API and the templates are "
          + "printed in the core alone")
    }
    for schema in model.tiles.schemas where schema.unit != .core {
      throw PrinterError(
        "TileSchema.\(schema.name): the admin unit's, and the Tile API is printed in the core alone"
      )
    }
    var groups: [String: Operation] = [:]
    for operation in model.rest.operations {
      guard let group = operation.namespace?.split(separator: ".").first.map(String.init) else {
        continue
      }
      guard let first = groups[group] else {
        groups[group] = operation
        continue
      }
      guard first.unit == operation.unit else {
        throw PrinterError(
          "rest.\(operation.operationId): the \(operation.unit.rawValue) unit's, and "
            + "`\(first.operationId)` of its group `\(group)` the \(first.unit.rawValue) unit's: a "
            + "group's accessor is printed in one unit")
      }
    }
    guard Set(model.rest.webhooks.map(\.unit)).count <= 1 else {
      throw PrinterError(
        "rest.webhooks: events of both units, and the event they are delivered as is printed in one"
      )
    }
  }

  func namespace(_ name: String, of surface: Surface, spaces: [ClientUnit: String])
    throws(PrinterError) -> Namespace
  {
    var schemas: [String: Schema] = [:]
    for schema in surface.schemas {
      guard schemas[schema.name] == nil else {
        throw PrinterError("\(name): two components named `\(schema.name)`")
      }
      guard !Self.reservedNames.contains(schema.name) else {
        throw PrinterError(
          "\(name).\(schema.name): a component named like a type the printed code uses"
        )
      }
      schemas[schema.name] = schema
    }
    return Namespace(name: name, unit: .core, schemas: schemas, spaces: spaces)
  }

  // MARK: - Shapes

  /// shape maps a type node of an OpenAPI surface to its Swift shape, registering an inline
  /// type the walk meets.
  func shape(_ node: TypeNode, in space: Namespace, usage: [String]) throws(PrinterError)
    -> Shape
  {
    switch node.kind {
    case .string(let format, _, let inlineEnum):
      if let inlineEnum {
        try register(.enumeration(inlineEnum), named: inlineEnum.name, in: space)
        return .direct("\(space.name).\(inlineEnum.name)") { "\($0).rawValue" }
      }
      switch format {
      case "date-time":
        return Shape(
          swift: "Date",
          wired: true,
          text: { "Timestamp.string(from: \($0))" },
          isList: false
        )
      case "uri":
        // A web address is the text the wire sent: `URI` keeps an answer's whatever it holds, and
        // a type a request carries writes it through `CodedURI`, which refuses one with no scheme
        // in a body a caller built (SPEC.md section 3).
        return Self.uri(sent: usage.contains("request"))
      case "binary":
        return .direct("Foundation.Data")
      default:
        return .direct("String") { $0 }
      }
    case .integer(let format, _):
      return .direct(format == "int64" ? "Int64" : "Int") { "String(\($0))" }
    case .number:
      return .direct("Double") { "String(\($0))" }
    case .boolean:
      return .direct("Bool") { "String(\($0))" }
    case .array(let items):
      let element = try shape(items, in: space, usage: usage)
      let swift = items.nullable ? optionalType(element.swift) : element.swift
      return Shape(
        swift: "[\(swift)]",
        wired: element.wired,
        text: items.nullable || element.isList ? nil : element.text,
        isList: true
      )
    case .map(let values, let keys):
      let value = try shape(values, in: space, usage: usage)
      let key = try keys.map { keys throws(PrinterError) in try keyType(keys, in: space) }
      let swift = values.nullable ? optionalType(value.swift) : value.swift
      return Shape(
        swift: "[\(key ?? "String"): \(swift)]",
        wired: value.wired,
        text: nil,
        isList: false
      )
    case .object(let object):
      try register(.object(object, usage: usage, form: nil), named: object.name, in: space)
      return .direct("\(space.name).\(object.name)")
    case .union(let name, let members):
      try register(.union(name: name, members: members), named: name, in: space)
      return .direct("\(space.name).\(name)")
    case .ref(let name):
      return try reference(name, in: space, usage: usage)
    case .null, .any:
      // A value that is always null is the envelope's own open type holding `.null`, so a
      // success with no payload still comes back whole.
      return .direct("JSONValue")
    }
  }

  /// uri is the shape of a `format: uri` value: read and written as its text in a type only an
  /// answer carries, and through its wire form, which refuses one with no scheme, in a type a
  /// request carries.
  static func uri(sent: Bool) -> Shape {
    Shape(swift: "URI", wired: sent, text: { "\($0).text" }, isList: false)
  }

  private func reference(_ name: String, in space: Namespace, usage: [String])
    throws(PrinterError) -> Shape
  {
    guard let schema = space.schemas[name] else {
      throw PrinterError("\(space.name): `\(name)` names no component")
    }
    guard !schema.isEnvelope else {
      throw PrinterError("\(space.name): `\(name)` is an envelope component, which is not printed")
    }
    let qualified = try space.qualified(name)
    switch schema.kind {
    case .enumeration(let valueType, _):
      return .direct(qualified) {
        valueType == "integer" ? "String(\($0).rawValue)" : "\($0).rawValue"
      }
    case .alias(let target):
      let resolved = try shape(target, in: space, usage: usage)
      guard !resolved.wired, !target.nullable else { return resolved }
      return Shape(swift: qualified, wired: false, text: resolved.text, isList: resolved.isList)
    case .object, .union, .geojson:
      return .direct(qualified)
    }
  }

  private func keyType(_ node: TypeNode, in space: Namespace) throws(PrinterError) -> String {
    switch node.kind {
    case .string(_, _, nil):
      return "String"
    case .ref(let name):
      if let schema = space.schemas[name], case .enumeration("string", _) = schema.kind {
        return try space.qualified(name)
      }
    default:
      break
    }
    throw PrinterError("\(space.name): a map keyed by something other than a string")
  }

  func register(_ type: InlineType, named name: String, in space: Namespace)
    throws(PrinterError)
  {
    guard space.schemas[name] == nil else {
      throw PrinterError("\(space.name): an inline type named `\(name)` beside a component")
    }
    if inline[space.name]?[name] == nil {
      inline[space.name, default: [:]][name] = type
    }
  }

  /// presence is how a property of an OpenAPI object is present on the wire.
  ///
  /// A property that is not required and is nullable, on an object a request sends, has three
  /// states, as the model's own format says: left out, a value, and `null`. That reaches every
  /// such property, a value object a merge body embeds included, and none a response alone
  /// carries.
  func presence(_ property: Property, sentByRequest: Bool) -> Presence {
    if property.required {
      return property.type.nullable ? .nullableRequired : .required
    }
    return property.type.nullable && sentByRequest ? .merge : .optional
  }

  // MARK: - Namespaces

  /// printNamespace prints a unit's namespace of a surface and every component the model gives
  /// that unit.
  private func printNamespace(_ space: Namespace, surface: Surface, doc: String)
    throws(PrinterError)
  {
    try emit("\(space.name).swift", unit: space.unit) { writer throws(PrinterError) in
      writer.doc(
        doc + "\n\nThe types live here rather than at module scope because many names exist on "
          + "more than one surface, not always with one shape, and some would shadow a type the "
          + "standard library or Foundation publishes in every file that imports this module."
      )
      writer.line("public enum \(space.name) {}")
    }
    let types = TypePrinter(printer: self, space: space)
    for schema in surface.schemas where !schema.isEnvelope && schema.unit == space.unit {
      try types.print(schema)
    }
  }

  /// printInline prints every inline type registered in a namespace so far, including the ones
  /// printing them registers.
  func printInline(_ space: Namespace) throws(PrinterError) {
    let types = TypePrinter(printer: self, space: space)
    var printed: Set<String> = []
    while let next = (inline[space.name] ?? [:]).keys.sorted().first(where: {
      !printed.contains($0)
    }) {
      printed.insert(next)
      if let type = inline[space.name]?[next] {
        try types.print(inline: type, named: next)
      }
    }
  }
}
