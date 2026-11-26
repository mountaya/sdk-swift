/// PublishedNames holds this SDK's public API to the names the registry publishes for it: the
/// declarations a consumer calls for a capability, which the registry's `swift` column records as
/// the paths of the API baselines of SPEC.md section 7 (`sdk/SPEC.md` §9).
///
/// A name is declared where a baseline lists a declaration at exactly that path, its argument
/// labels and its case included: `MapEngine.features(at:)`, `APIError.Kind.preconditionFailed`,
/// `GlyphSet.init(chaining:)`. No idiom stands between the two, since the registry spells the
/// name as Swift declares it (SPEC.md section 5).
package struct PublishedNames: Sendable {
  /// paths is every declaration's path the baselines list.
  let paths: Set<String>

  /// Creates the lookup over the text of each API baseline. A line is a declaration's path, two
  /// spaces, then what is declared; a line starting `//` is the header.
  package init(baselines: [String]) {
    var paths: Set<String> = []
    for baseline in baselines {
      for line in baseline.split(separator: "\n") where !line.hasPrefix("//") {
        guard let gap = line.firstRange(of: "  "), gap.lowerBound > line.startIndex else {
          continue
        }
        paths.insert(String(line[..<gap.lowerBound]))
      }
    }
    self.paths = paths
  }

  /// count is how many declarations the baselines list, which a baseline read to nothing makes
  /// zero.
  package var count: Int {
    paths.count
  }

  /// declares answers whether a baseline lists a declaration at exactly the path `name`.
  package func declares(_ name: String) -> Bool {
    paths.contains(name)
  }
}
