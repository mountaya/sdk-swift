import Foundation
import GateSupport
import Testing

@Suite("Scope")
struct ScopeTests {
  /// Returns the text of SPEC.md section 11, from its heading to the next one of its level.
  private func deliberateDivergences() throws -> String {
    let root = try #require(SourceTree.packageRoot(from: #filePath))
    let spec = try #require(SourceTree.read(root.appendingPathComponent("SPEC.md")))
    let lines = spec.split(separator: "\n", omittingEmptySubsequences: false)
    let start = try #require(lines.firstIndex { $0.hasPrefix("## 11. ") })
    let rest = lines[(start + 1)...]
    let end = rest.firstIndex { $0.hasPrefix("## ") } ?? lines.endIndex
    return lines[start..<end].joined(separator: "\n")
  }

  @Test("every scope rule is a sentence of SPEC.md section 11", arguments: Scope.rules)
  func ruleIsADeliberateDivergence(rule: Scope.Rule) throws {
    let section = try deliberateDivergences()

    #expect(
      section.contains("- **\(rule.bullet)**"),
      "SPEC.md section 11 has no bullet opening with \"\(rule.bullet)\""
    )
  }

  @Test("every scope rule scopes something the registry declares")
  func rulesScopeDeclaredCapabilities() throws {
    guard let registry = try Conformance.contract.get()?.registry else { return }
    let unused = Coverage.unusedScopeRules(registry: registry)

    #expect(unused.isEmpty, "scope rules that scope nothing: \(unused)")
  }
}
