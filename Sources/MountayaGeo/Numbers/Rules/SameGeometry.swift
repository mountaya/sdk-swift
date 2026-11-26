import MountayaClient

/// sameGeometry tells whether two GeoJSON geometries are the same: of one `type`, every position
/// the same numbers in the same order and the same box, each number by the same-number relation,
/// `NaN` the same as `NaN` and 0 another than -0. The client's own `==` reads them by IEEE equality.
///
/// It is the package's, for the map's values, which compare the geometries they hold by it, as they
/// compare their positions by `sameNumbers(_:_:)`, and no consumer's: every value that holds a
/// geometry is `Hashable` by it.
package func sameGeometry(_ a: GeoJSONGeometry, _ b: GeoJSONGeometry) -> Bool {
  switch (a, b) {
  case (.point(let left), .point(let right)):
    return sameNumbers(left.coordinates, right.coordinates) && sameBox(left.bbox, right.bbox)
  case (.multiPoint(let left), .multiPoint(let right)):
    return samePositions(left.coordinates, right.coordinates) && sameBox(left.bbox, right.bbox)
  case (.lineString(let left), .lineString(let right)):
    return samePositions(left.coordinates, right.coordinates) && sameBox(left.bbox, right.bbox)
  case (.multiLineString(let left), .multiLineString(let right)):
    return sameLines(left.coordinates, right.coordinates) && sameBox(left.bbox, right.bbox)
  case (.polygon(let left), .polygon(let right)):
    return sameLines(left.coordinates, right.coordinates) && sameBox(left.bbox, right.bbox)
  case (.multiPolygon(let left), .multiPolygon(let right)):
    return left.coordinates.count == right.coordinates.count
      && zip(left.coordinates, right.coordinates).allSatisfy { sameLines($0, $1) }
      && sameBox(left.bbox, right.bbox)
  case (.geometryCollection(let left), .geometryCollection(let right)):
    return left.geometries.count == right.geometries.count
      && zip(left.geometries, right.geometries).allSatisfy { sameGeometry($0, $1) }
      && sameBox(left.bbox, right.bbox)
  default:
    return false
  }
}

/// sameGeometry tells whether two geometries a value may leave absent are the same: both absent,
/// or both present and the same geometry.
func sameGeometry(_ a: GeoJSONGeometry?, _ b: GeoJSONGeometry?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return sameGeometry(a, b)
  default: return false
  }
}

/// samePositions tells whether two lines hold the same positions in the same order.
func samePositions(_ a: [[Double]], _ b: [[Double]]) -> Bool {
  a.count == b.count && zip(a, b).allSatisfy { sameNumbers($0, $1) }
}

/// samePositions tells whether two lines a value may leave absent are the same.
func samePositions(_ a: [[Double]]?, _ b: [[Double]]?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return samePositions(a, b)
  default: return false
  }
}

/// sameBox tells whether two lists of numbers a value may leave absent, such as a box, are the same.
func sameBox(_ a: [Double]?, _ b: [Double]?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return sameNumbers(a, b)
  default: return false
  }
}

private func sameLines(_ a: [[[Double]]], _ b: [[[Double]]]) -> Bool {
  a.count == b.count && zip(a, b).allSatisfy { samePositions($0, $1) }
}

extension Hasher {
  /// Feeds a geometry as `sameGeometry(_:_:)` reads it: its kind, then every number as the
  /// same-number relation reads it.
  mutating func combine(sameGeometry geometry: GeoJSONGeometry) {
    switch geometry {
    case .point(let point):
      combine(0)
      combine(sameNumbers: point.coordinates)
      combine(sameBox: point.bbox)
    case .multiPoint(let points):
      combine(1)
      combine(samePositions: points.coordinates)
      combine(sameBox: points.bbox)
    case .lineString(let line):
      combine(2)
      combine(samePositions: line.coordinates)
      combine(sameBox: line.bbox)
    case .multiLineString(let lines):
      combine(3)
      combineLines(lines.coordinates)
      combine(sameBox: lines.bbox)
    case .polygon(let polygon):
      combine(4)
      combineLines(polygon.coordinates)
      combine(sameBox: polygon.bbox)
    case .multiPolygon(let polygons):
      combine(5)
      combine(polygons.coordinates.count)
      for polygon in polygons.coordinates {
        combineLines(polygon)
      }
      combine(sameBox: polygons.bbox)
    case .geometryCollection(let collection):
      combine(6)
      combine(collection.geometries.count)
      for member in collection.geometries {
        combine(sameGeometry: member)
      }
      combine(sameBox: collection.bbox)
    }
  }

  /// Feeds a geometry a value may leave absent: whether it is present, then the geometry.
  mutating func combine(sameGeometry geometry: GeoJSONGeometry?) {
    combine(geometry != nil)
    if let geometry {
      combine(sameGeometry: geometry)
    }
  }

  /// Feeds a line, its length then each position as the same-number relation reads it.
  mutating func combine(samePositions positions: [[Double]]) {
    combine(positions.count)
    for position in positions {
      combine(sameNumbers: position)
    }
  }

  /// Feeds a line a value may leave absent: whether it is present, then the line.
  mutating func combine(samePositions positions: [[Double]]?) {
    combine(positions != nil)
    if let positions {
      combine(samePositions: positions)
    }
  }

  /// Feeds a list of numbers a value may leave absent: whether it is present, then the numbers.
  mutating func combine(sameBox box: [Double]?) {
    combine(box != nil)
    if let box {
      combine(sameNumbers: box)
    }
  }

  private mutating func combineLines(_ lines: [[[Double]]]) {
    combine(lines.count)
    for line in lines {
      combine(samePositions: line)
    }
  }
}
