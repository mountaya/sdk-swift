/// InfoRange is one entry of a segment's analysis, as the wire's `slope_info`, `surface_info` and
/// the rest carry it: an inclusive range of vertex indexes and the value that holds over it. The
/// indexes count the vertices of every line the segment holds, laid end to end.
///
/// Two are equal where they hold the same indexes and the same value, a number compared as every
/// value of the geo layer compares.
public struct InfoRange<Value> {
  /// fromIndex is the index of the range's first vertex.
  public var fromIndex: Int
  /// toIndex is the index of its last vertex.
  public var toIndex: Int
  /// value is the value over the range.
  public var value: Value

  /// Creates an entry from its indexes and its value.
  public init(fromIndex: Int, toIndex: Int, value: Value) {
    self.fromIndex = fromIndex
    self.toIndex = toIndex
    self.value = value
  }
}

extension InfoRange: Sendable where Value: Sendable {}

extension InfoRange: Equatable where Value: Equatable {
  /// Two entries are equal where the indexes are one and the values the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.fromIndex == rhs.fromIndex && lhs.toIndex == rhs.toIndex && sameValue(lhs.value, rhs.value)
  }
}

extension InfoRange: Hashable where Value: Hashable {
  /// hash feeds the indexes, then the value as the same-value relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(fromIndex)
    hasher.combine(toIndex)
    hasher.combine(sameValue: value)
  }
}
