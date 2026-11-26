/// profileScrubColumns is how many equal columns a scrub reads a profile's window through, the
/// `columns` `geo/profile-scrub-grid.json` declares: on a chart three hundred points wide a little
/// over one point a column, finer than a pointer is read and than a curve of five hundred samples
/// can show. It is a count rather than a width, so a chart reads its pointer without measuring
/// itself, and a column is exactly what a key press steps.
public let profileScrubColumns = 240

/// scrubGrid is the sample each column of a scrub over `window` resolves to, column by column from
/// the window's start (`geo.profile.scrub-grid`): the one `nearestSampleIndex(_:distance:)` finds
/// nearest the distance at the column's centre, `scrubDistance(column:window:)`, and nil for a
/// series with no sample. A chart reads a pointer and a key press through the same grid, and a
/// navigator drags through it.
public func scrubGrid(_ points: [ElevationPoint], window: ProfileRange) -> [Int?] {
  (0..<profileScrubColumns).map {
    nearestSampleIndex(points, distance: scrubDistance(column: $0, window: window))
  }
}

/// scrubDistance is the distance column `column` of a scrub over `window` stands for, in meters from
/// the itinerary's start: `window.from + (column + 0.5) / profileScrubColumns` of the window's width,
/// the window read as given (`geo.profile.scrub-grid`). A window's edge a navigator drags is a place
/// on the axis rather than a sample, so it moves by this distance and never snaps to a sample.
public func scrubDistance(column: Int, window: ProfileRange) -> Double {
  window.from + (Double(column) + 0.5) / Double(profileScrubColumns) * (window.to - window.from)
}
