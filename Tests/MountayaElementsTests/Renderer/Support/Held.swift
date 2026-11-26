import Observation
import SwiftUI

/// Held is a value a test holds for a view, as an app holds its own state, and hands the view as a
/// binding.
@MainActor
@Observable
public final class Held<Value> {
  /// value is what the test holds.
  public var value: Value

  /// Creates a hold of `value`.
  public init(_ value: Value) {
    self.value = value
  }

  /// binding is the value as a view takes it.
  public var binding: Binding<Value> {
    Bindable(self).value
  }
}
