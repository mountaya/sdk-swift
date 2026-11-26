import GateSupport

/// WebhookPrinter prints the webhook event each public type of the REST surface's `webhooks` is
/// delivered as: one case of `WebhookEvent` to a type, carrying the envelope's members, the object
/// the type carries at `data.object` and, at `data.previous_attributes`, the former value of each
/// field its change moved, and `unknown` for a type a build does not know.
///
/// Every fact is checked against the model before a line is printed, and an entry this printer
/// cannot print as stated is refused by name: an envelope other than `WebhookEvent`, an envelope
/// whose `type` or `data` is not the shape every entry narrows, an object that names no object
/// component, a previous attribute that is no field of its object, a type listed twice or folded
/// to a name another type takes, and a set of types that differs from the members of the enum the
/// envelope's `type` names.
struct WebhookPrinter {
  let printer: Printer
  let space: Namespace

  /// envelopeName is the one component a webhook event is delivered in, whose name the printed
  /// enum takes at the module's scope.
  static let envelopeName = "WebhookEvent"

  /// The names the printed enum's own nested types take, which no type's previous attributes may.
  static let nestedNames: Set<String> = ["Payload", "PayloadData"]

  /// Entry is one webhook entry, checked and named.
  private struct Entry {
    let webhook: Webhook
    /// caseName is the enum case the type is read as: its dots and underscores folded to
    /// lowerCamelCase.
    let caseName: String
    /// previous is the type its previous attributes are printed as, or nil where it names none.
    let previous: String?
    /// fields is each named field of its object, in the entry's order.
    let fields: [Property]
  }

  func printAll(_ webhooks: [Webhook]) throws(PrinterError) {
    guard !webhooks.isEmpty else { return }
    let envelope = try envelopeProperties()
    let type = try typeProperty(of: envelope)
    let data = try dataComponent(of: envelope)
    let entries = try checked(webhooks, type: type)
    let typeShape = try printer.shape(type.type, in: space, usage: ["response"])
    guard typeShape.swift == "String" || Self.isStringEnum(type.type, in: space) else {
      throw PrinterError(
        "\(space.name).\(Self.envelopeName).type: neither a string nor an enum of strings, which "
          + "a type a build does not know is held as")
    }
    let types = TypePrinter(printer: printer, space: space)
    var members: [Member] = []
    for property in envelope where property.name != "type" && property.name != "data" {
      members.append(try types.member(property, usage: ["response"], threeStates: false))
    }
    let taken = Set(entries.map(\.caseName)).union(Self.enumNames)
    for member in members where taken.contains(member.name) {
      throw PrinterError(
        "\(space.name).\(Self.envelopeName).\(member.name): read as a case or a member the event "
          + "holds of its own")
    }

    try printEnum(
      entries, typeShape: typeShape, members: members, envelope: envelope, data: data)
    try printEnvelope(members)
    try printPayload(envelope)
    try printPayloadData((data.object, data.previous))
    for entry in entries {
      try printPreviousAttributes(entry)
    }
  }

  /// The names the printed enum declares of its own, which no envelope member may take.
  static let enumNames: Set<String> = [
    "type", "envelope", "untyped", "unknown", "init", "encode", "Envelope",
  ]

  /// DataComponent is the component the envelope's `data` names, and its two members.
  private struct DataComponent {
    let name: String
    let object: Property
    let previous: Property
    /// objectIsUnion is true where `object` is a union, which holds an object of a kind it cannot
    /// read as its `unknown`, and false where it is any value, which holds one as it is.
    let objectIsUnion: Bool
  }

  /// isStringEnum is true for a type that names an enum component whose values are strings, which
  /// a value this build has never seen is made from with `init(rawValue:)`.
  private static func isStringEnum(_ node: TypeNode, in space: Namespace) -> Bool {
    guard case .ref(let name) = node.kind, let schema = space.schemas[name],
      case .enumeration("string", _) = schema.kind
    else { return false }
    return true
  }

  // MARK: - Checks

  /// envelopeProperties returns the envelope component's properties, refusing an envelope that is
  /// no object component.
  private func envelopeProperties() throws(PrinterError) -> [Property] {
    guard let schema = space.schemas[Self.envelopeName],
      case .object(let properties, _, _, _) = schema.kind
    else {
      throw PrinterError(
        "\(space.name).\(Self.envelopeName): the webhook envelope names no object component")
    }
    return properties
  }

  /// typeProperty returns the envelope's `type`, which must always be present: the case an event
  /// is read as is the one it names.
  private func typeProperty(of envelope: [Property]) throws(PrinterError) -> Property {
    guard let type = envelope.first(where: { $0.name == "type" }), type.required,
      !type.type.nullable
    else {
      throw PrinterError(
        "\(space.name).\(Self.envelopeName): an envelope with no required `type`, which names "
          + "the case an event is read as"
      )
    }
    return type
  }

  /// dataComponent returns the component the envelope's required `data` names, with its `object`
  /// and `previous_attributes`, refusing a `data` of any other shape, since every entry narrows
  /// those two members and nothing else, and refusing an `object` that is neither a union nor any
  /// value, or a `previous_attributes` that is no map of any value, since an event this build
  /// cannot type holds each as it arrived.
  private func dataComponent(of envelope: [Property]) throws(PrinterError) -> DataComponent {
    let site = "\(space.name).\(Self.envelopeName).data"
    guard let data = envelope.first(where: { $0.name == "data" }), data.required,
      !data.type.nullable, case .ref(let name) = data.type.kind,
      let schema = space.schemas[name], case .object(let properties, _, _, _) = schema.kind
    else {
      throw PrinterError("\(site): an envelope whose required `data` names no object component")
    }
    guard properties.count == 2,
      let object = properties.first(where: { $0.name == "object" }), object.required,
      let previous = properties.first(where: { $0.name == "previous_attributes" }),
      !previous.required
    else {
      throw PrinterError(
        "\(site): `\(name)` is not a required `object` and an optional `previous_attributes`, "
          + "which are what an entry narrows"
      )
    }
    var objectIsUnion = false
    if case .ref(let union) = object.type.kind, let schema = space.schemas[union],
      case .union = schema.kind
    {
      objectIsUnion = true
    } else if case .any = object.type.kind {
      objectIsUnion = false
    } else {
      throw PrinterError(
        "\(site).object: neither a union nor any value, so an object of a kind this build "
          + "does not read cannot be held as it arrived")
    }
    guard case .map(let values, nil) = previous.type.kind, case .any = values.kind else {
      throw PrinterError(
        "\(site).previous_attributes: no map of any value, so the attributes of an event this "
          + "build cannot type cannot be held as they arrived")
    }
    return DataComponent(
      name: name, object: object, previous: previous, objectIsUnion: objectIsUnion)
  }

  /// checked checks every entry against the model and names it.
  private func checked(_ webhooks: [Webhook], type: Property) throws(PrinterError) -> [Entry] {
    var entries: [Entry] = []
    var types: Set<String> = []
    var names: [String: String] = [:]
    for webhook in webhooks {
      let site = "rest.webhooks.\(webhook.type)"
      guard webhook.envelope == Self.envelopeName else {
        throw PrinterError(
          "\(site): delivered in `\(webhook.envelope)`, and this printer prints the "
            + "`\(Self.envelopeName)` envelope alone"
        )
      }
      guard let object = space.schemas[webhook.object],
        case .object(let properties, _, _, _) = object.kind
      else {
        throw PrinterError("\(site): `\(webhook.object)` names no object component")
      }
      var fields: [Property] = []
      for field in webhook.previousAttributes {
        guard let property = properties.first(where: { $0.name == field }) else {
          throw PrinterError(
            "\(site): the previous attribute `\(field)` is no field of `\(webhook.object)`")
        }
        fields.append(property)
      }
      guard Set(webhook.previousAttributes).count == fields.count else {
        throw PrinterError("\(site): a previous attribute named twice")
      }
      guard types.insert(webhook.type).inserted else {
        throw PrinterError("\(site): a type listed twice")
      }
      let caseName = Self.caseName(webhook.type)
      if let other = names[caseName] {
        throw PrinterError("\(site): read as `\(caseName)`, the case `\(other)` is read as")
      }
      names[caseName] = webhook.type
      guard caseName != "unknown" else {
        throw PrinterError("\(site): read as `unknown`, the case of a type a build does not know")
      }
      var previous: String?
      if !fields.isEmpty {
        let name = SwiftText.upperFirst(caseName) + "PreviousAttributes"
        guard SwiftText.isPlain(name), !Self.nestedNames.contains(name) else {
          throw PrinterError("\(site): its previous attributes cannot be named `\(name)`")
        }
        previous = name
      }
      entries.append(
        Entry(webhook: webhook, caseName: caseName, previous: previous, fields: fields))
    }
    try checkTypes(types, against: type)
    return entries
  }

  /// checkTypes refuses a set of types that differs from the members of the enum the envelope's
  /// `type` names, so a type with no entry is never read past, and an entry no type names is never
  /// printed.
  private func checkTypes(_ types: Set<String>, against type: Property) throws(PrinterError) {
    guard case .ref(let name) = type.type.kind, let schema = space.schemas[name],
      case .enumeration(_, let members) = schema.kind
    else { return }
    let declared = Set(members.compactMap(\.value.stringValue))
    let unlisted = declared.subtracting(types).sorted()
    let undeclared = types.subtracting(declared).sorted()
    guard unlisted.isEmpty, undeclared.isEmpty else {
      throw PrinterError(
        "rest.webhooks and `\(space.name).\(name)` disagree: "
          + (unlisted.isEmpty ? "" : "no webhook for \(unlisted.joined(separator: ", ")); ")
          + (undeclared.isEmpty ? "" : "no member for \(undeclared.joined(separator: ", ")); ")
          + "each type is one webhook and one member"
      )
    }
  }

  /// caseName folds a type's dots and underscores to lowerCamelCase:
  /// `organization.ai_provider_config.updated` is `organizationAiProviderConfigUpdated`.
  static func caseName(_ type: String) -> String {
    let words = type.split(whereSeparator: { $0 == "." || $0 == "_" }).map(String.init)
    guard let first = words.first else { return type }
    return first + words.dropFirst().map(SwiftText.upperFirst).joined()
  }

  // MARK: - The enum

  private func printEnum(
    _ entries: [Entry],
    typeShape: Shape,
    members: [Member],
    envelope: [Property],
    data: DataComponent
  ) throws(PrinterError) {
    let qualified = try space.qualified(Self.envelopeName)
    var objects: [String: String] = [:]
    for entry in entries {
      objects[entry.webhook.object] = try space.qualified(entry.webhook.object)
    }
    try printer.emit("\(Self.envelopeName).swift", unit: space.unit) {
      writer throws(PrinterError) in
      writer.doc(
        "\(Self.envelopeName) is a webhook event as Mountaya delivers it to an endpoint, typed by "
          + "its `type`: one case to each public type the contract's `webhooks` lists, carrying "
          + "every member of the envelope, the object the type carries at `data.object` and, at "
          + "`data.previous_attributes`, the former value of each field its change moved."
          + "\n\nAn event this build cannot type is `unknown`, holding the contract's envelope, "
          + "`\(qualified)`: one of a type it does not know, which a later contract adds, or one "
          + "whose payload its types do not read. It is delivered rather than refused, so a "
          + "receiver still acknowledges it and deduplicates it by its `id`, and every member of "
          + "the envelope is read off every case alike. "
          + Layout.nonexhaustiveNote(
            "A type the contract adds is a case of the build made after it")
      )
      Layout.nonexhaustive(&writer)
      try writer.block("public enum \(Self.envelopeName): Sendable, Hashable, Codable {") {
        writer throws(PrinterError) in
        for entry in entries {
          let summary = entry.webhook.summary.map { ": " + SwiftText.oneLine($0) } ?? "."
          writer.doc("`\(entry.webhook.type)`\(summary)")
          Self.payloadCase(
            &writer,
            name: SwiftText.identifier(entry.caseName),
            object: objects[entry.webhook.object] ?? entry.webhook.object,
            previous: entry.previous ?? "Never"
          )
        }
        writer.doc(
          "unknown is an event this build cannot type: a type it does not know, or a payload its "
            + "types do not read, as the envelope holds it.")
        writer.line("case unknown(\(qualified))")
        writer.line()

        writer.doc("type is the event's type, as the wire spells it.")
        try writer.block("public var type: \(typeShape.swift) {") { writer throws(PrinterError) in
          writer.line("switch self {")
          for entry in entries {
            let head = "case .\(SwiftText.identifier(entry.caseName)):"
            let value = SwiftText.literal(entry.webhook.type)
            if writer.fits("\(head) \(value)") {
              writer.line("\(head) \(value)")
            } else {
              writer.line(head)
              writer.line("  " + value)
            }
          }
          writer.line("case .unknown(let event): event.type")
          writer.line("}")
        }
        for member in members {
          writer.line()
          writer.doc(member.doc)
          Layout.available(&writer, deprecated: member.deprecation)
          try writer.block("public var \(member.identifier): \(member.declared) {") {
            writer throws(PrinterError) in
            writer.line("envelope.\(member.storage)")
          }
        }
        writer.line()

        writer.doc(
          "envelope is the members every case carries beside its `type` and its `data`, which "
            + "the accessors read.")
        try writer.block("private var envelope: any Envelope {") { writer throws(PrinterError) in
          writer.line("switch self {")
          for entry in entries {
            writer.line("case .\(SwiftText.identifier(entry.caseName))(let event): event")
          }
          writer.line("case .unknown(let event): event")
          writer.line("}")
        }
        writer.line()

        writer.doc(
          "Reads the case its `type` names, or `unknown` for a type this build does not know and "
            + "for a payload the case's types do not read.")
        try writer.block("public init(from decoder: any Decoder) throws {") {
          writer throws(PrinterError) in
          writer.line("let container = try decoder.container(keyedBy: WireKey.self)")
          writer.line("let type = try container.decode(String.self, forKey: \"type\")")
          writer.line("let typed: Self?")
          writer.line("switch type {")
          for entry in entries {
            let head = "case \(SwiftText.literal(entry.webhook.type)):"
            let read =
              "typed = try? Self.\(SwiftText.identifier(entry.caseName))(Payload(from: decoder))"
            if writer.fits("\(head) \(read)") {
              writer.line("\(head) \(read)")
            } else {
              writer.line(head)
              writer.line("  " + read)
            }
          }
          writer.line("default: typed = nil")
          writer.line("}")
          writer.line("self = try typed ?? .unknown(Self.untyped(decoder, type: type))")
        }
        writer.line()

        try printUntyped(&writer, envelope: envelope, data: data, typeShape: typeShape)
        writer.line()

        writer.doc(
          "Writes the event as the envelope it was delivered in, its `type` the one its case names."
        )
        try writer.block("public func encode(to encoder: any Encoder) throws {") {
          writer throws(PrinterError) in
          writer.line("switch self {")
          for entry in entries {
            writer.line("case .\(SwiftText.identifier(entry.caseName))(let event):")
            writer.line("  try event.encode(to: encoder)")
          }
          writer.line("case .unknown(let event):")
          writer.line("  try event.encode(to: encoder)")
          writer.line("  return")
          writer.line("}")
          writer.line("var container = encoder.container(keyedBy: WireKey.self)")
          writer.line("try container.encode(type, forKey: \"type\")")
        }
      }
    }
  }

  /// printUntyped writes the reading of an event this build cannot type: the envelope as its own
  /// types read it, or, where they do not read its object either, the envelope's members as a
  /// payload reads them, its object and its previous attributes held as they arrived.
  private func printUntyped(
    _ writer: inout SourceWriter,
    envelope: [Property],
    data: DataComponent,
    typeShape: Shape
  ) throws(PrinterError) {
    let types = TypePrinter(printer: printer, space: space)
    let qualified = try space.qualified(Self.envelopeName)
    let dataType = try space.qualified(data.name)
    let object = try types.member(data.object, usage: ["response"], threeStates: false)
    let previous = try types.member(data.previous, usage: ["response"], threeStates: false)
    var arguments: [String] = []
    var assignments: [String] = []
    for property in envelope {
      let member = try types.member(property, usage: ["response"], threeStates: false)
      guard let presence = member.presence else { continue }
      let value: String
      switch property.name {
      case "type":
        value = typeShape.swift == "String" ? "type" : "\(typeShape.swift)(rawValue: type)"
      case "data": value = "data"
      default: value = "payload.\(member.storage)"
      }
      if presence.isInitializerArgument {
        arguments.append("\(member.identifier): \(value)")
      } else {
        assignments.append("event.\(member.storage) = \(value)")
      }
    }
    writer.doc(
      "untyped reads an event this build cannot type as the envelope: as the envelope's own types "
        + "read it, or, where they do not read its object either, with its object and its previous "
        + "attributes as they arrived. It throws where the body holds no envelope at all.")
    // The formatter breaks a signature too long for its line before its result, the brace alone.
    let head = "private static func untyped(_ decoder: any Decoder, type: String) throws"
    if writer.fits("\(head) -> \(qualified) {") {
      writer.line("\(head) -> \(qualified) {")
    } else {
      writer.line(head)
      writer.line("  -> \(qualified)")
      writer.line("{")
    }
    try writer.nested { writer throws(PrinterError) in
      writer.line("if let event = try? \(qualified)(from: decoder) {")
      writer.line("  return event")
      writer.line("}")
      writer.line("let payload = try Payload<JSONValue, [String: JSONValue]>(from: decoder)")
      writer.call(
        prefix: "var data = ", callee: dataType,
        arguments: [
          "\(object.identifier): "
            + (data.objectIsUnion ? ".unknown(payload.data.object)" : "payload.data.object")
        ])
      writer.line("data.\(previous.storage) = payload.data.previous_attributes")
      if assignments.isEmpty {
        writer.call(prefix: "return ", callee: qualified, arguments: arguments)
      } else {
        writer.call(prefix: "var event = ", callee: qualified, arguments: arguments)
        for assignment in assignments {
          writer.line(assignment)
        }
        writer.line("return event")
      }
    }
    writer.line("}")
  }

  /// printEnvelope writes the protocol every case's value conforms to, a typed payload and the
  /// contract's envelope alike, whose members the event's accessors read: each member of the
  /// envelope but its `type` and its `data`, under the name its value is stored at, so a
  /// deprecated member is read with no warning. The two conformances follow it in its file.
  private func printEnvelope(_ members: [Member]) throws(PrinterError) {
    let type = Self.envelopeName
    let envelope = try space.qualified(type)
    try printer.emit("\(type)/\(type).Envelope.swift", unit: space.unit) {
      writer throws(PrinterError) in
      try writer.block("extension \(type) {") { writer throws(PrinterError) in
        writer.doc(
          "Envelope is what every event carries beside its `type` and its `data`, whichever case "
            + "holds it, which a typed payload and the contract's envelope each hold.")
        try writer.block("protocol Envelope {") { writer throws(PrinterError) in
          for member in members {
            writer.line("var \(member.storage): \(member.declared) { get }")
          }
        }
      }
      writer.line()
      writer.line("extension \(type).Payload: \(type).Envelope {}")
      writer.line()
      writer.line("extension \(envelope): \(type).Envelope {}")
    }
  }

  /// payloadCase writes `case name(Payload<Object, Previous>)` as the formatter lays it out: on
  /// one line where it fits; otherwise broken after the parenthesis, with the payload's type on
  /// the next line where it fits there, broken inside its angle brackets where it does not, and
  /// its two arguments on a line each where they do not fit on one.
  private static func payloadCase(
    _ writer: inout SourceWriter,
    name: String,
    object: String,
    previous: String
  ) {
    let arguments = "\(object), \(previous)"
    let whole = "case \(name)(Payload<\(arguments)>)"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    writer.line("case \(name)(")
    if writer.fits("Payload<\(arguments)>)", extra: 2) {
      writer.line("  Payload<\(arguments)>)")
      return
    }
    writer.line("  Payload<")
    if writer.fits(arguments, extra: 4) {
      writer.line("    " + arguments)
    } else {
      writer.line("    \(object),")
      writer.line("    " + previous)
    }
    writer.line("  >)")
  }

  // MARK: - The payload

  /// genericClause is the two parameters the payload and its data are generic over.
  private static let genericClause =
    "Object: Codable & Hashable & Sendable, PreviousAttributes: Codable & Hashable & Sendable"

  private func printPayload(_ envelope: [Property]) throws(PrinterError) {
    let types = TypePrinter(printer: printer, space: space)
    var members: [Member] = []
    for property in envelope where property.name != "type" {
      guard property.name == "data" else {
        members.append(try types.member(property, usage: ["response"], threeStates: false))
        continue
      }
      members.append(
        Member(
          name: property.name,
          shape: .direct("PayloadData<Object, PreviousAttributes>"),
          presence: .required,
          constant: nil,
          doc: property.description ?? "The contract's `data`.",
          deprecation: nil
        )
      )
    }
    let envelope = try space.qualified(Self.envelopeName)
    try emitNested("Payload") { writer throws(PrinterError) in
      try Layout.object(
        &writer,
        name: "Payload",
        doc: "Payload is an event of a type this build knows: every member of the contract's "
          + "envelope, `\(envelope)`, but its `type`, which the event's "
          + "case names, with the `data` that type carries.\n\n`Object` is the object the type "
          + "carries at `data.object`, and `PreviousAttributes` the former value of each field its "
          + "change moved, `Never` for a type whose change moves none.",
        members: members,
        style: .json,
        generics: Self.genericClause
      )
    }
  }

  private func printPayloadData(_ data: (object: Property, previous: Property)) throws(PrinterError)
  {
    let object = data.object.description ?? "The contract's `object`."
    let previous =
      (data.previous.description ?? "The contract's `previous_attributes`.")
      + "\n\nIt is always nil where `PreviousAttributes` is `Never`, a type whose change moves no "
      + "field: a `previous_attributes` such an event carries is not read, as a key this build does "
      + "not know is not."
    try emitNested("PayloadData") { writer throws(PrinterError) in
      writer.doc(
        "PayloadData is what an event of a type this build knows says about its object: the object "
          + "as the type carries it, and the former value of each field its change moved."
      )
      Layout.declaration(
        &writer,
        head: "public struct PayloadData",
        conformances: ["Sendable", "Hashable", "Codable"],
        generics: Self.genericClause
      )
      writer.nestedLines { writer in
        writer.doc(object)
        writer.line("public var object: Object")
        writer.doc(previous)
        writer.line("public var previous_attributes: PreviousAttributes?")
        writer.line()
        writer.doc(
          "Creates a `PayloadData` from the properties the contract requires, the optional ones "
            + "being set in `configure`."
        )
        writer.line("public init(")
        writer.line("  object: Object,")
        writer.line("  configure: (inout Self) -> Void = { _ in }")
        writer.line(") {")
        writer.line("  self.object = object")
        writer.line("  self.previous_attributes = nil")
        writer.line("  configure(&self)")
        writer.line("}")
        writer.line()
        writer.doc(
          "Reads a `PayloadData` from the JSON object the contract describes, its "
            + "`previous_attributes` left unread where `PreviousAttributes` is `Never`."
        )
        writer.line("public init(from decoder: any Decoder) throws {")
        writer.line("  let container = try decoder.container(keyedBy: WireKey.self)")
        writer.line("  self.object = try container.decode(Object.self, forKey: \"object\")")
        writer.line("  if PreviousAttributes.self == Never.self {")
        writer.line("    self.previous_attributes = nil")
        writer.line("  } else {")
        writer.line("    self.previous_attributes = try container.decodeIfPresent(")
        writer.line("      PreviousAttributes.self, forKey: \"previous_attributes\")")
        writer.line("  }")
        writer.line("}")
        writer.line()
        writer.doc("Writes a `PayloadData` as the JSON object the contract describes.")
        writer.line("public func encode(to encoder: any Encoder) throws {")
        writer.line("  var container = encoder.container(keyedBy: WireKey.self)")
        writer.line("  try container.encode(self.object, forKey: \"object\")")
        writer.line(
          "  try container.encodeIfPresent(self.previous_attributes, forKey: \"previous_attributes\")"
        )
        writer.line("}")
      }
      writer.line("}")
    }
  }

  // MARK: - Previous attributes

  private func printPreviousAttributes(_ entry: Entry) throws(PrinterError) {
    guard let name = entry.previous else { return }
    var members: [Member] = []
    for field in entry.fields {
      let shape = try printer.shape(field.type, in: space, usage: ["response"])
      let nullable = field.type.nullable
      members.append(
        Member(
          name: field.name,
          shape: shape,
          presence: nullable ? .merge : .optional,
          constant: nil,
          doc: (field.description ?? "The contract's `\(field.name)`.")
            + (nullable
              ? "\n\nThe value it held before the change, `.some(nil)` where it held null, and "
                + "nil where the change did not move it."
              : "\n\nThe value it held before the change, and nil where the change did not move "
                + "it."),
          deprecation: field.deprecated ? Layout.deprecation(field.description) : nil,
          secret: field.secret
        )
      )
    }
    let object = try space.qualified(entry.webhook.object)
    try emitNested(name) { writer throws(PrinterError) in
      try Layout.object(
        &writer,
        name: name,
        doc: "\(name) is the former value of each field a `\(entry.webhook.type)` event's change "
          + "moved, as its `data.previous_attributes` carries them, each typed as "
          + "`\(object)` types it: a field the change did not move is "
          + "nil.",
        members: members,
        style: .json
      )
    }
  }

  /// emitNested prints one type nested in the enum, in a file of its own.
  private func emitNested(
    _ name: String,
    body: (inout SourceWriter) throws(PrinterError) -> Void
  ) throws(PrinterError) {
    let type = Self.envelopeName
    try printer.emit("\(type)/\(type).\(name).swift", unit: space.unit) {
      writer throws(PrinterError) in
      try writer.block("extension \(type) {") { writer throws(PrinterError) in
        try body(&writer)
      }
    }
  }
}
