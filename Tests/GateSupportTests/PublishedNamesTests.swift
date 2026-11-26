import GateSupport
import Testing

@Suite("PublishedNames")
struct PublishedNamesTests {
  /// A baseline as PublicAPITests prints one: its header, then a declaration's path, two spaces
  /// and what it declares, one to a line, conformances among them.
  private static let baseline = PublishedNames(baselines: [
    """
    // The public API of MountayaClient, printed by BoundaryTests from the compiler's symbol graph.
    // Never edit it: a change to the API is printed again with `mise run api:update`, and the
    // diff is the review. A line removed or changed is a break (SPEC.md section 10).
    APIError  : Swift.CustomStringConvertible, Swift.Sendable
    APIError  struct APIError
    APIError.IdempotentAnswer  struct IdempotentAnswer
    APIError.Kind  @nonexhaustive enum Kind
    APIError.Kind.preconditionFailed  case preconditionFailed
    APIError.init(status:errors:)  init(status: Int, errors: [ErrorEntry] = [])
    isAPIError(_:)  func isAPIError(_ error: any Error) -> Bool
    """,
    """
    // The public API of MountayaGeo, printed by BoundaryTests from the compiler's symbol graph.
    GlyphSet  struct GlyphSet
    GlyphSet.init(chaining:)  init?(chaining sets: [GlyphSet])
    POIStyle  struct POIStyle
    Geodesy.haversineMeters(from:to:)  static func haversineMeters(from: [Double], to: [Double]) -> Double
    livelyPalette  let livelyPalette: [String]
      a line with no path
    """,
    """
    // The public API of MountayaElements, printed by BoundaryTests from the compiler's symbol graph.
    MapEngine.features(at:)  @MainActor func features(at point: [Double]) -> [QueriedFeature]
    MapEngine.close()  @MainActor func close()
    """,
  ])

  @Test("the header and a line with no path are no declaration, and every other line is one")
  func reading() {
    #expect(Self.baseline.count == 13)
    #expect(!Self.baseline.declares("The"))
    #expect(!Self.baseline.declares("//"))
    #expect(!Self.baseline.declares(""))
  }

  @Test(
    "a name is declared at exactly its path, its labels and its case included",
    arguments: [
      "APIError", "APIError.Kind.preconditionFailed", "APIError.IdempotentAnswer",
      "APIError.init(status:errors:)", "isAPIError(_:)", "GlyphSet.init(chaining:)", "POIStyle",
      "Geodesy.haversineMeters(from:to:)", "livelyPalette", "MapEngine.features(at:)",
      "MapEngine.close()",
    ])
  func declared(name: String) {
    #expect(Self.baseline.declares(name), "\(name)")
  }

  /// Each is a name an idiom once matched: the registry spells it as Swift declares it now.
  @Test(
    "no idiom stands between a name and its declaration",
    arguments: [
      "PreconditionFailedError", "preconditionFailed", "IdempotentAnswer", "isAPIError",
      "GlyphSet.chaining", "GlyphSet.init", "PoiStyle", "poiStyle", "haversineMeters",
      "Geodesy.haversineMeters", "MapEngine.featuresAt", "MapEngine.features",
      "MapEngine.features(_:)", "MapEngine.close", "apiError", "Kind",
    ])
  func undeclared(name: String) {
    #expect(!Self.baseline.declares(name), "\(name)")
  }
}
