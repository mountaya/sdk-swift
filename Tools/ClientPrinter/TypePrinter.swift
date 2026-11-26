import GateSupport

/// Member is one property of a printed struct.
struct Member {
  /// name is the property's name as the wire spells it.
  let name: String
  let shape: Shape
  /// presence is how the property is present, or nil for one whose value is fixed.
  let presence: Presence?
  /// constant is the fixed value's Swift literal, for a `const` or a union member's
  /// discriminator.
  let constant: String?
  let doc: String
  /// deprecation is the message a deprecated property carries, or nil.
  let deprecation: String?
  /// secret is true where the value is a secret the model marks, which the struct never prints.
  var secret = false

  var identifier: String {
    SwiftText.identifier(name)
  }

  /// storage is the stored property holding the value: the property itself, or for a
  /// deprecated one an internal `_name` beneath it, so the type's own initializer and coding
  /// use no deprecated declaration and only a consumer's use of it warns.
  var storage: String {
    deprecation == nil || constant != nil ? identifier : SwiftText.identifier("_" + name)
  }

  var declared: String {
    presence?.declared(shape) ?? shape.swift
  }
}

/// ObjectStyle is what a printed struct is besides its properties.
enum ObjectStyle {
  /// json is a value read and written as a JSON object.
  case json
  /// form is a `multipart/form-data` body, which writes its parts and is never JSON, each file's
  /// part carrying the media type `encoding` names for its property, by its wire name.
  case form(encoding: [String: String])
  /// query is an operation's query parameters, which write their items and are never JSON.
  case query
}

/// TypePrinter prints one namespace's components and inline types, one file each.
struct TypePrinter {
  let printer: Printer
  let space: Namespace

  func print(_ schema: Schema) throws(PrinterError) {
    let doc = schema.description ?? "The contract's `\(schema.name)`."
    try emit(schema.name) { writer throws(PrinterError) in
      switch schema.kind {
      case .object(let properties, _, _, _):
        let members = try properties.map { property throws(PrinterError) in
          try member(property, usage: schema.usage, threeStates: schema.usage.contains("request"))
        }
        try Layout.object(&writer, name: schema.name, doc: doc, members: members, style: .json)
      case .enumeration(let valueType, let members):
        try Layout.enumeration(
          &writer,
          name: schema.name,
          in: space.name,
          doc: doc,
          valueType: valueType,
          members: try members.map { member throws(PrinterError) in
            try enumMember(member, valueType: valueType, in: schema.name)
          }
        )
      case .union(let discriminator, let members):
        try union(&writer, schema: schema, doc: doc, discriminator: discriminator, members: members)
      case .alias(let target):
        let shape = try printer.shape(target, in: space, usage: schema.usage)
        writer.doc(doc)
        writer.assignment(
          "public typealias \(schema.name)",
          value: target.nullable ? optionalType(shape.swift) : shape.swift)
      case .geojson(let geometry):
        guard let type = Self.geometries[geometry] else {
          throw PrinterError(
            "\(space.name).\(schema.name): `\(geometry)` is not a GeoJSON geometry")
        }
        writer.doc(doc)
        writer.assignment("public typealias \(schema.name)", value: "MountayaClient.\(type)")
      }
    }
  }

  /// The GeoJSON type the module declares by hand for each geometry RFC 7946 names.
  static let geometries: [String: String] = [
    "Geometry": "GeoJSONGeometry",
    "GeometryCollection": "GeoJSONGeometryCollection",
    "LineString": "GeoJSONLineString",
    "MultiLineString": "GeoJSONMultiLineString",
    "MultiPoint": "GeoJSONMultiPoint",
    "MultiPolygon": "GeoJSONMultiPolygon",
    "Point": "GeoJSONPoint",
    "Polygon": "GeoJSONPolygon",
  ]

  func print(inline type: InlineType, named name: String) throws(PrinterError) {
    try emit(name) { writer throws(PrinterError) in
      switch type {
      case .object(let object, let usage, let form):
        let isForm = form != nil
        let members = try object.properties.map { property throws(PrinterError) in
          try member(property, usage: usage, threeStates: !isForm && usage.contains("request"))
        }
        try Layout.object(
          &writer,
          name: name,
          doc: isForm
            ? "\(name) is the `multipart/form-data` body the contract writes inline, one part to "
              + "a property."
            : "\(name) is an object the contract writes inline.",
          members: members,
          style: form.map { .form(encoding: $0) } ?? .json
        )
      case .enumeration(let enumeration):
        if let names = enumeration.names, names.count != enumeration.values.count {
          throw PrinterError(
            "\(space.name).\(name): \(names.count) `enumNames` for \(enumeration.values.count) values"
          )
        }
        try Layout.enumeration(
          &writer,
          name: name,
          in: space.name,
          doc: "\(name) is a set of values the contract writes inline.",
          valueType: "string",
          members: try enumeration.values.enumerated().map { index, value throws(PrinterError) in
            // A value the model names is printed by its words, as every component's member is
            // (`sdk/SPEC.md` §9); one it names nothing is printed under its wire spelling.
            let source = enumeration.names?[index] ?? value
            return Layout.EnumValue(
              source: source,
              name: enumeration.names == nil
                ? value : try MemberWords.rest(source, of: name, in: space.name),
              literal: SwiftText.literal(value),
              doc: "`\(value)`, as the wire spells it.",
              deprecation: nil
            )
          }
        )
      case .union(_, let members):
        try anyOf(&writer, name: name, members: members)
      }
    }
  }

  private func emit(_ name: String, body: (inout SourceWriter) throws(PrinterError) -> Void)
    throws(PrinterError)
  {
    try printer.emit("\(space.name)/\(space.name).\(name).swift", unit: space.unit) {
      writer throws(PrinterError) in
      try writer.block("extension \(space.name) {") { writer throws(PrinterError) in
        try body(&writer)
      }
    }
  }

  /// member reads one property of a component or an inline object.
  func member(_ property: Property, usage: [String], threeStates: Bool) throws(PrinterError)
    -> Member
  {
    let shape = try printer.shape(property.type, in: space, usage: usage)
    var doc = property.description ?? "The contract's `\(property.name)`."
    var constant: String?
    if let value = property.discriminatorValue {
      constant = SwiftText.literal(value)
      doc += "\n\nIt is always `\(value)`, the discriminator value naming this member of its union."
    } else {
      switch property.type.kind {
      case .string(_, let value?, _):
        constant = SwiftText.literal(value)
      case .integer(_, let value?):
        guard let integer = Int(exactly: value) else {
          throw PrinterError("\(property.name): a `const` integer that is not one")
        }
        constant = String(integer)
      case .boolean(let value?):
        constant = value ? "true" : "false"
      default:
        break
      }
      if let constant {
        doc += "\n\nIt is always \(constant), which this type writes itself."
      }
    }
    switch property.direction {
    case .readOnly:
      doc += "\n\nThe server writes it, and a request never sends it."
    case .writeOnly:
      doc += "\n\nA request sends it, and the server never answers it."
    case nil:
      break
    }
    let presence = constant == nil ? printer.presence(property, sentByRequest: threeStates) : nil
    if presence == .merge {
      doc +=
        "\n\nLeft `nil`, it is not sent, and a value already stored is left as it is. Set to a "
        + "value, it is sent, and set to `.some(nil)`, it is sent as `null`, which clears a "
        + "stored value: assigning `nil` is the absence of an instruction, never a clear."
    }
    if property.secret {
      doc +=
        "\n\nIt is a secret: the type prints it as `<redacted>` wherever it is printed, in a log, "
        + "a debugger's description or a dump, and a caller reads it as it is."
    }
    return Member(
      name: property.name,
      shape: shape,
      presence: presence,
      constant: constant,
      doc: doc,
      deprecation: property.deprecated ? Layout.deprecation(property.description) : nil,
      secret: property.secret
    )
  }

  private func enumMember(_ member: EnumMember, valueType: String, in name: String)
    throws(PrinterError) -> Layout.EnumValue
  {
    let literal: String
    if valueType == "integer" {
      guard let number = member.value.numberValue, let integer = Int(exactly: number) else {
        throw PrinterError("\(space.name).\(name).\(member.name): not an integer value")
      }
      literal = String(integer)
    } else {
      guard let text = member.value.stringValue else {
        throw PrinterError("\(space.name).\(name).\(member.name): not a string value")
      }
      literal = SwiftText.literal(text)
    }
    var doc = member.description ?? "\(literal), as the wire spells it."
    if !member.includes.isEmpty {
      let reach = member.includes.count == 1 ? "that scope reaches" : "those scopes reach"
      doc +=
        "\n\nIt includes \(Self.listed(member.includes)): a key carrying it reaches what \(reach)."
    }
    if !member.needs.isEmpty {
      doc += "\n\nA key carrying it carries \(Self.listed(member.needs)) beside it."
    }
    return Layout.EnumValue(
      source: member.name,
      name: try MemberWords.rest(member.name, of: name, in: space.name),
      literal: literal,
      doc: doc,
      deprecation: member.deprecated ? Layout.deprecation(member.description) : nil
    )
  }

  /// listed writes wire values as prose: `a`, `a` and `b`, or `a`, `b` and `c`.
  static func listed(_ values: [String]) -> String {
    let quoted = values.map { "`\($0)`" }
    guard let last = quoted.last, quoted.count > 1 else { return quoted.joined() }
    return quoted.dropLast().joined(separator: ", ") + " and " + last
  }

  // MARK: - Unions

  private func union(
    _ writer: inout SourceWriter,
    schema: Schema,
    doc: String,
    discriminator: String,
    members: [UnionMember]
  ) throws(PrinterError) {
    var qualified: [String: String] = [:]
    for member in members {
      guard let target = space.schemas[member.type], case .object = target.kind else {
        throw PrinterError(
          "\(space.name).\(schema.name): the member `\(member.type)` is not an object component"
        )
      }
      qualified[member.type] = try space.qualified(member.type)
    }
    writer.doc(
      doc + "\n\nA member this build has never seen decodes as `unknown`, holding what arrived, "
        + "so a member the contract adds decodes in a build made before it. "
        + Layout.nonexhaustiveNote("A build made after it reads that member as a case of its own")
    )
    Layout.nonexhaustive(&writer)
    try writer.block("public enum \(schema.name): Sendable, Hashable, Codable {") {
      writer throws(PrinterError) in
      for member in members {
        writer.doc("`\(member.value)`.")
        writer.call(
          prefix: "case ", callee: SwiftText.identifier(member.type),
          arguments: [qualified[member.type] ?? member.type])
      }
      writer.doc("unknown is a member this build has never seen, holding what arrived.")
      writer.line("case unknown(JSONValue)")
      writer.line()
      writer.doc(
        "Reads the member its `\(discriminator)` names, or `unknown` for one this build has never "
          + "seen."
      )
      try writer.block("public init(from decoder: any Decoder) throws {") {
        writer throws(PrinterError) in
        writer.line("let container = try decoder.container(keyedBy: WireKey.self)")
        writer.line(
          "switch try? container.decode(String.self, forKey: \(SwiftText.literal(discriminator))) {"
        )
        for member in members {
          writer.line("case \(SwiftText.literal(member.value)):")
          try writer.nested { writer throws(PrinterError) in
            writer.call(
              prefix: "self = .", callee: SwiftText.identifier(member.type),
              arguments: ["try \(qualified[member.type] ?? member.type)(from: decoder)"])
          }
        }
        writer.line("default:")
        writer.line("  self = .unknown(try JSONValue(from: decoder))")
        writer.line("}")
      }
      writer.line()
      writer.doc("Writes the member it holds.")
      try writer.block("public func encode(to encoder: any Encoder) throws {") {
        writer throws(PrinterError) in
        writer.line("switch self {")
        for member in members {
          writer.line("case .\(SwiftText.identifier(member.type))(let member):")
          writer.line("  try member.encode(to: encoder)")
        }
        writer.line("case .unknown(let value):")
        writer.line("  try value.encode(to: encoder)")
        writer.line("}")
      }
    }
  }

  /// anyOf prints a union the contract writes inline with no discriminator, read by trying
  /// each member in the contract's order.
  private func anyOf(_ writer: inout SourceWriter, name: String, members: [TypeNode])
    throws(PrinterError)
  {
    var cases: [(name: String, shape: Shape)] = []
    for node in members {
      let shape = try printer.shape(node, in: space, usage: ["response"])
      let label: String
      switch node.kind {
      case .string: label = "string"
      case .integer: label = "integer"
      case .number: label = "number"
      case .boolean: label = "boolean"
      case .array: label = "array"
      case .map: label = "map"
      case .any: label = "value"
      case .null: label = "null"
      case .ref(let target): label = target
      case .object(let object): label = object.name
      case .union(let union, _): label = union
      }
      guard !cases.contains(where: { $0.name == label }) else {
        throw PrinterError("\(space.name).\(name): two members read as `\(label)`")
      }
      cases.append((label, node.nullable ? Shape.direct(optionalType(shape.swift)) : shape))
    }
    writer.doc(
      "\(name) is a value the contract writes inline as one of several types, with nothing "
        + "naming which.\n\nIt is read by trying each member in the contract's order, the first "
        + "that reads winning, and a value none reads decodes as `unknown`, holding what arrived. "
        + Layout.nonexhaustiveNote(
          "A member the contract adds is a case of the build made after it")
    )
    Layout.nonexhaustive(&writer)
    try writer.block("public enum \(name): Sendable, Hashable, Codable {") {
      writer throws(PrinterError) in
      for member in cases {
        writer.doc("The value, read as a `\(member.shape.swift)`.")
        writer.call(
          prefix: "case ", callee: SwiftText.identifier(member.name),
          arguments: [member.shape.swift])
      }
      writer.doc("unknown is a value none of the members reads, holding what arrived.")
      writer.line("case unknown(JSONValue)")
      writer.line()
      writer.doc("Reads the first member the value is.")
      try writer.block("public init(from decoder: any Decoder) throws {") {
        writer throws(PrinterError) in
        writer.line("let container = try decoder.singleValueContainer()")
        for (position, member) in cases.enumerated() {
          let keyword = position == 0 ? "if" : "} else if"
          let read =
            member.shape.wired
            ? "try? container.decode(\(member.shape.swift).Wire.self)"
            : "try? container.decode(\(member.shape.swift).self)"
          writer.line("\(keyword) let value = \(read) {")
          let value = member.shape.wired ? "\(member.shape.swift)(wire: value)" : "value"
          writer.line("  self = .\(SwiftText.identifier(member.name))(\(value))")
        }
        writer.line("} else {")
        writer.line("  self = .unknown(try container.decode(JSONValue.self))")
        writer.line("}")
      }
      writer.line()
      writer.doc("Writes the member it holds.")
      try writer.block("public func encode(to encoder: any Encoder) throws {") {
        writer throws(PrinterError) in
        writer.line("var container = encoder.singleValueContainer()")
        writer.line("switch self {")
        for member in cases {
          writer.line("case .\(SwiftText.identifier(member.name))(let value):")
          writer.line("  try container.encode(value\(member.shape.wired ? ".wire" : ""))")
        }
        writer.line("case .unknown(let value):")
        writer.line("  try container.encode(value)")
        writer.line("}")
      }
    }
  }
}
