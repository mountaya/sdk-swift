extension KeyedDecodingContainer {
  /// decodeMerge reads a property a merge body declares optional and nullable, whose three
  /// states are three instructions: absent leaves the stored value, `null` clears it, and a
  /// value replaces it.
  package func decodeMerge<Value: Decodable>(_ type: Value.Type, forKey key: Key) throws -> Value??
  {
    guard contains(key) else { return nil }
    if try decodeNil(forKey: key) {
      return .some(nil)
    }
    return .some(try decode(type, forKey: key))
  }

  /// decodeWired reads a required property through its wire form.
  package func decodeWired<Value: WireCoded>(_ type: Value.Type, forKey key: Key) throws -> Value {
    Value(wire: try decode(Value.Wire.self, forKey: key))
  }

  /// decodeWiredIfPresent reads an optional property through its wire form, `nil` standing for
  /// an absent key and for `null`.
  package func decodeWiredIfPresent<Value: WireCoded>(_ type: Value.Type, forKey key: Key) throws
    -> Value?
  {
    try decodeIfPresent(Value.Wire.self, forKey: key).map(Value.init(wire:))
  }

  /// decodeWiredMerge reads a merge property's three states through its wire form.
  package func decodeWiredMerge<Value: WireCoded>(_ type: Value.Type, forKey key: Key) throws
    -> Value??
  {
    try decodeMerge(Value.Wire.self, forKey: key).map { $0.map(Value.init(wire:)) }
  }
}
