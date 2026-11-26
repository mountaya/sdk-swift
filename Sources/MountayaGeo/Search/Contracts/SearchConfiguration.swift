import MountayaClient

/// searchSectionOrder is the order a search asks its branches in and renders their sections in,
/// whatever order they answer in (`geo.search.section-order`): the itineraries, the reader's own
/// answers to where to go, then the places, which a query most often names, and the ways after
/// them, the road to a summit being the second reading of its name, then the points of interest,
/// the zones, and the collections last, a collection being a set of itineraries rather than a
/// destination.
public let searchSectionOrder: [DataSchema.SearchTarget] = [
  .itineraries, .places, .ways, .pois, .zones, .collections,
]

/// SearchConfiguration is what a search asks its rounds with: how a request reaches the Data API,
/// the language and the cap a round asks with, the branches it asks, how a row is worded, and who
/// hears a failed branch.
///
/// A round asks one request per branch of `targets`, in their order, each enabling its branch
/// alone, and renders the sections in that order (`geo.search.section-order`); a branch listed
/// twice is asked once, and one this build cannot enable is asked none. A change of the language,
/// the cap, the branches, whether there is a transport, or the language or the length system of
/// the wording's units asks a fresh round (`geo.search.live-round`); a replaced transport, word
/// resolver or handler asks nothing, its words read as a branch lands. It is not `Equatable`, since
/// it holds functions.
public struct SearchConfiguration: Sendable {
  /// fetch is how a request reaches the Data API, or nil for a search that asks nothing and shows
  /// every section settled with nothing.
  public var fetch: SearchFetch?
  /// language is the language a round asks the Data API to answer in, or nil for the API's own
  /// default.
  public var language: DataSchema.Language?
  /// limit is the cap a round asks each branch for, or nil for the API's own default.
  public var limit: SearchLimit?
  /// targets is the branches a round asks, in the order their sections render.
  public var targets: [DataSchema.SearchTarget]
  /// wording is how a row's title and second line are worded for the reader.
  public var wording: SearchWording
  /// onError is handed each failure the transport throws for a branch of the live round, after
  /// its section reads it, or nil for none. A branch the Data API answers as failed is no thrown
  /// failure, and its section alone reads it.
  public var onError: (@MainActor @Sendable (any Error) -> Void)?

  /// Creates a configuration of its transport, the language and the cap a round asks with, its
  /// branches, every one by default, its wording and its failure handler.
  public init(
    fetch: SearchFetch? = nil,
    language: DataSchema.Language? = nil,
    limit: SearchLimit? = nil,
    targets: [DataSchema.SearchTarget] = searchSectionOrder,
    wording: SearchWording = SearchWording(),
    onError: (@MainActor @Sendable (any Error) -> Void)? = nil
  ) {
    self.fetch = fetch
    self.language = language
    self.limit = limit
    self.targets = targets
    self.wording = wording
    self.onError = onError
  }
}
