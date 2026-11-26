/// stepsTile tells whether steps cover a geometry of `coordinateCount` vertices once, in travel
/// order: the first step starts on vertex 0, each later one starts on the vertex the one before it
/// ends on, the last ends on the last vertex, and none ends before it starts, which holds every
/// index within the geometry as well. A step may start and end on one vertex.
///
/// An empty list tiles nothing.
func stepsTile(_ steps: [NavigationStep], coordinateCount: Int) -> Bool {
  var expected = 0
  for step in steps {
    if step.fromIndex != expected || step.toIndex < step.fromIndex { return false }
    expected = step.toIndex
  }
  return !steps.isEmpty && expected == coordinateCount - 1
}

/// refusedSteps is the reading of a refused list: refused, and no steps.
let refusedSteps = NavigationStepsReading(refused: true, steps: [])

/// stepsReading answers steps read to the tiling rule, whole: as they are where there are none or
/// they tile a geometry of `coordinateCount` vertices, and refused, with no steps, otherwise. A
/// list is refused rather than repaired, since a repair would be a guess at where a maneuver is.
func stepsReading(_ steps: [NavigationStep], coordinateCount: Int) -> NavigationStepsReading {
  if steps.isEmpty || stepsTile(steps, coordinateCount: coordinateCount) {
    return NavigationStepsReading(refused: false, steps: steps)
  }
  return refusedSteps
}
