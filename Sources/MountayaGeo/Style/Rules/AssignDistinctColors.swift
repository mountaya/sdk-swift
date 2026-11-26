/// assignDistinctColors is `count` colours of `palette` for a batch shown side by side, such as a
/// set of suggested itineraries, each another than every colour `reserved` names, and spread as
/// widely around the wheel as the colours left allow.
///
/// The colours left are the palette's, in its order, but those `reserved` names, compared with the
/// ASCII capitals folded, so `#FA5252` reserves `#fa5252`; where none is left, the whole palette.
/// The answer takes every `stride`-th of them, the stride the colours left over `count` rounded
/// down and at least one, and wraps past the last: over the twelve of `livelyPalette`, three are
/// the first, the fifth and the ninth. It is deterministic, so a batch regenerated with some of its
/// colours kept assigns the others the same way every time.
///
/// Exactly `count` colours, each in the palette's own spelling, repeating once the colours left are
/// spent; none for a count under one. A palette that lists no colour reads as `livelyPalette`.
public func assignDistinctColors(
  _ count: Int, reserved: [String], palette: [String] = livelyPalette
) -> [String] {
  guard count > 0 else { return [] }
  let listed = listedOr(palette)
  let taken = Set(reserved.map(asciiLowercase))
  let left = listed.filter { !taken.contains(asciiLowercase($0)) }
  let pool = left.isEmpty ? listed : left
  let stride = max(1, pool.count / count)
  return (0..<count).map { slot in colorAt(pool, position: slot * stride % pool.count) }
}
