/// Layout prints the shapes every surface shares: a struct of properties and an open enum.
enum Layout {
  /// EnumValue is one value of an open enum.
  struct EnumValue {
    /// source is the member's name as the model gives it, which a refusal names: its
    /// `x-enum-varnames` name, its Data API name, or its wire value for a set written inline.
    let source: String
    /// name is the static member's name: the source's words in lowerCamelCase (`MemberWords`),
    /// or the wire value for a set written inline, whose members carry no names.
    let name: String
    /// literal is the value's Swift literal, a string or an integer.
    let literal: String
    let doc: String
    let deprecation: String?
  }

  /// The names an open enum holds of its own, which no member may take: the ones it declares,
  /// the ones its conformances give it, the ones Swift reads after a dot as something other than
  /// a member, and `allCases`, which `CaseIterable` gives a type, as a consumer may conform a set.
  static let ownMembers: Set<String> = [
    "ExtendedGraphemeClusterLiteralType", "IntegerLiteralType", "Protocol", "RawValue",
    "StringLiteralType", "Type", "UnicodeScalarLiteralType", "allCases", "codingKey", "encode",
    "hash", "hashValue", "init", "rawValue", "self",
  ]

  /// deprecation is the message a deprecated declaration carries: its description's own first
  /// sentence.
  static func deprecation(_ description: String?) -> String {
    description.map(SwiftText.firstSentence) ?? "The contract marks this deprecated."
  }

  /// available writes the deprecation attribute.
  static func available(_ writer: inout SourceWriter, deprecated message: String?) {
    guard let message else { return }
    writer.call(
      prefix: "@available", callee: "",
      arguments: ["*", "deprecated", "message: \(SwiftText.literal(message))"])
  }

  /// nonexhaustive writes the attribute of an enum a later contract gives another case, which
  /// the error ladder carries too, so a `switch` over it outside the module ends in
  /// `@unknown default` (SPEC.md section 3).
  static func nonexhaustive(_ writer: inout SourceWriter) {
    writer.line("@nonexhaustive")
  }

  /// nonexhaustiveNote is the sentence the doc of such an enum ends on, which says what grows it.
  static func nonexhaustiveNote(_ growth: String) -> String {
    "\(growth), so a `switch` over it outside this module ends in `@unknown default`."
  }

  /// declaration writes a type's opening line, wrapping its conformances the way the
  /// formatter does: as many to a line as fit, the brace alone on the last line.
  ///
  /// A generic type's parameters follow its name in angle brackets, which the formatter breaks
  /// around where the line does not fit, the parameters on a line of their own and the
  /// conformances after the closing bracket.
  static func declaration(
    _ writer: inout SourceWriter,
    head: String,
    conformances: [String],
    generics: String? = nil
  ) {
    if let generics {
      let whole = "\(head)<\(generics)>: \(conformances.joined(separator: ", ")) {"
      if writer.fits(whole) {
        writer.line(whole)
      } else {
        writer.line("\(head)<")
        writer.line("  " + generics)
        writer.line(">: \(conformances.joined(separator: ", ")) {")
      }
      return
    }
    let whole = "\(head): \(conformances.joined(separator: ", ")) {"
    if writer.fits(whole) {
      writer.line(whole)
      return
    }
    var lines: [String] = []
    var current = "\(head):"
    var extra = 0
    for (position, conformance) in conformances.enumerated() {
      let piece = conformance + (position == conformances.count - 1 ? "" : ",")
      let candidate = current.isEmpty ? piece : current + " " + piece
      if current.isEmpty || current.hasSuffix(":") || writer.fits(candidate, extra: extra) {
        current = candidate
      } else {
        lines.append(current)
        current = piece
        extra = 2
      }
    }
    lines.append(current)
    for (position, line) in lines.enumerated() {
      writer.line(position == 0 ? line : "  " + line)
    }
    writer.line("{")
  }

  // MARK: - Structs

  /// object writes a struct of properties, its initializer, and its coding, generic over the
  /// parameters `generics` declares where it declares any.
  static func object(
    _ writer: inout SourceWriter,
    name: String,
    doc: String,
    members: [Member],
    style: ObjectStyle,
    conformingTo extra: [String] = [],
    generics: String? = nil
  ) throws(PrinterError) {
    let names = Set(members.map(\.name))
    guard names.count == members.count else {
      throw PrinterError("\(name): two properties of one name")
    }
    for member in members where member.deprecation != nil && names.contains("_" + member.name) {
      throw PrinterError(
        "\(name): `_\(member.name)` is both a property and a deprecated one's storage")
    }
    guard !names.contains("configure") else {
      throw PrinterError("\(name): a property named `configure`, which is the initializer's own")
    }
    let stored = members.filter { $0.presence != nil }
    let holdsSecrets = stored.contains(where: \.secret)
    writer.doc(
      doc
        + (holdsSecrets
          ? "\n\nIt prints every property but its secrets, each printed as `<redacted>`, however "
            + "it is printed (`sdk/SPEC.md` §1)." : ""))
    var conformances: [String]
    switch style {
    case .json: conformances = ["Sendable", "Hashable", "Codable"]
    case .form, .query: conformances = ["Sendable", "Hashable"]
    }
    if holdsSecrets {
      // A wire member may be named `description`, as a webhook endpoint's is, so the redacted text
      // is the debug description alone, which `print`, `String(describing:)` and `dump` all read
      // where a type is not `CustomStringConvertible`.
      for reserved in ["debugDescription", "customMirror"] where names.contains(reserved) {
        throw PrinterError("\(name): a property named `\(reserved)` beside a secret")
      }
      conformances += ["CustomDebugStringConvertible", "CustomReflectable"]
    }
    declaration(
      &writer, head: "public struct \(name)", conformances: conformances + extra, generics: generics
    )
    try writer.nested { writer throws(PrinterError) in
      for member in members {
        writer.doc(member.doc)
        available(&writer, deprecated: member.deprecation)
        if let constant = member.constant {
          try writer.block("public var \(member.identifier): \(member.shape.swift) {") {
            writer throws(PrinterError) in
            writer.line(constant)
          }
        } else if member.deprecation != nil {
          writer.line("public var \(member.identifier): \(member.declared) {")
          writer.line("  get { \(member.storage) }")
          writer.line("  set { \(member.storage) = newValue }")
          writer.line("}")
        } else {
          writer.line("public var \(member.identifier): \(member.declared)")
        }
      }
      let deprecated = stored.filter { $0.deprecation != nil }
      if !deprecated.isEmpty {
        writer.line()
      }
      for member in deprecated {
        writer.line("var \(member.storage): \(member.declared)")
      }
      if !members.isEmpty {
        writer.line()
      }

      initializer(&writer, name: name, stored: stored)
      switch style {
      case .json:
        writer.line()
        decoding(&writer, name: name, stored: stored)
        writer.line()
        encoding(&writer, name: name, members: members)
      case .form(let encoding):
        writer.line()
        try parts(&writer, name: name, members: stored, kind: .form, encoding: encoding)
      case .query:
        writer.line()
        try parts(&writer, name: name, members: stored, kind: .query, encoding: [:])
      }
      if holdsSecrets {
        writer.line()
        redacted(&writer, name: name, stored: stored)
      }
    }
    writer.line("}")
  }

  /// redacted writes how a struct holding a secret prints: every stored property by its value but
  /// the secrets, each `<redacted>`, in a log, a debugger's description and a dump alike. The text
  /// is its debug description, which a type that is not `CustomStringConvertible` is printed by
  /// wherever it is printed, so a wire member named `description` keeps its name.
  private static func redacted(_ writer: inout SourceWriter, name: String, stored: [Member]) {
    writer.doc(
      "debugDescription is the value as a log may show it, which `print`, `String(describing:)` "
        + "and `dump` all write: every property but its secrets, each printed as `<redacted>`.")
    writer.line("public var debugDescription: String {")
    writer.nestedLines { writer in
      writer.line("var fields: [String] = []")
      for member in stored {
        let value =
          member.secret ? "<redacted>" : "\\(String(reflecting: self.\(member.storage)))"
        writer.call(
          prefix: "", callee: "fields.append", arguments: ["\"\(member.name): \(value)\""])
      }
      writer.line("return \"\(name)(\\(fields.joined(separator: \", \")))\"")
    }
    writer.line("}")
    writer.line()
    writer.doc(
      "customMirror has no children, so `dump` and a debugger's variable view print the redacted "
        + "description rather than the secrets.")
    writer.line("public var customMirror: Mirror {")
    writer.line("  Mirror(self, children: [], displayStyle: .struct)")
    writer.line("}")
  }

  private static func initializer(_ writer: inout SourceWriter, name: String, stored: [Member]) {
    let arguments = stored.filter { $0.presence?.isInitializerArgument == true }
    writer.doc(
      "Creates a `\(name)` from the properties the contract requires, the optional ones being "
        + "set in `configure`."
    )
    writer.line("public init(")
    for member in arguments {
      writer.line("  \(member.identifier): \(member.declared),")
    }
    writer.line("  configure: (inout Self) -> Void = { _ in }")
    writer.line(") {")
    for member in stored {
      let value = member.presence?.isInitializerArgument == true ? member.identifier : "nil"
      writer.line("  self.\(member.storage) = \(value)")
    }
    writer.line("  configure(&self)")
    writer.line("}")
  }

  private static func decoding(_ writer: inout SourceWriter, name: String, stored: [Member]) {
    writer.doc("Reads a `\(name)` from the JSON object the contract describes.")
    writer.line("public init(from decoder: any Decoder) throws {")
    writer.nestedLines { writer in
      guard !stored.isEmpty else {
        writer.line("_ = try decoder.container(keyedBy: WireKey.self)")
        return
      }
      writer.line("let container = try decoder.container(keyedBy: WireKey.self)")
      for member in stored {
        guard let presence = member.presence else { continue }
        writer.call(
          prefix: "self.\(member.storage) = ", callee: presence.decodeCallee(member.shape),
          arguments: ["\(member.shape.swift).self", "forKey: \(SwiftText.literal(member.name))"])
      }
    }
    writer.line("}")
  }

  private static func encoding(_ writer: inout SourceWriter, name: String, members: [Member]) {
    writer.doc("Writes a `\(name)` as the JSON object the contract describes.")
    writer.line("public func encode(to encoder: any Encoder) throws {")
    writer.nestedLines { writer in
      guard !members.isEmpty else {
        writer.line("_ = encoder.container(keyedBy: WireKey.self)")
        return
      }
      writer.line("var container = encoder.container(keyedBy: WireKey.self)")
      for member in members {
        let method = member.presence?.encodeMethod(member.shape) ?? "encode"
        writer.call(
          prefix: "", callee: "try container.\(method)",
          arguments: ["self.\(member.storage)", "forKey: \(SwiftText.literal(member.name))"])
      }
    }
    writer.line("}")
  }

  /// PartKind is what a request carries a struct's properties as, one entry to a value.
  private enum PartKind {
    case form
    case query

    var property: String {
      self == .form ? "parts" : "items"
    }

    var element: String {
      self == .form ? "MultipartPart" : "QueryItem"
    }
  }

  /// parts writes the property a form or a query is carried as. A file's part carries the media
  /// type `encoding` names for its property, and an encoding of a property the type does not hold,
  /// or of one written as text, is refused: the printer has no way to send it as named.
  private static func parts(
    _ writer: inout SourceWriter, name: String, members: [Member], kind: PartKind,
    encoding: [String: String]
  ) throws(PrinterError) {
    for (property, contentType) in encoding.sorted(by: { $0.key < $1.key }) {
      guard let member = members.first(where: { $0.name == property }) else {
        throw PrinterError("\(name): an encoding for `\(property)`, which the form does not hold")
      }
      guard member.shape.swift == "Foundation.Data" else {
        throw PrinterError(
          "\(name).\(property): sent as `\(contentType)`, and the printer writes it as text")
      }
    }
    writer.doc(
      kind == .form
        ? "parts is the form, as the request carries it: one part to a property, in the "
          + "contract's order, and none for a property left `nil`."
        : "items is the query, as the request carries it: one item to a value, in the "
          + "operation's order, and none for a parameter left `nil`."
    )
    writer.line("var \(kind.property): [\(kind.element)] {")
    try writer.nested { writer throws(PrinterError) in
      writer.line("var \(kind.property): [\(kind.element)] = []")
      for member in members {
        guard let presence = member.presence else { continue }
        let key = SwiftText.literal(member.name)
        if presence == .required {
          try part(
            &writer, key: key, value: "self.\(member.storage)", shape: member.shape, kind: kind,
            contentType: encoding[member.name])
        } else {
          writer.line("if let value = self.\(member.storage) {")
          try writer.nested { writer throws(PrinterError) in
            try part(
              &writer, key: key, value: "value", shape: member.shape, kind: kind,
              contentType: encoding[member.name])
          }
          writer.line("}")
        }
      }
      writer.line("return \(kind.property)")
    }
    writer.line("}")
  }

  private static func part(
    _ writer: inout SourceWriter,
    key: String,
    value: String,
    shape: Shape,
    kind: PartKind,
    contentType: String?
  ) throws(PrinterError) {
    let append = "\(kind.property).append"
    if shape.swift == "Foundation.Data", kind == .form {
      let file = contentType.map { "\(value), contentType: \(SwiftText.literal($0))" } ?? value
      writer.call(
        prefix: "", callee: append, arguments: [".init(name: \(key), content: .file(\(file)))"])
      return
    }
    guard let text = shape.text else {
      throw PrinterError("\(key): a value whose type has no text a request carries")
    }
    let entry: (String) -> String = { value in
      kind == .form
        ? ".init(name: \(key), content: .text(\(text(value))))"
        : ".init(name: \(key), value: \(text(value)))"
    }
    if shape.isList {
      writer.line("for element in \(value) {")
      writer.nestedLines { writer in
        writer.call(prefix: "", callee: append, arguments: [entry("element")])
      }
      writer.line("}")
    } else {
      writer.call(prefix: "", callee: append, arguments: [entry(value)])
    }
  }

  // MARK: - Open enums

  /// enumeration writes an open enum: a struct over the wire's own type, with a static member
  /// per value the contract names.
  ///
  /// It refuses two members of one name, compared without regard to case as the contract
  /// compares their words, and a member named as the type holds a name of its own, so a set the
  /// contract grows is printed whole or not at all, never with a member renamed.
  static func enumeration(
    _ writer: inout SourceWriter,
    name: String,
    in namespace: String,
    doc: String,
    valueType: String,
    members: [EnumValue]
  ) throws(PrinterError) {
    let isInteger: Bool
    switch valueType {
    case "string": isInteger = false
    case "integer": isInteger = true
    default: throw PrinterError("\(namespace).\(name): an enum over `\(valueType)`")
    }
    var taken: [String: String] = [:]
    for member in members {
      guard !ownMembers.contains(member.name) else {
        throw PrinterError(
          "\(namespace).\(name).\(member.source): named `\(member.name)`, a name the type holds "
            + "of its own")
      }
      if let other = taken[member.name.lowercased()] {
        throw PrinterError(
          "\(namespace).\(name): `\(other)` and `\(member.source)` are both named "
            + "`\(member.name)`, compared without regard to case")
      }
      taken[member.name.lowercased()] = member.source
    }
    let raw = isInteger ? "Int" : "String"
    writer.doc(
      doc + "\n\nThe set is open: a value this build has never seen decodes as itself rather than "
        + "failing the response, and a value the contract adds is one more static member."
    )
    var conformances = ["RawRepresentable", "Sendable", "Hashable", "Codable"]
    conformances +=
      isInteger
      ? ["ExpressibleByIntegerLiteral"] : ["CodingKeyRepresentable", "ExpressibleByStringLiteral"]
    declaration(&writer, head: "public struct \(name)", conformances: conformances)
    writer.nestedLines { writer in
      for member in members {
        writer.doc(member.doc)
        available(&writer, deprecated: member.deprecation)
        writer.assignment(
          "public static let \(SwiftText.identifier(member.name)): Self", value: member.literal)
      }
      if !members.isEmpty {
        writer.line()
      }
      writer.doc("rawValue is the value as the wire spells it.")
      writer.line("public let rawValue: \(raw)")
      writer.line()
      writer.doc(
        "Creates a value from its wire spelling, which may be one this build has never seen.")
      writer.line("public init(rawValue: \(raw)) {")
      writer.line("  self.rawValue = rawValue")
      writer.line("}")
      writer.line()
      if isInteger {
        writer.doc("Creates a value from an integer literal, which is its wire spelling.")
        writer.line("public init(integerLiteral value: Int) {")
      } else {
        writer.doc("Creates a value from a string literal, which is its wire spelling.")
        writer.line("public init(stringLiteral value: String) {")
      }
      writer.line("  self.rawValue = value")
      writer.line("}")
      writer.line()
      if !isInteger {
        writer.doc(
          "codingKey is the value as an object's key, where the contract keys a map by it.")
        writer.line("public var codingKey: any CodingKey {")
        writer.line("  WireKey(stringValue: rawValue)")
        writer.line("}")
        writer.line()
        writer.doc("Creates a value from an object's key.")
        writer.line("public init?<Key: CodingKey>(codingKey: Key) {")
        writer.line("  self.rawValue = codingKey.stringValue")
        writer.line("}")
        writer.line()
      }
      writer.doc("Reads the value from its wire spelling.")
      writer.line("public init(from decoder: any Decoder) throws {")
      writer.line("  self.rawValue = try decoder.singleValueContainer().decode(\(raw).self)")
      writer.line("}")
      writer.line()
      writer.doc("Writes the value as the wire spells it.")
      writer.line("public func encode(to encoder: any Encoder) throws {")
      writer.line("  var container = encoder.singleValueContainer()")
      writer.line("  try container.encode(rawValue)")
      writer.line("}")
    }
    writer.line("}")
  }
}

extension Presence {
  /// decodeCallee is the container method reading a property of this presence.
  func decodeCallee(_ shape: Shape) -> String {
    let wired = shape.wired ? "Wired" : ""
    switch self {
    case .required: return "try container.decode\(wired)"
    case .nullableRequired, .optional: return "try container.decode\(wired)IfPresent"
    case .merge: return "try container.decode\(shape.wired ? "WiredMerge" : "Merge")"
    }
  }
}
