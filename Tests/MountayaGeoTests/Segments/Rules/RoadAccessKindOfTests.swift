import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("roadAccessKindOf")
struct RoadAccessKindOfTests {
  private func rest(_ values: String...) -> RoadAccessKind? {
    roadAccessKindOf(values.map { RestSchema.RoadAccessRestrictionType(rawValue: $0) })
  }

  private func data(_ values: String...) -> RoadAccessKind? {
    roadAccessKindOf(values.map { DataSchema.RoadAccessRestrictionType(rawValue: $0) })
  }

  @Test("each value the contract names reads as its kind alone")
  func eachValue() {
    #expect(rest("no") == .forbidden)
    #expect(rest("private") == .private)
    #expect(rest("permit") == .permit)
    #expect(rest("service") == .service)
    #expect(rest("destination") == .localAccess)
    #expect(rest("customers") == .localAccess)
    #expect(rest("delivery") == .localAccess)
    #expect(rest("restricted") == .restricted)
    #expect(rest("unknown") == .restricted)
  }

  @Test("a value of no kind, and no value at all, read as none")
  func none() {
    #expect(rest("permissive") == nil)
    #expect(rest("agricultural") == nil)
    #expect(rest("forestry") == nil)
    #expect(rest("agricultural", "forestry", "permissive") == nil)
    #expect(rest() == nil)
    #expect(data() == nil)
  }

  @Test("the most severe kind among the values wins, whatever their order")
  func mostSevere() {
    #expect(rest("destination", "private") == .private)
    #expect(rest("private", "destination") == .private)
    #expect(rest("permit", "private", "no") == .forbidden)
    #expect(rest("customers", "service") == .service)
    #expect(rest("unknown", "delivery") == .localAccess)
    #expect(rest("permissive", "permit") == .permit)
  }

  @Test("a value the table does not name reads as restricted")
  func unnamed() {
    #expect(rest("military") == .restricted)
    #expect(rest("permissive", "military") == .restricted)
    #expect(rest("military", "permit") == .permit)
    #expect(rest("") == .restricted)
    #expect(rest(" private") == .restricted)
  }

  @Test("the Data API's spelling reads as REST's, and either spelling in either type")
  func eitherSpelling() {
    #expect(data("PRIVATE") == .private)
    #expect(data("PERMISSIVE", "DESTINATION") == .localAccess)
    #expect(data("AGRICULTURAL", "FORESTRY") == nil)
    #expect(rest("PRIVATE") == .private)
    #expect(data("private") == .private)
    #expect(rest("Private") == .private)
  }

  /// Only A to Z fold: a capital outside ASCII, or a full-width letter, names another value.
  @Test("only the ASCII capitals fold")
  func asciiOnly() {
    #expect(rest("PR\u{130}VATE") == .restricted)
    #expect(data("ＰＲＩＶＡＴＥ") == .restricted)
  }

  @Test("the table names every value each surface spells, and both spellings read alike")
  func table() {
    let table: [String: RoadAccessKind?] = [
      "no": .forbidden, "private": .private, "permit": .permit, "service": .service,
      "destination": .localAccess, "customers": .localAccess, "delivery": .localAccess,
      "restricted": .restricted, "unknown": .restricted, "permissive": nil, "agricultural": nil,
      "forestry": nil,
    ]
    var published: [String: RoadAccessKind?] = [:]
    for (value, kind) in roadAccessValueKinds {
      published[value.rawValue] = .some(kind)
    }
    #expect(published == table)

    let rest: [RestSchema.RoadAccessRestrictionType] = [
      .no, .customers,
      .destination, .delivery,
      .private, .permissive,
      .permit, .restricted,
      .unknown, .service,
      .agricultural, .forestry,
    ]
    let data: [DataSchema.RoadAccessRestrictionType] = [
      .no, .customers, .destination, .delivery, .private, .permissive, .permit, .restricted,
      .unknown, .service, .agricultural, .forestry,
    ]
    #expect(Set(rest.map(\.rawValue)) == Set(table.keys))
    for (restValue, dataValue) in zip(rest, data) {
      let kind = table[restValue.rawValue] ?? nil
      #expect(roadAccessKindOf([restValue]) == kind, "\(restValue.rawValue)")
      #expect(roadAccessKindOf([dataValue]) == kind, "\(dataValue.rawValue)")
    }
  }
}
