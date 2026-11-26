import Foundation
import GateSupport
import Testing

@Suite("Conformance")
struct ConformanceTests {
  @Test("the contract checkout is present where a run requires it")
  func checkoutIsPresentWhereRequired() throws {
    let contract = try Conformance.contract.get()
    if ContractCheckout.isRequired {
      #expect(
        contract != nil,
        """
        No `sdk/registry.yaml` under \(ContractCheckout.expectedDirectory?.path ?? "the sibling directory"). \
        A run with `\(ContractCheckout.requiredVariable)` set must run the fixtures: check \
        `mountaya/schemas` out beside this repository, or point \
        `\(ContractCheckout.directoryVariable)` at it.
        """
      )
    }
  }

  @Test("conformance", arguments: Conformance.cases)
  func conformance(_ item: ConformanceCase) async {
    let problems = await Conformance.run(item)

    #expect(problems.isEmpty, "\(item.testDescription)\n\(problems.joined(separator: "\n"))")
  }

  @Test("scoped", arguments: Conformance.scoped)
  func scoped(_ item: ScopedCapability) {
    // Reported, never skipped. The sentence that scopes it is held to SPEC.md by `ScopeTests`,
    // and a runner for it is refused by `CoverageTests`.
    #expect(!Conformance.runners.contains { $0.id == item.capability.id })
  }
}
