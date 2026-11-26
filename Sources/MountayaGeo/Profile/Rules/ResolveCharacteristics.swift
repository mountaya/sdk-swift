/// resolveCharacteristics is an itinerary's figures as a surface states them: each the one
/// `stated` holds, the server's, over the one `derived` reads off the geometry, figure by figure,
/// so a figure the server left out is still stated where the geometry answers it. The geometry's
/// lowest and highest altitude are the altitude band and its steepest grade the steepest ascent;
/// the duration, the steepest descent and the difficulties have no derived figure, and are the
/// stated ones or none.
public func resolveCharacteristics(_ derived: ProfileTotals, stated: ProfileCharacteristics?)
  -> ResolvedCharacteristics
{
  ResolvedCharacteristics(
    distance: stated?.distance ?? derived.distance,
    duration: stated?.duration,
    ascent: stated?.ascent.map(Double.init) ?? derived.ascent,
    descent: stated?.descent.map(Double.init) ?? derived.descent,
    altitudeMin: stated?.altitudeMin.map(Double.init) ?? derived.elevationMin,
    altitudeMax: stated?.altitudeMax.map(Double.init) ?? derived.elevationMax,
    slopeMin: stated?.slopeMin,
    slopeMax: stated?.slopeMax ?? derived.gradeMax,
    trailDifficultyMin: stated?.trailDifficultyMin,
    trailDifficultyMax: stated?.trailDifficultyMax
  )
}
