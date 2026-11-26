import Foundation

/// defaultSegmentColor is the colour a segment is drawn in when it carries none of its own, a
/// neutral grey. It is a hex colour rather than a theme's token, since a renderer's paint takes the
/// colour itself.
public let defaultSegmentColor = "#868e96"

/// livelyPalette is the palette a segment's colour is read from where its caller names none: twelve
/// hues stepping once around the wheel (red, pink, grape, violet, indigo, blue, cyan, teal, green,
/// lime, yellow, orange), so two neighbouring positions are easy to tell apart on a map.
public let livelyPalette = [
  "#fa5252",
  "#e64980",
  "#be4bdb",
  "#7950f2",
  "#4c6ef5",
  "#228be6",
  "#15aabf",
  "#12b886",
  "#40c057",
  "#82c91e",
  "#fab005",
  "#fd7e14",
]

/// listedOr is the palette a caller lists, or `livelyPalette` where it lists no colour.
func listedOr(_ palette: [String]) -> [String] {
  palette.isEmpty ? livelyPalette : palette
}

/// colorAt is the colour of a palette that lists one at least, at a whole position wrapped into it
/// by the floor modulo, so -1 is its last colour.
func colorAt(_ palette: [String], position: Int) -> String {
  let size = palette.count
  return palette[((position % size) + size) % size]
}

/// segmentColorAt is the colour of `palette` a segment at the 0-based `position` is drawn in, the
/// palette wrapped: a position past the end reads on from the first colour, and one before the
/// first reads back from the last, so 12 is the first colour of the twelve of `livelyPalette` and
/// -1 its last. A palette that lists no colour reads as `livelyPalette`, so the answer is always a
/// colour of the palette read.
public func segmentColorAt(_ position: Int, palette: [String] = livelyPalette) -> String {
  colorAt(listedOr(palette), position: position)
}

/// segmentColorAt is the colour of `palette` at `position`, as the whole position reads it, for a
/// position that is any number: a fraction reads the position it is past, so 2.7 reads 2 and -0.5
/// reads -1, and a number that is none, `NaN` or an infinity, reads the first colour.
///
/// The position is wrapped as the number it is, `((index % size) + size) % size` on its whole part
/// with the truncated remainder, so a position past the range of an `Int`, 1e20, wraps as exactly
/// as one within it and never traps.
public func segmentColorAt(_ position: Double, palette: [String] = livelyPalette) -> String {
  let listed = listedOr(palette)
  let index = position.isFinite ? position.rounded(.down) : 0
  let size = Double(listed.count)
  let wrapped = (index.truncatingRemainder(dividingBy: size) + size)
    .truncatingRemainder(dividingBy: size)
  return listed[Int(wrapped)]
}
