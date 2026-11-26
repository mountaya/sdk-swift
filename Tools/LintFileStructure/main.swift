import Foundation
import GateSupport

// The layout gate of SPEC.md section 6. Run once, at the repository root:
// `swift run LintFileStructure`.
//
// It holds every file under `Sources/` to `<Topic>/<Kind>/<Type>.swift`, with a kind from the
// closed set, a name matching the type the file declares, no empty directory, and a test at
// the mirrored path under `Tests/`.

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path)
else {
  FileHandle.standardError.write(Data("LintFileStructure runs at the repository root.\n".utf8))
  exit(2)
}

let report = FileStructureRules.check(packageRoot: root)
for finding in report.findings {
  print("\(finding.path): \(finding.message)")
}
print("\(report.checked) files checked, \(report.findings.count) findings")
exit(report.passes ? 0 : 1)
