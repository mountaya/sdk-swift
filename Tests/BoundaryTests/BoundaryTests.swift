import Foundation
import GateSupport
import Testing

/// The boundary rules of SPEC.md section 7, held over this repository's own tree. Each is a
/// scan of the source or of the package description, never an assertion about behaviour.
@Suite("Boundaries")
struct BoundaryTests {
  @Test("the package description lists the targets the scans walk")
  func descriptionListsShippedTargets() throws {
    let manifest = try PackageTree.manifest.get()

    // A scan that walked nothing would pass on anything.
    #expect(manifest.shippedTargets.contains { $0.name == "MountayaClient" })
    #expect(try !PackageTree.shippedFiles().isEmpty)
  }

  @Test("no shipped file crosses its product's row of the boundary table")
  func noFileCrossesItsBoundary() throws {
    let findings = try PackageTree.shippedFiles().flatMap {
      BoundaryRules.scan(target: $0.target, relativePath: $0.relativePath, source: $0.source)
    }

    #expect(findings.isEmpty, "\(PackageTree.describe(findings))")
  }

  @Test(
    "no shipped target reaches Ferrostar, nor MapLibre outside the elements, through a dependency")
  func builtArtifactWalk() throws {
    let findings = BoundaryRules.artifactWalk(manifest: try PackageTree.manifest.get())

    #expect(findings.isEmpty, "\(PackageTree.describe(findings))")
  }

  @Test("the environment is read in Seams and nowhere else")
  func determinism() throws {
    let findings = try PackageTree.shippedFiles().flatMap {
      BoundaryRules.determinism(target: $0.target, relativePath: $0.relativePath, source: $0.source)
    }

    #expect(findings.isEmpty, "\(PackageTree.describe(findings))")
  }

  /// A press on the watermark opens its link in the device's browser, and nothing an app states
  /// replaces it (`sdk/SPEC.md` §15): the environment's `openURL` is an action any app may set
  /// above `MapView`, so the mark's view reads none, and opens through the system's own opener.
  @Test("the watermark opens its link through the system's opener, never an environment's openURL")
  func watermarkOpensOutside() throws {
    let marks = try PackageTree.shippedFiles().filter {
      $0.target == "MountayaElements" && $0.relativePath.hasSuffix("/WatermarkLink.swift")
    }
    try #require(marks.count == 1, "no WatermarkLink.swift in MountayaElements")
    let names = marks[0].source.tokens.map(\.text)
    #expect(!names.contains("openURL"), "the mark reads the environment's openURL")
    #expect(names.contains("UIApplication"), "the mark opens through no system opener")
  }

  @Test("every suppression is a ledger entry with its sentence, and every entry a suppression")
  func suppressionsAreCounted() throws {
    let files = try PackageTree.allFiles()
    let suppressions = files.flatMap {
      BoundaryRules.suppressions(file: $0.path, source: $0.source)
    }
    let comments = Dictionary(
      files.map { ($0.path, $0.source.comments) },
      uniquingKeysWith: { first, _ in first }
    )
    let findings = BoundaryRules.reconcile(
      suppressions: suppressions,
      comments: comments,
      ledger: SuppressionLedger.entries
    )

    #expect(findings.isEmpty, "\(PackageTree.describe(findings))")
    #expect(suppressions.count == SuppressionLedger.entries.count)
  }
}
