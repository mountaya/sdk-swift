/// namesPlace tells whether a position names a place: it states a longitude and a latitude, its
/// first two values, and both are finite numbers. An altitude is no part of the place, so a
/// position with none, or with one that is `NaN`, still names one.
///
/// It is the one statement of the rule every geo rule reads a position by. A position written
/// short, or with a longitude or a latitude that is `NaN` or infinite, names none. A value past
/// the range, such as `[190, 95]`, still names a place, which each rule reads its own way.
func namesPlace(_ position: [Double]) -> Bool {
  position.count >= 2 && position[0].isFinite && position[1].isFinite
}
