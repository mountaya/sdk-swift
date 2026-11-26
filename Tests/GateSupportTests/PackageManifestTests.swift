import GateSupport
import Testing

@Suite("PackageManifest")
struct PackageManifestTests {
  private static let description = """
    warning: a notice SwiftPM prints before the document
    {
      "name" : "sdk-swift",
      "products" : [
        { "name" : "MountayaGeo", "targets" : ["MountayaGeo"], "type" : { "library" : ["automatic"] } },
        { "name" : "LintNaming", "targets" : ["LintNaming"], "type" : { "executable" : null } }
      ],
      "targets" : [
        {
          "name" : "MountayaGeo", "path" : "Sources/MountayaGeo", "type" : "library",
          "sources" : ["Geodesy/Rules/Geodesy.swift"],
          "target_dependencies" : ["MountayaClient"]
        },
        {
          "name" : "MountayaClient", "path" : "Sources/MountayaClient", "type" : "library",
          "product_dependencies" : ["Crypto"]
        },
        { "name" : "GateSupport", "path" : "Tools/GateSupport", "type" : "library" },
        { "name" : "LintNaming", "path" : "Tools/LintNaming", "type" : "executable" }
      ]
    }
    """

  @Test("it reads targets, their dependencies and the products")
  func readsTheDescription() throws {
    let manifest = try PackageManifest.parse(Self.description)

    #expect(
      manifest.targets.map(\.name) == [
        "MountayaGeo", "MountayaClient", "GateSupport", "LintNaming",
      ])
    #expect(manifest.targets.first?.targetDependencies == ["MountayaClient"])
    #expect(manifest.targets.first?.sources == ["Geodesy/Rules/Geodesy.swift"])
    #expect(manifest.targets[1].productDependencies == ["Crypto"])
    #expect(manifest.products.map(\.isLibrary) == [true, false])
  }

  @Test("the shipped targets are the libraries under Sources, sorted by name")
  func shippedTargets() throws {
    let manifest = try PackageManifest.parse(Self.description)

    #expect(manifest.shippedTargets.map(\.name) == ["MountayaClient", "MountayaGeo"])
  }

  @Test("a description that is not the expected document is refused")
  func refusals() {
    #expect(throws: PackageManifestError.self) { try PackageManifest.parse("error: no manifest") }
    #expect(throws: PackageManifestError.self) { try PackageManifest.parse(#"{"name": "x"}"#) }
    #expect(throws: PackageManifestError.self) {
      try PackageManifest.parse(#"{"targets": [{"name": "x"}], "products": []}"#)
    }
  }
}
