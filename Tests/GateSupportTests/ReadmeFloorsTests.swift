import GateSupport
import Testing

@Suite("ReadmeFloors")
struct ReadmeFloorsTests {
  /// declared is a package's floors as its manifest and an app's project state them, iOS's twice.
  private static let declared = [
    ReadmeFloors.Floor(name: "Swift", version: "6.2.3", file: "Package.swift"),
    ReadmeFloors.Floor(name: "iOS", version: "17", file: "Package.swift"),
    ReadmeFloors.Floor(name: "macOS", version: "14", file: "Package.swift"),
    ReadmeFloors.Floor(name: "Mac Catalyst", version: "17", file: "Package.swift"),
    ReadmeFloors.Floor(name: "iOS", version: "17.0", file: "Trail.xcodeproj"),
  ]

  /// readme is a README whose Install section states `rows` under the table's header, with `prose`
  /// after it and a code fence that names a platform and a version, which is no prose.
  private static func readme(_ rows: [String], prose: String = "") -> String {
    """
    # A package

    ## Install

    | Floor | Version |
    | --- | --- |
    \(rows.joined(separator: "\n"))

    \(prose)

    ```swift
    platforms: [.iOS(.v17)]  // iOS 17
    ```

    ## Next
    """
  }

  private static let rows = [
    "| Swift | 6.2.3 or newer |", "| iOS and iPadOS | 17 or newer |",
    "| Mac Catalyst | 17 or newer |", "| macOS | 14 or newer |",
  ]

  @Test("a table stating each floor once at its figure, and nothing outside it, holds")
  func holds() {
    #expect(ReadmeFloors.problems(in: Self.readme(Self.rows), declared: Self.declared) == [])
  }

  @Test("a row stating another figure fails at its line, naming the file that declares it")
  func anotherFigure() {
    var rows = Self.rows
    rows[3] = "| macOS | 15 or newer |"

    #expect(
      ReadmeFloors.problems(in: Self.readme(rows), declared: Self.declared) == [
        "README.md, line 10: states macOS's floor as 15, and Package.swift declares 14"
      ])
  }

  @Test("a floor two files declare is held to both, a project's 17.0 being the manifest's 17")
  func twoFiles() {
    let declared =
      Self.declared.dropLast() + [
        ReadmeFloors.Floor(name: "iOS", version: "18.0", file: "Trail.xcodeproj")
      ]

    #expect(
      ReadmeFloors.problems(in: Self.readme(Self.rows), declared: Array(declared)) == [
        "README.md, line 8: states iOS's floor as 17, and Trail.xcodeproj declares 18.0"
      ])
  }

  @Test("a floor stated on no row, or on two, fails")
  func coverage() {
    #expect(
      ReadmeFloors.problems(in: Self.readme(Array(Self.rows.dropFirst())), declared: Self.declared)
        == [
          "README.md's floors table states no row for Swift, which Package.swift declares as 6.2.3"
        ])
    #expect(
      ReadmeFloors.problems(
        in: Self.readme(Self.rows + ["| macOS | 14 |"]), declared: Self.declared) == [
          "README.md states macOS's floor on 2 rows, at lines 10, 11: one row states it"
        ])
  }

  @Test("a row naming no floor the package declares fails")
  func unknownRow() {
    #expect(
      ReadmeFloors.problems(
        in: Self.readme(Self.rows + ["| tvOS | 17 |", "| Linux | any |"]),
        declared: Self.declared) == [
          "README.md, line 12: `Linux` names no floor the package declares; a row's first cell "
            + "opens with Swift or a platform's name",
          "README.md, line 11: a row for tvOS, which no file of the package declares",
        ])
  }

  @Test("a floor's number stated in prose outside the table fails; a code fence is no prose")
  func prose() {
    #expect(
      ReadmeFloors.problems(
        in: Self.readme(Self.rows, prose: "It runs on iPadOS 17 and later."),
        declared: Self.declared) == [
          "README.md, line 12: `iPadOS 17` states a floor outside the floors table, which is its "
            + "one copy in prose"
        ])
    #expect(
      ReadmeFloors.problems(
        in: Self.readme(Self.rows, prose: "Turn the trait on in a tools 6.1 manifest."),
        declared: Self.declared) == [])
  }

  @Test("no table, two tables, or a table outside Install fail")
  func placement() {
    #expect(
      ReadmeFloors.problems(in: "# A package\n\n## Install\n", declared: Self.declared) == [
        "README.md holds no floors table, opened by `| Floor | Version |`, under `## Install`"
      ])
    let twice = Self.readme(Self.rows) + "\n\n| Floor | Version |\n| --- | --- |\n"
    #expect(
      ReadmeFloors.problems(in: twice, declared: Self.declared).first
        == "README.md holds 2 floors tables, at lines 5, 20: one table states the floors")
    let elsewhere = Self.readme(Self.rows).replacing("## Install", with: "## Overview")
    #expect(
      ReadmeFloors.problems(in: elsewhere, declared: Self.declared) == [
        "README.md, line 5: the floors table stands outside `## Install`"
      ])
  }
}
