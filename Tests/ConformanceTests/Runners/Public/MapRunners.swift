import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapEnginePatch answers what a map holds once the case's `patch` is merged onto its `held`
  /// members, through the map engine a consumer drives: a layer drawn with `held` as its paint, then
  /// edited with the patch, every member the case names `unstated` written as `nil`, which is how a
  /// Swift caller forwards a member it may not have, JSON having no `undefined` to write. What the
  /// layer holds after the edit is the answer. A case whose `drawn` is false patches a layer the map
  /// does not draw, and answers the kind of the refusal, the drawn layer held to be as it was.
  ///
  /// A case stating `spelled` patches with its members too, each the JSON text of its value, read
  /// as the map's own values are read, by `JSONDecoder` into the client's `JSONValue`, and answers
  /// `holds`, the layer's paint after the edit, and `changed`, whether the map's state differs from
  /// the one before it, as the map compares its states.
  static let mapEnginePatch = Runner(id: "map.engine.patch", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    let drawn = input["drawn"]?.boolValue ?? true
    let held = try GeoFixtures.jsonObject(input["held"] ?? .null, naming: "held")
    var patch: [String: JSONValue?] = try GeoFixtures.jsonObject(
      input["patch"] ?? .null, naming: "patch"
    ).mapValues { .some($0) }
    for member in input["unstated"] == nil ? [] : try GeoFixtures.textList(input, at: "unstated") {
      patch.updateValue(nil, forKey: member)
    }
    for member in input["spelled"]?.members ?? [] {
      guard let text = member.value.stringValue else {
        throw FixtureError(description: "`spelled.\(member.key)` is no JSON text")
      }
      patch[member.key] = .some(try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8)))
    }
    let spelled = input["spelled"] != nil
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(
        client: try MapFixtures.client(credential: .publishable(key: "pk_conformance")),
        geolocation: InertGeolocation())
      map.addLayer(
        MapLayer(
          id: "held", type: .circle, source: "held",
          rank: LayerRank.chrome.rank, paint: held))
      let before = map.state
      do throws(MapError) {
        try map.editLayer(drawn ? "held" : "not-drawn", paint: patch)
      } catch {
        guard map.state.layers.first(where: { $0.id == "held" })?.paint == held else {
          throw FixtureError(description: "a refused patch moved what the map holds")
        }
        return .refused(MapFixtures.kind(error))
      }
      guard let layer = map.state.layers.first(where: { $0.id == "held" }) else {
        throw FixtureError(description: "the map draws no layer it was given")
      }
      guard spelled else { return .value(GeoFixtures.ordered(layer.paint)) }
      return .value(
        .object([
          OrderedJSON.Member(key: "changed", value: .bool(map.state != before)),
          OrderedJSON.Member(key: "holds", value: GeoFixtures.ordered(layer.paint)),
        ]))
    }
  }
}
