import MountayaClient

/// trailDifficultyRank is the rank of a trail difficulty within its scale, the
/// `trailDifficultyRank` `geo/profile-characteristics.json` declares: the SAC hiking scale from
/// `hiking`, 1, to `difficult-alpine-hiking`, 6, and the mountain-biking scale from `mtb-0`, 0, to
/// `mtb-6`, 6.
///
/// Nil for `unknown`, a way that carries no difficulty, and for a grade the contract adds after
/// this build: neither has a place on the range.
public func trailDifficultyRank(_ difficulty: RestSchema.TrailDifficultyType) -> Int? {
  switch difficulty {
  case .hiking: 1
  case .mountainHiking: 2
  case .demandingMountainHiking: 3
  case .alpineHiking: 4
  case .demandingAlpineHiking: 5
  case .difficultAlpineHiking: 6
  case .mtb0: 0
  case .mtb1: 1
  case .mtb2: 2
  case .mtb3: 3
  case .mtb4: 4
  case .mtb5: 5
  case .mtb6: 6
  default: nil
  }
}
