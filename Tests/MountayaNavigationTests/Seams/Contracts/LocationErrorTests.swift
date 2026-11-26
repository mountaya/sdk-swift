import Testing

@testable import MountayaNavigation

@Suite("LocationError")
struct LocationErrorTests {
  private struct Lost: Error, CustomStringConvertible {
    var description: String { "the fix was lost" }
  }

  @Test("each kind is named as every SDK names it, and the set is open")
  func kinds() {
    let named: [(LocationError.Kind, String)] = [
      (.noProvider, "noProvider"), (.providerDisabled, "providerDisabled"),
      (.permissionRevoked, "permissionRevoked"), (.platformFailed, "platformFailed"),
      (.backgroundUndeclared, "backgroundUndeclared"), (.audioUndeclared, "audioUndeclared"),
    ]
    for (kind, name) in named {
      #expect(kind.rawValue == name)
      #expect("\(kind)" == name)
      #expect(LocationError.Kind(rawValue: name) == kind)
    }
    #expect(Set(named.map(\.0)).count == 6, "six kinds, each its own")
    let later = LocationError.Kind(rawValue: "satellitesLost")
    #expect(!named.map(\.0).contains(later), "a kind a later build tells is none of these")
    #expect(
      LocationError(kind: later).description.contains("satellitesLost"), "and is said by its name")
  }

  @Test("two kinds are equal where their names are written with the same scalars")
  func scalars() {
    let composed = LocationError.Kind(rawValue: "caf\u{E9}")
    let decomposed = LocationError.Kind(rawValue: "cafe\u{301}")
    #expect(composed != decomposed)
    #expect(composed == LocationError.Kind(rawValue: "caf\u{E9}"))
    #expect(composed.hashValue == LocationError.Kind(rawValue: "caf\u{E9}").hashValue)
  }

  @Test("a failure carries what the platform reported, and says what to do")
  func described() {
    let failed = LocationError(kind: .platformFailed, cause: Lost())
    #expect(failed.cause is Lost)
    #expect(failed.description.contains("the fix was lost"))
    #expect(failed.description.hasSuffix("the source keeps reading."))
    #expect(LocationError(kind: .noProvider).cause == nil)
    #expect(
      LocationError(kind: .permissionRevoked).description.contains("recheckPermission()"))
    #expect(LocationError(kind: .providerDisabled).description.contains("system's settings"))
    #expect(LocationError(kind: .backgroundUndeclared).description.contains("`location`"))
    #expect(LocationError(kind: .audioUndeclared).description.contains("`audio`"))
    #expect(LocationError(kind: .noProvider).description.contains("ReplayLocationSource"))
  }
}
