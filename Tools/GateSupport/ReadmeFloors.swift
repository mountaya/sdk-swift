/// ReadmeFloors holds the README's floors table to the floors the package's files declare
/// (SPEC.md section 2): the oldest Swift a consumer builds with and the oldest release of each
/// platform, which a developer looks for under Install and which no other prose of the README
/// states, since a number no gate holds is a second copy the next bump leaves behind.
///
/// The table opens with `| Floor | Version |`, sits under `## Install`, and states each floor on a
/// row of its own: the floor's name first in its first cell, `Swift` or a platform as
/// `Package.swift` names it, iOS's row free to name iPadOS after it, and its version first in its
/// second cell, `6.2.3 or newer`. A version is compared with trailing `.0`s dropped, so a project's
/// `17.0` is the manifest's `17`.
package enum ReadmeFloors {
  /// Floor is one floor a file of the package declares.
  package struct Floor: Sendable, Equatable {
    /// name is the floor's name in the table, `Swift` or a platform's, `Mac Catalyst`.
    package let name: String
    /// version is the version the file declares, `6.2.3` or `17`.
    package let version: String
    /// file is the file that declares it, relative to the repository's root.
    package let file: String

    package init(name: String, version: String, file: String) {
      self.name = name
      self.version = version
      self.file = file
    }
  }

  /// header is the line that opens the floors table.
  package static let header = "| Floor | Version |"

  /// section is the README's section the table belongs to.
  package static let section = "## Install"

  /// The names a floor may go by in the table, longest first, so `Mac Catalyst` is never read as
  /// `macOS`'s start.
  private static let names = [
    "Mac Catalyst", "visionOS", "watchOS", "macOS", "tvOS", "Swift", "iOS",
  ]

  /// The words that state a floor's number in prose: a platform's name, or Swift's, followed by a
  /// version.
  private static let proseNames = [
    "Mac Catalyst", "iPadOS", "visionOS", "watchOS", "macOS", "tvOS", "Swift", "iOS",
  ]

  /// problems lists every way `readme` states the package's floors otherwise than `declared` does,
  /// each with its line, and nothing where the table states each floor once at its figure and no
  /// other line of prose states one. `declared` may name a floor twice, from two files, which then
  /// both hold the one row.
  package static func problems(in readme: String, declared: [Floor]) -> [String] {
    let lines = readme.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let tables = lines.indices.filter { lines[$0].trimmingTrailingSpaces == header }
    guard let start = tables.first else {
      return ["README.md holds no floors table, opened by `\(header)`, under `\(section)`"]
    }
    var problems: [String] = []
    if tables.count > 1 {
      problems.append(
        "README.md holds \(tables.count) floors tables, at lines "
          + tables.map { "\($0 + 1)" }.joined(separator: ", ")
          + ": one table states the floors")
    }
    let install = lines.firstIndex { $0.trimmingTrailingSpaces == section }
    let end =
      install.flatMap { at in lines[(at + 1)...].firstIndex { $0.hasPrefix("## ") } }
      ?? lines.count
    if !(install.map { start > $0 && start < end } ?? false) {
      problems.append("README.md, line \(start + 1): the floors table stands outside `\(section)`")
    }

    // The table's rows run from the line after its separator to the first line that is no row.
    var rows: [(line: Int, cells: [String])] = []
    var index = start + 2
    while index < lines.count, lines[index].hasPrefix("|") {
      rows.append((index + 1, cells(of: lines[index])))
      index += 1
    }
    let tableLines = start..<index

    var stated: [String: [(line: Int, version: String?)]] = [:]
    for row in rows {
      let first = row.cells.first ?? ""
      guard let name = names.first(where: { leads(first, with: $0) }) else {
        problems.append(
          "README.md, line \(row.line): `\(first)` names no floor the package declares; a row's "
            + "first cell opens with Swift or a platform's name")
        continue
      }
      let version = row.cells.dropFirst().first.flatMap(leadingVersion(of:))
      stated[name, default: []].append((row.line, version))
    }

    for name in names {
      let files = declared.filter { $0.name == name }
      let rowsStating = stated[name] ?? []
      if files.isEmpty {
        for row in rowsStating {
          problems.append(
            "README.md, line \(row.line): a row for \(name), which no file of the package declares")
        }
        continue
      }
      guard let row = rowsStating.first else {
        let floor = files[0]
        problems.append(
          "README.md's floors table states no row for \(name), which \(floor.file) declares as "
            + floor.version)
        continue
      }
      if rowsStating.count > 1 {
        problems.append(
          "README.md states \(name)'s floor on \(rowsStating.count) rows, at lines "
            + rowsStating.map { "\($0.line)" }.joined(separator: ", ") + ": one row states it")
      }
      for floor in files where row.version.map(normalized) != normalized(floor.version) {
        problems.append(
          "README.md, line \(row.line): states \(name)'s floor as \(row.version ?? "no version"), "
            + "and \(floor.file) declares \(floor.version)")
      }
    }

    // Anywhere else, prose names the reason for a floor and never its number.
    var fenced = false
    for (offset, line) in lines.enumerated() where !tableLines.contains(offset) {
      if line.hasPrefix("```") {
        fenced.toggle()
        continue
      }
      guard !fenced, let stated = statedFloor(in: line) else { continue }
      problems.append(
        "README.md, line \(offset + 1): `\(stated)` states a floor outside the floors table, "
          + "which is its one copy in prose")
    }
    return problems
  }

  /// cells reads a table row's cells, trimmed, `| a | b |` as `a` and `b`.
  private static func cells(of row: String) -> [String] {
    row.split(separator: "|", omittingEmptySubsequences: false).dropFirst().dropLast()
      .map { String($0).trimmingSpaces }
  }

  /// leads is whether `cell` opens with `name` as a whole word.
  private static func leads(_ cell: String, with name: String) -> Bool {
    guard cell.hasPrefix(name) else { return false }
    let after = cell.dropFirst(name.count).first
    return after == nil || after == " " || after == ","
  }

  /// leadingVersion reads the version a cell opens with, digits and the dots between them, nil
  /// where it opens with no digit.
  private static func leadingVersion(of cell: String) -> String? {
    let run = cell.prefix { $0.isASCII && ($0.isNumber || $0 == ".") }
    let trimmed = String(run.reversed().drop { $0 == "." }.reversed())
    return trimmed.first?.isNumber == true ? trimmed : nil
  }

  /// normalized drops a version's trailing `.0`s, so `17.0` reads as `17`.
  private static func normalized(_ version: String) -> String {
    var parts = version.split(separator: ".").map(String.init)
    while parts.count > 1, parts.last == "0" {
      parts.removeLast()
    }
    return parts.joined(separator: ".")
  }

  /// statedFloor is the run of a prose line that states a floor, a platform's or Swift's name and
  /// a version after it, `iOS 17` or `Swift 6.2`, or nil where the line states none.
  private static func statedFloor(in line: String) -> String? {
    for name in proseNames {
      var rest = Substring(line)
      while let found = rest.firstRange(of: name) {
        let before = rest[..<found.lowerBound].last
        let tail = rest[found.upperBound...]
        if before?.isLetter != true, tail.first == " ",
          let version = leadingVersion(of: String(tail.dropFirst()))
        {
          return "\(name) \(version)"
        }
        rest = tail
      }
    }
    return nil
  }
}

extension String {
  fileprivate var trimmingTrailingSpaces: String {
    var text = Substring(self)
    while let last = text.last, last == " " || last == "\t" || last == "\r" {
      text = text.dropLast()
    }
    return String(text)
  }

  fileprivate var trimmingSpaces: String {
    var text = Substring(self)
    while text.first == " " {
      text = text.dropFirst()
    }
    while text.last == " " {
      text = text.dropLast()
    }
    return String(text)
  }
}
