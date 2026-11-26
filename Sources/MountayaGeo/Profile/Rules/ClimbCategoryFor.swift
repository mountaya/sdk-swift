/// minClimbGradePercent is the average grade under which a stretch is never a categorized climb
/// whatever its length, the `minGradePercent` `geo/climbs.json` declares: a 2 % false flat scores no
/// category even over 50 km.
public let minClimbGradePercent: Double = 3

/// climbCategoryFor is the category of a climb `lengthMeters` long at an average grade of
/// `avgGradePercent`: the hardest whose `minimumScore` the score, the length times the grade,
/// reaches. 4 km at 4 % scores 16,000, Cat 3, and 8 km at 10 % 80,000, hors catégorie.
///
/// Nil under a `minClimbGradePercent` grade, never categorized, under the Cat 4 score, too easy to
/// badge, and where either figure is no finite number.
public func climbCategoryFor(lengthMeters: Double, avgGradePercent: Double) -> ClimbCategory? {
  guard lengthMeters.isFinite, avgGradePercent.isFinite, avgGradePercent >= minClimbGradePercent
  else { return nil }
  let score = lengthMeters * avgGradePercent
  return ClimbCategory.allCases.last { score >= $0.minimumScore }
}
