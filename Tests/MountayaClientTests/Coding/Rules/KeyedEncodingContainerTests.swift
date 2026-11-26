import Foundation
import Testing

@testable import MountayaClient

@Suite("KeyedEncodingContainer")
struct KeyedEncodingContainerTests {
  /// Probe writes one key every way the generated types write one.
  private struct Probe: Encodable {
    let merge: String??
    let nullable: String?
    let wiredMerge: Date??
    let wiredNullable: Date?

    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(merge, forKey: "merge")
      try container.encodeNullable(nullable, forKey: "nullable")
      try container.encodeWiredMerge(wiredMerge, forKey: "wiredMerge")
      try container.encodeWiredNullable(wiredNullable, forKey: "wiredNullable")
    }
  }

  @Test("nil leaves a merge property out and writes a required one as null")
  func absentAndNull() throws {
    let probe = Probe(merge: nil, nullable: nil, wiredMerge: .some(nil), wiredNullable: nil)

    #expect(
      try ScriptedSender.json(probe) == #"{"nullable":null,"wiredMerge":null,"wiredNullable":null}"#
    )
  }

  @Test("a value is written as itself, a timestamp in its wire form")
  func values() throws {
    let epoch = Date(timeIntervalSince1970: 0)
    let probe = Probe(merge: "x", nullable: "y", wiredMerge: epoch, wiredNullable: epoch)

    #expect(
      try ScriptedSender.json(probe)
        == #"{"merge":"x","nullable":"y","wiredMerge":"1970-01-01T00:00:00.000Z","#
        + #""wiredNullable":"1970-01-01T00:00:00.000Z"}"#
    )
  }
}
