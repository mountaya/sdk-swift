#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import os
  internal import SwiftUI

  /// GlyphFigureCache keeps the figures each glyph's markup is read into, so a glyph is read once
  /// and every later drawing of it, a control's, a marker's pin or a map's sprite, takes the figures
  /// kept (`glyphFigures(_:in:)`).
  ///
  /// A glyph's figures are its markup's, painted as its set paints them, so they are kept under the
  /// markup and the paint and the width of its set: a set chained over another, or one built anew
  /// holding the same glyphs, takes the figures of every glyph they share. It keeps the figures of
  /// `capacity` glyphs at most, 256 for the process's, more than the bundled sets hold together, and
  /// lets the glyph drawn least recently go to keep another, so a host drawing glyphs without end
  /// holds a bounded store. It is Sendable, read from any thread, since MapLibre asks for a sprite
  /// on a thread of its own, so what it keeps sits behind a lock.
  final class GlyphFigureCache: Sendable {
    /// shared is the process's, which every glyph the elements draw is read through.
    static let shared = GlyphFigureCache()

    /// Key is what a glyph's figures depend on: its markup, and how its set paints it.
    private struct Key: Hashable, Sendable {
      let markup: String
      let paint: GlyphSet.Paint
      let strokeWidth: Double
    }

    /// Kept is a glyph's figures, and when they were last drawn, by the cache's own count.
    private struct Kept: Sendable {
      let figures: [GlyphFigure]
      var drawn: UInt64
    }

    /// Held is the figures kept, the count of drawings so far, and how many glyphs were read from
    /// their markup.
    private struct Held: Sendable {
      var figures: [Key: Kept] = [:]
      var drawings: UInt64 = 0
      var read = 0
    }

    /// capacity is how many glyphs' figures the cache keeps at most.
    let capacity: Int
    private let held = OSAllocatedUnfairLock(initialState: Held())

    /// Creates a cache keeping the figures of `capacity` glyphs at most, one at least.
    init(capacity: Int = 256) {
      self.capacity = Swift.max(1, capacity)
    }

    /// read is how many glyphs the cache has read from their markup, which a test counts.
    var read: Int {
      held.withLock { $0.read }
    }

    /// kept is how many glyphs' figures the cache keeps now.
    var kept: Int {
      held.withLock { $0.figures.count }
    }

    /// figures is the glyph `glyph` of `set` as a renderer draws it, read from its markup the first
    /// time and kept for later drawings while it is among the `capacity` drawn most recently, or nil
    /// where the set does not hold the glyph.
    func figures(_ glyph: String, in set: GlyphSet) -> [GlyphFigure]? {
      guard let markup = set.markup[glyph] else { return nil }
      let key = Key(markup: markup, paint: set.paint, strokeWidth: set.strokeWidth)
      let kept = held.withLock { held -> [GlyphFigure]? in
        // One look-up of the key, the drawing then counted in place.
        guard let index = held.figures.index(forKey: key) else { return nil }
        held.drawings += 1
        held.figures.values[index].drawn = held.drawings
        return held.figures.values[index].figures
      }
      if let kept {
        return kept
      }
      // Read outside the lock, so a long glyph holds up no other; two threads reading one glyph at
      // once each read it, and the figures kept are the same.
      let figures = readGlyphFigures(markup, in: set)
      let capacity = capacity
      held.withLock { held in
        held.drawings += 1
        held.figures[key] = Kept(figures: figures, drawn: held.drawings)
        held.read += 1
        // The glyph drawn least recently goes, once more are kept than the cache holds.
        if held.figures.count > capacity,
          let oldest = held.figures.min(by: { $0.value.drawn < $1.value.drawn })?.key
        {
          held.figures.removeValue(forKey: oldest)
        }
      }
      return figures
    }
  }
#endif
