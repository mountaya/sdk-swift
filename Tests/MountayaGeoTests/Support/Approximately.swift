/// isClose tells whether a number lies within a distance of the one a test expects, the way a
/// test states a value that the platform's transcendental functions may move by an ulp.
func isClose(_ actual: Double, _ expected: Double, within tolerance: Double) -> Bool {
  abs(actual - expected) <= tolerance
}

/// areClose tells whether two lists hold as many numbers, each within a distance of the other's.
func areClose(_ actual: [Double], _ expected: [Double], within tolerance: Double) -> Bool {
  actual.count == expected.count
    && zip(actual, expected).allSatisfy { isClose($0, $1, within: tolerance) }
}
