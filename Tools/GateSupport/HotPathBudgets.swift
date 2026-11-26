import Foundation

/// HotPathBudgets is the gate that keeps a live budget test for every hot path the contract lists
/// for this SDK (SPEC.md section 7).
///
/// A hot path is work that runs per pointer frame, per camera frame or per scrub: a hit-test a
/// pointer move pays for, a redraw a scrub causes, a measurement a fix repeats. Its failure is the
/// one no correctness test sees: the output stays right and only the count of work grows, one
/// reasonable change at a time. So each path keeps a BUDGET test beside its subject, which drives
/// the path through a realistic burst, counts the work, and asserts the count against a named
/// constant, the number a reader can argue with, next to a control that the work still happened.
/// A budget test guards only while it exists, and nothing else notices when it stops existing:
/// this gate is what makes the absence loud.
///
/// ## The list
///
/// `sdk/hot-paths.yaml` in the contract checkout lists every hot path, the SDKs that budget it and
/// the sentence saying what its budget holds, which every SDK listed holds alike. The numbers live
/// here, beside each test, and never there: a SwiftUI body, a Compose recomposition and a React
/// render are different units of work.
///
/// ## The convention it reads
///
/// A budget test is a function marked `@Test` whose display name starts `hot-path budget <id>:`,
/// `<id>` being the path's kebab-case id. Its body hands the path's constant, its id in
/// lowerCamelCase followed by `Budget` (`profile-cursor` is `profileCursorBudget`), to an
/// `#expect` or a `#require`, and the file it sits in declares that constant with `let` at its top
/// level. Every Swift file under `Tests/` is read, the packages of their own under it included,
/// the Renderer's and the Speech topic's, through the lexer, so a title in a comment, a string that
/// titles no test and a constant named only in prose count for nothing.
///
/// A path listed for this SDK with no live budget test fails: one that runs and asserts its count
/// against its constant. So does a budget test that names a path the list does not hold for this
/// SDK, one that hands its constant to no expectation, one whose file declares no such constant,
/// and one switched off: by a `.disabled`, `.enabled(if:)` or `.bug` trait on it or on a suite
/// around it, or by a `withKnownIssue` in its body, which records its failure as expected.
///
/// ## What it does not check
///
/// Whether a budget is tight, which is the reviewer's to argue, and whether the burst a test drives
/// is realistic or reaches the path at all: a count of zero passes over a path the test never
/// reached, which is why each budget test also asserts that the work it budgets still happened.
package enum HotPathBudgets {
  /// sdk is the name the list gives this SDK.
  package static let sdk = "swift"

  /// sdks is the four SDKs the list names, in its order.
  package static let sdks = ["typescript", "dart", "swift", "kotlin"]

  /// titlePrefix is the start of a budget test's display name, before the id of its path.
  package static let titlePrefix = "hot-path budget "

  /// Path is one entry of the list: its id, the SDKs that budget it, the sentence saying what its
  /// budget holds, and the line it starts on.
  package struct Path: Sendable, Hashable {
    package let id: String
    package let sdks: [String]
    package let holds: String
    package let line: Int

    package init(id: String, sdks: [String], holds: String, line: Int) {
      self.id = id
      self.sdks = sdks
      self.holds = holds
      self.line = line
    }
  }

  /// BudgetTest is one test a scan found whose display name starts `hot-path budget <id>:`.
  package struct BudgetTest: Sendable, Hashable {
    /// id is the path its display name names.
    package let id: String
    /// title is its display name, as written between its quotes.
    package let title: String
    /// file is the path of the file it sits in, as the scan was handed it.
    package let file: String
    /// line is the line its `@Test` attribute stands on.
    package let line: Int
    /// asserted is whether its body hands its path's constant to an `#expect` or a `#require`.
    package let asserted: Bool
    /// declared is whether its file declares its path's constant with `let` at its top level.
    package let declared: Bool
    /// switchedOff is what switches it off, `.disabled` or `withKnownIssue`, or nil where
    /// nothing does.
    package let switchedOff: String?

    package init(
      id: String, title: String, file: String, line: Int, asserted: Bool, declared: Bool,
      switchedOff: String?
    ) {
      self.id = id
      self.title = title
      self.file = file
      self.line = line
      self.asserted = asserted
      self.declared = declared
      self.switchedOff = switchedOff
    }

    /// isLive is whether the test holds its path: it asserts against a declared constant, and runs.
    package var isLive: Bool {
      asserted && declared && switchedOff == nil
    }
  }

  /// Finding is one way the tests fail to hold the list.
  package struct Finding: Sendable, Hashable {
    /// Kind is what the finding says is wrong.
    package enum Kind: Sendable, Hashable {
      /// missing is a path listed for this SDK with no live budget test.
      case missing
      /// unregistered is a budget test naming a path the list does not hold for this SDK.
      case unregistered
      /// unasserted is a budget test that hands its constant to no expectation.
      case unasserted
      /// undeclared is a budget test whose file declares no such constant at its top level.
      case undeclared
      /// switchedOff is a budget test something switches off.
      case switchedOff
    }

    package let kind: Kind
    package let file: String
    package let line: Int
    package let message: String
  }

  /// Scan is what a walk of the tests found: every Swift file it read, and every budget test.
  package struct Scan: Sendable {
    package let files: [String]
    package let tests: [BudgetTest]
  }

  /// constant names the constant a budget test of `id` asserts against: the id in lowerCamelCase,
  /// then `Budget`, so `profile-cursor` is `profileCursorBudget`.
  package static func constant(of id: String) -> String {
    let words = id.split(separator: "-")
    let raised = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
    return (words.first.map(String.init) ?? "") + raised.joined() + "Budget"
  }

  /// findings holds the budget tests a scan found to the paths of the list: every path listed for
  /// this SDK needs a live test, and every test a path listed for it, a constant it asserts
  /// against, a declaration of that constant, and nothing switching it off.
  package static func findings(paths: [Path], tests: [BudgetTest]) -> [Finding] {
    var findings: [Finding] = []
    let live = Set(tests.filter(\.isLive).map(\.id))
    for path in paths where path.sdks.contains(sdk) && !live.contains(path.id) {
      findings.append(
        Finding(
          kind: .missing, file: "sdk/hot-paths.yaml", line: path.line,
          message:
            "`\(path.id)` has no live budget test: write one beside its subject, titled "
            + "`\(titlePrefix)\(path.id):`, asserting a count against a top-level "
            + "`let \(constant(of: path.id))`"))
    }
    for test in tests {
      let constant = constant(of: test.id)
      if let path = paths.first(where: { $0.id == test.id }) {
        if !path.sdks.contains(sdk) {
          findings.append(
            Finding(
              kind: .unregistered, file: test.file, line: test.line,
              message:
                "`\(test.id)` is listed for \(path.sdks.joined(separator: ", ")) and not for "
                + "\(sdk): budget the paths sdk/hot-paths.yaml lists for this SDK, or list it there"
            ))
        }
      } else {
        findings.append(
          Finding(
            kind: .unregistered, file: test.file, line: test.line,
            message:
              "`\(test.id)` is no path of sdk/hot-paths.yaml: list it there with the sentence "
              + "saying what its budget holds, or title the test with the path it budgets"))
      }
      if !test.asserted {
        findings.append(
          Finding(
            kind: .unasserted, file: test.file, line: test.line,
            message:
              "the test hands `\(constant)` to no `#expect` or `#require`, so its title promises "
              + "a budget nothing asserts"))
      }
      if !test.declared {
        findings.append(
          Finding(
            kind: .undeclared, file: test.file, line: test.line,
            message:
              "the file declares no top-level `let \(constant)`: declare the number beside the "
              + "subject it budgets"))
      }
      if let switchedOff = test.switchedOff {
        findings.append(
          Finding(
            kind: .switchedOff, file: test.file, line: test.line,
            message:
              "the test is switched off by `\(switchedOff)`, and a budget that does not run "
              + "holds nothing"))
      }
    }
    return findings
  }

  /// scan reads every Swift file below `directory` of `root` for budget tests, each file named by
  /// its path from `root`.
  package static func scan(root: URL, directory: String) -> Scan {
    let base = root.appendingPathComponent(directory)
    var files: [String] = []
    var tests: [BudgetTest] = []
    for relative in SourceTree.swiftFiles(under: base) {
      let path = "\(directory)/\(relative)"
      files.append(path)
      guard let text = SourceTree.read(base.appendingPathComponent(relative)) else { continue }
      tests += budgetTests(in: text, file: path)
    }
    return Scan(files: files, tests: tests)
  }

  // MARK: - The tests of one file

  /// budgetTests reads the budget tests of one file: each function marked `@Test` whose display
  /// name starts `hot-path budget <id>:`, whether its body asserts against its path's constant,
  /// whether the file declares that constant, and what switches it off, on its own attribute, on
  /// a suite around it, or in its body.
  package static func budgetTests(in source: String, file: String) -> [BudgetTest] {
    // Most files hold no budget test, and the text check spares lexing every one of them.
    guard source.contains(titlePrefix) else { return [] }
    let tokens = SwiftLexer.lex(source, keepingStrings: true).tokens
    let declared = topLevelConstants(tokens)
    var found: [BudgetTest] = []

    // What switches off each brace open around the cursor, nil where nothing does.
    var scopes: [String?] = []
    // A suite's switch, the type a declaration or an extension names, and whether the next brace
    // opens that type's body.
    var pendingSwitch: String?
    var pendingType: (name: String, isExtension: Bool)?
    // What switches off each type this file declares, by its name, which its extensions inherit.
    var switchedTypes: [String: String] = [:]

    var position = 0
    while position < tokens.count {
      let token = tokens[position]
      switch (token.kind, token.text) {
      case (.identifier, "@Suite"):
        let arguments = argumentRange(after: position, in: tokens)
        pendingSwitch = arguments.flatMap { traitSwitch(in: tokens, range: $0) }
        position = (arguments?.upperBound ?? position) + 1
        continue
      case (.identifier, "@Test"):
        let arguments = argumentRange(after: position, in: tokens)
        if let arguments,
          let test = budgetTest(
            at: position, arguments: arguments, tokens: tokens, file: file,
            enclosing: scopes.last ?? nil, declared: declared)
        {
          found.append(test)
        }
        position = (arguments?.upperBound ?? position) + 1
        continue
      case (.identifier, "struct"), (.identifier, "class"), (.identifier, "enum"),
        (.identifier, "actor"), (.identifier, "extension"):
        if let name = typeName(after: position, in: tokens) {
          pendingType = (name, token.text == "extension")
        }
      case (.punctuation, "{"):
        var reason = scopes.last ?? nil
        if let type = pendingType {
          let own = type.isExtension ? switchedTypes[type.name] : pendingSwitch
          if !type.isExtension, let own {
            switchedTypes[type.name] = own
          }
          reason = own ?? reason
        }
        scopes.append(reason)
        pendingType = nil
        pendingSwitch = nil
      case (.punctuation, "}"):
        _ = scopes.popLast()
      default:
        break
      }
      position += 1
    }
    return found
  }

  /// budgetTest reads the test whose `@Test` attribute stands at `attribute`, its arguments over
  /// `arguments`, or nil where its display name titles no budget test.
  private static func budgetTest(
    at attribute: Int, arguments: ClosedRange<Int>, tokens: [SourceToken], file: String,
    enclosing: String?, declared: Set<String>
  ) -> BudgetTest? {
    let first = arguments.lowerBound + 1
    guard first < arguments.upperBound, tokens[first].kind == .string,
      let id = pathId(titling: tokens[first].text)
    else { return nil }
    let constant = constant(of: id)
    var asserted = false
    var switchedOff = traitSwitch(in: tokens, range: arguments) ?? enclosing
    if let body = functionBody(after: arguments.upperBound, in: tokens) {
      asserted = assertsAgainst(constant, in: tokens, range: body)
      if switchedOff == nil, tokens[body].contains(where: { $0.text == "withKnownIssue" }) {
        switchedOff = "withKnownIssue"
      }
    }
    return BudgetTest(
      id: id, title: tokens[first].text, file: file, line: tokens[attribute].line,
      asserted: asserted, declared: declared.contains(constant), switchedOff: switchedOff)
  }

  /// pathId is the id of the path a display name titles, where it starts `hot-path budget <id>:`
  /// with a kebab-case id, and nil otherwise.
  static func pathId(titling title: String) -> String? {
    guard title.hasPrefix(titlePrefix) else { return nil }
    let rest = title.dropFirst(titlePrefix.count)
    guard let colon = rest.firstIndex(of: ":") else { return nil }
    let id = String(rest[..<colon])
    return isKebabCase(id) ? id : nil
  }

  /// isKebabCase is true of words of lowercase letters and digits joined by single hyphens, the
  /// first word starting with a letter.
  static func isKebabCase(_ id: String) -> Bool {
    let words = id.split(separator: "-", omittingEmptySubsequences: false)
    guard let first = words.first?.utf8.first, first >= 0x61, first <= 0x7A else { return false }
    return words.allSatisfy { word in
      !word.isEmpty
        && word.utf8.allSatisfy { ($0 >= 0x61 && $0 <= 0x7A) || ($0 >= 0x30 && $0 <= 0x39) }
    }
  }

  /// The traits that switch a test off, or a whole suite's: a test disabled, enabled only on a
  /// condition, or tied to a known bug holds no budget.
  private static let switches: Set<String> = ["disabled", "enabled", "bug"]

  /// traitSwitch is the first trait among an attribute's arguments over `range`, its parentheses
  /// included, that switches its test off, written as `.disabled`, or nil where none does.
  private static func traitSwitch(in tokens: [SourceToken], range: ClosedRange<Int>) -> String? {
    var depth = 0
    for position in range {
      let text = tokens[position].text
      if tokens[position].kind == .punctuation {
        if text == "(" || text == "[" { depth += 1 }
        if text == ")" || text == "]" { depth -= 1 }
      }
      // A trait stands at the top of the argument list: after its opening parenthesis or a comma.
      guard depth == 1, text == ".", position + 1 <= range.upperBound,
        tokens[position - 1].text == "(" || tokens[position - 1].text == ",",
        switches.contains(tokens[position + 1].text)
      else { continue }
      return "." + tokens[position + 1].text
    }
    return nil
  }

  /// assertsAgainst is whether the tokens over `range` hand `constant` to an `#expect` or a
  /// `#require`: the name appears among the arguments of one of them.
  private static func assertsAgainst(
    _ constant: String, in tokens: [SourceToken], range: ClosedRange<Int>
  ) -> Bool {
    for position in range
    where tokens[position].text == "#expect" || tokens[position].text == "#require" {
      guard let arguments = argumentRange(after: position, in: tokens) else { continue }
      if tokens[arguments].contains(where: { $0.kind == .identifier && $0.text == constant }) {
        return true
      }
    }
    return false
  }

  /// argumentRange is the range of the parentheses that open right after the token at
  /// `position`, both included, or nil where none opens there or it never closes.
  private static func argumentRange(after position: Int, in tokens: [SourceToken])
    -> ClosedRange<Int>?
  {
    let open = position + 1
    guard open < tokens.count, tokens[open].text == "(" else { return nil }
    return closing(from: open, open: "(", close: ")", in: tokens).map { open...$0 }
  }

  /// functionBody is the range of the body of the function declared after `position`, its braces
  /// included: the first `func` before any brace, past its parameters, then the brace that opens
  /// its body. It is nil where no function follows.
  private static func functionBody(after position: Int, in tokens: [SourceToken])
    -> ClosedRange<Int>?
  {
    var cursor = position + 1
    while cursor < tokens.count, tokens[cursor].text != "func" {
      if tokens[cursor].text == "{" || tokens[cursor].text == "}" { return nil }
      cursor += 1
    }
    // The parameters, then the brace the body opens with.
    while cursor < tokens.count, tokens[cursor].text != "(" {
      cursor += 1
    }
    guard cursor < tokens.count,
      let parameters = closing(from: cursor, open: "(", close: ")", in: tokens)
    else { return nil }
    cursor = parameters + 1
    while cursor < tokens.count, tokens[cursor].text != "{" {
      if tokens[cursor].text == "}" { return nil }
      cursor += 1
    }
    guard cursor < tokens.count,
      let end = closing(from: cursor, open: "{", close: "}", in: tokens)
    else { return nil }
    return cursor...end
  }

  /// closing is the position of the `close` that balances the `open` at `start`, or nil where
  /// none does.
  private static func closing(
    from start: Int, open: String, close: String, in tokens: [SourceToken]
  ) -> Int? {
    var depth = 0
    for position in start..<tokens.count where tokens[position].kind == .punctuation {
      if tokens[position].text == open {
        depth += 1
      } else if tokens[position].text == close {
        depth -= 1
        if depth == 0 { return position }
      }
    }
    return nil
  }

  /// typeName is the name a type declaration or an extension at `position` names, its dotted
  /// parts joined, or nil where the word is no introducer of one, `class func` among them.
  private static func typeName(after position: Int, in tokens: [SourceToken]) -> String? {
    var cursor = position + 1
    guard cursor < tokens.count, tokens[cursor].kind == .identifier,
      !["func", "var", "let", "subscript", "init"].contains(tokens[cursor].text)
    else { return nil }
    var name = tokens[cursor].text
    while cursor + 2 < tokens.count, tokens[cursor + 1].text == ".",
      tokens[cursor + 2].kind == .identifier
    {
      name += "." + tokens[cursor + 2].text
      cursor += 2
    }
    return name
  }

  /// topLevelConstants is the name of every constant a file declares with `let` outside every
  /// brace.
  private static func topLevelConstants(_ tokens: [SourceToken]) -> Set<String> {
    var names: Set<String> = []
    var depth = 0
    for (position, token) in tokens.enumerated() {
      if token.kind == .punctuation {
        if token.text == "{" { depth += 1 }
        if token.text == "}" { depth = max(0, depth - 1) }
        continue
      }
      guard depth == 0, token.kind == .identifier, token.text == "let",
        position + 1 < tokens.count, tokens[position + 1].kind == .identifier
      else { continue }
      names.insert(tokens[position + 1].text)
    }
    return names
  }
}

// MARK: - The list

/// HotPathsError names the line of `sdk/hot-paths.yaml` the reader could not read.
package struct HotPathsError: Error, Sendable, CustomStringConvertible {
  package let line: Int
  package let message: String

  package var description: String {
    "sdk/hot-paths.yaml line \(line): \(message)"
  }
}

extension HotPathBudgets {
  /// parse reads the list's text.
  ///
  /// The file has one fixed shape, which the contract's own gate enforces: `paths` at the top, then
  /// each entry as `- id: <id>` with `sdks` as a list on one line, `[dart, swift]`, and `holds` as
  /// a folded block, `>-`, every line of it below. This reader knows that shape and nothing else of
  /// YAML. Anything it does not recognise is an error naming the line, so a list that outgrows it
  /// fails loudly instead of being half read.
  package static func parse(_ text: String) throws(HotPathsError) -> [Path] {
    var sawPaths = false
    var paths: [Path] = []
    var draft: (id: String, line: Int, sdks: [String]?, holds: [String]?)?
    var inHolds = false

    func finish() throws(HotPathsError) {
      guard let entry = draft else { return }
      guard let sdks = entry.sdks else {
        throw HotPathsError(line: entry.line, message: "`\(entry.id)` names no `sdks`")
      }
      guard let holds = entry.holds, !holds.isEmpty else {
        throw HotPathsError(line: entry.line, message: "`\(entry.id)` says nothing it `holds`")
      }
      guard !paths.contains(where: { $0.id == entry.id }) else {
        throw HotPathsError(line: entry.line, message: "`\(entry.id)` is listed twice")
      }
      paths.append(
        Path(id: entry.id, sdks: sdks, holds: holds.joined(separator: " "), line: entry.line))
    }

    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    for (offset, rawLine) in lines.enumerated() {
      let number = offset + 1
      let line = rawLine.hasSuffix("\r") ? rawLine.dropLast() : rawLine
      let trimmed = line.drop { $0 == " " }
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }
      if line.contains("\t") {
        throw HotPathsError(line: number, message: "a tab, where the file indents with spaces")
      }
      let indent = line.count - trimmed.count
      if inHolds {
        if indent >= 6 {
          draft?.holds?.append(String(trimmed))
          continue
        }
        inHolds = false
      }
      switch indent {
      case 0:
        guard trimmed == "paths:", !sawPaths else {
          throw HotPathsError(line: number, message: "unrecognised top-level line `\(trimmed)`")
        }
        sawPaths = true
      case 2:
        guard sawPaths, trimmed.hasPrefix("- "), let id = value(of: "id", in: trimmed.dropFirst(2))
        else {
          throw HotPathsError(line: number, message: "expected `- id: <id>`")
        }
        try finish()
        guard isKebabCase(id) else {
          throw HotPathsError(line: number, message: "`\(id)` is not a kebab-case id")
        }
        draft = (id, number, nil, nil)
      case 4:
        guard draft != nil else {
          throw HotPathsError(line: number, message: "a field outside any entry")
        }
        if let list = value(of: "sdks", in: trimmed) {
          guard draft?.sdks == nil else {
            throw HotPathsError(line: number, message: "`sdks` appears twice")
          }
          draft?.sdks = try sdkList(list, line: number)
        } else if let holds = value(of: "holds", in: trimmed) {
          guard draft?.holds == nil else {
            throw HotPathsError(line: number, message: "`holds` appears twice")
          }
          guard holds == ">-" else {
            throw HotPathsError(
              line: number, message: "`holds` is expected as a folded block, `>-`")
          }
          draft?.holds = []
          inHolds = true
        } else {
          throw HotPathsError(line: number, message: "unrecognised field `\(trimmed)`")
        }
      default:
        throw HotPathsError(line: number, message: "unrecognised indentation of \(indent) spaces")
      }
    }
    try finish()
    guard sawPaths else {
      throw HotPathsError(line: lines.count, message: "no `paths`")
    }
    return paths
  }

  /// sdkList reads `[dart, swift]`: one SDK of the four or more, none twice.
  private static func sdkList(_ list: String, line: Int) throws(HotPathsError) -> [String] {
    guard list.hasPrefix("["), list.hasSuffix("]") else {
      throw HotPathsError(line: line, message: "`sdks` is expected as a list on one line, `[…]`")
    }
    let names = list.dropFirst().dropLast().split(separator: ",").map {
      String($0.trimmingCharacters(in: .whitespaces))
    }
    guard !names.isEmpty else {
      throw HotPathsError(line: line, message: "`sdks` names no SDK")
    }
    for (index, name) in names.enumerated() {
      guard sdks.contains(name) else {
        throw HotPathsError(
          line: line, message: "`\(name)` is none of \(sdks.joined(separator: ", "))")
      }
      guard !names[..<index].contains(name) else {
        throw HotPathsError(line: line, message: "`\(name)` is named twice")
      }
    }
    return names
  }

  /// Returns the scalar after `key: `, or nil when the line is not that key.
  private static func value(of key: String, in line: Substring) -> String? {
    let prefix = key + ":"
    guard line.hasPrefix(prefix) else { return nil }
    let rest = line.dropFirst(prefix.count)
    guard rest.isEmpty || rest.hasPrefix(" ") else { return nil }
    return String(rest.drop { $0 == " " })
  }
}
