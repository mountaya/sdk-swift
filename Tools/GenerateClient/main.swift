import ClientPrinter
import Foundation
import GateSupport

// The printer of SPEC.md section 3. Run at the repository root:
//
//   swift run GenerateClient           prints Sources/MountayaClient/Generated/ and
//                                      Sources/MountayaAdmin/Generated/ from the model, each
//                                      unit's surface into its target,
//                                      Sources/MountayaGeo/Generated/ from the elements' data,
//                                      and THIRD-PARTY-NOTICES.txt from the notice it carries
//   swift run GenerateClient --check   fails where the files on disk differ from what it prints
//
// The model is `sdk/model.json` in the contract checkout, and the elements' data the four files
// of `sdk/elements/` beside it: the sibling `../schemas`, or wherever MOUNTAYA_SCHEMAS_DIR points.
// The five are the inputs of `modelDigest` (`sdk/SPEC.md` section 11), taken over their bytes as
// the checkout holds them and printed beside `schemaVersion` and in every printed file's header.
// Without a checkout the check is skipped on a contributor's machine and fails in CI, as the
// conformance suite does.

let environment = ProcessInfo.processInfo.environment
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path)
else {
  FileHandle.standardError.write(Data("GenerateClient runs at the repository root.\n".utf8))
  exit(2)
}
let isCheck = CommandLine.arguments.dropFirst().contains("--check")

let schemas: URL
if let path = environment["MOUNTAYA_SCHEMAS_DIR"], !path.isEmpty {
  schemas = URL(fileURLWithPath: path)
} else {
  schemas = root.deletingLastPathComponent().appendingPathComponent("schemas")
}

/// read reads a file of the contract checkout, or stops the run where the checkout lacks it.
func read(_ path: String) -> String {
  let url = schemas.appendingPathComponent(path)
  guard let text = try? String(contentsOf: url, encoding: .utf8) else {
    let required = !(environment["CI"] ?? "").isEmpty
    let message = "GenerateClient: no \(path) in a contract checkout at \(schemas.path)"
    if isCheck, !required {
      print("\(message); the check is skipped")
      exit(0)
    }
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(2)
  }
  return text
}

let modelText = read("sdk/model.json")
let elements = (
  words: read("sdk/elements/words.json"), tokens: read("sdk/elements/tokens.json"),
  glyphs: read("sdk/elements/glyphs.json"), notice: read("sdk/elements/NOTICE")
)
let digest: String
do {
  digest = try ModelDigest.digest(ofCheckout: schemas)
} catch {
  FileHandle.standardError.write(Data("GenerateClient: \(error)\n".utf8))
  exit(2)
}

let client: [ClientUnit: [GeneratedFile]]
let geo: [GeneratedFile]
let notices: String
do {
  client = try ClientPrinter.files(for: try Model.parse(modelText), digest: digest)
  let data = try ElementsData.parse(
    words: elements.words, tokens: elements.tokens, glyphs: elements.glyphs,
    notice: elements.notice)
  geo = try ElementsPrinter.files(for: data, digest: digest)
  notices = try ElementsPrinter.notices(for: data)
} catch {
  FileHandle.standardError.write(Data("GenerateClient: \(error)\n".utf8))
  exit(2)
}

let printedTrees =
  ClientUnit.allCases.map { unit in
    (
      directory: ClientPrinter.directory(of: unit), files: client[unit] ?? [],
      source: "sdk/model.json"
    )
  } + [(directory: ElementsPrinter.directory, files: geo, source: "sdk/elements/")]
let noticesURL = root.appendingPathComponent(ElementsPrinter.noticesFile)

if isCheck {
  var failed = false
  for tree in printedTrees {
    let directory = root.appendingPathComponent(tree.directory)
    let onDisk = FileTree.files(under: directory)
    if let difference = FileTree.firstDifference(
      printed: tree.files, onDisk: onDisk, at: directory)
    {
      print(
        "\(tree.directory): \(onDisk.count) files on disk, \(tree.files.count) printed, "
          + difference + ". Run `swift run GenerateClient` and commit what it prints."
      )
      failed = true
    } else {
      print("\(tree.directory): \(tree.files.count) files match \(tree.source)")
    }
  }
  if (try? String(contentsOf: noticesURL, encoding: .utf8)) == notices {
    print("\(ElementsPrinter.noticesFile) matches sdk/elements/NOTICE")
  } else {
    print(
      "\(ElementsPrinter.noticesFile) is not what sdk/elements/NOTICE prints. Run "
        + "`swift run GenerateClient` and commit what it prints.")
    failed = true
  }
  exit(failed ? 1 : 0)
}

do {
  for tree in printedTrees {
    let directory = root.appendingPathComponent(tree.directory)
    try FileTree.write(tree.files, replacing: FileTree.files(under: directory), at: directory)
    print("\(tree.directory): \(tree.files.count) files printed from \(tree.source)")
  }
  if (try? String(contentsOf: noticesURL, encoding: .utf8)) != notices {
    try Data(notices.utf8).write(to: noticesURL)
  }
  print("\(ElementsPrinter.noticesFile) printed from sdk/elements/NOTICE")
} catch {
  FileHandle.standardError.write(Data("GenerateClient could not write: \(error)\n".utf8))
  exit(2)
}
