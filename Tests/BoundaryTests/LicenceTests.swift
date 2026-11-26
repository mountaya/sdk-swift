import Foundation
import GateSupport
import Testing

/// The licence of SPEC.md section 10: the Mountaya SDK License 1.0, in English and French at the
/// root, carried verbatim and named for every product.
@Suite("Licence")
struct LicenceTests {
  static let texts = ["LICENSE.txt", "LICENCE.fr.txt"]

  @Test("both texts stand at the root and are named by the README and the manifest")
  func named() throws {
    let root = try ConsumerPackage.root()
    let readme = try #require(SourceTree.read(root.appendingPathComponent("README.md")))
    let manifest = try #require(SourceTree.read(root.appendingPathComponent("Package.swift")))

    for text in Self.texts {
      let licence = SourceTree.read(root.appendingPathComponent(text))
      #expect(licence?.contains("Version 1.0") == true, "\(text)")
      #expect(readme.contains("(\(text))"), "README.md does not link \(text)")
      #expect(manifest.contains(text), "Package.swift does not name \(text)")
    }
  }

  @Test("the third-party notices stand at the root with Lucide's licences, named by the README")
  func thirdParty() throws {
    let root = try ConsumerPackage.root()
    let readme = try #require(SourceTree.read(root.appendingPathComponent("README.md")))
    let notices = try #require(
      SourceTree.read(root.appendingPathComponent("THIRD-PARTY-NOTICES.txt")),
      "THIRD-PARTY-NOTICES.txt is missing: swift run GenerateClient prints it")

    #expect(readme.contains("(THIRD-PARTY-NOTICES.txt)"), "README.md does not link the notices")
    #expect(notices.contains("ISC License"))
    #expect(notices.contains("The MIT License"))
  }

  @Test("each text is the TypeScript packages' own, byte for byte, where that checkout is beside")
  func verbatim() throws {
    let root = try ConsumerPackage.root()
    let typescript = root.deletingLastPathComponent().appendingPathComponent("sdk-typescript")
    guard FileManager.default.fileExists(atPath: typescript.path) else { return }

    for text in Self.texts + [Self.examples] {
      let ours = FileManager.default.contents(atPath: root.appendingPathComponent(text).path)
      let theirs = FileManager.default.contents(
        atPath: typescript.appendingPathComponent(
          text == Self.examples ? Self.typescriptExamples : text
        ).path)
      #expect(ours != nil && ours == theirs, "\(text) differs from sdk-typescript's")
    }
  }

  /// examples is the examples' own licence: Trail is copied into apps, so it is MIT-licensed, as
  /// sdk-typescript's examples are, its text theirs, `typescriptExamples`, byte for byte.
  static let examples = "Examples/LICENSE"
  static let typescriptExamples = "examples/LICENSE"

  @Test("the examples carry the MIT licence, named by the README")
  func examplesLicence() throws {
    let root = try ConsumerPackage.root()
    let readme = try #require(SourceTree.read(root.appendingPathComponent("README.md")))
    let licence = try #require(
      SourceTree.read(root.appendingPathComponent(Self.examples)),
      "\(Self.examples) is missing: copy sdk-typescript's examples/LICENSE there")

    #expect(licence.hasPrefix("MIT License\n"))
    #expect(readme.contains("(\(Self.examples))"), "README.md does not link \(Self.examples)")
  }
}
