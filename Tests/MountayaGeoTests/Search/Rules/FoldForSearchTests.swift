import Testing

@testable import MountayaGeo

@Suite("foldForSearch")
struct FoldForSearchTests {
  private func folded(_ text: String) -> String {
    String(String.UnicodeScalarView(foldForSearch(text).text))
  }

  @Test("a segment is lowercased and stripped of its accents")
  func accents() {
    #expect(scalars(folded("\u{C9}vian")) == scalars("evian"))
    #expect(scalars(folded("E\u{301}vian")) == scalars("evian"))
    #expect(scalars(folded("\u{110}\u{E0} N\u{1EB5}ng")) == scalars("da nang"))
    #expect(
      scalars(folded("\u{39F}\u{394}\u{39F}\u{3A3}")) == scalars("\u{3BF}\u{3B4}\u{3BF}\u{3C3}"))
    // A dotted capital I lowercases to `i` and a combining dot, which the strip drops.
    #expect(scalars(folded("\u{130}")) == scalars("i"))
  }

  @Test("a sharp s and a stroke letter read as the letters a reader types")
  func typedLetters() {
    #expect(folded("Stra\u{DF}e") == "strasse")
    #expect(folded("STRA\u{1E9E}E") == "strasse")
    #expect(folded("\u{141}\u{F3}d\u{17A}") == "lodz")
    #expect(folded("Troms\u{F8}") == "tromso")
    #expect(folded("\u{126}\u{110}\u{166}") == "hdt")
  }

  /// Every folded scalar maps back to the whole segment it came from, here in UTF-16 offsets.
  @Test("each folded scalar maps back to its segment")
  func segments() {
    let title = "Stra\u{DF}e"
    let straße = foldForSearch(title)
    #expect(straße.starts.map { $0.utf16Offset(in: title) } == [0, 1, 2, 3, 4, 4, 5])
    #expect(straße.ends.map { $0.utf16Offset(in: title) } == [1, 2, 3, 4, 5, 5, 6])
    let accented = "E\u{301}v"
    let accent = foldForSearch(accented)
    #expect(accent.starts.map { $0.utf16Offset(in: accented) } == [0, 2])
    #expect(accent.ends.map { $0.utf16Offset(in: accented) } == [2, 3])
  }

  /// A mark that is no accent is kept, and a letter that composes with the one before joins its
  /// segment.
  @Test("a mark that is no accent is kept, and a composing letter joins")
  func joins() {
    #expect(scalars(folded("\u{628}\u{64E}")) == [0x628, 0x64E])
    let jamo = "\u{1100}\u{1161}"
    let hangul = foldForSearch(jamo)
    #expect(scalars(String(String.UnicodeScalarView(hangul.text))) == [0xAC00])
    #expect(hangul.starts.map { $0.utf16Offset(in: jamo) } == [0])
    #expect(hangul.ends.map { $0.utf16Offset(in: jamo) } == [2])
    // A scalar beyond the basic plane is one scalar of the fold, two UTF-16 units of the title,
    // where Kotlin records one entry per unit.
    let grin = "\u{1F600}"
    #expect(foldForSearch(grin).starts.map { $0.utf16Offset(in: grin) } == [0])
    #expect(foldForSearch(grin).ends.map { $0.utf16Offset(in: grin) } == [2])
  }

  @Test("an ASCII character is only lowercased")
  func ascii() {
    #expect(foldSegment("A") == "a")
    #expect(folded("").isEmpty)
  }

  /// A run is never a `Character`: the two regional indicators of a flag are two segments, and a
  /// carriage return and a line feed two.
  @Test("a segment is a scalar with what joins it, never an extended grapheme cluster")
  func notGraphemes() {
    #expect(foldForSearch("\u{1F1EB}\u{1F1F7}").starts.count == 2)
    let crlf = "\r\n"
    #expect(foldForSearch(crlf).starts.map { $0.utf16Offset(in: crlf) } == [0, 1])
  }

  /// composedSegmentEnds is where each segment of `text` ends, in UTF-16 offsets, the segments read
  /// by composing every scalar from U+0300 with the segment before it, the join test the table
  /// stands in front of.
  private func composedSegmentEnds(_ text: String) -> [Int] {
    let scalars = text.unicodeScalars
    var ends: [Int] = []
    var start = scalars.startIndex
    var index = scalars.startIndex
    while index < scalars.endIndex {
      let scalar = scalars[index]
      if index > start {
        let segment = String(scalars[start..<index])
        let point = String(scalar)
        let joins =
          scalar.value >= 0x300
          && (isCombiningMark(scalar)
            || !sameText(
              canonicalComposition(segment + point),
              canonicalComposition(segment) + canonicalComposition(point)))
        if !joins {
          ends.append(index.utf16Offset(in: text))
          start = index
        }
      }
      index = scalars.index(after: index)
    }
    if index > start { ends.append(index.utf16Offset(in: text)) }
    return ends
  }

  /// The table is asked first, and composing only for the letters it holds, so every segment is
  /// the one composing every scalar would find.
  @Test("a letter that is no mark joins only where the table holds it and composing proves it")
  func composingLettersJoin() {
    let texts = [
      "\u{AC00}\u{11A8}", "\u{1100}\u{1161}\u{11A8}", "a\u{1161}", "\u{1161}\u{1161}",
      "\u{11A8}\u{11A8}", "\u{16D63}\u{16D67}", "\u{16D67}\u{16D67}", "\u{16D63}\u{16D68}",
      "a\u{16D67}", "\u{39F}\u{394}\u{39F}\u{3A3} \u{3AC}\u{3B8}\u{3B7}\u{3BD}\u{3B1}",
      "\u{41C}\u{43E}\u{441}\u{43A}\u{432}\u{430} \u{419}\u{43E}\u{448}\u{43A}\u{430}\u{440}",
      "\u{5E9}\u{5C1}\u{5B8}\u{5DC}\u{5D5}\u{5B9}\u{5DD}", "\u{628}\u{64E}\u{64A}\u{652}\u{62A}",
      "\u{915}\u{93F}\u{932}\u{93E}", "\u{B92}\u{BD7} \u{BC6}\u{BBE}", "\u{B47}\u{B3E}",
      "\u{6771}\u{4EAC}\u{90FD}", "\u{1F1EB}\u{1F1F7}\u{1F600}", "E\u{301}vian \u{130}stanbul",
      "\u{304B}\u{3099}\u{FF76}\u{FF9E}", "\u{212B}\u{2126}A\u{30A}",
    ]
    for text in texts {
      // Each folded scalar names the end of its segment, so a segment folded to two scalars names
      // it twice.
      var ends: [Int] = []
      for end in foldForSearch(text).ends.map({ $0.utf16Offset(in: text) }) where ends.last != end {
        ends.append(end)
      }
      #expect(ends == composedSegmentEnds(text), "\(Array(text.unicodeScalars.map(\.value)))")
    }
    let syllable = "\u{1100}\u{1161}\u{11A8}"
    #expect(
      foldForSearch(syllable).starts.map { $0.utf16Offset(in: syllable) } == [0],
      "a vowel and a final jamo complete the syllable before them")
    let apart = "a\u{1161}"
    #expect(
      foldForSearch(apart).starts.map { $0.utf16Offset(in: apart) } == [0, 1],
      "a vowel jamo the letter before it does not compose with starts its own segment")
  }

  /// Read off the platform's own canonical mappings: every scalar that is no mark and whose
  /// decomposition starts with a scalar a composition takes second, or with a mark canonical
  /// ordering moves, is held by the table, so a character database that adds one fails here rather
  /// than splitting a segment it would join.
  @Test("the table holds every letter that is no mark and can compose with the one before it")
  func tableIsComplete() {
    var seconds: Set<UInt32> = []
    var leading: [(scalar: Unicode.Scalar, first: Unicode.Scalar)] = []
    for value in UInt32(0xC0)...0x2_FFFF {
      guard let scalar = Unicode.Scalar(value) else { continue }
      let properties = scalar.properties
      if properties.isUnifiedIdeograph { continue }
      switch properties.generalCategory {
      case .unassigned, .privateUse, .surrogate: continue
      default: break
      }
      let decomposed = Array(canonicalDecomposition(String(scalar)).unicodeScalars)
      guard let first = decomposed.first else { continue }
      if value >= 0x300, !isCombiningMark(scalar) {
        leading.append((scalar, first))
      }
      guard decomposed.count > 1,
        sameText(canonicalComposition(String(String.UnicodeScalarView(decomposed))), String(scalar))
      else { continue }
      for later in decomposed.dropFirst() {
        seconds.insert(later.value)
      }
    }
    let composing = leading.filter {
      seconds.contains($0.first.value)
        || $0.first.properties.canonicalCombiningClass != .notReordered
    }.map(\.scalar.value)
    #expect(!composing.isEmpty, "the Hangul jamo compose on every platform")
    for value in composing {
      #expect(
        composingLetters.contains { $0.contains(value) },
        "U+\(String(value, radix: 16, uppercase: true)) composes with the scalar before it")
    }
  }
}
