import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// dataSegmentGroups answers the case's chain of `segments` projected with its `groups`
  /// collapsed.
  ///
  /// Each segment and group is built as the REST API's, from the members the fixture writes and a
  /// placeholder for every other the type requires. The fixture's segments are not quite the
  /// wire's: a mode of `ROUTED`, which the open mode keeps as written, a creator written as its id
  /// where the wire writes a user, and no colour, name or revision, as `geo/segment-groups.json`
  /// writes them and `CONTRACT-GAPS.md`'s row for it says. So the
  /// projected chain is written back as the wire's own encoder writes it, a creator as its id: a
  /// segment that passes as itself with the members its case wrote, and a collapsed one with every
  /// member of the wire's segment.
  static let dataSegmentGroups = Runner(id: "geo.data.segment-groups", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var written: [(segment: RestSchema.ItinerarySegment, keys: [String])] = []
    for fields in try input.array(at: "segments") {
      written.append(
        (try GeoProfileFixtures.segment(fields), (fields.members ?? []).map(\.key)))
    }
    var groups: [RestSchema.ItinerarySegmentGroup] = []
    for group in try input.array(at: "groups") {
      groups.append(
        RestSchema.ItinerarySegmentGroup(
          color: try group.string(at: "color"),
          created_at: try GeoProfileFixtures.instant(try group.string(at: "created_at")),
          created_by: RestSchema.RelationToUser(id: try group.string(at: "created_by")),
          id: try group.string(at: "id"),
          itinerary_id: try group.string(at: "itinerary_id"),
          name: try group.string(at: "name"),
          revision: try group.integer(at: "revision"),
          speed: try group.optionalNumber(at: "speed")
        ))
    }
    let projected = applySegmentGroups(written.map(\.segment), groups: groups)
    var answer: [OrderedJSON] = []
    for segment in projected {
      let wire = try wireValue(segment)
      let keys =
        written.first { $0.segment == segment }?.keys ?? (wire.members ?? []).map(\.key)
      var members: [OrderedJSON.Member] = []
      for key in keys {
        guard let value = wire[key] else {
          throw FixtureError(description: "the wire's segment has no member `\(key)`")
        }
        // The fixture writes a creator as its id.
        let spelled = key == "created_by" ? (value["id"] ?? value) : value
        members.append(OrderedJSON.Member(key: key, value: spelled))
      }
      answer.append(.object(members))
    }
    return .value(.array(answer))
  }

  /// unnamedRoadAccessValue is a value no access tag spells, which the table must not name: the
  /// probe the kind of a value the table does not name, which Geo keeps to its rule, is read back
  /// through.
  private static let unnamedRoadAccessValue = "not-an-access-value"

  /// dataRoadAccessKinds answers the kind a stretch of the case's `values` is shown as, or null.
  ///
  /// The kinds, most severe first, and the kind each value names are held to the ones Geo
  /// publishes, and the kind of a value the table does not name, which Geo keeps to its rule, to
  /// what the rule answers for one. A case's values are asked through both surfaces' types, REST's
  /// and the Data API's, since a value is read in either spelling whichever type it arrives in, and
  /// the two must agree.
  static let dataRoadAccessKinds = Runner(id: "geo.data.road-access-kinds", table: .public) {
    fixture, fixtureCase in
    let unnamed = RestSchema.RoadAccessRestrictionType(rawValue: unnamedRoadAccessValue)
    guard roadAccessValueKinds.index(forKey: unnamed) == nil else {
      throw FixtureError(description: "the table names `\(unnamedRoadAccessValue)`")
    }
    let kinds = roadAccessValueKinds.sorted { $0.key.rawValue < $1.key.rawValue }.map {
      OrderedJSON.Member(key: $0.key.rawValue, value: $0.value.map { .string($0.id) } ?? .null)
    }
    try fixture.holdConstants(
      [:],
      values: [
        "kinds": GeoFixtures.texts(RoadAccessKind.allCases.map(\.id)),
        "valueKinds": .object(kinds),
        "unknownValueKind": roadAccessKindOf([unnamed]).map { .string($0.id) } ?? .null,
      ])
    let values = try GeoFixtures.textList(fixtureCase.input, at: "values")
    let rest = roadAccessKindOf(values.map { RestSchema.RoadAccessRestrictionType(rawValue: $0) })
    let data = roadAccessKindOf(values.map { DataSchema.RoadAccessRestrictionType(rawValue: $0) })
    guard rest == data else {
      throw FixtureError(
        description: "REST's values read as \(rest?.id ?? "none"), and the Data API's as "
          + "\(data?.id ?? "none")")
    }
    return .value(rest.map { .string($0.id) } ?? .null)
  }

  /// formatLocaleServices answers a number, a date or a time of day written by the platform's
  /// locale services for the case's `locale`, never assembled. A number takes the one option the
  /// fixture names, `maximumFractionDigits`; an instant is the fixture's `referenceDate` in its
  /// `timeZone`, the two constants every `dateTime` case reads, or in the zone the case names, its
  /// date at the `DateLength` its `dateLength` names, its time of day at the `TimeLength` its
  /// `timeLength` names, or both, and null where the zone data holds no such zone. A case naming
  /// neither length, a length neither type holds, or any other option fails rather than being
  /// read past.
  ///
  /// The strings are those CLDR 44 to 48 write alike, as the fixture's description scopes them: a
  /// platform whose data writes another fails the case there, and no digit is assembled to match.
  static let formatLocaleServices = Runner(id: "geo.format.locale-services", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:], inputs: ["referenceDate", "timeZone"])
    let input = fixtureCase.input
    let locale = try input.string(at: "locale")
    let options = input["options"]
    switch try input.string(at: "kind") {
    case "number":
      let unknown = (options?.members ?? []).map(\.key).filter { $0 != "maximumFractionDigits" }
      guard unknown.isEmpty else {
        throw FixtureError(description: "the runner knows no number option \(unknown.sorted())")
      }
      let value = try input.number(at: "value")
      guard let digits = try options?.optionalInteger(at: "maximumFractionDigits") else {
        return .value(.string(formatNumber(value, locale: locale)))
      }
      return .value(.string(formatNumber(value, locale: locale, maximumFractionDigits: digits)))
    case "dateTime":
      guard options == nil else {
        throw FixtureError(description: "a date-time case names its lengths, and no options")
      }
      let dateLength = try input.optionalString(at: "dateLength").map { named in
        guard let length = DateLength(rawValue: named) else {
          throw FixtureError(description: "no date length is called `\(named)`")
        }
        return length
      }
      let timeLength = try input.optionalString(at: "timeLength").map { named in
        guard let length = TimeLength(rawValue: named) else {
          throw FixtureError(description: "no time length is called `\(named)`")
        }
        return length
      }
      guard dateLength != nil || timeLength != nil else {
        throw FixtureError(
          description: "a date-time case names a date length, a time length or both")
      }
      guard let constants = fixture.constants else {
        throw FixtureError(description: "the fixture declares no constants")
      }
      let zone = try input.optionalString(at: "timeZone") ?? constants.string(at: "timeZone")
      let text = formatDateTime(
        try GeoProfileFixtures.instant(try constants.string(at: "referenceDate")),
        locale: locale, timeZone: zone, dateLength: dateLength, timeLength: timeLength)
      return .value(text.map(OrderedJSON.string) ?? .null)
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind the runner knows")
    }
  }

  /// The JSON a segment is as the wire's own encoder writes it.
  private static func wireValue(_ segment: RestSchema.ItinerarySegment) throws(FixtureError)
    -> OrderedJSON
  {
    let data: Data
    do {
      data = try JSONEncoder().encode(segment)
    } catch {
      throw FixtureError(description: "the wire's encoder refuses the segment: \(error)")
    }
    do {
      return try OrderedJSON.parse(String(decoding: data, as: UTF8.self))
    } catch {
      throw FixtureError(description: "the wire's encoder writes no JSON: \(error)")
    }
  }
}
