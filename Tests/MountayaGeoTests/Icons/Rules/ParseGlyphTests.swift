import Testing

@testable import MountayaGeo

@Suite("parseGlyph")
struct ParseGlyphTests {
  private func shape(_ tag: String, attributes: KeyValuePairs<String, String> = [:]) -> GlyphShape {
    GlyphShape(tag: tag, attributes: Dictionary(uniqueKeysWithValues: attributes.map { ($0, $1) }))
  }

  @Test("a shape keeps the attributes on the list, quoted either way")
  func quoted() {
    #expect(parseGlyph(#"<path d="M5 12h14" />"#) == [shape("path", attributes: ["d": "M5 12h14"])])
    #expect(
      parseGlyph(#"<circle cx='12' cy="12" r = '10' />"#)
        == [shape("circle", attributes: ["cx": "12", "cy": "12", "r": "10"])])
    #expect(
      parseGlyph(#"<circle cx="1"cy='2'r="3"/>"#)
        == [shape("circle", attributes: ["cx": "1", "cy": "2", "r": "3"])])
    #expect(
      parseGlyph(#"<path id='a"b' d="M0 0h1" /><path id="a>b" d='M1 1h1' />"#)
        == [shape("path", attributes: ["d": "M0 0h1"]), shape("path", attributes: ["d": "M1 1h1"])])
  }

  @Test("an attribute off the list is dropped")
  func offTheList() {
    #expect(
      parseGlyph(#"<path d="M5 12h14" onload="alert(1)" />"#) == [
        shape("path", attributes: ["d": "M5 12h14"])
      ])
    #expect(
      parseGlyph(#"<circle cx="1" cy="2" r="3" style="fill:red" />"#)
        == [shape("circle", attributes: ["cx": "1", "cy": "2", "r": "3"])])
    #expect(
      parseGlyph(#"<rect width="4" height="4" sodipodi:rx="9" xlink:x="3" />"#)
        == [shape("rect", attributes: ["width": "4", "height": "4"])])
    #expect(
      parseGlyph(#"<rect width="4" 1:rx="9" -x="3" .y="2" 9d="M0 0" />"#)
        == [shape("rect", attributes: ["width": "4"])])
    // A name with no quoted value is skipped whole, and a name written twice keeps its last value.
    #expect(
      parseGlyph(#"<rect width=1 height="3" width="2" />"#)
        == [shape("rect", attributes: ["width": "2", "height": "3"])])
    // The white space around `=` is the ECMAScript set: a no-break space is one, U+0085 is none.
    #expect(
      parseGlyph("<rect width\u{A0}=\u{FEFF}\"5\" />") == [
        shape("rect", attributes: ["width": "5"])
      ])
    #expect(parseGlyph("<rect width\u{85}=\"5\" />") == [shape("rect")])
  }

  @Test("a fill is kept only as the current colour or none")
  func fill() {
    #expect(
      parseGlyph(#"<circle r="1" FILL='CURRENTCOLOR' />"#)
        == [shape("circle", attributes: ["r": "1", "fill": "CURRENTCOLOR"])])
    #expect(
      parseGlyph(#"<path d="M0 0" fill=" none " />"#)
        == [shape("path", attributes: ["d": "M0 0", "fill": "none"])])
    #expect(
      parseGlyph(##"<path d="M0 0" fill="#ff0000" />"##) == [
        shape("path", attributes: ["d": "M0 0"])
      ])
    #expect(
      parseGlyph(#"<path d="M0 0" fill="url(#a)" />"#) == [shape("path", attributes: ["d": "M0 0"])]
    )
  }

  @Test("a stroke is kept only as the current colour or none, and never a stroke's width")
  func stroke() {
    #expect(
      parseGlyph(#"<path d="M0 0h1" stroke="CurrentColor"/><circle r="1" stroke=" NONE "/>"#)
        == [
          shape("path", attributes: ["d": "M0 0h1", "stroke": "CurrentColor"]),
          shape("circle", attributes: ["r": "1", "stroke": "NONE"]),
        ])
    #expect(
      parseGlyph(##"<path d="M0 0h1" stroke="#e9501e"/><path d="M1 1h1" stroke="url(#paint)"/>"##)
        == [shape("path", attributes: ["d": "M0 0h1"]), shape("path", attributes: ["d": "M1 1h1"])])
    #expect(
      parseGlyph(#"<path d="M0 0h1" stroke="currentColor" stroke-width="4" STROKE-WIDTH="1"/>"#)
        == [shape("path", attributes: ["d": "M0 0h1", "stroke": "currentColor"])])
    // A tab and a line feed are white space around `=` and at a keyword's ends.
    #expect(
      parseGlyph("<path d=\"M0 0\" stroke\t=\n\"\tnone\n\"/>")
        == [shape("path", attributes: ["d": "M0 0", "stroke": "none"])])
  }

  @Test("a cap and a join are kept only as the keywords SVG names them with, in any case")
  func lineEnds() {
    #expect(
      parseGlyph(#"<path d="M0 0h1" stroke-linecap="Square" stroke-linejoin=" bevel "/>"#)
        == [
          shape(
            "path",
            attributes: ["d": "M0 0h1", "stroke-linecap": "Square", "stroke-linejoin": "bevel"])
        ])
    #expect(
      parseGlyph(#"<path d="M0 0h1" stroke-linecap="BUTT" stroke-linejoin="Miter-Clip"/>"#)
        == [
          shape(
            "path",
            attributes: ["d": "M0 0h1", "stroke-linecap": "BUTT", "stroke-linejoin": "Miter-Clip"])
        ])
    #expect(
      parseGlyph(
        #"<path d="M0 0h1" stroke-linejoin="arcs"/><path d="M0 0" stroke-linejoin="round"/>"#)
        == [
          shape("path", attributes: ["d": "M0 0h1", "stroke-linejoin": "arcs"]),
          shape("path", attributes: ["d": "M0 0", "stroke-linejoin": "round"]),
        ])
    #expect(
      parseGlyph(#"<path d="M1 1h1" stroke-linecap="flat" stroke-linejoin="sharp"/>"#)
        == [shape("path", attributes: ["d": "M1 1h1"])])
    // A letter outside ASCII is no keyword's, whatever a full case mapping folds it to.
    #expect(
      parseGlyph("<path d=\"M0 0\" stroke-linejoin=\"m\u{130}ter\"/>") == [
        shape("path", attributes: ["d": "M0 0"])
      ])
  }

  @Test("a miter limit is kept only as a plain number of at least 1, as written")
  func miterLimit() {
    func limit(_ written: String) -> String? {
      parseGlyph("<path d=\"M0 0\" stroke-miterlimit=\"\(written)\"/>").first?
        .attributes["stroke-miterlimit"]
    }

    #expect(limit("1") == "1")
    #expect(limit(" 4.5 ") == "4.5")
    #expect(limit("4.") == "4.")
    #expect(limit("10") == "10")
    #expect(limit("007") == "007")
    #expect(limit("1.0") == "1.0")
    #expect(limit("0.5") == nil)
    #expect(limit(".5") == nil)
    #expect(limit("0") == nil)
    #expect(limit("10px") == nil)
    #expect(limit("+10") == nil)
    #expect(limit("-1") == nil)
    #expect(limit("1e1") == nil)
    #expect(limit("1.5.5") == nil)
    #expect(limit(".") == nil)
    #expect(limit("") == nil)
    #expect(limit("inf") == nil)
    #expect(limit("0x10") == nil)
    // A digit of another script is no ASCII digit.
    #expect(limit("\u{0664}") == nil)
  }

  @Test("an attribute written twice keeps the later of its values a glyph may carry")
  func writtenTwice() {
    #expect(
      parseGlyph(#"<path d="M0 0h1" d="M5 5h1"/>"#) == [shape("path", attributes: ["d": "M5 5h1"])])
    #expect(
      parseGlyph(#"<path d="M0 0" stroke="none" stroke="currentColor"/>"#)
        == [shape("path", attributes: ["d": "M0 0", "stroke": "currentColor"])])
    #expect(
      parseGlyph(##"<path d="M0 0" stroke="none" stroke="#fff"/>"##)
        == [shape("path", attributes: ["d": "M0 0", "stroke": "none"])])
    #expect(
      parseGlyph(#"<path d="M0 0" stroke-miterlimit="8" stroke-miterlimit="0.5"/>"#)
        == [shape("path", attributes: ["d": "M0 0", "stroke-miterlimit": "8"])])
  }

  @Test("a tag whose name carries a namespace prefix reads as the prefix")
  func namespacedTag() {
    #expect(parseGlyph(#"<svg:path d="M0 0h1"/>"#).isEmpty)
    #expect(
      parseGlyph(#"<svg:g transform="scale(2)"><path d="M0 0"/></svg:g>"#)
        == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(#"<dc:title>hut</dc:title><path d="M0 0"/>"#) == [
        shape("path", attributes: ["d": "M0 0"])
      ])
  }

  @Test("a value the parse keeps is the one keptGlyphValue keeps, whoever built the shape")
  func keptValues() {
    #expect(keptGlyphValue("d", value: " M0 0 ") == " M0 0 ")
    #expect(keptGlyphValue("fill", value: " currentColor ") == "currentColor")
    #expect(keptGlyphValue("stroke", value: "red") == nil)
    #expect(keptGlyphValue("stroke-linecap", value: "round") == "round")
    #expect(keptGlyphValue("stroke-miterlimit", value: "4") == "4")
    #expect(keptGlyphValue("stroke-miterlimit", value: "0.99") == nil)
  }

  @Test("a group's transform is folded outermost first, and before the shape's own")
  func transform() {
    #expect(
      parseGlyph(#"<g transform="translate(2 2)"><path d="M0 0h1" transform="scale(3)" /></g>"#)
        == [shape("path", attributes: ["d": "M0 0h1", "transform": "translate(2 2) scale(3)"])])
    #expect(
      parseGlyph(
        #"<g transform="translate(2 2)"><g transform="scale(3)"><path d="M0 0h1" /></g></g>"#)
        == [shape("path", attributes: ["d": "M0 0h1", "transform": "translate(2 2) scale(3)"])])
    #expect(
      parseGlyph(#"<g><path d="M5 12h14" /></g>"#) == [shape("path", attributes: ["d": "M5 12h14"])]
    )
    #expect(
      parseGlyph(#"<g transform="scale(3)" /><path d="M5 12h14" />"#)
        == [shape("path", attributes: ["d": "M5 12h14"])])
    #expect(
      parseGlyph(#"<svg viewBox="0 0 24 24"><path d="M5 12h14" /></svg>"#)
        == [shape("path", attributes: ["d": "M5 12h14"])])
  }

  @Test("an element that is no shape is dropped with all it holds")
  func dropped() {
    #expect(
      parseGlyph(#"<script>alert(1)</script><path d="M5 12h14" />"#)
        == [shape("path", attributes: ["d": "M5 12h14"])])
    #expect(parseGlyph(#"<image href="https://example.invalid/pixel.gif" />"#).isEmpty)
    #expect(parseGlyph(#"<foreignObject><div>hi</div></foreignObject>"#).isEmpty)
    #expect(
      parseGlyph(
        #"<defs><defs><rect width="1" /></defs><rect width="2" /></defs><path d="M0 0" />"#)
        == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(#"<path d="M0 0"><circle r="1" /></path><rect width="2" />"#)
        == [shape("path", attributes: ["d": "M0 0"]), shape("rect", attributes: ["width": "2"])])
  }

  /// Never closed, an element holds nothing: dropped alone, a shape kept alone, a group handing on
  /// nothing.
  @Test("an element the markup never closes holds nothing")
  func neverClosed() {
    #expect(
      parseGlyph(#"<path d="M0 0"><circle r="1" />"#)
        == [shape("path", attributes: ["d": "M0 0"]), shape("circle", attributes: ["r": "1"])])
    #expect(
      parseGlyph(#"<path d="M0 0" /><img src="x" onerror="alert(1)"><circle r="3" />"#)
        == [shape("path", attributes: ["d": "M0 0"]), shape("circle", attributes: ["r": "3"])])
    #expect(
      parseGlyph(#"<g transform="translate(2 2)"><path d="M0 0" />"#)
        == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(
        #"<g transform="scale(2)"><path d="M0 0" /><g transform="rotate(5)"><circle r="1" /></g><rect width="2" />"#
      )
        == [
          shape("path", attributes: ["d": "M0 0"]),
          shape("circle", attributes: ["r": "1", "transform": "rotate(5)"]),
          shape("rect", attributes: ["width": "2"]),
        ])
  }

  @Test("a closing group tag ends the group it is paired with, wherever it is written")
  func pairedClosing() {
    #expect(
      parseGlyph(#"<g transform="scale(2)"><mask></g></mask><path d="M0 0"/>"#)
        == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(#"<g transform="scale(2)"><path d="M1 1"></g></path><circle r="1"/>"#)
        == [
          shape("path", attributes: ["d": "M1 1", "transform": "scale(2)"]),
          shape("circle", attributes: ["r": "1"]),
        ])
    #expect(
      parseGlyph(#"<g transform="rotate(9)"><mask><g></mask></g><path d="M0 0"/></g>"#)
        == [shape("path", attributes: ["d": "M0 0", "transform": "rotate(9)"])])
    #expect(
      parseGlyph(#"<g transform="rotate(9)"></g></g><path d="M0 0"/>"#)
        == [shape("path", attributes: ["d": "M0 0"])])
  }

  @Test("a comment or a CDATA section is white space")
  func comments() {
    #expect(
      parseGlyph(#"<!-- <circle r="1" /> --><path d="M0 0" /><![CDATA[<rect width="1" />]]>"#)
        == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(#"<path d="M0 0" /><!-- <path d="M1 1" />"#) == [
        shape("path", attributes: ["d": "M0 0"])
      ])
    #expect(parseGlyph(#"<pa<!-- -->th d="M0 0"/>"#).isEmpty)
    #expect(parseGlyph(#"<<!-- -->path d="M0 0"/>"#).isEmpty)
    #expect(
      parseGlyph(#"<path<!-- a -->d="M0 0"<!-- b -->/><!-- c --><circle r="1"/>"#)
        == [shape("path", attributes: ["d": "M0 0"]), shape("circle", attributes: ["r": "1"])])
  }

  @Test("a tag the markup never ends is no tag")
  func neverEnded() {
    #expect(parseGlyph(#"<a "<path d="M0 0" />"#) == [shape("path", attributes: ["d": "M0 0"])])
    #expect(
      parseGlyph(#"<circle r="1" /><path d="M0 0"#) == [shape("circle", attributes: ["r": "1"])])
    #expect(parseGlyph("< path d=\"M0 0\" />").isEmpty)
    #expect(parseGlyph("").isEmpty)
    // A long run of tags that never end is read in one pass.
    #expect(parseGlyph(String(repeating: "<a \"", count: 20_000)).isEmpty)
  }

  /// A carriage return and a line feed are one `Character` and two scalars; the scanner reads
  /// scalars, so the white space between attributes is read as any other.
  @Test("the markup is read scalar by scalar")
  func scalars() {
    #expect(
      parseGlyph("<circle\r\ncx=\"1\"\r\nr=\"2\"/>") == [
        shape("circle", attributes: ["cx": "1", "r": "2"])
      ])
    #expect(
      parseGlyph("<path d=\"M0 0\u{301}\" />") == [shape("path", attributes: ["d": "M0 0\u{301}"])])
  }

  @Test("the lists are the ones a renderer covers")
  func lists() {
    #expect(glyphAttributes.count == 23)
    #expect(
      glyphAttributes.isSuperset(of: [
        "stroke", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit",
      ]))
    #expect(!glyphAttributes.contains("stroke-width"))
    #expect(glyphShapeTags == ["circle", "ellipse", "line", "path", "polygon", "polyline", "rect"])
    // Each shape is read as a shape when it is written alone.
    for tag in glyphShapeTags {
      #expect(parseGlyph("<\(tag)/>") == [shape(tag)])
    }
  }
}
