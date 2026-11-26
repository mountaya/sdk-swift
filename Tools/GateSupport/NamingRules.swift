/// NamingRules is the naming law of SPEC.md section 5, as checks over the compiler's symbols.
///
/// The law stops at the generated boundary: a declaration under a `Generated` directory
/// carries the contract's own name and is not read.
package enum NamingRules {
  /// Finding is one name that breaks the law.
  package struct Finding: Sendable, Hashable {
    package let name: String
    package let rule: String
    package let message: String
    package let location: String?
  }

  /// Report is the outcome of one run over a set of symbols.
  package struct Report: Sendable {
    /// checked counts the declarations the law was applied to, the exempt ones included.
    package let checked: Int
    /// exempt lists the names an exemption covered, each of which the tree does declare.
    package let exempt: [String]
    package let findings: [Finding]
    /// staleExemptions lists the exemptions that name nothing the tree declares.
    package let staleExemptions: [String]

    /// passes is true when no name breaks the law and no exemption is stale.
    package var passes: Bool {
      findings.isEmpty && staleExemptions.isEmpty
    }

    /// summary is the line a reviewer watches move.
    package var summary: String {
      "\(checked) checked, \(exempt.count) exempt"
    }
  }

  /// check applies the law to every symbol outside the generated directory.
  ///
  /// An exemption is keyed by a declaration's qualified name and valued by the sentence that
  /// justifies it. One that names nothing is reported, since it would otherwise cover the
  /// next declaration to take that name.
  package static func check(symbols: [SymbolGraph.Symbol], exemptions: [String: String]) -> Report {
    var findings: [Finding] = []
    var exempt: Set<String> = []
    var checked = 0

    for symbol in symbols where !isGenerated(symbol) {
      checked += 1
      if exemptions[symbol.qualifiedName] != nil {
        exempt.insert(symbol.qualifiedName)
        continue
      }
      for (rule, message) in violations(of: symbol) {
        findings.append(
          Finding(
            name: symbol.qualifiedName,
            rule: rule,
            message: message,
            location: location(of: symbol)
          )
        )
      }
    }

    return Report(
      checked: checked,
      exempt: exempt.sorted(),
      findings: findings.sorted { ($0.name, $0.rule) < ($1.name, $1.rule) },
      staleExemptions: exemptions.keys.filter { !exempt.contains($0) }.sorted()
    )
  }

  private static func isGenerated(_ symbol: SymbolGraph.Symbol) -> Bool {
    symbol.file?.split(separator: "/").contains("Generated") ?? false
  }

  private static func location(of symbol: SymbolGraph.Symbol) -> String? {
    guard let file = symbol.file else { return nil }
    guard let line = symbol.line else { return file }
    return "\(file):\(line)"
  }

  private static func violations(of symbol: SymbolGraph.Symbol) -> [(String, String)] {
    guard let declared = symbol.path.last else { return [] }
    var found: [(String, String)] = []

    if symbol.isType {
      found += typeViolations(name: declared, isMachine: isInEngines(symbol))
      if symbol.path.count == 1, symbol.isPublished, platformNames.contains(declared) {
        found.append(
          (
            "shadow",
            "`\(declared)` is a name the platform already publishes, and a consumer imports "
              + "both in the same file"
          )
        )
      }
    } else {
      // A function's name carries its labels: `sleep(for:)`. The base name and each label are
      // each a word a caller reads.
      let base = declared.split(separator: "(").first.map(String.init) ?? declared
      var words = symbol.parameterLabels
      if base != "init", base != "subscript", base != "deinit" {
        words.append(base)
      }
      for word in words where isPlainIdentifier(word) {
        found += memberViolations(name: word, isPublished: symbol.isPublished)
      }
      // A seam a consumer is handed as a value, rather than as a type, is named the same way.
      if symbol.path.count == 1, isPlainIdentifier(base) {
        found += nullObjectViolations(name: base)
      }
    }
    return found
  }

  /// isInEngines tells whether the layout law files a symbol under an `Engines` directory,
  /// which is what makes it a machine in every SDK.
  private static func isInEngines(_ symbol: SymbolGraph.Symbol) -> Bool {
    symbol.file?.split(separator: "/").contains("Engines") ?? false
  }

  private static func typeViolations(name: String, isMachine: Bool) -> [(String, String)] {
    var found: [(String, String)] = []

    if name.hasPrefix("Mountaya"), name != "Mountaya" {
      found.append(
        ("prefix", "a type prefix the module already says: drop `Mountaya` from `\(name)`")
      )
    }
    // Outside `Engines` the words are the domain's: a value about an edit in progress may be
    // an edit session.
    for suffix in engineSynonyms where isMachine && name.hasSuffix(suffix) {
      found.append(("engine", "`\(suffix)` means `Engine`: a machine is named `…Engine`"))
    }
    for suffix in vagueSuffixes where name.hasSuffix(suffix) {
      found.append(
        ("vague", "`\(suffix)` names what the author could not name: say what `\(name)` is")
      )
    }
    found += nullObjectViolations(name: name)
    if name.contains("Inert"), !name.hasPrefix("Inert") {
      found.append(("inert", "`Inert` leads the name of a null object: `Inert…`"))
    }
    if let word = camelWords(of: name).first(where: isWordAcronym) {
      let capitals = word.hasSuffix("s") ? word.dropLast().uppercased() + "s" : word.uppercased()
      found.append(
        ("acronym", "an acronym is capitals in a type: `\(capitals)`, never `\(word)`")
      )
    }
    return found
  }

  /// isWordAcronym is true of a word of a type's name that is an acronym written as a word,
  /// `Api` or `Urls`, which a type spells in capitals, `APIError` and `BaseURLs`.
  private static func isWordAcronym(_ word: String) -> Bool {
    let singular = word.hasSuffix("s") && word.count > 2 ? String(word.dropLast()) : word
    return wordAcronyms.contains(word) || wordAcronyms.contains(singular)
  }

  /// The acronyms the SDK's names hold, as a member writes each: a type writes each in capitals
  /// (SPEC.md section 5).
  private static let wordAcronyms: Set<String> = [
    "Api", "Dem", "Html", "Http", "Id", "Json", "Poi", "Sdk", "Sse", "Svg", "Uri", "Url", "Uuid",
    "Xml",
  ]

  /// nullObjectViolations refuses a name whose first whole word means `Inert`. `Nullable`
  /// is not `Null`, so the word is compared whole rather than as a prefix.
  private static func nullObjectViolations(name: String) -> [(String, String)] {
    let words = camelWords(of: name)
    guard words.count > 1, let lead = words.first, nullObjectWords.contains(lead.lowercased())
    else { return [] }
    return [("inert", "a null object leads with `Inert`, not `\(lead)`")]
  }

  private static func memberViolations(name: String, isPublished: Bool) -> [(String, String)] {
    var found: [(String, String)] = []
    let words = camelWords(of: name)

    // A handler is what a consumer is handed, so the closed set reads the published surface.
    if isPublished, words.first == "on", words.count > 1 {
      let verbs = words.dropFirst()
      if let synonym = verbs.first(where: { handlerSynonyms[$0] != nil }),
        let canonical = handlerSynonyms[synonym]
      {
        found.append(
          ("handler", "`\(synonym)` is a synonym of `\(canonical)`, which is the verb in the set")
        )
      } else if !verbs.contains(where: { handlerVerbs.contains($0) }) {
        found.append(
          (
            "handler",
            "`\(name)` uses no verb of the closed set: "
              + handlerVerbs.sorted().map { "on\($0)" }.joined(separator: ", ")
          )
        )
      }
    }

    if hasUppercaseRun(name) {
      found.append(
        ("acronym", "an acronym is a word in a member: `loadHttpUrl`, never `loadHTTPURL`")
      )
    }
    return found
  }

  /// Splits `onQueryChange` into `on`, `Query`, `Change`. A run of capitals stays one word.
  static func camelWords(of name: String) -> [String] {
    var words: [String] = []
    var current = ""
    let characters = Array(name)
    for (position, character) in characters.enumerated() {
      let startsWord: Bool
      if position == 0 || !character.isUppercase {
        startsWord = false
      } else {
        let previous = characters[position - 1]
        let next = position + 1 < characters.count ? characters[position + 1] : nil
        startsWord = !previous.isUppercase || (next?.isLowercase ?? false)
      }
      if startsWord, !current.isEmpty {
        words.append(current)
        current = ""
      }
      current.append(character)
    }
    if !current.isEmpty {
      words.append(current)
    }
    return words
  }

  private static func hasUppercaseRun(_ name: String) -> Bool {
    var previousWasUppercase = false
    for character in name {
      let isUppercase = character.isUppercase
      if isUppercase, previousWasUppercase {
        return true
      }
      previousWasUppercase = isUppercase
    }
    return false
  }

  private static func isPlainIdentifier(_ name: String) -> Bool {
    guard let first = name.unicodeScalars.first, first == "_" || first.properties.isAlphabetic
    else {
      return false
    }
    return name.unicodeScalars.allSatisfy {
      $0 == "_" || $0.properties.isAlphabetic || ($0 >= "0" && $0 <= "9")
    }
  }

  /// The names SPEC.md section 5 says all mean `Engine`, for a type the layout files under
  /// `Engines`.
  private static let engineSynonyms = [
    "Controller", "Manager", "Session", "Service", "Coordinator",
  ]

  private static let vagueSuffixes = ["Helper", "Helpers", "Util", "Utils", "Utility", "Utilities"]

  /// The first words that mean `Inert`, compared lowercased and whole. `sdk/SPEC.md` §9 in
  /// `mountaya/schemas` lists them for every SDK.
  private static let nullObjectWords: Set<String> = [
    "null", "noop", "nop", "dummy", "never", "silent", "no",
  ]

  /// The closed set of handler verbs. `Tap` is this SDK's spelling of the gesture.
  private static let handlerVerbs: Set<String> = [
    "Change", "Close", "Error", "Hover", "Select", "Tap", "Toggle", "Ready", "Destroy",
  ]

  /// Words that say what a verb of the set already says, each with the verb it stands for.
  private static let handlerSynonyms: [String: String] = [
    "Click": "Tap", "Press": "Tap", "Touch": "Tap",
    "Dismiss": "Close",
    "Update": "Change", "Changed": "Change", "Edit": "Change",
    "Fail": "Error", "Failure": "Error",
    "Pick": "Select", "Choose": "Select",
    "Switch": "Toggle", "Flip": "Toggle",
    "Load": "Ready", "Loaded": "Ready", "Mount": "Ready",
    "Dispose": "Destroy", "Teardown": "Destroy", "Unmount": "Destroy",
  ]

  /// Top-level names the standard library, Foundation, Observation and SwiftUI publish. A
  /// published top-level type that takes one makes the platform's own type ambiguous in every
  /// file that imports this SDK beside it. The table is closed and grows by hand.
  private static let platformNames: Set<String> = [
    // The standard library.
    "Any", "Array", "Bool", "Character", "Clock", "Codable", "CodingKey", "Collection",
    "Comparable", "Decodable", "Decoder", "Dictionary", "Double", "Duration", "Encodable",
    "Encoder", "Equatable", "Error", "Float", "Hashable", "Identifiable", "Instant", "Int",
    "Never", "Optional", "Range", "Result", "Sendable", "Sequence", "Set", "String", "Task",
    "Type", "Void",
    // Foundation.
    "Bundle", "Calendar", "Data", "Date", "DateInterval", "Decimal", "FileManager", "IndexPath",
    "Locale", "Measurement", "Notification", "Operation", "Process", "Progress", "Scanner",
    "TimeInterval", "TimeZone", "Timer", "URL", "URLRequest", "URLResponse", "URLSession", "UUID",
    "Unit",
    // Observation.
    "Observable", "Observations",
    // SwiftUI.
    "Alert", "Animation", "App", "Binding", "Button", "Canvas", "Color", "Divider", "Environment",
    "Font", "ForEach", "Form", "Gesture", "Grid", "Group", "Image", "Label", "Layout", "Link",
    "List", "Map", "Menu", "NavigationLink", "NavigationStack", "NavigationView", "Path",
    "Picker", "Scene", "ScrollView", "Section", "Shape", "Slider", "Spacer", "State", "Stepper",
    "Table", "Text", "TextField", "Toggle", "Transaction", "View",
  ]
}
