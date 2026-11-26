import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("GlyphFigureCache")
struct GlyphFigureCacheTests {
  @Test("a glyph is read once, and every later drawing of it takes the figures kept")
  func readOnce() throws {
    let cache = GlyphFigureCache()
    let markup = try #require(GlyphSet.control.markup["zoom-in"])
    let first = try #require(cache.figures("zoom-in", in: .control))
    let again = try #require(cache.figures("zoom-in", in: .control))
    let read = readGlyphFigures(markup, in: .control)

    #expect(cache.read == 1)
    #expect(first.map(\.paint) == again.map(\.paint))
    #expect(first.map(\.path) == again.map(\.path))
    #expect(first.map(\.paint) == read.map(\.paint), "the figures the markup reads into")
  }

  @Test("a set sharing a glyph's markup and paint takes its figures, another paint reads it again")
  func keyedByMarkupAndPaint() throws {
    let cache = GlyphFigureCache()
    let markup = try #require(GlyphSet.control.markup["zoom-in"])
    let host = try #require(GlyphSet(name: "host", paint: .stroke, markup: ["hut": markup]))
    let chained = try #require(GlyphSet(chaining: [host, .control]))
    let wider = try #require(
      GlyphSet(name: "wide", paint: .stroke, strokeWidth: 3, markup: ["zoom-in": markup]))

    _ = cache.figures("zoom-in", in: .control)
    _ = cache.figures("zoom-in", in: chained)
    _ = cache.figures("hut", in: chained)
    #expect(cache.read == 1, "the same markup under the same paint and width is one glyph")
    let widened = try #require(cache.figures("zoom-in", in: wider))
    #expect(cache.read == 2)
    #expect(widened.allSatisfy { $0.paint.strokeWidth == 3 })
  }

  @Test("a glyph the set does not hold is no figures, and nothing is read for it")
  func missing() {
    let cache = GlyphFigureCache()

    #expect(cache.figures("hut", in: .control) == nil)
    #expect(cache.read == 0)
  }

  @Test("it keeps the glyphs drawn most recently, up to its capacity, and lets the oldest go")
  func bounded() throws {
    // Three glyphs of distinct markup, since a glyph sharing another's is that glyph.
    var names: [String] = []
    var markups: Set<String> = []
    for (name, markup) in GlyphSet.control.markup.sorted(by: { $0.key < $1.key })
    where markups.insert(markup).inserted {
      names.append(name)
      if names.count == 3 { break }
    }
    try #require(names.count == 3)
    let cache = GlyphFigureCache(capacity: 2)

    _ = cache.figures(names[0], in: .control)
    _ = cache.figures(names[1], in: .control)
    _ = cache.figures(names[0], in: .control)
    #expect(cache.read == 2)
    _ = cache.figures(names[2], in: .control)
    #expect(cache.read == 3)
    #expect(cache.kept == 2, "never more than its capacity")
    _ = cache.figures(names[0], in: .control)
    #expect(cache.read == 3, "the glyph drawn before the last one read is kept")
    _ = cache.figures(names[1], in: .control)
    #expect(cache.read == 4, "the glyph drawn least recently went, and is read again")
    #expect(cache.kept == 2)
  }

  @Test("the process's cache holds every bundled glyph at once")
  func sharedCapacity() {
    let bundled =
      Set(GlyphSet.control.markup.values).count + Set(GlyphSet.marker.markup.values).count
    #expect(GlyphFigureCache.shared.capacity == 256)
    #expect(GlyphFigureCache.shared.capacity >= bundled, "\(bundled) glyphs bundled")
  }

  @Test("the process's cache is the one every glyph drawn is read through")
  func shared() throws {
    let before = GlyphFigureCache.shared.read
    _ = glyphFigures("zoom-out", in: .control)
    let afterFirst = GlyphFigureCache.shared.read
    _ = glyphFigures("zoom-out", in: .control)

    #expect(afterFirst - before <= 1)
    #expect(GlyphFigureCache.shared.read == afterFirst, "a glyph drawn again is read no more")
  }
}
