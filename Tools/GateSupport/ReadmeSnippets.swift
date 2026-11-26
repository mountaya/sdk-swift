/// ReadmeSnippets prints the Swift snippets of a Markdown document as one Swift file, which the
/// consumer package compiles against the real products (SPEC.md section 10), the README's
/// committed in it and the skill's in the `ai` checkout type-checked against its iOS build.
///
/// Every fence tagged `swift` is printed, each into a function of its own, since a snippet is
/// written as the statements a consumer pastes; its `import` lines are gathered at the top of the
/// file. A fence that cannot be compiled opts out with a marker on the line above it, which names
/// its reason, and the printed file lists every fence that opted out, so an opt-out is read in
/// review rather than taken on trust:
///
///     <!-- swift:skip a manifest, which the consumer package's own declares -->
package enum ReadmeSnippets {
  /// Fence is one Swift fence of the document.
  package struct Fence: Sendable, Equatable {
    /// line is the line of its opening, counted from 1.
    package let line: Int
    /// code is its lines, as written.
    package let code: [String]
    /// skipped is the reason its marker names, or nil where it is compiled.
    package let skipped: String?

    package init(line: Int, code: [String], skipped: String? = nil) {
      self.line = line
      self.code = code
      self.skipped = skipped
    }
  }

  /// Refusal says why a document's fences cannot be read.
  package struct Refusal: Error, Sendable, CustomStringConvertible {
    package let description: String
  }

  /// The marker that opts the fence below it out of the compile.
  package static let skipMarker = "<!-- swift:skip"

  /// fences reads every fenced block tagged `swift` in a Markdown document, in order.
  ///
  /// It refuses a fence that is never closed and a skip marker that names no reason or stands
  /// above no Swift fence.
  package static func fences(in markdown: String) throws(Refusal) -> [Fence] {
    let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map {
      String($0).trimmingTrailingWhitespace
    }
    var fences: [Fence] = []
    var index = 0
    var marker: (line: Int, reason: String)?
    while index < lines.count {
      let line = lines[index]
      if line.hasPrefix(skipMarker) {
        guard line.hasSuffix("-->") else {
          throw Refusal(description: "line \(index + 1): a skip marker ends on its own line")
        }
        let reason = String(line.dropFirst(skipMarker.count).dropLast(3))
          .trimmingCharacters(in: " ")
        guard !reason.isEmpty else {
          throw Refusal(description: "line \(index + 1): a skip marker names the reason it skips")
        }
        marker = (index + 1, reason)
        index += 1
        continue
      }
      guard line.hasPrefix("```") else {
        if let pending = marker, !line.isEmpty {
          throw Refusal(description: "line \(pending.line): a skip marker stands above no fence")
        }
        index += 1
        continue
      }
      let language = String(line.dropFirst(3))
      let opening = index
      var code: [String] = []
      index += 1
      while index < lines.count, lines[index] != "```" {
        code.append(lines[index])
        index += 1
      }
      guard index < lines.count else {
        throw Refusal(description: "line \(opening + 1): a fence that is never closed")
      }
      index += 1
      if language == "swift" {
        fences.append(Fence(line: opening + 1, code: code, skipped: marker?.reason))
      } else if let pending = marker {
        throw Refusal(
          description: "line \(pending.line): a skip marker stands above no Swift fence")
      }
      marker = nil
    }
    if let pending = marker {
      throw Refusal(description: "line \(pending.line): a skip marker stands above no fence")
    }
    return fences
  }

  /// file prints the Swift file a document's fences compile as, named after the document.
  ///
  /// `rewrite` is the command that prints a committed file again, and nil for a file printed
  /// afresh at every run and never committed, such as a skill's read from its own checkout.
  package static func file(_ fences: [Fence], document: String, rewrite: String?) -> String {
    let compiled = fences.filter { $0.skipped == nil }
    var imports: [String] = []
    for fence in compiled {
      for line in fence.code where line.hasPrefix("import ") && !imports.contains(line) {
        imports.append(line)
      }
    }
    var origin = """
      // Printed from \(document) by BoundaryTests at every run, and never committed: edit the
      // document.
      """
    if let rewrite {
      origin = """
        // Printed from \(document) by BoundaryTests. Never edit it: edit the document, then run
        //   \(rewrite)
        // and the diff is the review.
        """
    }
    var text = """
      // swift-format-ignore-file
      \(origin)
      //
      // \(compiled.count) snippets compiled, \(fences.count - compiled.count) skipped.

      """
    for fence in fences {
      if let reason = fence.skipped {
        text += "// Skipped: \(reason).\n"
      }
    }
    text += "\n" + imports.joined(separator: "\n") + "\n\n"
    text += """
      /// ReadmeSnippets is every Swift snippet of \(document), each in a function of its own, written
      /// as a consumer pastes it.
      enum ReadmeSnippets {

      """
    for (position, fence) in compiled.enumerated() {
      if position > 0 {
        text += "\n"
      }
      text += "  static func snippet\(position + 1)() async throws {\n"
      let body = fence.code.filter { !$0.hasPrefix("import ") }.drop { $0.isEmpty }
      for line in body {
        text += line.isEmpty ? "\n" : "    \(line)\n"
      }
      text += "  }\n"
    }
    text += "}\n"
    return text
  }
}

extension String {
  fileprivate var trimmingTrailingWhitespace: String {
    var text = Substring(self)
    while let last = text.last, last == " " || last == "\t" || last == "\r" {
      text = text.dropLast()
    }
    return String(text)
  }

  fileprivate func trimmingCharacters(in set: Character) -> String {
    var text = Substring(self)
    while text.first == set {
      text = text.dropFirst()
    }
    while text.last == set {
      text = text.dropLast()
    }
    return String(text)
  }
}
