import Foundation
import GateSupport

// The naming gate of SPEC.md section 5. Run once, at the repository root: `swift run LintNaming`.
//
// It reads every shipped target's declarations from the compiler's symbol graph, applies the
// law to each, and prints "N checked, M exempt" so a reviewer sees the exemptions move. On macOS
// it reads the graph of an iOS simulator build with every trait on as well, so the declarations
// behind a trait and `os(iOS)`, which the host builds none of, are held to the law too.

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path)
else {
  FileHandle.standardError.write(Data("LintNaming runs at the repository root.\n".utf8))
  exit(2)
}

do {
  let manifest = try PackageManifest.load(packageRoot: root)
  let modules = manifest.shippedTargets.map(\.name)
  var graphs = try SymbolGraph.dump(packageRoot: root, modules: modules)
  #if os(macOS)
    graphs += try SymbolGraph.dumpForIosSimulator(packageRoot: root, modules: modules)
    let read = "macOS and the iOS simulator with every trait"
    let exemptions = NamingExemptions.table.merging(NamingExemptions.guarded) { held, _ in held }
  #else
    let read = "this host; the declarations an iOS trait guards are read on macOS"
    let exemptions = NamingExemptions.table
  #endif
  let report = NamingRules.check(symbols: SymbolGraph.union(graphs), exemptions: exemptions)

  for finding in report.findings {
    let place = finding.location.map { " (\($0))" } ?? ""
    print("\(finding.name)\(place): [\(finding.rule)] \(finding.message)")
  }
  for name in report.staleExemptions {
    print("\(name): an exemption that names nothing the tree declares")
  }
  for name in report.exempt {
    print("exempt \(name): \(exemptions[name] ?? "")")
  }
  print("\(modules.joined(separator: ", ")), read on \(read): \(report.summary)")
  exit(report.passes ? 0 : 1)
} catch {
  FileHandle.standardError.write(Data("LintNaming could not run: \(error)\n".utf8))
  exit(2)
}
