/// DataPrinter prints the Data API's types into `DataSchema`.
struct DataPrinter {
  let printer: Printer

  /// The Swift type each of GraphQL's own scalars maps onto.
  static let builtins: [String: Shape] = [
    "Boolean": .direct("Bool") { "String(\($0))" },
    "Float": .direct("Double") { "String(\($0))" },
    "ID": .direct("String") { $0 },
    "Int": .direct("Int") { "String(\($0))" },
    "String": .direct("String") { $0 },
  ]

  /// scalarShape maps a scalar onto its Swift shape: one of GraphQL's own by its name, and one
  /// the Data API declares by the wire form it names, so `DateTime` reads through its wire form
  /// as REST's `date-time` does, `URL` is the `URI` REST's `uri` is, and `GeoJSON` is the one
  /// geometry type both surfaces share.
  static func scalarShape(_ scalar: DataScalar, sent: Bool = false) throws(PrinterError) -> Shape {
    switch scalar.wire {
    case nil:
      guard let shape = builtins[scalar.name] else {
        throw PrinterError("DataSchema: the scalar `\(scalar.name)` maps onto no Swift type")
      }
      return shape
    case .string(format: "date-time"?):
      return Shape(
        swift: "Date",
        wired: true,
        text: { "Timestamp.string(from: \($0))" },
        isList: false
      )
    case .string(format: "uri"?):
      return Printer.uri(sent: sent)
    case .string(format: nil):
      return .direct("String") { $0 }
    case .string(let format?):
      throw PrinterError("DataSchema: the scalar `\(scalar.name)` is a string as `\(format)`")
    case .geojson(let geometry):
      guard let type = TypePrinter.geometries[geometry] else {
        throw PrinterError("DataSchema: the scalar `\(scalar.name)` is no GeoJSON geometry")
      }
      return .direct(type)
    }
  }

  /// scalars maps every scalar the Data API declares onto its Swift shape, by name, as a type an
  /// answer carries reads it, or as an input a request carries writes it where `sent` is true.
  func scalars(sent: Bool = false) throws(PrinterError) -> [String: Shape] {
    var shapes: [String: Shape] = [:]
    for scalar in printer.model.data.scalars {
      guard shapes[scalar.name] == nil else {
        throw PrinterError("DataSchema: two scalars named `\(scalar.name)`")
      }
      shapes[scalar.name] = try Self.scalarShape(scalar, sent: sent)
    }
    return shapes
  }

  func printAll() throws(PrinterError) {
    let data = printer.model.data
    let declared = try names()
    let scalars = try scalars()
    let sentScalars = try self.scalars(sent: true)
    try printer.emit("DataSchema.swift", unit: .core) { writer throws(PrinterError) in
      writer.doc(
        "DataSchema is every type the Data API sends or receives, named as the contract names it."
          + "\n\nThe types live here rather than at module scope because many names exist on "
          + "more than one surface, not always with one shape, and the Data API's namespace is "
          + "never a bare `Data`, which would shadow Foundation's in every file that imports "
          + "this module."
      )
      writer.line("public enum DataSchema {}")
    }

    for object in data.objects {
      let members = try object.fields.map { field throws(PrinterError) in
        try member(field, presence: .optional, names: declared, scalars: scalars)
      }
      try emit(object.name) { writer throws(PrinterError) in
        try Layout.object(
          &writer,
          name: object.name,
          doc: (object.description ?? "The contract's `\(object.name)`.")
            + "\n\nEvery property is optional, since a field the caller did not select is absent "
            + "from the response, and Swift cannot compute a result type from a selection.",
          members: members,
          style: .json
        )
      }
    }
    for input in data.inputs {
      let members = try input.fields.map { field throws(PrinterError) in
        try member(
          field,
          presence: field.required ? .required : .optional,
          names: declared,
          scalars: sentScalars
        )
      }
      try emit(input.name) { writer throws(PrinterError) in
        try Layout.object(
          &writer,
          name: input.name,
          doc: input.description ?? "The contract's `\(input.name)`.",
          members: members,
          style: .json
        )
      }
    }
    for enumeration in data.enums {
      try emit(enumeration.name) { writer throws(PrinterError) in
        try Layout.enumeration(
          &writer,
          name: enumeration.name,
          in: "DataSchema",
          doc: enumeration.description ?? "The contract's `\(enumeration.name)`.",
          valueType: "string",
          members: try enumeration.members.map { member throws(PrinterError) in
            Layout.EnumValue(
              source: member.name,
              name: try MemberWords.data(member.name, of: enumeration.name, in: "DataSchema"),
              literal: SwiftText.literal(member.name),
              doc: member.description ?? "`\(member.name)`, as the wire spells it.",
              deprecation: member.deprecated ? Layout.deprecation(member.description) : nil
            )
          }
        )
      }
    }
  }

  /// Kind is what a Data API name declares.
  enum Kind {
    case object
    case input
    case enumeration
  }

  /// names maps every printed Data API type to its kind, refusing a name twice or a name the
  /// printed code uses.
  func names() throws(PrinterError) -> [String: Kind] {
    let data = printer.model.data
    var names: [String: Kind] = [:]
    let declared =
      data.objects.map { ($0.name, Kind.object) } + data.inputs.map { ($0.name, Kind.input) }
      + data.enums.map { ($0.name, Kind.enumeration) }
    for (name, kind) in declared {
      guard names[name] == nil else {
        throw PrinterError("DataSchema: two types named `\(name)`")
      }
      guard !Printer.reservedNames.contains(name) else {
        throw PrinterError("DataSchema.\(name): a type named like a type the printed code uses")
      }
      names[name] = kind
    }
    return names
  }

  /// shape maps a Data API type reference to its Swift shape.
  func shape(_ type: DataType, names: [String: Kind], scalars: [String: Shape])
    throws(PrinterError) -> Shape
  {
    switch type.kind {
    case .named(let name):
      if let scalar = scalars[name] {
        return scalar
      }
      switch names[name] {
      case .enumeration:
        return .direct("DataSchema.\(name)") { "\($0).rawValue" }
      case .object, .input:
        return .direct("DataSchema.\(name)")
      case nil:
        throw PrinterError("DataSchema: `\(name)` names no type")
      }
    case .list(let items):
      let element = try shape(items, names: names, scalars: scalars)
      return Shape(
        swift: "[\(items.nullable ? optionalType(element.swift) : element.swift)]",
        wired: element.wired,
        text: items.nullable || element.isList ? nil : element.text,
        isList: true
      )
    }
  }

  private func member(
    _ field: DataField,
    presence: Presence,
    names: [String: Kind],
    scalars: [String: Shape]
  ) throws(PrinterError) -> Member {
    Member(
      name: field.name,
      shape: try shape(field.type, names: names, scalars: scalars),
      presence: presence,
      constant: nil,
      doc: field.description ?? "The contract's `\(field.name)`.",
      deprecation: field.deprecated ? Layout.deprecation(field.description) : nil
    )
  }

  private func emit(_ name: String, body: (inout SourceWriter) throws(PrinterError) -> Void)
    throws(PrinterError)
  {
    try printer.emit("DataSchema/DataSchema.\(name).swift", unit: .core) {
      writer throws(PrinterError) in
      try writer.block("extension DataSchema {") { writer throws(PrinterError) in
        try body(&writer)
      }
    }
  }
}
