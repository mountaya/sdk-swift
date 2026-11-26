import Foundation
import Testing

@testable import MountayaClient

@Suite("KeyedDecodingContainer")
struct KeyedDecodingContainerTests {
  /// Probe reads one key every way the generated types read one.
  private struct Probe: Decodable {
    let merge: String??
    let wiredMerge: Date??
    let wired: [Date]?

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      merge = try container.decodeMerge(String.self, forKey: "value")
      wiredMerge = try container.decodeWiredMerge(Date.self, forKey: "when")
      wired = try container.decodeWiredIfPresent([Date].self, forKey: "dates")
    }
  }

  @Test("a merge property reads absent, null and a value as three states")
  func merge() throws {
    let absent = try ScriptedSender.decode(Probe.self, from: "{}")
    let cleared = try ScriptedSender.decode(Probe.self, from: #"{"value": null, "when": null}"#)
    let set = try ScriptedSender.decode(
      Probe.self,
      from: #"{"value": "x", "when": "1970-01-01T00:00:00Z", "dates": ["1970-01-01T00:00:01Z"]}"#
    )

    #expect(absent.merge == .none && absent.wiredMerge == .none && absent.wired == nil)
    #expect(cleared.merge == .some(nil) && cleared.wiredMerge == .some(nil))
    #expect(set.merge == .some("x"))
    #expect(set.wiredMerge == .some(Date(timeIntervalSince1970: 0)))
    #expect(set.wired == [Date(timeIntervalSince1970: 1)])
  }
}
