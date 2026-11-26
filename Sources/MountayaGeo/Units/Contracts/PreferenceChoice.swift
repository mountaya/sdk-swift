/// PreferenceChoice is one preference a preferences picker offers (`geo.units.preference-choices`):
/// the field it sets, headed by the word of the elements' `preferences` section its raw value
/// names, and its options, in the order the contract lists them.
public struct PreferenceChoice: Sendable, Hashable {
  /// field is the preference the choice sets.
  public var field: PreferenceField
  /// options is the preference's options, in the order the contract lists them.
  public var options: [PreferenceOption]

  /// Creates a choice of `field` offering `options`.
  public init(field: PreferenceField, options: [PreferenceOption]) {
    self.field = field
    self.options = options
  }
}
