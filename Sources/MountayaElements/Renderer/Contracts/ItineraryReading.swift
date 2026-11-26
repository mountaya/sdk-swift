#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  import MountayaGeo

  /// ItineraryReading is how a data element reads its itinerary, as `sdk-dart`'s and `sdk-kotlin`'s
  /// data elements read theirs: through the engine the app hands it, which the element shows and
  /// never asks nor closes, the app choosing the itinerary through its `configure`; or through an
  /// engine of the element's own over the app's cache, which it asks about the itinerary an id names
  /// on a surface as that question changes.
  enum ItineraryReading {
    /// engine is the app's engine, which the element shows.
    case engine(ItineraryResourceEngine)
    /// cache is the itinerary `itineraryId` names on `surface`, read through `cache` by an engine of
    /// the element's own.
    case cache(ItineraryResourceCache, itineraryId: String?, surface: RestSchema.ReadSurface?)

    /// handed is the app's engine, or nil where the element reads through one of its own.
    var handed: ItineraryResourceEngine? {
      if case .engine(let engine) = self { return engine }
      return nil
    }

    /// question is what the element asks, compared to ask again where it changes: the engine the
    /// app hands, or the id, the surface and the cache.
    var question: Question {
      switch self {
      case .engine(let engine):
        Question(engine: ObjectIdentifier(engine), itineraryId: nil, surface: nil, cache: nil)
      case .cache(let cache, let itineraryId, let surface):
        Question(
          engine: nil, itineraryId: itineraryId, surface: surface, cache: ObjectIdentifier(cache))
      }
    }

    /// read has the engine the element reads through ask its question, where it is the element's
    /// own, made over the cache where `own` is none yet, the element's, and answers the element's
    /// own engine. `failures` follows the engine shown before it is asked, so every failure it
    /// shows is handed on; the app's engine is followed and never asked.
    @MainActor
    func read(_ own: ItineraryResourceEngine?, following failures: FailureRelay)
      -> ItineraryResourceEngine?
    {
      switch self {
      case .engine(let engine):
        failures.follow(engine)
        return own
      case .cache(let cache, let itineraryId, let surface):
        let engine = own ?? ItineraryResourceEngine(cache: cache)
        failures.follow(engine)
        engine.configure(cache: cache, itineraryId: itineraryId, surface: surface)
        return engine
      }
    }

    /// Question is what a data element asks of its itinerary, compared to ask again where it changes.
    struct Question: Equatable {
      let engine: ObjectIdentifier?
      let itineraryId: String?
      let surface: RestSchema.ReadSurface?
      let cache: ObjectIdentifier?
    }
  }
#endif
