import GateSupport

extension Fixture {
  /// holdConstants holds every constant the fixture declares to the value the SDK's own rule
  /// states for it, each read back through what the rule answers, within the fixture's tolerance
  /// or exactly where it states none.
  ///
  /// `rules` holds the constants that are one number. `values` holds the ones that are no single
  /// number, such as a ramp, a rank table or a vocabulary, each compared as a case's answer is.
  /// A constant the fixture declares and neither names fails, so a constant the contract adds is
  /// caught the day it lands rather than read past.
  ///
  /// `inputs` names the constants the cases read as their own input, such as a reference date, and
  /// `unstated` the ones no case reads and no rule of this SDK states, each a row of
  /// `CONTRACT-GAPS.md`. Both are held to nothing, since a value held to itself proves nothing, and
  /// each must still be declared, so one the contract drops is noticed too.
  func holdConstants(
    _ rules: [String: Double],
    values: [String: OrderedJSON] = [:],
    inputs: Set<String> = [],
    unstated: Set<String> = []
  ) throws(FixtureError) {
    let declared = constants?.members ?? []
    for member in declared where !unstated.contains(member.key) && !inputs.contains(member.key) {
      if let stated = values[member.key] {
        let mismatches = Comparison.mismatches(
          actual: stated, expected: member.value, tolerance: tolerance, at: member.key)
        guard mismatches.isEmpty else {
          throw FixtureError(
            description: "the fixture declares \(member.key), and the rule states another value: "
              + mismatches.joined(separator: "; "))
        }
        continue
      }
      guard let value = member.value.numberValue else {
        throw FixtureError(description: "the constant `\(member.key)` is not a number")
      }
      guard let stated = rules[member.key] else {
        throw FixtureError(
          description: "the fixture declares `\(member.key)`, which no rule here states")
      }
      guard Comparison.agrees(actual: stated, expected: value, tolerance: tolerance) else {
        throw FixtureError(
          description:
            "the fixture declares \(member.key) as \(value), and the rule states \(stated)"
        )
      }
    }
    let undeclared = Set(rules.keys).union(values.keys).union(inputs).union(unstated)
      .subtracting(declared.map(\.key))
    guard undeclared.isEmpty else {
      throw FixtureError(
        description: "the fixture no longer declares \(undeclared.sorted().joined(separator: ", "))"
      )
    }
  }
}
