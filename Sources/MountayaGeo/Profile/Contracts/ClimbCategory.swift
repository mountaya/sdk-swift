/// ClimbCategory is the category a climb is badged with, in ascending severity, the roadbook's
/// vocabulary: Cat 4, the lightest categorized climb, through Cat 1, then hors catégorie, beyond
/// categorization. Each is spelled by its contract id and reached at `minimumScore`, a climb's
/// length in meters times its average grade in percent.
///
/// The cases are declared in ascending severity, the order `allCases` yields and the order a climb
/// is categorized in, which is not the order of their ids.
public enum ClimbCategory: String, CaseIterable, Sendable {
  /// category4 is Cat 4, from a score of 8,000: 2 km at 4 %.
  case category4 = "4"
  /// category3 is Cat 3, from 16,000: 4 km at 4 %.
  case category3 = "3"
  /// category2 is Cat 2, from 32,000: 4 km at 8 %.
  case category2 = "2"
  /// category1 is Cat 1, from 64,000: 6.4 km at 10 %.
  case category1 = "1"
  /// horsCategorie is hors catégorie, from 80,000: 8 km at 10 %.
  case horsCategorie = "hc"

  /// id is the category as `geo/climbs.json` spells it, `4` to `1`, then `hc`.
  public var id: String { rawValue }

  /// minimumScore is the least score of the category.
  public var minimumScore: Double {
    switch self {
    case .category4: 8_000
    case .category3: 16_000
    case .category2: 32_000
    case .category1: 64_000
    case .horsCategorie: 80_000
    }
  }
}
