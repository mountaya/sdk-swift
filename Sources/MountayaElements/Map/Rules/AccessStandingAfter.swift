import MountayaGeo

/// accessStandingAfter is the refusals of access that stand once a map hears one more answer, and
/// whether that answer ended the last of them, which is what is told
/// (`map.events.access-standing`).
///
/// A refusal stands for its source until a tile of that source loads, and one naming no source, of
/// a style, a sprite, a glyph or the layers manifest, until the next style loads; each answer also
/// ends the refusal of every source the style no longer holds, `holdsSource` read as the answer
/// arrives, so a source that left the style takes its refusal with it. A refusal adds its source,
/// once, to those standing. An answer while nothing stands ends nothing, so the end is told once,
/// and again only after a later refusal has ended in turn.
func accessStandingAfter(
  _ standing: StandingRefusals, answer: AccessAnswer, holdsSource: (String) -> Bool
) -> (standing: StandingRefusals, restored: Bool) {
  var after = standing
  switch answer {
  case .refused(let source?):
    if !after.sources.contains(where: { sameText($0, source) }) {
      after.sources.append(source)
    }
    return (after, false)
  case .refused(nil):
    after.unsourced = true
    return (after, false)
  case .tile(let source):
    guard !standing.isEmpty else { return (standing, false) }
    after.sources.removeAll { sameText($0, source) || !holdsSource($0) }
  case .style:
    guard !standing.isEmpty else { return (standing, false) }
    after.unsourced = false
    after.sources.removeAll { !holdsSource($0) }
  }
  return (after, after.isEmpty)
}
