import Foundation
import GateSupport
import MountayaClient
import Testing

/// The report this SDK files with the contract. What a run does with it is decided by
/// `MOUNTAYA_CONFORMANCE_REPORT`: unset, nothing is read or written; `write` writes
/// `sdk/reports/swift.json` in the checkout, from macOS only; `check` fails when that file is
/// not what this run would write, which is how the Linux run is held to the macOS one. The names
/// it reports are read off the committed API baselines, which every host reads alike, and its
/// `modelDigest` is the digest of the files in the checkout the run read, which a run refuses to
/// report while the printed `modelDigest` names other files.
@Suite("Report")
struct ReportTests {
  @Test("the report on file is the one this run produces")
  func report() async throws {
    let mode = ProcessInfo.processInfo.environment[ConformanceReport.modeVariable] ?? ""
    if mode.isEmpty {
      return
    }
    let only = ProcessInfo.processInfo.environment[Conformance.onlyVariable] ?? ""
    try #require(
      only.isEmpty,
      "a report covers every capability, so it cannot be produced by a narrowed run"
    )
    let contract = try #require(
      try Conformance.contract.get(),
      "a report needs the contract checkout"
    )
    let digest = try ModelDigest.digest(ofCheckout: contract.checkout.directory)
    try #require(
      digest == MountayaClient.modelDigest,
      """
      the client was printed from the files whose digest is \(MountayaClient.modelDigest), and the \
      checkout's digest to \(digest): run `swift run GenerateClient` before a report, since its \
      ticks would be earned by a surface printed from other files
      """
    )
    let rendered = ConformanceReport.render(
      registryVersion: contract.registry.version,
      modelDigest: digest,
      statuses: await Conformance.statuses(of: contract),
      published: Coverage.reportedNames(
        registry: contract.registry, declared: try Coverage.declaredNames())
    )

    switch mode {
    case "write":
      #if os(macOS)
        try rendered.write(to: contract.checkout.reportUrl, atomically: true, encoding: .utf8)
      #else
        Issue.record("the report is written by the macOS run; this host checks it")
      #endif
    case "check":
      let onFile = SourceTree.read(contract.checkout.reportUrl)
      #expect(
        onFile == rendered,
        """
        sdk/reports/\(ConformanceReport.sdk).json \(onFile == nil ? "is absent" : "differs from this run"). \
        This run produces:
        \(rendered)
        """
      )
    default:
      Issue.record(
        "\(ConformanceReport.modeVariable) is `\(mode)`, expected `write`, `check` or nothing"
      )
    }
  }
}
