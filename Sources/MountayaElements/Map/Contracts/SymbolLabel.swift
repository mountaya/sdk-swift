import MountayaClient

/// SymbolLabel is the label a symbol layer draws: the layer's id and its `text-field`.
struct SymbolLabel: Sendable, Equatable {
  /// id is the symbol layer's id.
  let id: String
  /// textField is the label, as a style writes a `text-field`.
  let textField: JSONValue
}
