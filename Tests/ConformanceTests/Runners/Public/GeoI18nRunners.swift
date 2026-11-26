import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// i18nBundleResolution answers the words the case's `bundle` resolves to in its `language`,
  /// English where it names none, with its `overrides` and the `translations` a host handed over.
  /// The bundle's `base` is its English and the translations it carries; the overrides are read as
  /// JSON writes them, so an override naming a language and a section together is the refusal,
  /// answered as the fixture writes it, `refused`.
  static let i18nBundleResolution = Runner(id: "geo.i18n.bundle-resolution", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let bundle = input["bundle"] else {
      throw FixtureError(description: "the case has no `bundle`")
    }
    var base = try languages(bundle["base"])
    guard let english = base.removeValue(forKey: .en) else {
      throw FixtureError(description: "the bundle's base carries no English")
    }
    var overrides: WordOverrides?
    if let written = input["overrides"], !written.isNull {
      guard let read = wordOverridesOf(try GeoFixtures.jsonObject(written, naming: "overrides"))
      else { return .value(.string("refused")) }
      overrides = read
    }
    let resolved = resolveBundle(
      WordBundle(english: english, translations: base, partial: try languages(bundle["partial"])),
      language: try input.optionalString(at: "language").map(RestSchema.Language.init(rawValue:))
        ?? .en,
      overrides: overrides, handedOver: try languages(input["translations"]))
    return .value(GeoFixtures.ordered(resolved))
  }

  /// i18nLocalizedName answers the display name of the case's catalogue `entry` in its `language`.
  /// The entry's `locales` are built as the REST API's, each language's strings as the fixture
  /// writes them.
  static let i18nLocalizedName = Runner(id: "geo.i18n.localized-name", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let entry = input["entry"], let written = entry["locales"] else {
      throw FixtureError(description: "the case has no `entry` with `locales`")
    }
    func strings(_ language: String) -> RestSchema.LocaleMap? {
      guard let names = written[language]?.members else { return nil }
      return Dictionary(
        names.map { ($0.key, $0.value.stringValue) }, uniquingKeysWith: { _, last in last })
    }
    let locales = RestSchema.Locales(
      de: strings("de"), en: strings("en"), es: strings("es"), fr: strings("fr"),
      it: strings("it"), ja: strings("ja"), zh: strings("zh"))
    return .value(
      .string(
        localizedName(
          locales: locales, slug: try entry.string(at: "slug"),
          language: try input.optionalString(at: "language"))))
  }

  /// The words per language a record writes, keyed by the wire's spelling of each language.
  private static func languages(_ record: OrderedJSON?) throws(FixtureError)
    -> [RestSchema.Language: [String: JSONValue]]
  {
    guard let record, !record.isNull else { return [:] }
    guard let members = record.members else {
      throw FixtureError(description: "a set of languages is not an object")
    }
    var words: [RestSchema.Language: [String: JSONValue]] = [:]
    for member in members {
      words[RestSchema.Language(rawValue: member.key)] = try GeoFixtures.jsonObject(
        member.value, naming: member.key)
    }
    return words
  }
}
