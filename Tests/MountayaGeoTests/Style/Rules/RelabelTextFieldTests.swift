import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("relabelTextField")
struct RelabelTextFieldTests {
  private let name = #"["coalesce", ["get", "name:fr"], ["get", "name"]]"#

  private func relabel(_ textField: String) throws -> JSONValue? {
    relabelTextField(try json(textField), language: .fr)
  }

  @Test("a read of a name field reads the language's name, falling back to the default")
  func nameRead() throws {
    #expect(try relabel(#"["get", "name"]"#) == json(name))
    #expect(try relabel(#"["get", "name:latin"]"#) == json(name))
    #expect(try relabel(#"["get", "name_en"]"#) == json(name))
    #expect(try relabel(#""{name}""#) == json(name))
    #expect(try relabel(#"["coalesce", ["get", "name:en"], ["get", "name"]]"#) == json(name))
    #expect(
      relabelTextField(try json(#""{name}""#), language: .ja)
        == (try json(#"["coalesce", ["get", "name:ja"], ["get", "name"]]"#)))
  }

  @Test("the rest of the label stays")
  func restStays() throws {
    #expect(
      try relabel(#""{name}\n{ele} m""#)
        == json(#"["concat", \#(name), "\n", ["get", "ele"], " m"]"#))
    #expect(
      try relabel(#"["step", ["zoom"], "", 10, ["get", "name"]]"#)
        == json(#"["step", ["zoom"], "", 10, \#(name)]"#))
    #expect(
      try relabel(
        #"["format", ["get", "name"], {"font-scale": 1.2}, "\n", {}, ["get", "ref"], {"font-scale": 0.8}]"#
      )
        == json(
          #"["format", \#(name), {"font-scale": 1.2}, "\n", {}, ["get", "ref"], {"font-scale": 0.8}]"#
        ))
    // A match's input and labels decide, and stay; each output says the name, and an output
    // standing where the label does is the name alone rather than a row of one.
    #expect(
      try relabel(
        #"["match", ["get", "class"], "peak", ["concat", ["get", "name"]], ["get", "ref"]]"#)
        == json(#"["match", ["get", "class"], "peak", \#(name), ["get", "ref"]]"#))
    #expect(try relabel(#"["upcase", ["get", "name"]]"#) == json(#"["upcase", \#(name)]"#))
  }

  @Test("names joined by white space read as one name")
  func joinedNames() throws {
    #expect(try relabel(#""{name:latin}\n{name:nonlatin}""#) == json(name))
    #expect(
      try relabel(#"["concat", ["get", "name:latin"], " ", ["get", "name:nonlatin"]]"#)
        == json(name))
    // A row of names and white space keeps the first name's options in a format.
    #expect(
      try relabel(
        #"["format", ["get", "name:latin"], {"font-scale": 1.2}, "\n", ["get", "name:nonlatin"]]"#
      ) == json(#"["format", \#(name), {"font-scale": 1.2}]"#))
  }

  /// Where nothing and a string differ, the name standing for a row is a concat of one.
  @Test("a row that is the name alone under an operand is a concat of one")
  func concatOfOne() throws {
    #expect(
      try relabel(
        #"["upcase", ["concat", ["get", "name:latin"], "\n", ["get", "name:nonlatin"]]]"#)
        == json(#"["upcase", ["concat", \#(name)]]"#))
    #expect(
      try relabel(#"["concat", "\n", ["get", "name"], " "]"#)
        == json(#"["concat", "\n", \#(name), " "]"#))
  }

  @Test("a label that reads no name, or that already reads the language, is left alone")
  func leftAlone() throws {
    #expect(try relabel(#"["get", "ref"]"#) == nil)
    #expect(try relabel(#"["get", "place_name"]"#) == nil)
    #expect(try relabel(#""{ref}""#) == nil)
    #expect(try relabel(#""Summit""#) == nil)
    #expect(try relabel("12") == nil)
    #expect(try relabel(name) == nil)
    #expect(relabelTextField(nil, language: .fr) == nil)
    #expect(relabelTextField(.null, language: .fr) == nil)
    // A variant ends at no line terminator, as an ECMAScript `.` reads one.
    #expect(try relabel(#"["get", "name: "]"#) == nil)
    #expect(try relabel(#"["get", "name:"]"#) == nil)
  }

  @Test("a name the walk cannot rewrite without saying it twice or dropping text is left alone")
  func unfoldable() throws {
    #expect(try relabel(#""{name} ({name:en})""#) == nil)
    #expect(try relabel(#""{name} {ref} {name:en}""#) == nil)
    #expect(try relabel(#"["slice", ["get", "name"], 0, 3]"#) == nil)
    #expect(try relabel(#"["let", "n", ["get", "name"], ["var", "n"]]"#) == nil)
    // A separator written as a literal is text, and a name on each side of it is twice.
    #expect(
      try relabel(#"["concat", ["get", "name"], ["literal", " / "], ["get", "name:en"]]"#) == nil)
  }

  @Test("a legacy function is the name alone only where every stop is")
  func legacyFunction() throws {
    #expect(try relabel(#"{"stops": [[8, "{name}"], [12, "{name:latin}"]]}"#) == json(name))
    #expect(try relabel(#"{"stops": [[8, "{name}"], [12, "{ref}"]]}"#) == nil)
    #expect(try relabel(#"{"base": 1}"#) == nil)
  }

  @Test("a let's result is walked, and its bindings stay")
  func letResult() throws {
    #expect(
      try relabel(#"["let", "size", 2, ["get", "name"]]"#)
        == json(#"["let", "size", 2, \#(name)]"#))
  }

  /// Empty braces and a brace never closed are text, and a token reads from the last brace opened.
  @Test("a token is a field in braces, read from the brace nearest it")
  func tokens() throws {
    #expect(
      try relabel(#""{}{name}""#) == json(#"["concat", "{}", \#(name)]"#))
    #expect(try relabel(#""{{name}""#) == json(#"["concat", "{", \#(name)]"#))
    #expect(try relabel(#""{name""#) == nil)
  }

  @Test("a label nested past the limit is left alone")
  func depth() throws {
    func nested(_ depth: Int) -> String {
      String(repeating: #"["upcase", "#, count: depth - 1) + #"["get", "name"]"#
        + String(repeating: "]", count: depth - 1)
    }
    #expect(
      try relabel(nested(maxLabelDepth))
        == json(nested(maxLabelDepth).replacingOccurrences(of: #"["get", "name"]"#, with: name)))
    #expect(try relabel(nested(maxLabelDepth + 1)) == nil)
    // Built without a parser, a label ten thousand arrays deep is read with no recursion at all.
    var deep: JSONValue = try json(#"["get", "name"]"#)
    for _ in 0..<10_000 {
      deep = .array([.string("upcase"), deep])
    }
    #expect(relabelTextField(deep, language: .fr) == nil)
    // Swift releases nested arrays by recursion, so the test takes the label apart one level at a
    // time rather than let its release reach the end of the stack.
    while case .array(let elements) = deep, elements.count == 2 {
      deep = elements[1]
    }
  }
}
