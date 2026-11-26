extension KeyedEncodingContainer {
  /// encodeMerge writes a property a merge body declares optional and nullable: nothing for
  /// `nil`, which leaves the stored value, `null` for `.some(nil)`, which clears it, and the
  /// value otherwise.
  package mutating func encodeMerge<Value: Encodable>(_ value: Value??, forKey key: Key) throws {
    switch value {
    case .none:
      return
    case .some(.none):
      try encodeNil(forKey: key)
    case .some(.some(let value)):
      try encode(value, forKey: key)
    }
  }

  /// encodeNullable writes a property the contract requires and lets be null: `null` for
  /// `nil`, since there the null is the instruction and leaving the key out is not one.
  package mutating func encodeNullable<Value: Encodable>(_ value: Value?, forKey key: Key) throws {
    if let value {
      try encode(value, forKey: key)
    } else {
      try encodeNil(forKey: key)
    }
  }

  /// encodeWired writes a required property in its wire form.
  package mutating func encodeWired<Value: WireCoded>(_ value: Value, forKey key: Key) throws {
    try encode(value.wire, forKey: key)
  }

  /// encodeWiredIfPresent writes an optional property in its wire form, and nothing for `nil`.
  package mutating func encodeWiredIfPresent<Value: WireCoded>(_ value: Value?, forKey key: Key)
    throws
  {
    try encodeIfPresent(value.map(\.wire), forKey: key)
  }

  /// encodeWiredNullable writes a required, nullable property in its wire form, and `null` for
  /// `nil`.
  package mutating func encodeWiredNullable<Value: WireCoded>(_ value: Value?, forKey key: Key)
    throws
  {
    try encodeNullable(value.map(\.wire), forKey: key)
  }

  /// encodeWiredMerge writes a merge property's three states in its wire form.
  package mutating func encodeWiredMerge<Value: WireCoded>(_ value: Value??, forKey key: Key) throws
  {
    try encodeMerge(value.map { $0.map(\.wire) }, forKey: key)
  }
}
