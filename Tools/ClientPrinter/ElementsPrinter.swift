import Foundation
import GateSupport

/// ElementsData is the elements' contract data as `sdk/elements/` in the contract checkout holds
/// it: the words, the tokens, the glyph table and the notice of the markup that table carries.
package struct ElementsData: Sendable {
  let words: OrderedJSON
  let tokens: OrderedJSON
  let glyphs: OrderedJSON
  let notice: String

  /// parse reads the four files, refusing one of the three tables that is no JSON.
  package static func parse(words: String, tokens: String, glyphs: String, notice: String)
    throws(PrinterError) -> ElementsData
  {
    func json(_ text: String, file: String) throws(PrinterError) -> OrderedJSON {
      do {
        return try OrderedJSON.parse(text)
      } catch {
        throw PrinterError("sdk/elements/\(file) is not JSON: \(error)")
      }
    }
    return ElementsData(
      words: try json(words, file: "words.json"),
      tokens: try json(tokens, file: "tokens.json"),
      glyphs: try json(glyphs, file: "glyphs.json"),
      notice: notice
    )
  }
}

/// ElementsPrinter prints the elements' contract data into `MountayaGeo`, as `ClientPrinter`
/// prints the model into `MountayaClient`: the words as `WordBundle.elements` and
/// `languageEndonyms`, the tokens as `ElementTokens` and their measures as `ElementLayout`, the
/// glyph table's two sets as
/// `GlyphSet.marker` and `GlyphSet.control` and its drawings as `GlyphDrawing.artwork`, and the
/// licences the glyph markup carries into `THIRD-PARTY-NOTICES.txt` at the root.
///
/// A printed file is data a long literal holds, a glyph's markup or a word, which no formatter
/// may break without changing it, so each opens with `// swift-format-ignore-file`, as the README
/// snippets' file does. The printer refuses any member of a table it has no place for, so a table
/// the contract grows is printed whole or not at all.
package enum ElementsPrinter {
  /// directory is where the printed Swift files live, from the package root.
  package static let directory = "Sources/MountayaGeo/Generated"

  /// noticesFile is the third-party notices file at the package root.
  package static let noticesFile = "THIRD-PARTY-NOTICES.txt"

  /// CLDR's plural categories, the keys a counted word's forms take.
  static let pluralCategories: Set<String> = ["zero", "one", "two", "few", "many", "other"]

  /// files prints the tables, in path order, each naming `digest`, the model's digest
  /// (`ModelDigest`), in its header.
  package static func files(for data: ElementsData, digest: String) throws(PrinterError)
    -> [GeneratedFile]
  {
    guard ClientPrinter.isDigest(digest) else {
      throw PrinterError("`\(digest)` is no model digest, 64 lowercase hexadecimal digits")
    }
    let tokens = try Tokens(data.tokens)
    let glyphs = try Glyphs(data.glyphs, tokens: tokens)
    let licence = try licence(of: data.notice)
    var files = [
      try wordsFile(data.words, digest: digest),
      try endonymsFile(data.words, digest: digest),
      tokensFile(tokens, digest: digest),
      layoutFile(tokens, digest: digest),
      artworkFile(glyphs, digest: digest),
    ]
    for set in glyphs.sets {
      files.append(glyphSetFile(set, source: glyphs.source, licence: licence, digest: digest))
    }
    return files.sorted { $0.path < $1.path }
  }

  /// notices is the third-party notices file: where the markup is printed, then the licences the
  /// glyph table carries, verbatim.
  package static func notices(for data: ElementsData) throws(PrinterError) -> String {
    let glyphs = try Glyphs(data.glyphs, tokens: try Tokens(data.tokens))
    let licence = try licence(of: data.notice)
    let files = glyphs.sets.map { "  \(directory)/\(fileName(of: $0))" }
    let heading = "\(glyphs.source.package) (v\(glyphs.source.version))"
    return """
      Third-party licences in sdk-swift
      =================================

      \(heading)
      \(String(repeating: "-", count: heading.count))
      The glyph sets MountayaGeo publishes hold the markup of icons from Lucide, printed from the
      glyph table of mountaya/schemas into

      \(files.joined(separator: "\n"))

      each carrying the licences below too: the ISC licence for Lucide, and the MIT licence for the
      icons Lucide derives from Feather, which it lists.

      \(licence)

      """
  }

  // MARK: - The words

  private static func wordsFile(_ json: OrderedJSON, digest: String) throws(PrinterError)
    -> GeneratedFile
  {
    let members = try objectMembers(
      json, at: "words.json", allowed: ["//", "endonyms", "languages"])
    guard let languagesJSON = members["languages"] else {
      throw PrinterError("sdk/elements/words.json carries no `languages`")
    }
    let languages = try objectMembers(languagesJSON, at: "words.json `languages`", allowed: nil)
    guard languages.keys.contains("en") else {
      throw PrinterError(
        "sdk/elements/words.json carries no English, which every language falls back to")
    }
    var writer = SourceWriter()
    header(into: &writer, source: "words.json", digest: digest)
    writer.line("import MountayaClient")
    writer.line()
    let translated = languages.order.filter { $0 != "en" }
    for code in languages.order {
      try check(language: code)
    }
    try writer.block("extension WordBundle {") { writer throws(PrinterError) in
      writer.doc(
        """
        elements is the words the elements put on screen, by section, as the contract's words \
        table holds them: English, which every language falls back to, and the translations it \
        carries (\(translated.joined(separator: ", "))). A word is a string, a template a string \
        holding `{name}` placeholders, and a counted word an object of the forms CLDR's plural \
        rules name, `other` among them. A consumer's own words are folded over them by \
        `resolveBundle(_:language:overrides:handedOver:)`.
        """)
      let translations = translated.map { "\(SwiftText.literal($0)): \(wordsName($0))" }
      writer.line(
        "public static let elements = WordBundle(english: \(wordsName("en")), translations: ["
          + (translations.isEmpty ? ":" : translations.joined(separator: ", ")) + "])")
    }
    for code in languages.order {
      guard let tree = languages[code] else { continue }
      writer.line()
      writer.doc("The elements' words in the language `\(code)`.")
      writer.line("private let \(wordsName(code)): [String: JSONValue] = [")
      try writer.nested { writer throws(PrinterError) in
        try wordsTree(tree, at: code, into: &writer)
      }
      writer.line("]")
    }
    return GeneratedFile(path: "WordBundle.Elements.swift", text: writer.text)
  }

  private static func wordsName(_ code: String) -> String {
    "words" + SwiftText.upperFirst(code)
  }

  private static func check(language code: String) throws(PrinterError) {
    let letters = code.unicodeScalars.allSatisfy { ("a"..."z").contains($0) }
    guard letters, (2...3).contains(code.unicodeScalars.count) else {
      throw PrinterError("sdk/elements/words.json names a language `\(code)` no wire spells")
    }
  }

  /// wordsTree writes a section's members, each a word, a counted word or a section.
  private static func wordsTree(
    _ json: OrderedJSON, at path: String, into writer: inout SourceWriter
  )
    throws(PrinterError)
  {
    guard let members = json.members else {
      throw PrinterError("sdk/elements/words.json `\(path)` is no section")
    }
    for member in members where member.key != "//" {
      let key = SwiftText.literal(member.key)
      let place = "\(path).\(member.key)"
      guard !member.key.isEmpty else {
        throw PrinterError("sdk/elements/words.json `\(path)` holds a member with no name")
      }
      switch member.value {
      case .string(let word):
        writer.line("\(key): \(SwiftText.literal(word)),")
      case .object(let inner):
        let keys = inner.map(\.key).filter { $0 != "//" }
        let named = keys.filter { pluralCategories.contains($0) }
        if !named.isEmpty {
          let counted =
            named.count == keys.count && keys.contains("other")
            && inner.allSatisfy { $0.key == "//" || $0.value.stringValue != nil }
          guard counted else {
            throw PrinterError(
              "sdk/elements/words.json `\(place)` names a plural form and is no counted word: "
                + "a counted word's keys are CLDR's categories alone, `other` among them")
          }
        }
        if keys.isEmpty {
          writer.line("\(key): [:],")
          continue
        }
        writer.line("\(key): [")
        try writer.nested { writer throws(PrinterError) in
          try wordsTree(member.value, at: place, into: &writer)
        }
        writer.line("],")
      default:
        throw PrinterError(
          "sdk/elements/words.json `\(place)` is \(kind(of: member.value)): a word is a string, "
            + "a counted word or a section")
      }
    }
  }

  private static func endonymsFile(_ json: OrderedJSON, digest: String) throws(PrinterError)
    -> GeneratedFile
  {
    let members = try objectMembers(
      json, at: "words.json", allowed: ["//", "endonyms", "languages"])
    guard let endonymsJSON = members["endonyms"] else {
      throw PrinterError("sdk/elements/words.json carries no `endonyms`")
    }
    let endonyms = try objectMembers(endonymsJSON, at: "words.json `endonyms`", allowed: nil)
    var writer = SourceWriter()
    header(into: &writer, source: "words.json", digest: digest)
    writer.line("import MountayaClient")
    writer.line()
    writer.doc(
      """
      languageEndonyms is each label language's name in its own tongue, the same whatever \
      language the reader reads: a French reader picking German reads `Deutsch`.
      """)
    writer.line("public let languageEndonyms: [RestSchema.Language: String] = [")
    if endonyms.order.isEmpty {
      writer.line("  :")
    }
    for code in endonyms.order {
      try check(language: code)
      guard let name = endonyms[code]?.stringValue else {
        throw PrinterError("sdk/elements/words.json `endonyms.\(code)` is no string")
      }
      writer.line("  \(SwiftText.literal(code)): \(SwiftText.literal(name)),")
    }
    writer.line("]")
    return GeneratedFile(path: "LanguageEndonyms.swift", text: writer.text)
  }

  // MARK: - The tokens

  /// Tokens is the tokens table, read and checked: every token by the member it is printed as.
  struct Tokens {
    struct Token {
      let name: String
      let member: String
      let light: String
      let dark: String?
    }

    /// Measure is one measure of the `layout` group: a length in logical pixels, or a count of
    /// columns where its name ends in `columns`.
    struct Measure {
      let name: String
      let member: String
      let value: Double
      let isCount: Bool
    }

    var colors: [Token] = []
    var shadows: [Token] = []
    var dashes: [Token] = []
    var layout: [Measure] = []

    init(_ json: OrderedJSON) throws(PrinterError) {
      let members = try objectMembers(
        json, at: "tokens.json", allowed: ["//", "colors", "shadows", "dashes", "layout"])
      var taken: Set<String> = []
      func read(_ group: String, value: (OrderedJSON, String) throws(PrinterError) -> String)
        throws(PrinterError) -> [Token]
      {
        guard let groupJSON = members[group] else { return [] }
        let tokens = try objectMembers(groupJSON, at: "tokens.json `\(group)`", allowed: nil)
        var read: [Token] = []
        for name in tokens.order {
          let place = "tokens.json `\(group).\(name)`"
          let schemes = try objectMembers(
            tokens[name] ?? .null, at: place, allowed: ["light", "dark"])
          guard let light = schemes["light"] else {
            throw PrinterError("sdk/elements/\(place) states no light value")
          }
          let member = try camelCase(name, at: place)
          guard taken.insert(member).inserted else {
            throw PrinterError("sdk/elements/\(place) prints as `\(member)`, which a token holds")
          }
          var dark: String?
          if let darkJSON = schemes["dark"] {
            dark = try value(darkJSON, "\(place) dark")
          }
          read.append(
            Token(name: name, member: member, light: try value(light, "\(place) light"), dark: dark)
          )
        }
        return read
      }
      colors = try read("colors") { (json, place) throws(PrinterError) in
        try ElementsPrinter.color(json, at: place)
      }
      shadows = try read("shadows") { (json, place) throws(PrinterError) in
        guard let layers = json.elements, !layers.isEmpty else {
          throw PrinterError("sdk/elements/\(place) is no list of colours")
        }
        var colors: [String] = []
        for (position, layer) in layers.enumerated() {
          colors.append(try ElementsPrinter.color(layer, at: "\(place) [\(position)]"))
        }
        return "[" + colors.joined(separator: ", ") + "]"
      }
      dashes = try read("dashes") { (json, place) throws(PrinterError) in
        guard let lengths = json.elements, !lengths.isEmpty else {
          throw PrinterError("sdk/elements/\(place) is no list of lengths")
        }
        var printed: [String] = []
        for length in lengths {
          guard let number = length.numberValue, number.isFinite, number >= 0 else {
            throw PrinterError("sdk/elements/\(place) holds a length that is no number from 0")
          }
          printed.append(ElementsPrinter.number(number))
        }
        return "[" + printed.joined(separator: ", ") + "]"
      }
      layout = try Self.measures(members["layout"])
    }

    /// measures reads the `layout` group, plain numbers that read alike in both schemes: a count of
    /// columns, a whole number from 1, where a name ends in `columns`, and a length otherwise.
    private static func measures(_ json: OrderedJSON?) throws(PrinterError) -> [Measure] {
      guard let json else { return [] }
      let group = try objectMembers(json, at: "tokens.json `layout`", allowed: nil)
      var read: [Measure] = []
      var taken: Set<String> = []
      for name in group.order {
        let place = "tokens.json `layout.\(name)`"
        guard let value = group[name]?.numberValue, value.isFinite else {
          throw PrinterError("sdk/elements/\(place) is no number")
        }
        let isCount = name.hasSuffix("-columns")
        guard !isCount || (value >= 1 && value == value.rounded() && value < 1_000) else {
          throw PrinterError("sdk/elements/\(place) is no count of columns from 1")
        }
        let member = try camelCase(name, at: place)
        guard taken.insert(member).inserted else {
          throw PrinterError("sdk/elements/\(place) prints as `\(member)`, which a measure holds")
        }
        read.append(Measure(name: name, member: member, value: value, isCount: isCount))
      }
      return read
    }
  }

  private static func tokensFile(_ tokens: Tokens, digest: String) -> GeneratedFile {
    var writer = SourceWriter()
    header(into: &writer, source: "tokens.json", digest: digest)
    writer.doc(
      """
      ElementTokens is every colour and dash the elements are drawn with, as the contract's \
      tokens table names them, each spelled in camel case: `control-bg` is `controlBg`. The \
      sizes, the radii, the fonts and the geometry of the shadows are each platform's own and \
      are not here.

      A consumer restyles the elements by setting the tokens it changes on a copy of \
      `standard`, which is every token as the table states it.
      """)
    writer.lines("public struct ElementTokens: Sendable, Hashable {") { writer in
      let groups: [(tokens: [Tokens.Token], type: String, what: String)] = [
        (tokens.colors, "HexColor", "the colour token `%@`."),
        (
          tokens.shadows, "[HexColor]",
          "the shadow token `%@`: each layer's colour, in drawing order."
        ),
        (tokens.dashes, "[Double]", "the dash token `%@`: lengths, alternately drawn and skipped."),
      ]
      for group in groups {
        for token in group.tokens {
          let what = group.what.replacingOccurrences(of: "%@", with: token.name)
          writer.doc("\(token.member) is \(what)")
          writer.line("public var \(token.member): ThemeToken<\(group.type)>")
        }
      }
      writer.line()
      writer.doc("standard is every token as the contract's tokens table states it.")
      writer.line("public static let standard = ElementTokens(")
      let all = groups.flatMap(\.tokens)
      for (position, token) in all.enumerated() {
        let dark = token.dark.map { ", dark: \($0)" } ?? ""
        let end = position == all.count - 1 ? "" : ","
        writer.line("  \(token.member): ThemeToken(light: \(token.light)\(dark))\(end)")
      }
      writer.line(")")
      let maps: [(name: String, tokens: [Tokens.Token], type: String, what: String)] = [
        ("colorTokens", tokens.colors, "HexColor", "colour"),
        ("shadowTokens", tokens.shadows, "[HexColor]", "shadow"),
        ("dashTokens", tokens.dashes, "[Double]", "dash"),
      ]
      for map in maps {
        writer.line()
        writer.doc(
          "\(map.name) is each \(map.what) token's member, by the name the table gives it.")
        writer.line(
          "static let \(map.name): [String: any KeyPath<ElementTokens, ThemeToken<\(map.type)>> & "
            + "Sendable] = [")
        if map.tokens.isEmpty {
          writer.line("  :")
        }
        for token in map.tokens {
          writer.line("  \(SwiftText.literal(token.name)): \\ElementTokens.\(token.member),")
        }
        writer.line("]")
      }
    }
    return GeneratedFile(path: "ElementTokens.swift", text: writer.text)
  }

  private static func layoutFile(_ tokens: Tokens, digest: String) -> GeneratedFile {
    var writer = SourceWriter()
    header(into: &writer, source: "tokens.json", digest: digest)
    writer.doc(
      """
      ElementLayout is every measure the elements are laid out by, as the contract's tokens \
      table's `layout` group names them, each spelled in camel case: a length in logical pixels, \
      the unit an iOS point is, and a count of columns where its name ends in `columns`. They read \
      alike in both schemes, and every other size is each platform's own.
      """)
    writer.lines("package enum ElementLayout {") { writer in
      for measure in tokens.layout {
        if measure.isCount {
          writer.doc("\(measure.member) is the measure `\(measure.name)`, a count of columns.")
          writer.line("package static let \(measure.member) = \(number(measure.value))")
        } else {
          writer.doc("\(measure.member) is the measure `\(measure.name)`, in logical pixels.")
          writer.line("package static let \(measure.member): Double = \(number(measure.value))")
        }
      }
      writer.line()
      writer.doc("measures is each measure by the name the table gives it.")
      writer.line("package static let measures: [String: Double] = [")
      if tokens.layout.isEmpty {
        writer.line("  :")
      }
      for measure in tokens.layout {
        writer.line("  \(SwiftText.literal(measure.name)): \(number(measure.value)),")
      }
      writer.line("]")
    }
    return GeneratedFile(path: "ElementLayout.swift", text: writer.text)
  }

  /// color reads a colour, `{hex, opacity?}`, into the Swift that builds it.
  static func color(_ json: OrderedJSON, at place: String) throws(PrinterError) -> String {
    let members = try objectMembers(json, at: place, allowed: ["hex", "opacity"])
    return try hexColor(members, at: place)
  }

  private static func hexColor(_ members: Members, at place: String) throws(PrinterError)
    -> String
  {
    guard let hex = members["hex"]?.stringValue, isHex(hex) else {
      throw PrinterError("sdk/elements/\(place) holds no `hex` of six lowercase digits")
    }
    guard let opacity = try opacity(members, at: place) else {
      return "HexColor(hex: \(SwiftText.literal(hex)))"
    }
    return "HexColor(hex: \(SwiftText.literal(hex)), opacity: \(number(opacity)))"
  }

  private static func opacity(_ members: Members, at place: String) throws(PrinterError) -> Double?
  {
    guard let value = members["opacity"] else { return nil }
    guard let opacity = value.numberValue, opacity >= 0, opacity <= 1 else {
      throw PrinterError("sdk/elements/\(place) holds an `opacity` that is no number from 0 to 1")
    }
    return opacity
  }

  private static func isHex(_ text: String) -> Bool {
    let scalars = Array(text.unicodeScalars)
    return scalars.count == 7 && scalars[0] == "#"
      && scalars.dropFirst().allSatisfy { ("0"..."9").contains($0) || ("a"..."f").contains($0) }
  }

  // MARK: - The glyph table

  /// Glyphs is the glyph table, read and checked.
  struct Glyphs {
    struct Source {
      let package: String
      let version: String
    }

    struct NamedSet {
      let key: String
      let paint: String
      let strokeWidth: Double
      let viewBox: Double
      let glyphs: [(name: String, markup: String)]
    }

    struct Drawing {
      let name: String
      let viewBox: [Double]
      /// opacity is the drawing's own opacity, nil where it states none.
      let opacity: Double?
      /// shadow is the Swift that builds the drawing's drop shadow, nil where it casts none.
      let shadow: String?
      let shapes: [String]
    }

    /// The sets the table holds, in the order they are printed, and the static each is.
    static let setKeys = ["marker", "control"]

    var source: Source
    var sets: [NamedSet] = []
    var drawings: [Drawing] = []

    init(_ json: OrderedJSON, tokens: Tokens) throws(PrinterError) {
      let members = try objectMembers(
        json, at: "glyphs.json", allowed: Set(["//", "source", "artwork"] + Self.setKeys))
      let source = try objectMembers(
        members["source"] ?? .null, at: "glyphs.json `source`", allowed: ["package", "version"])
      guard let package = source["package"]?.stringValue,
        let version = source["version"]?.stringValue
      else {
        throw PrinterError("sdk/elements/glyphs.json `source` names no package and version")
      }
      self.source = Source(package: package, version: version)
      for key in Self.setKeys {
        guard let setJSON = members[key] else {
          throw PrinterError("sdk/elements/glyphs.json carries no `\(key)` set")
        }
        sets.append(try Self.set(setJSON, key: key))
      }
      let colors = Dictionary(
        tokens.colors.map { ($0.name, $0.member) }, uniquingKeysWith: { first, _ in first })
      guard let artwork = (members["artwork"] ?? OrderedJSON.array([])).elements else {
        throw PrinterError("sdk/elements/glyphs.json `artwork` is no list")
      }
      var names: Set<String> = []
      for drawing in artwork {
        let read = try Self.drawing(drawing, colors: colors)
        guard names.insert(read.name).inserted else {
          throw PrinterError("sdk/elements/glyphs.json names the drawing `\(read.name)` twice")
        }
        drawings.append(read)
      }
    }

    private static func set(_ json: OrderedJSON, key: String) throws(PrinterError) -> NamedSet {
      let place = "glyphs.json `\(key)`"
      let members = try objectMembers(
        json, at: place, allowed: ["paint", "strokeWidth", "viewBox", "glyphs"])
      guard let paint = members["paint"]?.stringValue, ["fill", "stroke"].contains(paint) else {
        throw PrinterError("sdk/elements/\(place) paints neither `fill` nor `stroke`")
      }
      // A set is printed only where it can be drawn (`geo.icons.glyph-set`): a stroke set strokes
      // at a width above 0, and a fill set reads one from 0.
      guard let width = members["strokeWidth"]?.numberValue, width.isFinite,
        paint == "stroke" ? width > 0 : width >= 0
      else {
        throw PrinterError(
          "sdk/elements/\(place) states no `strokeWidth` \(paint == "stroke" ? "above" : "from") 0"
        )
      }
      guard let box = members["viewBox"]?.numberValue, box.isFinite, box > 0 else {
        throw PrinterError("sdk/elements/\(place) states no `viewBox` above 0")
      }
      guard let entries = members["glyphs"]?.elements else {
        throw PrinterError("sdk/elements/\(place) holds no `glyphs` list")
      }
      var glyphs: [(name: String, markup: String)] = []
      var names: Set<String> = []
      for entry in entries {
        let glyph = try objectMembers(
          entry, at: "\(place) glyph", allowed: ["name", "lucide", "markup"])
        guard let name = glyph["name"]?.stringValue, !name.isEmpty,
          glyph["lucide"]?.stringValue != nil, let markup = glyph["markup"]?.stringValue
        else {
          throw PrinterError(
            "sdk/elements/\(place) holds a glyph with no name, Lucide name or markup")
        }
        guard names.insert(name).inserted else {
          throw PrinterError("sdk/elements/\(place) names the glyph `\(name)` twice")
        }
        glyphs.append((name, markup))
      }
      return NamedSet(key: key, paint: paint, strokeWidth: width, viewBox: box, glyphs: glyphs)
    }

    private static func drawing(_ json: OrderedJSON, colors: [String: String])
      throws(PrinterError) -> Drawing
    {
      let members = try objectMembers(
        json, at: "glyphs.json drawing",
        allowed: ["name", "viewBox", "opacity", "shadow", "shapes"])
      guard let name = members["name"]?.stringValue, !name.isEmpty else {
        throw PrinterError("sdk/elements/glyphs.json holds a drawing with no name")
      }
      let place = "glyphs.json `artwork.\(name)`"
      let box = (members["viewBox"]?.elements ?? []).compactMap(\.numberValue)
      guard box.count == 4, members["viewBox"]?.elements?.count == 4,
        box.allSatisfy(\.isFinite), box[2] > 0, box[3] > 0
      else {
        throw PrinterError("sdk/elements/\(place) states no `viewBox` of four numbers")
      }
      var opacity: Double?
      if let opacityJSON = members["opacity"] {
        guard let value = opacityJSON.numberValue, value > 0, value <= 1 else {
          throw PrinterError(
            "sdk/elements/\(place) holds an `opacity` that is no number above 0 to 1")
        }
        opacity = value
      }
      let shadow = try members["shadow"].map { json throws(PrinterError) in
        try Self.shadow(json, at: "\(place) shadow")
      }
      guard let shapesJSON = members["shapes"]?.elements, !shapesJSON.isEmpty else {
        throw PrinterError("sdk/elements/\(place) holds no shapes")
      }
      var shapes: [String] = []
      for (position, shapeJSON) in shapesJSON.enumerated() {
        let at = "\(place) shape \(position)"
        let shape = try objectMembers(shapeJSON, at: at, allowed: ["markup", "fill", "stroke"])
        guard let markup = shape["markup"]?.stringValue else {
          throw PrinterError("sdk/elements/\(at) holds no markup")
        }
        var arguments = ["markup: \(SwiftText.literal(markup))"]
        if let fill = shape["fill"] {
          arguments.append(
            "fill: "
              + (try paint(
                fill, at: "\(at) fill", colors: colors,
                allowed: ["hex", "token", "opacity", "linear"])))
        }
        if let stroke = shape["stroke"] {
          let members = try objectMembers(
            stroke, at: "\(at) stroke", allowed: ["hex", "token", "opacity", "width"])
          guard let width = members["width"]?.numberValue, width.isFinite, width > 0 else {
            throw PrinterError("sdk/elements/\(at) stroke states no `width` above 0")
          }
          arguments.append(
            "stroke: "
              + (try paint(
                stroke, at: "\(at) stroke", colors: colors,
                allowed: ["hex", "token", "opacity", "width"])))
          arguments.append("strokeWidth: \(ElementsPrinter.number(width))")
        }
        shapes.append("PaintedShape(\(arguments.joined(separator: ", ")))")
      }
      return Drawing(name: name, viewBox: box, opacity: opacity, shadow: shadow, shapes: shapes)
    }

    /// shadow reads a drawing's drop shadow, `{blur, dx, dy, hex, opacity?}`, the blur the
    /// Gaussian's standard deviation in the drawing's units, into its Swift.
    private static func shadow(_ json: OrderedJSON, at place: String) throws(PrinterError)
      -> String
    {
      let members = try objectMembers(
        json, at: place, allowed: ["blur", "dx", "dy", "hex", "opacity"])
      guard let blur = members["blur"]?.numberValue, blur.isFinite, blur >= 0 else {
        throw PrinterError("sdk/elements/\(place) states no `blur` from 0")
      }
      var offset: [Double] = []
      for key in ["dx", "dy"] {
        guard let value = members[key]?.numberValue, value.isFinite else {
          throw PrinterError("sdk/elements/\(place) states no `\(key)` that is a number")
        }
        offset.append(value)
      }
      let color = try ElementsPrinter.hexColor(members, at: place)
      return
        "Shadow(blur: \(ElementsPrinter.number(blur)), dx: \(ElementsPrinter.number(offset[0])), "
        + "dy: \(ElementsPrinter.number(offset[1])), color: \(color))"
    }

    /// gradient reads a linear gradient, `{from, to, stops}`, its two ends in the drawing's units
    /// and at least two stops whose offsets rise from 0 to 1, into its Swift.
    private static func gradient(_ json: OrderedJSON, at place: String) throws(PrinterError)
      -> String
    {
      let members = try objectMembers(json, at: place, allowed: ["from", "to", "stops"])
      var ends: [String] = []
      for key in ["from", "to"] {
        let point = (members[key]?.elements ?? []).compactMap(\.numberValue)
        guard point.count == 2, members[key]?.elements?.count == 2, point.allSatisfy(\.isFinite)
        else {
          throw PrinterError("sdk/elements/\(place) states no `\(key)` of two numbers")
        }
        ends.append("[\(point.map(ElementsPrinter.number).joined(separator: ", "))]")
      }
      guard let stopsJSON = members["stops"]?.elements, stopsJSON.count >= 2 else {
        throw PrinterError("sdk/elements/\(place) holds no two `stops`")
      }
      var stops: [String] = []
      var last = 0.0
      for (position, stopJSON) in stopsJSON.enumerated() {
        let at = "\(place) stop \(position)"
        let stop = try objectMembers(stopJSON, at: at, allowed: ["offset", "hex", "opacity"])
        guard let offset = stop["offset"]?.numberValue, offset >= last, offset <= 1 else {
          throw PrinterError("sdk/elements/\(at) states no `offset` from the one before it to 1")
        }
        last = offset
        stops.append(
          "GradientStop(offset: \(ElementsPrinter.number(offset)), color: "
            + "\(try ElementsPrinter.hexColor(stop, at: at)))")
      }
      return "Gradient(from: \(ends[0]), to: \(ends[1]), stops: [\(stops.joined(separator: ", "))])"
    }

    /// paint reads a drawing's paint, a colour or one of the tokens' colours, into its Swift.
    private static func paint(
      _ json: OrderedJSON, at place: String, colors: [String: String], allowed: Set<String>
    ) throws(PrinterError) -> String {
      let members = try objectMembers(json, at: place, allowed: allowed)
      if let linear = members["linear"] {
        guard members.keys == ["linear"] else {
          throw PrinterError("sdk/elements/\(place) states a `linear` gradient beside a colour")
        }
        return ".linear(\(try gradient(linear, at: "\(place) linear")))"
      }
      switch (members["hex"], members["token"]) {
      case (.some, nil):
        return ".color(\(try ElementsPrinter.hexColor(members, at: place)))"
      case (nil, .some(let token)):
        guard let name = token.stringValue, let member = colors[name] else {
          throw PrinterError("sdk/elements/\(place) names no colour of the tokens table")
        }
        let opacity = try ElementsPrinter.opacity(members, at: place) ?? 1
        return ".token(\\ElementTokens.\(member), opacity: \(ElementsPrinter.number(opacity)))"
      default:
        throw PrinterError("sdk/elements/\(place) states neither a `hex` nor a `token`, or both")
      }
    }
  }

  private static func fileName(of set: Glyphs.NamedSet) -> String {
    "GlyphSet.\(SwiftText.upperFirst(set.key)).swift"
  }

  private static func glyphSetFile(
    _ set: Glyphs.NamedSet, source: Glyphs.Source, licence: String, digest: String
  ) -> GeneratedFile {
    var writer = SourceWriter()
    header(into: &writer, source: "glyphs.json", digest: digest)
    writer.line(
      "// The markup is that of icons from Lucide, read from \(source.package) at version "
        + "\(source.version), and")
    writer.line("// carries the licences `sdk/elements/NOTICE` reproduces:")
    writer.line("//")
    for line in licence.split(separator: "\n", omittingEmptySubsequences: false) {
      writer.line(line.isEmpty ? "//" : "// \(line)")
    }
    writer.line()
    writer.lines("extension GlyphSet {") { writer in
      writer.doc(
        """
        \(set.key) is the \(set.key) set of the contract's glyph table, drawn from \
        \(source.package) \(source.version): \(set.glyphs.count) glyphs, by name.
        """)
      writer.line("public static let \(set.key) = GlyphSet(")
      writer.line("  drawable: \(SwiftText.literal(set.key)),")
      writer.line("  paint: .\(set.paint),")
      writer.line("  strokeWidth: \(number(set.strokeWidth)),")
      writer.line("  viewBox: \(number(set.viewBox)),")
      writer.line("  markup: [")
      if set.glyphs.isEmpty {
        writer.line("    :")
      }
      for glyph in set.glyphs {
        writer.line("    \(SwiftText.literal(glyph.name)): \(SwiftText.literal(glyph.markup)),")
      }
      writer.line("  ]")
      writer.line(")")
    }
    return GeneratedFile(path: fileName(of: set), text: writer.text)
  }

  private static func artworkFile(_ glyphs: Glyphs, digest: String) -> GeneratedFile {
    var writer = SourceWriter()
    header(into: &writer, source: "glyphs.json", digest: digest)
    writer.lines("extension GlyphDrawing {") { writer in
      writer.doc(
        """
        artwork is Mountaya's own drawings the contract's glyph table carries, by the name it \
        gives each.
        """)
      writer.line("public static let artwork: [String: GlyphDrawing] = [")
      if glyphs.drawings.isEmpty {
        writer.line("  :")
      }
      for drawing in glyphs.drawings {
        writer.line("  \(SwiftText.literal(drawing.name)): GlyphDrawing(")
        writer.line("    viewBox: [\(drawing.viewBox.map(number).joined(separator: ", "))],")
        if drawing.opacity != nil || drawing.shadow != nil {
          writer.line("    opacity: \(number(drawing.opacity ?? 1)),")
          writer.line("    shadow: \(drawing.shadow ?? "nil"),")
        }
        writer.line("    shapes: [")
        for shape in drawing.shapes {
          writer.line("      \(shape),")
        }
        writer.line("    ]")
        writer.line("  ),")
      }
      writer.line("]")
    }
    return GeneratedFile(path: "GlyphDrawing.Artwork.swift", text: writer.text)
  }

  /// licence is the licences a notice carries, from its first, the ISC licence, to its end.
  private static func licence(of notice: String) throws(PrinterError) -> String {
    guard let start = notice.range(of: "ISC License"), notice.contains("The MIT License") else {
      throw PrinterError("sdk/elements/NOTICE carries no ISC and MIT licence to reproduce")
    }
    var licence = String(notice[start.lowerBound...])
    while licence.hasSuffix("\n") {
      licence.removeLast()
    }
    return licence
  }

  // MARK: - Shared

  /// Members is an object's members by key, in document order.
  struct Members {
    let order: [String]
    private let values: [String: OrderedJSON]

    init(_ members: [OrderedJSON.Member]) {
      order = members.map(\.key).filter { $0 != "//" }
      values = Dictionary(
        members.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })
    }

    subscript(key: String) -> OrderedJSON? {
      values[key]
    }

    var keys: Set<String> {
      Set(order)
    }
  }

  /// objectMembers reads an object, refusing anything else, a key written twice, and, where
  /// `allowed` is given, a key it does not name.
  static func objectMembers(_ json: OrderedJSON, at place: String, allowed: Set<String>?)
    throws(PrinterError) -> Members
  {
    guard let members = json.members else {
      throw PrinterError("sdk/elements/\(place) is \(kind(of: json)), where an object stands")
    }
    var seen: Set<String> = []
    for member in members {
      guard seen.insert(member.key).inserted else {
        throw PrinterError("sdk/elements/\(place) writes `\(member.key)` twice")
      }
      if let allowed, !allowed.contains(member.key) {
        throw PrinterError(
          "sdk/elements/\(place) holds `\(member.key)`, which this printer has no place for")
      }
    }
    return Members(members)
  }

  private static func kind(of json: OrderedJSON) -> String {
    switch json {
    case .null: return "null"
    case .bool: return "a boolean"
    case .number: return "a number"
    case .string: return "a string"
    case .array: return "a list"
    case .object: return "an object"
    }
  }

  /// camelCase spells a kebab-case name in camel case, `control-bg` as `controlBg`, refusing a
  /// name that would not be a plain Swift identifier.
  static func camelCase(_ name: String, at place: String) throws(PrinterError) -> String {
    let words = name.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
    let spelled =
      (words.first ?? "") + words.dropFirst().map { SwiftText.upperFirst($0) }.joined()
    let lowerWords = words.allSatisfy { word in
      !word.isEmpty
        && word.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) }
    }
    guard lowerWords, SwiftText.identifier(spelled) == spelled else {
      throw PrinterError("sdk/elements/\(place) names no Swift member in camel case")
    }
    return spelled
  }

  /// number spells a number as the shortest Swift literal that reads back as it: a whole number
  /// with no fraction.
  static func number(_ value: Double) -> String {
    if value == value.rounded(), abs(value) < 9_007_199_254_740_992 {
      return String(Int64(value))
    }
    return "\(value)"
  }

  private static func header(into writer: inout SourceWriter, source: String, digest: String) {
    writer.line("// swift-format-ignore-file")
    writer.line(
      "// Printed by `swift run GenerateClient` from `sdk/elements/\(source)`, model digest")
    writer.line("// \(digest).")
    writer.line(
      "// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and "
        + "printed")
    writer.line("// again (SPEC.md section 3).")
    writer.line()
  }
}

extension SourceWriter {
  /// lines writes `opening`, the body one level in, and the closing brace, for a body that
  /// cannot fail.
  mutating func lines(_ opening: String, body: (inout SourceWriter) -> Void) {
    line(opening)
    nestedLines(body)
    line("}")
  }
}
