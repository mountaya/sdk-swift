import Foundation
import Testing

@testable import ClientPrinter

/// The printer of the elements' data against miniature tables holding one of every kind,
/// compared byte for byte with the files it is meant to print.
///
/// The miniatures sit in `Golden/elements/` and the files they print in
/// `Golden/ElementsGenerated/`, beside `Golden/THIRD-PARTY-NOTICES.txt`. After a deliberate change
/// to the printer, `MOUNTAYA_GOLDEN=write swift test --filter ElementsPrinterTests` rewrites them,
/// and the diff is what a reviewer reads.
@Suite("ElementsPrinter")
struct ElementsPrinterTests {
  private static let golden = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Golden")

  private static func miniature(_ file: String) throws -> String {
    try String(contentsOf: golden.appendingPathComponent("elements/\(file)"), encoding: .utf8)
  }

  private static func data(
    words: String? = nil, tokens: String? = nil, glyphs: String? = nil, notice: String? = nil
  ) throws -> ElementsData {
    try ElementsData.parse(
      words: try words ?? miniature("words.json"),
      tokens: try tokens ?? miniature("tokens.json"),
      glyphs: try glyphs ?? miniature("glyphs.json"),
      notice: try notice ?? miniature("NOTICE")
    )
  }

  /// refusal is what printing the miniatures with one file replaced refuses, or nil.
  private static func refusal(
    words: String? = nil, tokens: String? = nil, glyphs: String? = nil, notice: String? = nil
  ) -> String? {
    do {
      let data = try data(words: words, tokens: tokens, glyphs: glyphs, notice: notice)
      _ = try ElementsPrinter.files(for: data, digest: ClientPrinterTests.digest)
      _ = try ElementsPrinter.notices(for: data)
      return nil
    } catch {
      return "\(error)"
    }
  }

  @Test("the miniature tables print the golden files and the notices, byte for byte")
  func golden() throws {
    let data = try Self.data()
    let printed = try ElementsPrinter.files(for: data, digest: ClientPrinterTests.digest)
    let notices = try ElementsPrinter.notices(for: data)
    let directory = Self.golden.appendingPathComponent("ElementsGenerated")
    let noticesURL = Self.golden.appendingPathComponent(ElementsPrinter.noticesFile)

    if ProcessInfo.processInfo.environment["MOUNTAYA_GOLDEN"] == "write" {
      try FileTree.write(printed, replacing: FileTree.files(under: directory), at: directory)
      try Data(notices.utf8).write(to: noticesURL)
    }

    #expect(
      FileTree.files(under: directory) == printed.map(\.path),
      "the golden files are not the files the miniature tables print"
    )
    for file in printed {
      let expected = try String(
        contentsOf: directory.appendingPathComponent(file.path), encoding: .utf8)
      #expect(file.text == expected, "\(file.path)")
    }
    #expect(notices == (try String(contentsOf: noticesURL, encoding: .utf8)))
  }

  @Test("printing is deterministic")
  func deterministic() throws {
    #expect(
      try ElementsPrinter.files(for: try Self.data(), digest: ClientPrinterTests.digest)
        == ElementsPrinter.files(for: try Self.data(), digest: ClientPrinterTests.digest))
  }

  @Test("every printed file is left to no formatter, and every glyph file carries the licences")
  func licences() throws {
    let files = try ElementsPrinter.files(for: try Self.data(), digest: ClientPrinterTests.digest)
    let glyphFiles = files.filter { $0.path.hasPrefix("GlyphSet.") }

    #expect(files.allSatisfy { $0.text.hasPrefix("// swift-format-ignore-file\n") })
    #expect(glyphFiles.map(\.path) == ["GlyphSet.Control.swift", "GlyphSet.Marker.swift"])
    for file in glyphFiles {
      #expect(file.text.contains("// ISC License\n"), "\(file.path)")
      #expect(file.text.contains("// The MIT License (MIT) (for the icons listed above)\n"))
      #expect(!file.text.contains("beside this file"), "\(file.path)")
    }
  }

  @Test("a member a table gains that the printer has no place for is refused, never skipped")
  func refusesMembers() throws {
    let tokens = try Self.miniature("tokens.json").replacingOccurrences(
      of: "\"dashes\": {", with: "\"sizes\": {}, \"dashes\": {")
    let glyphs = try Self.miniature("glyphs.json").replacingOccurrences(
      of: "\"artwork\": [", with: "\"studio\": {}, \"artwork\": [")
    let colour = try Self.miniature("tokens.json").replacingOccurrences(
      of: "{ \"hex\": \"#1c7ed6\" }", with: "{ \"hex\": \"#1c7ed6\", \"name\": \"blue\" }")

    #expect(
      Self.refusal(tokens: tokens)?.contains("`sizes`, which this printer has no place for") == true
    )
    #expect(Self.refusal(glyphs: glyphs)?.contains("`studio`") == true)
    #expect(Self.refusal(tokens: colour)?.contains("`name`") == true)
  }

  @Test("a word that is no string, counted word or section is refused")
  func refusesWords() throws {
    let number = try Self.miniature("words.json").replacingOccurrences(
      of: "\"close\": \"Close\"", with: "\"close\": 3")
    let mixed = try Self.miniature("words.json").replacingOccurrences(
      of: "\"title\": \"Zoom in\"", with: "\"title\": \"Zoom in\", \"one\": \"A zoom\"")
    let noEnglish = try Self.miniature("words.json").replacingOccurrences(
      of: "\"en\": {\n      \"controls\"", with: "\"de\": {\n      \"controls\"")
    let language = try Self.miniature("words.json").replacingOccurrences(
      of: "\"ja\": \"日本語\"", with: "\"JA\": \"日本語\"")

    #expect(Self.refusal(words: number)?.contains("`en.controls.close` is a number") == true)
    #expect(Self.refusal(words: mixed)?.contains("is no counted word") == true)
    #expect(Self.refusal(words: noEnglish)?.contains("carries no English") == true)
    #expect(Self.refusal(words: language)?.contains("`JA`") == true)
  }

  @Test("a colour, a token or a drawing the table cannot hold faithfully is refused")
  func refusesValues() throws {
    let short = try Self.miniature("tokens.json").replacingOccurrences(
      of: "#1c7ed6", with: "#FFF")
    let opacity = try Self.miniature("tokens.json").replacingOccurrences(
      of: "\"opacity\": 0.12", with: "\"opacity\": 1.5")
    let twice = try Self.miniature("tokens.json").replacingOccurrences(
      of: "\"profile-cursor-dash\"", with: "\"control-bg\"")
    let noLight = try Self.miniature("tokens.json").replacingOccurrences(
      of: "\"accent\": { \"light\":", with: "\"accent\": { \"dark\":")
    let token = try Self.miniature("glyphs.json").replacingOccurrences(
      of: "{ \"token\": \"control-bg\" }", with: "{ \"token\": \"control-background\" }")
    let width = try Self.miniature("glyphs.json").replacingOccurrences(
      of: ", \"width\": 1 }", with: " }")
    let glyph = try Self.miniature("glyphs.json").replacingOccurrences(
      of: "\"name\": \"map-pin\"", with: "\"name\": \"airport\"")
    // A stroke set of no width draws nothing (`geo.icons.glyph-set`), where a fill set of none
    // is drawn.
    let noWidth = try Self.miniature("glyphs.json").replacingOccurrences(
      of: "\"strokeWidth\": 2,\n    \"viewBox\": 24,\n    \"glyphs\": [{",
      with: "\"strokeWidth\": 0,\n    \"viewBox\": 24,\n    \"glyphs\": [{")
    let fillNoWidth = noWidth.replacingOccurrences(
      of: "\"paint\": \"stroke\",\n    \"strokeWidth\": 0",
      with: "\"paint\": \"fill\",\n    \"strokeWidth\": 0"
    )

    #expect(Self.refusal(tokens: short)?.contains("six lowercase digits") == true)
    #expect(Self.refusal(tokens: opacity)?.contains("from 0 to 1") == true)
    #expect(Self.refusal(tokens: twice)?.contains("prints as `controlBg`") == true)
    #expect(Self.refusal(tokens: noLight)?.contains("states no light value") == true)
    #expect(Self.refusal(glyphs: token)?.contains("names no colour of the tokens table") == true)
    #expect(Self.refusal(glyphs: width)?.contains("states no `width`") == true)
    #expect(Self.refusal(glyphs: glyph)?.contains("`airport` twice") == true)
    #expect(noWidth != (try Self.miniature("glyphs.json")))
    #expect(Self.refusal(glyphs: noWidth)?.contains("states no `strokeWidth` above 0") == true)
    #expect(Self.refusal(glyphs: fillNoWidth) == nil)
  }

  @Test("a measure, a drawing's opacity, its shadow or a gradient the table cannot hold is refused")
  func refusesLayoutAndArtwork() throws {
    let tokens = try Self.miniature("tokens.json")
    let glyphs = try Self.miniature("glyphs.json")
    let measure = tokens.replacingOccurrences(
      of: "\"panel-width\": 340", with: "\"panel-width\": \"340\"")
    let columns = tokens.replacingOccurrences(
      of: "\"panel-layer-card-columns\": 3", with: "\"panel-layer-card-columns\": 2.5")
    let opacity = glyphs.replacingOccurrences(
      of: "\"opacity\": 0.9,", with: "\"opacity\": 0,")
    let shadow = glyphs.replacingOccurrences(of: "\"blur\": 12.1452, ", with: "")
    let oneStop = glyphs.replacingOccurrences(
      of: "[{ \"offset\": 0, \"hex\": \"#090b0e\" }, ", with: "[")
    let falling = glyphs.replacingOccurrences(
      of: "{ \"offset\": 1, \"hex\": \"#dddbdc\"", with: "{ \"offset\": -1, \"hex\": \"#dddbdc\"")
    let both = glyphs.replacingOccurrences(
      of: "\"fill\": { \"linear\": {", with: "\"fill\": { \"hex\": \"#ffffff\", \"linear\": {")

    #expect(Self.refusal(tokens: measure)?.contains("`layout.panel-width` is no number") == true)
    #expect(Self.refusal(tokens: columns)?.contains("no count of columns") == true)
    #expect(Self.refusal(glyphs: opacity)?.contains("`opacity`") == true)
    #expect(Self.refusal(glyphs: shadow)?.contains("states no `blur`") == true)
    #expect(Self.refusal(glyphs: oneStop)?.contains("holds no two `stops`") == true)
    #expect(Self.refusal(glyphs: falling)?.contains("states no `offset`") == true)
    #expect(Self.refusal(glyphs: both)?.contains("beside a colour") == true)
  }

  @Test("a notice carrying no ISC and MIT licence is refused")
  func refusesNotice() {
    #expect(
      Self.refusal(notice: "Lucide is licensed.\n")?.contains("carries no ISC and MIT licence")
        == true)
  }
}
