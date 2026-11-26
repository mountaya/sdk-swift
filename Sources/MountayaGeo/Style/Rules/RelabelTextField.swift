import MountayaClient

/// maxLabelDepth is how many arrays deep a label may nest and still be relabelled, the read of the
/// name counted as one. A label a designer writes is a few levels deep; one a stored style nests by
/// the thousand is left alone, so the walk, which reads a level per call, never ends on the
/// runtime's stack.
public let maxLabelDepth = 64

/// The operators whose operands are text the label draws, each walked where nothing and a string
/// differ.
private let textOperators: Set<String> = ["downcase", "string", "to-string", "upcase"]

/// The operators that draw one of several outputs.
private let branchOperators: Set<String> = ["case", "match", "step"]

/// The line terminators an ECMAScript `.` refuses, which a name field's variant holds none of.
private let lineTerminators: Set<Unicode.Scalar> = ["\n", "\r", "\u{2028}", "\u{2029}"]

/// relabelTextField is the `text-field` a symbol layer of a map takes to label in `language`, the
/// label `textField` as the style writes it relabelled, or `nil` where the layer is left as it is.
///
/// A read of a name field, `name` or a variant of it (`name:fr`, `name:latin`, `name_en`) by a `get`
/// or a legacy `{token}`, reads `["coalesce", ["get", "name:{language}"], ["get", "name"]]`: the
/// language's name, falling back to the default one, so a feature with no translation still draws a
/// name. The rest of the label stays: a token string is written as the `concat` that says the same
/// thing, an expression keeps its shape, and each branch of a `case`, a `match` and a `step` says
/// the name where it read one, the decisions left as written. `coalesce`, `concat`, `format`, the
/// result of a `let`, `upcase`, `downcase`, `string` and `to-string` are walked through; a `format`
/// keeps each section's options.
///
/// A row, what a token string, a `concat` or a `format` sets side by side, says the name once: name
/// variants joined by nothing but white space read as one name, the white space going with the
/// second, and a row of nothing but names and white space is the name alone. Where nothing and a
/// string differ (an operand of `coalesce` or of a text operator, a branch under a row) the name
/// standing for a row is a `concat` of one, since a row is a string for a feature that holds no
/// name.
///
/// `nil`, the layer left as it is, where the label reads no name field; where it reads one under an
/// operator the walk does not rewrite (`slice`, a binding of a `let`, a legacy function that is not
/// the name alone at every stop); where a row holds the name more than once beside another field or
/// beside constant text that is not white space (`"{name} ({name:en})"`), since localized one by
/// one each read would say one name twice and the name alone would drop text; where the label nests
/// more than `maxLabelDepth` arrays deep; and where the label already reads the language, so a
/// second call writes nothing. The language is written as the wire spells it, `name:fr` for French.
///
/// The walk is the same, edge for edge, in every SDK.
public func relabelTextField(_ textField: JSONValue?, language: RestSchema.Language) -> JSONValue? {
  guard let textField else { return nil }
  let walk = LabelWalk(language: language.rawValue)
  let label: LabelPart
  switch textField {
  case .null:
    return nil
  case .string(let text):
    label = walk.tokens(text)
  case .array:
    guard !nestsPast(textField, limit: maxLabelDepth) else { return nil }
    label = walk.output(textField, at: .label)
  case .object(let members):
    label = walk.function(members)
  case .bool, .number:
    label = walk.part(textField)
  }
  guard label.hasName, !label.isUnreadable, !label.isUnfolded else { return nil }
  // `JSONValue` is `ExpressibleByNilLiteral`, so `nil` in a conditional beside a value would be
  // JSON's `null`; the label left as it is is answered by a return of its own.
  if sameJson(label.value, textField) { return nil }
  return label.value
}

/// Where a node of a label stands, by what the style makes of nothing there: the label itself and
/// the outputs drawn in its place, a part of a row, which writes nothing for nothing, or an
/// operand, where nothing and a string differ.
private enum Place {
  case label
  case row
  case operand

  /// Where the outputs of a branch standing here stand.
  var branch: Place { self == .label ? .label : .operand }
}

/// One node of a label as the walk reads it: whether it draws the localized name, another field, or
/// constant text that is not white space; whether it is the name itself and nothing more; whether
/// it is a row whose names fold into no single one; whether it reads a name in a form the walk does
/// not rewrite; and the node as the relabelled label states it. A class, so a format's options are
/// keyed by the very part they belong to. It is Sendable: every stored property is a constant of a
/// Sendable type.
private final class LabelPart: Sendable {
  let value: JSONValue
  let hasName: Bool
  let hasOther: Bool
  let hasText: Bool
  let isName: Bool
  let isUnfolded: Bool
  let isUnreadable: Bool

  init(
    _ value: JSONValue, hasName: Bool = false, hasOther: Bool = false, hasText: Bool = false,
    isName: Bool = false, isUnfolded: Bool = false, isUnreadable: Bool = false
  ) {
    self.value = value
    self.hasName = hasName
    self.hasOther = hasOther
    self.hasText = hasText
    self.isName = isName
    self.isUnfolded = isUnfolded
    self.isUnreadable = isUnreadable
  }

  /// The part with the flags named changed, its value, its name and whether it is one kept.
  func with(
    hasText: Bool? = nil, hasOther: Bool? = nil, isUnfolded: Bool? = nil,
    isUnreadable: Bool? = nil
  ) -> LabelPart {
    LabelPart(
      value, hasName: hasName, hasOther: hasOther ?? self.hasOther,
      hasText: hasText ?? self.hasText, isName: isName, isUnfolded: isUnfolded ?? self.isUnfolded,
      isUnreadable: isUnreadable ?? self.isUnreadable)
  }
}

/// Whether a name field is named: `name` alone, or `name`, a colon or an underscore, then any run
/// of characters but the line terminators, as an ECMAScript `.` reads one, matched whole, so
/// `place_name` is another field and one pattern means one field in every SDK.
private func isNameField(_ field: String) -> Bool {
  let scalars = Array(field.unicodeScalars)
  guard scalars.count >= 4, scalars[0..<4].elementsEqual("name".unicodeScalars) else {
    return false
  }
  guard scalars.count > 4 else { return true }
  guard scalars[4] == ":" || scalars[4] == "_", scalars.count > 5 else { return false }
  return scalars[5...].allSatisfy { !lineTerminators.contains($0) }
}

/// Whether a value is a constant the label draws as text: a string not white space alone, a number
/// or a boolean.
private func isDrawnText(_ value: JSONValue) -> Bool {
  switch value {
  case .string(let text): return !trimWhiteSpace(text).isEmpty
  case .number, .bool: return true
  case .null, .array, .object: return false
  }
}

/// Whether the value a `literal` states is drawn as text: a constant `isDrawnText(_:)` reads so,
/// an array or an object.
private func isDrawnLiteral(_ value: JSONValue?) -> Bool {
  guard let value else { return false }
  switch value {
  case .array, .object: return true
  default: return isDrawnText(value)
  }
}

/// Whether a node reads a name field off the feature: `["get", "name:latin"]`.
private func isNameRead(_ node: JSONValue) -> Bool {
  guard case .array(let elements) = node, elements.count == 2,
    case .string("get") = elements[0], case .string(let field) = elements[1]
  else { return false }
  return isNameField(field)
}

/// Whether a node reads a name field anywhere inside it, through arrays.
private func readsName(_ node: JSONValue) -> Bool {
  guard case .array(let elements) = node else { return false }
  return isNameRead(node) || elements.contains(where: readsName)
}

/// The operator a node opens with, or `nil` where it states none.
private func operatorOf(_ elements: [JSONValue]) -> String? {
  guard case .string(let name)? = elements.first else { return nil }
  return name
}

/// The text a string holds, or `nil` for any other value.
private func textOf(_ value: JSONValue) -> String? {
  guard case .string(let text) = value else { return nil }
  return text
}

/// An expression of an operator over its values.
private func row(_ name: String, over values: [JSONValue]) -> JSONValue {
  .array([.string(name)] + values)
}

/// The walk over one label, for one language.
private struct LabelWalk {
  let localized: JSONValue

  init(language: String) {
    localized = .array([
      .string("coalesce"),
      .array([.string("get"), .string("name:\(language)")]),
      .array([.string("get"), .string("name")]),
    ])
  }

  /// The localized name, a new part each time it is stated.
  func name() -> LabelPart {
    LabelPart(localized, hasName: true, isName: true)
  }

  /// A node that is not a name, built over the parts under it.
  func part(_ value: JSONValue, under: [LabelPart] = []) -> LabelPart {
    LabelPart(
      value,
      hasName: under.contains { $0.hasName },
      hasOther: under.contains { $0.hasOther },
      hasText: under.contains { $0.hasText } || isDrawnText(value),
      isUnfolded: under.contains { $0.isUnfolded },
      isUnreadable: under.contains { $0.isUnreadable })
  }

  private func other(_ value: JSONValue) -> LabelPart {
    part(value).with(hasOther: true)
  }

  private func unreadable(_ value: JSONValue) -> LabelPart {
    part(value).with(isUnreadable: true)
  }

  private func unfolded(_ value: JSONValue, under: [LabelPart]) -> LabelPart {
    part(value, under: under).with(isUnfolded: true)
  }

  /// The names a row prints side by side folded into one, or `nil` for a row that still holds the
  /// name more than once: two names with nothing but white space between them read as the first.
  private func joinedNames(_ parts: [LabelPart]) -> [LabelPart]? {
    var folded: [LabelPart] = []
    var text: [LabelPart] = []
    var before: LabelPart?
    for part in parts {
      if textOf(part.value) != nil, !part.hasName {
        text.append(part)
        continue
      }
      let isSameName =
        part.isName && before?.isName == true
        && text.allSatisfy { trimWhiteSpace(textOf($0.value) ?? "").isEmpty }
      if !isSameName {
        folded += text
        folded.append(part)
        before = part
      }
      text = []
    }
    folded += text
    return folded.filter(\.hasName).count > 1 ? nil : folded
  }

  /// Whether a row draws nothing but names and white space, each read in a form the walk rewrites.
  private func isNamesAlone(_ parts: [LabelPart]) -> Bool {
    parts.allSatisfy { !$0.hasOther && !$0.hasText && !$0.isUnreadable }
  }

  /// Parts as one row: the name alone where that is all they come to.
  private func concat(_ parts: [LabelPart], at place: Place) -> LabelPart {
    let folded = joinedNames(parts)
    if folded == nil, !isNamesAlone(parts) {
      return unfolded(row("concat", over: parts.map(\.value)), under: parts)
    }
    let stated = folded ?? [name()]
    guard stated.count == 1, let only = stated.first, only.isName else {
      return part(row("concat", over: stated.map(\.value)), under: stated)
    }
    return place == .operand ? part(row("concat", over: [only.value]), under: [only]) : only
  }

  /// A legacy token string: each `{field}` a read, each stretch of text itself. A field is named
  /// in one character or more, so empty braces are text.
  func tokens(_ text: String) -> LabelPart {
    let scalars = Array(text.unicodeScalars)
    func stretch(_ range: Range<Int>) -> String {
      String(String.UnicodeScalarView(scalars[range]))
    }
    var parts: [LabelPart] = []
    var from = 0
    var at = 0
    while at < scalars.count {
      guard scalars[at] == "{" else {
        at += 1
        continue
      }
      var end = at + 1
      while end < scalars.count, scalars[end] != "{", scalars[end] != "}" {
        end += 1
      }
      guard end < scalars.count, scalars[end] == "}", end > at + 1 else {
        at += 1
        continue
      }
      parts.append(part(.string(stretch(from..<at))))
      let field = stretch((at + 1)..<end)
      parts.append(isNameField(field) ? name() : other(row("get", over: [.string(field)])))
      from = end + 1
      at = end + 1
    }
    parts.append(part(.string(stretch(from..<scalars.count))))
    return concat(parts.filter { textOf($0.value)?.isEmpty != true }, at: .label)
  }

  /// A `format`, whose arguments are sections: a text, then the options it is drawn with where it
  /// states any.
  private func format(_ sections: [JSONValue]) -> LabelPart {
    var options: [ObjectIdentifier: JSONValue] = [:]
    var parts: [LabelPart] = []
    for argument in sections {
      if case .object = argument, let last = parts.last, options[ObjectIdentifier(last)] == nil {
        options[ObjectIdentifier(last)] = argument
      } else {
        parts.append(output(argument, at: .row))
      }
    }
    func stated(_ part: LabelPart) -> [JSONValue] {
      [part.value] + (options[ObjectIdentifier(part)].map { [$0] } ?? [])
    }
    if let folded = joinedNames(parts) {
      return part(row("format", over: folded.flatMap(stated)), under: folded)
    }
    if !isNamesAlone(parts) {
      return unfolded(row("format", over: parts.flatMap(stated)), under: parts)
    }
    let name = name()
    if let first = parts.first(where: \.hasName), let held = options[ObjectIdentifier(first)] {
      options[ObjectIdentifier(name)] = held
    }
    return part(row("format", over: stated(name)), under: [name])
  }

  /// The outputs of a branch walked, its decisions left as written.
  private func branches(_ name: String, over operands: [JSONValue], at place: Place) -> LabelPart {
    let last = operands.count - 1
    var outputs: [LabelPart] = []
    var stated: [JSONValue] = []
    for (index, operand) in operands.enumerated() {
      let isOutput =
        name == "match"
        ? index == last || (index > 0 && index % 2 == 0)
        : index % 2 == 1 || (name == "case" && index == last)
      guard isOutput else {
        stated.append(operand)
        continue
      }
      let walked = output(operand, at: place.branch)
      outputs.append(walked)
      stated.append(walked.value)
    }
    return part(row(name, over: stated), under: outputs)
  }

  /// A `let`: its result walked, its bindings as written, and a name a binding reads unreadable.
  private func result(_ operands: [JSONValue], at place: Place) -> LabelPart {
    let bindings = Array(operands.dropLast())
    guard let last = operands.last, !bindings.contains(where: readsName) else {
      return unreadable(row("let", over: operands))
    }
    let result = output(last, at: place.branch)
    return part(row("let", over: bindings + [result.value]), under: [result])
  }

  /// One node whose value the label draws, standing at `place`.
  func output(_ node: JSONValue, at place: Place) -> LabelPart {
    guard case .array(let elements) = node else { return part(node) }
    if isNameRead(node) { return name() }
    guard let name = operatorOf(elements) else { return part(node) }
    let operands = Array(elements.dropFirst())
    switch name {
    case "literal":
      return part(node).with(hasText: isDrawnLiteral(operands.first))
    case "concat":
      return concat(operands.map { output($0, at: .row) }, at: place)
    case "coalesce":
      let walked = operands.map { output($0, at: .operand) }
      let parts = walked.enumerated().filter { index, part in
        !(part.isName && index > 0 && walked[index - 1].isName)
      }.map(\.element)
      if parts.count == 1, let only = parts.first, only.isName { return only }
      return part(row("coalesce", over: parts.map(\.value)), under: parts)
    case "format":
      return format(operands)
    case _ where branchOperators.contains(name):
      return branches(name, over: operands, at: place)
    case "let" where !operands.isEmpty:
      return result(operands, at: place)
    case _ where textOperators.contains(name):
      let parts = operands.map { output($0, at: .operand) }
      return part(row(name, over: parts.map(\.value)), under: parts)
    default:
      return readsName(node) ? unreadable(node) : other(node)
    }
  }

  /// A legacy function, `{"stops": [[zoom, output]]}`, which takes no expression for an output, so
  /// a name cannot be localized inside it: the name alone where every output is, else left as
  /// written.
  func function(_ members: [String: JSONValue]) -> LabelPart {
    var stops: [JSONValue] = []
    if case .array(let written)? = members["stops"] {
      stops = written
    }
    let outputs = stops.map { stop -> LabelPart in
      if case .array(let pair) = stop, pair.count > 1, case .string(let text) = pair[1] {
        return tokens(text)
      }
      return unreadable(stop)
    }
    if !outputs.isEmpty, outputs.allSatisfy(\.isName) { return name() }
    return unreadable(.object(members))
  }
}

/// Whether an expression nests arrays deeper than `limit`, read with a stack of its own and never
/// by recursion.
private func nestsPast(_ expression: JSONValue, limit: Int) -> Bool {
  var pending = [(1, expression)]
  while let (depth, node) = pending.popLast() {
    if depth > limit { return true }
    guard case .array(let elements) = node else { continue }
    for child in elements {
      if case .array = child {
        pending.append((depth + 1, child))
      }
    }
  }
  return false
}
