import Foundation
import GateSupport
import MountayaClient
import Testing

@testable import MountayaGeo

/// The elements' data `MountayaGeo` publishes against the tables in the contract checkout, table
/// by table: every word, endonym, token, glyph and drawing the table holds is printed, as the
/// table writes it, and nothing else is. A printer that dropped a section, a dark value or a glyph
/// would compile and draw the elements a little wrong in no test's sight.
@Suite("Elements data")
struct ElementsDataTests {
  private static func table(_ file: String) throws -> OrderedJSON? {
    guard let checkout = try Conformance.contract.get()?.checkout else { return nil }
    let url = checkout.directory.appendingPathComponent("sdk/elements/\(file)")
    let text = try #require(SourceTree.read(url), "sdk/elements/\(file) cannot be read")
    return try OrderedJSON.parse(text)
  }

  /// words lists a table's words by path, `controls.close`, a counted word's forms each a path of
  /// their own.
  private static func words(_ json: OrderedJSON, path: String = "") -> [String: String] {
    var words: [String: String] = [:]
    for member in json.members ?? [] where member.key != "//" {
      let place = path.isEmpty ? member.key : "\(path).\(member.key)"
      if let word = member.value.stringValue {
        words[place] = word
      } else {
        words.merge(Self.words(member.value, path: place)) { first, _ in first }
      }
    }
    return words
  }

  /// words lists printed words by path, as the table's are listed.
  private static func words(_ tree: [String: JSONValue], path: String = "") -> [String: String] {
    var words: [String: String] = [:]
    for (key, value) in tree {
      let place = path.isEmpty ? key : "\(path).\(key)"
      switch value {
      case .string(let word): words[place] = word
      case .object(let section): words.merge(Self.words(section, path: place)) { first, _ in first }
      default: words[place] = "\(value)"
      }
    }
    return words
  }

  /// color reads a table's colour as the printed one is compared.
  private static func color(_ json: OrderedJSON?) -> HexColor? {
    guard let hex = json?["hex"]?.stringValue else { return nil }
    return HexColor(hex: hex, opacity: json?["opacity"]?.numberValue ?? 1)
  }

  @Test("the words are the table's, word for word, in every language it carries")
  func words() throws {
    guard let table = try Self.table("words.json") else { return }
    let languages = try #require(table["languages"]?.members)
    let bundle = WordBundle.elements

    #expect(bundle.translations.count + 1 == languages.count)
    #expect(bundle.partial.isEmpty)
    for language in languages {
      let printed =
        language.key == "en"
        ? bundle.english : bundle.translations[RestSchema.Language(rawValue: language.key)]
      let expected = Self.words(language.value)

      #expect(printed != nil, "\(language.key) is not printed")
      #expect(Self.words(printed ?? [:]) == expected, "\(language.key)")
      #expect(expected.count >= 150, "\(language.key) holds \(expected.count) words")
    }
  }

  @Test("every word stands in every language the words print, under the same keys")
  func sameKeys() {
    let english = Set(Self.words(WordBundle.elements.english).keys)

    #expect(!WordBundle.elements.translations.isEmpty)
    for (language, words) in WordBundle.elements.translations {
      #expect(Set(Self.words(words).keys) == english, "\(language.rawValue)")
    }
  }

  @Test("each label language's endonym is the table's")
  func endonyms() throws {
    guard let table = try Self.table("words.json") else { return }
    let endonyms = try #require(table["endonyms"]?.members)

    #expect(languageEndonyms.count == endonyms.count)
    for endonym in endonyms {
      #expect(
        languageEndonyms[RestSchema.Language(rawValue: endonym.key)] == endonym.value.stringValue,
        "\(endonym.key)")
    }
    #expect(Set(labelLanguages).isSubset(of: Set(languageEndonyms.keys)))
  }

  @Test("every token is the table's, light and dark, and no other is printed")
  func tokens() throws {
    guard let table = try Self.table("tokens.json") else { return }
    let standard = ElementTokens.standard
    let colors = try #require(table["colors"]?.members)
    let shadows = try #require(table["shadows"]?.members)
    let dashes = try #require(table["dashes"]?.members)

    #expect(Set(ElementTokens.colorTokens.keys) == Set(colors.map(\.key)))
    #expect(Set(ElementTokens.shadowTokens.keys) == Set(shadows.map(\.key)))
    #expect(Set(ElementTokens.dashTokens.keys) == Set(dashes.map(\.key)))
    for token in colors {
      guard let path = ElementTokens.colorTokens[token.key] else { continue }
      let printed = standard[keyPath: path]
      #expect(printed.light == Self.color(token.value["light"]), "\(token.key)")
      #expect(printed.dark == Self.color(token.value["dark"]), "\(token.key)")
    }
    for token in shadows {
      guard let path = ElementTokens.shadowTokens[token.key] else { continue }
      let printed = standard[keyPath: path]
      #expect(
        printed.light == token.value["light"]?.elements?.compactMap { Self.color($0) },
        "\(token.key)")
      #expect(printed.dark == token.value["dark"]?.elements?.compactMap { Self.color($0) })
    }
    for token in dashes {
      guard let path = ElementTokens.dashTokens[token.key] else { continue }
      let printed = standard[keyPath: path]
      #expect(printed.light == token.value["light"]?.elements?.compactMap(\.numberValue))
      #expect(printed.dark == token.value["dark"]?.elements?.compactMap(\.numberValue))
    }
  }

  @Test("every measure is the table's layout, and no other is printed")
  func layout() throws {
    guard let table = try Self.table("tokens.json") else { return }
    let layout = try #require(table["layout"]?.members)

    #expect(ElementLayout.measures.count == layout.count)
    for measure in layout {
      #expect(ElementLayout.measures[measure.key] == measure.value.numberValue, "\(measure.key)")
    }
    #expect(ElementLayout.panelWidth == ElementLayout.measures["panel-width"])
    #expect(
      Double(ElementLayout.panelLayerCardColumns)
        == layout.first {
          $0.key == "panel-layer-card-columns"
        }?.value.numberValue)
  }

  @Test("the theme-tokens runner reaches each token by the member the printed table names")
  func runnerTokens() {
    let colors = GeoControlFixtures.colorTokens
    let shadows = GeoControlFixtures.shadowTokens
    let dashes = GeoControlFixtures.dashTokens

    #expect(Set(colors.keys) == Set(ElementTokens.colorTokens.keys))
    #expect(Set(shadows.keys) == Set(ElementTokens.shadowTokens.keys))
    #expect(Set(dashes.keys) == Set(ElementTokens.dashTokens.keys))
    for (name, path) in colors {
      #expect(ElementTokens.colorTokens[name].map { $0 as AnyKeyPath } == path, "\(name)")
    }
    for (name, path) in shadows {
      #expect(ElementTokens.shadowTokens[name].map { $0 as AnyKeyPath } == path, "\(name)")
    }
    for (name, path) in dashes {
      #expect(ElementTokens.dashTokens[name].map { $0 as AnyKeyPath } == path, "\(name)")
    }
  }

  @Test("each glyph set is the table's, glyph for glyph", arguments: ["marker", "control"])
  func glyphSets(set: String) throws {
    guard let table = try Self.table("glyphs.json") else { return }
    let expected = try #require(table[set])
    let printed = set == "marker" ? GlyphSet.marker : GlyphSet.control
    let glyphs = try #require(expected["glyphs"]?.elements)

    #expect(printed.paint.rawValue == expected["paint"]?.stringValue)
    #expect(printed.strokeWidth == expected["strokeWidth"]?.numberValue)
    #expect(printed.viewBox == expected["viewBox"]?.numberValue)
    #expect(printed.markup.count == glyphs.count)
    for glyph in glyphs {
      let name = try glyph.string(at: "name")
      #expect(printed.markup[name] == (try glyph.string(at: "markup")), "\(name)")
    }
  }

  @Test("each drawing is the table's, shape for shape and paint for paint")
  func artwork() throws {
    guard let table = try Self.table("glyphs.json") else { return }
    let drawings = try #require(table["artwork"]?.elements)
    /// printedPaint reads a printed paint back as the table writes one.
    func printedPaint(_ paint: GlyphDrawing.Paint?) -> [String: String] {
      guard let paint else { return [:] }
      switch paint {
      case .color(let color):
        return ["hex": color.hex, "opacity": "\(color.opacity)"]
      case .token(let path, let opacity):
        let name = ElementTokens.colorTokens.first {
          ($0.value as AnyKeyPath) == (path as AnyKeyPath)
        }
        return ["token": name?.key ?? "?", "opacity": "\(opacity)"]
      case .linear(let gradient):
        let stops = gradient.stops.map { "\($0.offset) \($0.color.hex) \($0.color.opacity)" }
        return [
          "linear": "\(gradient.from) \(gradient.to) \(stops.joined(separator: ", "))"
        ]
      }
    }
    /// tablePaint reads a table's paint, its opacity 1 where it states none.
    func tablePaint(_ json: OrderedJSON?) -> [String: String] {
      guard let json else { return [:] }
      if let linear = json["linear"] {
        let point = { (key: String) in linear[key]?.elements?.compactMap(\.numberValue) ?? [] }
        let stops = (linear["stops"]?.elements ?? []).map { stop in
          "\(stop["offset"]?.numberValue ?? .nan) \(stop["hex"]?.stringValue ?? "?") "
            + "\(stop["opacity"]?.numberValue ?? 1)"
        }
        return ["linear": "\(point("from")) \(point("to")) \(stops.joined(separator: ", "))"]
      }
      var read = ["opacity": "\(json["opacity"]?.numberValue ?? 1)"]
      read["hex"] = json["hex"]?.stringValue
      read["token"] = json["token"]?.stringValue
      return read
    }

    #expect(GlyphDrawing.artwork.count == drawings.count)
    for drawing in drawings {
      let name = try drawing.string(at: "name")
      let printed = try #require(GlyphDrawing.artwork[name], "\(name)")
      let shapes = try #require(drawing["shapes"]?.elements)

      #expect(printed.viewBox == drawing["viewBox"]?.elements?.compactMap(\.numberValue))
      #expect(printed.opacity == drawing["opacity"]?.numberValue ?? 1, "\(name)")
      let shadow = drawing["shadow"]
      #expect(printed.shadow?.blur == shadow?["blur"]?.numberValue, "\(name)")
      #expect(printed.shadow?.dx == shadow?["dx"]?.numberValue, "\(name)")
      #expect(printed.shadow?.dy == shadow?["dy"]?.numberValue, "\(name)")
      #expect(printed.shadow?.color == Self.color(shadow), "\(name)")
      #expect(printed.shapes.count == shapes.count, "\(name)")
      for (shape, expected) in zip(printed.shapes, shapes) {
        #expect(shape.markup == (try expected.string(at: "markup")), "\(name)")
        #expect(printedPaint(shape.fill) == tablePaint(expected["fill"]), "\(name)")
        #expect(printedPaint(shape.stroke) == tablePaint(expected["stroke"]), "\(name)")
        #expect(shape.strokeWidth == expected["stroke"]?["width"]?.numberValue, "\(name)")
      }
    }
  }
}
