/// AnalysisHandle is what drawing a Data API result answers: the id the map draws it under, which
/// its edit and its removal name, and the result itself, the client's answer or the one handed
/// over (`map.analysis.slots`).
public struct AnalysisHandle<Result: Sendable>: Sendable {
  /// id is the id the result is drawn under.
  public let id: String
  /// result is the result drawn.
  public let result: Result

  /// Creates the handle of `result` drawn under `id`.
  public init(id: String, result: Result) {
    self.id = id
    self.result = result
  }
}

extension AnalysisHandle: Equatable where Result: Equatable {}
