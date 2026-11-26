/// glyphShapeTags are the SVG shapes a glyph may hold, the only elements a parsed glyph answers.
public let glyphShapeTags: Set<String> = [
  "circle", "ellipse", "line", "path", "polygon", "polyline", "rect",
]

/// glyphAttributes are every attribute a glyph's shape keeps: its geometry, its fill rules, a fill
/// and a stroke that name no colour of their own, and how a stroked line ends and turns, and
/// nothing else, so no style, no handler, no reference and no namespaced attribute survives. A
/// stroke's width is not among them: the width is the set's, so no glyph draws heavier than the
/// set it belongs to. A renderer that maps them onto its own names covers every one.
public let glyphAttributes: Set<String> = [
  "clip-rule", "cx", "cy", "d", "fill", "fill-rule", "height", "points", "r", "rx", "ry",
  "stroke", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "transform", "width", "x",
  "x1", "x2", "y", "y1", "y2",
]

/// The values an attribute read as a keyword may state, compared with the ASCII capitals folded,
/// by the attribute: a fill and a stroke name no colour of their own, the current colour or none,
/// and a line's cap and join are the keywords SVG spells them with.
private let glyphKeywords: [String: Set<String>] = [
  "fill": ["currentcolor", "none"],
  "stroke": ["currentcolor", "none"],
  "stroke-linecap": ["butt", "round", "square"],
  "stroke-linejoin": ["arcs", "bevel", "miter", "miter-clip", "round"],
]

/// The attribute whose value is kept only as a plain number of at least 1.
private let miterLimitAttribute = "stroke-miterlimit"

/// keptGlyphValue is the value an attribute of `glyphAttributes` is kept with, or `nil` for one a
/// glyph may not carry.
///
/// A fill, a stroke, a cap and a join are kept, past the white space at their ends, where the
/// value is one of the keywords the attribute takes in any letter case, as written. A miter limit
/// is kept, past the same white space, where it is a plain number of at least 1: ASCII digits with
/// at most one decimal point, a digit on one side of it at least, and no sign, unit or exponent, so
/// `4.` and `.5` are numbers and `+10`, `1e1` and `10px` are not, and `.5` is below 1. Every other
/// attribute is kept as written. `glyphPaint(_:in:)` reads a shape's own paint through it, so a
/// value the parse would drop is no statement, whoever built the shape.
func keptGlyphValue(_ name: String, value: String) -> String? {
  if let keywords = glyphKeywords[name] {
    let keyword = trimWhiteSpace(value)
    return keywords.contains(asciiLowercase(keyword)) ? keyword : nil
  }
  guard name == miterLimitAttribute else { return value }
  let limit = trimWhiteSpace(value)
  guard isPlainNumber(limit), let number = Double(limit), number >= 1 else { return nil }
  return limit
}

/// Whether `text` is a plain number: ASCII digits with at most one decimal point, and a digit on one
/// side of it at least.
private func isPlainNumber(_ text: String) -> Bool {
  var digits = 0
  var points = 0
  for scalar in text.unicodeScalars {
    if ("0"..."9").contains(scalar) {
      digits += 1
    } else if scalar == ".", points == 0 {
      points += 1
    } else {
      return false
    }
  }
  return digits > 0
}

/// A group, read for its transform and never answered.
private let groupTag = "g"

/// The document element, read through.
private let documentTag = "svg"

/// parseGlyph reads `markup`, a glyph's inner SVG markup as an icon set answers it, into the shapes
/// a renderer builds, in document order, with nothing of it executed or fetched.
///
/// A shape (one of `glyphShapeTags`) is read at the top level, inside a group and inside an `svg`
/// wrapper. It keeps the attributes of `glyphAttributes`, quoted either way, with white space
/// around the `=` or none, and keyed lowercase: a `fill` or a `stroke` only where it is
/// `currentColor` or `none`, a `stroke-linecap` or a `stroke-linejoin` only as a keyword SVG names
/// it with, each in any letter case, and a `stroke-miterlimit` only as a plain number of at least
/// 1, each kept as written past the white space at its ends (`keptGlyphValue(_:value:)`). Every group
/// around it hands it its `transform`, outermost first and before its own, joined by a space.
/// Everything else is dropped: an attribute off the list, a `stroke-width` among them, a name
/// holding a namespace or opening with a digit, a hyphen or a dot, and an element that is neither
/// a shape nor a group with all it holds, up to the tag that closes it, since SVG draws nothing
/// inside a `defs`, a `clipPath` or a `mask`. A tag whose name carries a namespace prefix reads as
/// the prefix alone, so `<svg:path>` is an `svg` wrapper and no shape. A shape is no container, so
/// what it holds is dropped too. An element the markup never closes holds nothing and is dropped
/// alone, so a group it never closes hands its transform to no shape. A name written twice keeps
/// the later of its values a glyph may carry.
///
/// A comment and a CDATA section, to their end or to the end of the markup where they never end,
/// read as one space: they hold no shape, and one written inside a name splits it. A tag is `<`, an
/// optional `/`, then its name at once; one the markup never ends, past its quoted values, is no
/// tag, and the scan goes on from the next `<`. A closing tag closes the nearest element of its own
/// name still open, so a `</g>` ends the group it is paired with wherever it is written, inside an
/// element that is dropped included, and a group opened inside a dropped element closes no other.
///
/// It never refuses: markup that holds no shape answers an empty list. It is a scanner of its own,
/// never a platform XML parser, which refuses markup that is not well formed, expands entities and
/// may fetch, and it reads the markup scalar by scalar in one pass, so the time a glyph takes grows
/// with its length and no faster.
public func parseGlyph(_ markup: String) -> [GlyphShape] {
  let scan = scanTags(withoutComments(Array(markup.unicodeScalars)))
  let tags = scan.tags
  var shapes: [GlyphShape] = []
  var groups: [OpenGroup] = []

  // The place the walk resumes from after the element opened at `index`, dropped with what it
  // holds: the tag that closes it, or the tag itself where the markup never closes it. A group
  // closed inside the dropped element ends there.
  func skip(_ index: Int) -> Int {
    let end = scan.closings[index] ?? index
    while let top = groups.last, top.closesAt > index, top.closesAt <= end {
      groups.removeLast()
    }
    return end
  }

  var index = 0
  while index < tags.count {
    let tag = tags[index]
    if tag.name == groupTag {
      if tag.isClosing, groups.last?.closesAt == index {
        groups.removeLast()
      } else if tag.isOpen, let closesAt = scan.closings[index] {
        groups.append(
          OpenGroup(closesAt: closesAt, transform: attributesOf(tag.attributes)["transform"] ?? ""))
      }
    } else if tag.isClosing || tag.name == documentTag {
      // A closing tag that ends no group the walk holds, and the document element: read through.
    } else if !glyphShapeTags.contains(tag.name) {
      index = skip(index)
    } else {
      var attributes = attributesOf(tag.attributes)
      let transform = (groups.map(\.transform) + [attributes["transform"] ?? ""])
        .filter { !$0.isEmpty }
      if !transform.isEmpty {
        attributes["transform"] = transform.joined(separator: " ")
      }
      shapes.append(GlyphShape(tag: tag.name, attributes: attributes))
      index = skip(index)
    }
    index += 1
  }
  return shapes
}

/// A group the walk stands inside: the place of the tag that closes it, and its own transform.
private struct OpenGroup {
  let closesAt: Int
  let transform: String
}

/// One tag of the markup: its name lowercase, whether it closes or opens an element, and its
/// attribute list unread.
private struct Tag {
  let name: String
  let isClosing: Bool
  let isOpen: Bool
  let attributes: ArraySlice<Unicode.Scalar>
}

/// The markup's tags in order, and the place of the tag that closes each element closed, keyed by
/// the place of its opening tag.
private struct TagScan {
  let tags: [Tag]
  let closings: [Int: Int]
}

/// The text a run of scalars spells.
private func text(_ scalars: ArraySlice<Unicode.Scalar>) -> String {
  String(String.UnicodeScalarView(scalars))
}

/// Whether `markup` holds `pattern` starting at `at`.
private func holds(_ pattern: [Unicode.Scalar], in markup: [Unicode.Scalar], at: Int) -> Bool {
  at + pattern.count <= markup.count && markup[at..<(at + pattern.count)].elementsEqual(pattern)
}

private let commentOpening: [Unicode.Scalar] = ["<", "!", "-", "-"]
private let commentClosing: [Unicode.Scalar] = ["-", "-", ">"]
private let cdataOpening: [Unicode.Scalar] = ["<", "!", "[", "C", "D", "A", "T", "A", "["]
private let cdataClosing: [Unicode.Scalar] = ["]", "]", ">"]

/// `markup` with each comment and CDATA section, to its end or to the markup's, written as one
/// space, so the names on either side of one never join.
private func withoutComments(_ markup: [Unicode.Scalar]) -> [Unicode.Scalar] {
  guard firstPlace(of: ["<", "!"], in: markup, from: 0) != nil else { return markup }
  var out: [Unicode.Scalar] = []
  out.reserveCapacity(markup.count)
  var at = 0
  while at < markup.count {
    var end: Int?
    if holds(commentOpening, in: markup, at: at) {
      end = firstPlace(of: commentClosing, in: markup, from: at + 4).map { $0 + 3 } ?? markup.count
    } else if holds(cdataOpening, in: markup, at: at) {
      end = firstPlace(of: cdataClosing, in: markup, from: at + 9).map { $0 + 3 } ?? markup.count
    }
    if let end {
      out.append(" ")
      at = end
    } else {
      out.append(markup[at])
      at += 1
    }
  }
  return out
}

/// Whether a scalar may open a tag's name: an ASCII letter.
private func opensName(_ scalar: Unicode.Scalar) -> Bool {
  ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar)
}

/// Whether a scalar may continue a tag's name: an ASCII letter, a digit or a hyphen.
private func continuesName(_ scalar: Unicode.Scalar) -> Bool {
  opensName(scalar) || ("0"..."9").contains(scalar) || scalar == "-"
}

/// Whether a scalar may be in an attribute's name: an ASCII letter, a digit, `_`, `.`, `:` or `-`.
private func inAttributeName(_ scalar: Unicode.Scalar) -> Bool {
  continuesName(scalar) || scalar == "_" || scalar == "." || scalar == ":"
}

/// The place of the first `<` in `markup` past `after`, or `nil`.
private func nextOpening(_ markup: [Unicode.Scalar], after: Int) -> Int? {
  var at = after + 1
  while at < markup.count {
    if markup[at] == "<" { return at }
    at += 1
  }
  return nil
}

/// The markup's tags, each closing tag paired with the nearest element of its name still open.
private func scanTags(_ markup: [Unicode.Scalar]) -> TagScan {
  var tags: [Tag] = []
  var closings: [Int: Int] = [:]
  var opened: [String: [Int]] = [:]
  // A mark at each place an attribute list was read from without finding its end: what follows a
  // place reads the same whichever tag reached it, so a run of tags that never end is one pass.
  var read = [Bool](repeating: false, count: markup.count)
  var next = nextOpening(markup, after: -1)
  while let at = next {
    let closing = at + 1 < markup.count && markup[at + 1] == "/"
    let nameAt = at + 1 + (closing ? 1 : 0)
    var nameEnd = nameAt
    if nameEnd < markup.count, opensName(markup[nameEnd]) {
      nameEnd += 1
      while nameEnd < markup.count, continuesName(markup[nameEnd]) {
        nameEnd += 1
      }
    }
    guard nameEnd > nameAt, let end = tagEnd(markup, from: nameEnd, read: &read) else {
      next = nextOpening(markup, after: at)
      continue
    }
    let name = asciiLowercase(text(markup[nameAt..<nameEnd]))
    let selfClosing = end > nameEnd && markup[end - 1] == "/"
    let open = !closing && !selfClosing
    if open {
      opened[name, default: []].append(tags.count)
    } else if closing, let opener = opened[name]?.popLast() {
      closings[opener] = tags.count
    }
    tags.append(
      Tag(
        name: name, isClosing: closing, isOpen: open,
        attributes: markup[nameEnd..<(selfClosing ? end - 1 : end)]))
    next = nextOpening(markup, after: end)
  }
  return TagScan(tags: tags, closings: closings)
}

/// The place of the `>` that ends the tag whose attribute list starts at `from`, read quote by
/// quote, or `nil` for a tag the markup never ends: a quote never closed ends none.
private func tagEnd(_ markup: [Unicode.Scalar], from: Int, read: inout [Bool]) -> Int? {
  var index = from
  while index < markup.count, !read[index] {
    read[index] = true
    let scalar = markup[index]
    if scalar == ">" { return index }
    guard scalar == "\"" || scalar == "'" else {
      index += 1
      continue
    }
    guard let closing = firstPlace(of: [scalar], in: markup, from: index + 1) else { return nil }
    index = closing + 1
  }
  return nil
}

/// The attributes of one tag's `list` a glyph keeps, keyed lowercase. A name is a whole run of the
/// characters names are written in, so `sodipodi:rx` is never the `rx` it ends in; one with no
/// quoted value is skipped whole; a name written twice keeps the later of its values a glyph may
/// carry.
private func attributesOf(_ list: ArraySlice<Unicode.Scalar>) -> [String: String] {
  let list = Array(list)
  var attributes: [String: String] = [:]
  var index = 0
  while index < list.count {
    guard inAttributeName(list[index]) else {
      index += 1
      continue
    }
    var nameEnd = index
    while nameEnd < list.count, inAttributeName(list[nameEnd]) {
      nameEnd += 1
    }
    let name = text(list[index..<nameEnd])
    index = nameEnd
    var at = index
    while at < list.count, isWhiteSpace(list[at]) {
      at += 1
    }
    guard at < list.count, list[at] == "=" else { continue }
    at += 1
    while at < list.count, isWhiteSpace(list[at]) {
      at += 1
    }
    guard at < list.count, list[at] == "\"" || list[at] == "'",
      let closing = firstPlace(of: [list[at]], in: list, from: at + 1)
    else { continue }
    let value = text(list[(at + 1)..<closing])
    index = closing + 1
    let key = asciiLowercase(name)
    guard glyphAttributes.contains(key), let kept = keptGlyphValue(key, value: value) else {
      continue
    }
    attributes[key] = kept
  }
  return attributes
}
