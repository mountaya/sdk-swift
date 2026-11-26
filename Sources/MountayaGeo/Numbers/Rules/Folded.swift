/// folded is a figure held so far and one a value states, combined by `combine`, either left out
/// where it is nil, and nil where both are: how a summary folds figures its parts may each leave
/// unstated.
func folded<Figure>(_ held: Figure?, _ stated: Figure?, by combine: (Figure, Figure) -> Figure)
  -> Figure?
{
  guard let held else { return stated }
  guard let stated else { return held }
  return combine(held, stated)
}
