import Foundation
import GateSupport
import Testing

@Suite("FileStructureRules")
struct FileStructureRulesTests {
  /// Builds a package that obeys the law, then lets a test plant one thing in it.
  private func check(planting plant: (TemporaryTree) throws -> Void = { _ in }) throws
    -> FileStructureRules.Report
  {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    try tree.write("Package.swift")
    try tree.write(
      "Sources/MountayaGeo/Profile/Rules/SlopeRamp.swift", contents: "enum SlopeRamp {}")
    try tree.write("Tests/MountayaGeoTests/Profile/Rules/SlopeRampTests.swift")
    try tree.write(
      "Sources/MountayaGeo/Seams/Contracts/LocationSource.swift",
      contents: "protocol LocationSource {}")
    try tree.write("Tests/MountayaGeoTests/Seams/Contracts/LocationSourceTests.swift")
    try tree.write(
      "Sources/MountayaElements/Profile/Views/ItineraryProfile.swift",
      contents: "// struct Decoy {}\nextension Namespace.ItineraryProfile {}")
    try tree.write("Tests/MountayaElementsTests/Profile/Views/ItineraryProfileTests.swift")
    try tree.write(
      "Sources/MountayaClient/Generated/Rest/Schemas/collection.swift",
      contents: "struct Anything {}")
    try plant(tree)
    return FileStructureRules.check(packageRoot: tree.root)
  }

  @Test("a tree that obeys the law passes, and the generated directory is not read")
  func lawfulTree() throws {
    let report = try check()

    #expect(report.findings.isEmpty, "\(report.findings)")
    #expect(report.checked == 3)
  }

  @Test("a kind outside the closed set fails")
  func unknownKind() throws {
    let report = try check {
      try $0.write("Sources/MountayaGeo/Profile/Helpers/Thing.swift", contents: "struct Thing {}")
      try $0.write("Tests/MountayaGeoTests/Profile/Helpers/ThingTests.swift")
    }

    #expect(report.findings.map(\.path) == ["Sources/MountayaGeo/Profile/Helpers"])
  }

  @Test("views live in the elements target only")
  func viewsOutsideElements() throws {
    let report = try check {
      try $0.write("Sources/MountayaGeo/Profile/Views/Chart.swift", contents: "struct Chart {}")
      try $0.write("Tests/MountayaGeoTests/Profile/Views/ChartTests.swift")
    }

    #expect(report.findings.map(\.path) == ["Sources/MountayaGeo/Profile/Views"])
  }

  @Test("a kind with no topic above it fails")
  func kindWithoutTopic() throws {
    let report = try check {
      try $0.write("Sources/MountayaGeo/Rules/Geodesy.swift", contents: "enum Geodesy {}")
    }

    #expect(
      Set(report.findings.map(\.path))
        == ["Sources/MountayaGeo/Rules", "Sources/MountayaGeo/Rules/Geodesy.swift"]
    )
  }

  @Test("a file above or below `<Topic>/<Kind>/` fails")
  func wrongDepth() throws {
    let report = try check {
      try $0.write("Sources/MountayaGeo/Loose.swift", contents: "struct Loose {}")
      try $0.write(
        "Sources/MountayaGeo/Profile/Rules/Deeper/Nested.swift", contents: "struct Nested {}")
    }

    #expect(
      report.findings.map(\.path) == [
        "Sources/MountayaGeo/Loose.swift",
        "Sources/MountayaGeo/Profile/Rules/Deeper",
        "Sources/MountayaGeo/Profile/Rules/Deeper/Nested.swift",
      ]
    )
  }

  @Test("a file whose name is not its type's fails")
  func nameMismatch() throws {
    let report = try check {
      try $0.write(
        "Sources/MountayaGeo/Profile/Rules/Totals.swift", contents: "enum ElevationTotals {}")
      try $0.write("Tests/MountayaGeoTests/Profile/Rules/TotalsTests.swift")
      try $0.write(
        "Sources/MountayaGeo/Profile/Rules/slopeColor.swift", contents: "enum slopeColor {}")
      try $0.write("Tests/MountayaGeoTests/Profile/Rules/slopeColorTests.swift")
      try $0.write("Sources/MountayaGeo/Profile/Rules/Notes.md", contents: "notes")
    }

    #expect(
      report.findings.map(\.path) == [
        "Sources/MountayaGeo/Profile/Rules/Notes.md",
        "Sources/MountayaGeo/Profile/Rules/Totals.swift",
        "Sources/MountayaGeo/Profile/Rules/slopeColor.swift",
      ]
    )
  }

  @Test("a file is named after its top-level function as it is after its type")
  func namedAfterFunction() throws {
    let report = try check {
      try $0.write(
        "Sources/MountayaGeo/Geodesy/Rules/HaversineMeters.swift",
        contents: "public let earthRadiusMeters = 6_371_000.0\n"
          + "public func haversineMeters(from: [Double], to: [Double]) -> Double { 0 }")
      try $0.write("Tests/MountayaGeoTests/Geodesy/Rules/HaversineMetersTests.swift")
      try $0.write(
        "Sources/MountayaGeo/Geodesy/Rules/BearingDegrees.swift",
        contents: "enum Geodesy { static func bearingDegrees() -> Double { 0 } }")
      try $0.write("Tests/MountayaGeoTests/Geodesy/Rules/BearingDegreesTests.swift")
    }

    // A function inside a type's braces is the type's, and names no file.
    #expect(
      report.findings.map(\.path) == ["Sources/MountayaGeo/Geodesy/Rules/BearingDegrees.swift"])
    #expect(report.findings.first?.message.contains("function `bearingDegrees`") == true)
  }

  @Test("a rule named as another file of its target is filed with `Rule`, and only then")
  func ruleBesideItsName() throws {
    let report = try check {
      for (path, text) in [
        ("MountayaGeo/Profile/Contracts/ProfileTotals.swift", "struct ProfileTotals {}"),
        (
          "MountayaGeo/Profile/Rules/ProfileTotalsRule.swift",
          "public let gradeWindowMeters = 100.0\n"
            + "public func profileTotals(_ series: [Double]) -> ProfileTotals { .init() }"
        ),
        // A type spelled with another acronym is the same file on a disk that ignores case.
        ("MountayaGeo/Layers/Contracts/POIPanelRows.swift", "struct POIPanelRows {}"),
        ("MountayaGeo/Layers/Rules/PoiPanelRowsRule.swift", "func poiPanelRows() {}"),
        // No file of the target is named as the rule: its own name is free.
        ("MountayaGeo/Profile/Rules/SlopeColorRule.swift", "func slopeColor() {}"),
        // The file of that name is another target's.
        ("MountayaElements/Map/Rules/MapPaintRule.swift", "func mapPaint() {}"),
        ("MountayaGeo/Style/Contracts/MapPaint.swift", "struct MapPaint {}"),
        // Only a rule takes the word.
        ("MountayaGeo/Profile/Contracts/ProfileTotalsRule.swift", "func profileTotals() {}"),
        // A type of the file's name, rather than the rule's function, is no rule.
        ("MountayaGeo/Search/Contracts/SearchListState.swift", "struct SearchListState {}"),
        ("MountayaGeo/Search/Rules/SearchListStateRule.swift", "struct SearchListState {}"),
      ] {
        try $0.write("Sources/" + path, contents: text)
        let mirrored = path.split(separator: "/").dropFirst().joined(separator: "/")
        let target = path.prefix { $0 != "/" }
        try $0.write(
          "Tests/\(target)Tests/" + mirrored.replacingOccurrences(of: ".swift", with: "Tests.swift")
        )
      }
    }

    #expect(
      report.findings.map(\.path) == [
        "Sources/MountayaElements/Map/Rules/MapPaintRule.swift",
        "Sources/MountayaGeo/Profile/Contracts/ProfileTotalsRule.swift",
        "Sources/MountayaGeo/Profile/Rules/SlopeColorRule.swift",
        "Sources/MountayaGeo/Search/Rules/SearchListStateRule.swift",
      ],
      "\(report.findings)"
    )
  }

  @Test("a source file with no test at the mirrored path fails")
  func missingMirroredTest() throws {
    let report = try check {
      try $0.write("Sources/MountayaGeo/Profile/Rules/Geodesy.swift", contents: "enum Geodesy {}")
      try $0.write("Tests/MountayaGeoTests/Profile/GeodesyTests.swift")
    }

    #expect(report.findings.map(\.path) == ["Sources/MountayaGeo/Profile/Rules/Geodesy.swift"])
    #expect(
      report.findings.first?.message.contains("MountayaGeoTests/Profile/Rules/GeodesyTests.swift")
        == true)
  }

  @Test("an empty directory fails, under Sources and under Tests")
  func emptyDirectories() throws {
    let report = try check {
      try $0.makeDirectory("Sources/MountayaGeo/Camera/Rules")
      try $0.makeDirectory("Tests/MountayaGeoTests/Camera")
    }

    #expect(
      report.findings.map(\.path) == [
        "Sources/MountayaGeo/Camera",
        "Sources/MountayaGeo/Camera/Rules",
        "Tests/MountayaGeoTests/Camera",
      ]
    )
  }
}
