// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetItineraryExportQuery is the query of `getItineraryExport`, one property to a parameter.
  public struct GetItineraryExportQuery: Sendable, Hashable {
    /// File format to render. Required: there is no default, because a download
    /// whose format the caller did not choose is never the right guess. One of
    /// `gpx`, `geojson`, `kml`, `kmz`, `fit`, `tcx`, or `csv`; the schema below
    /// describes what each one carries. The value also decides the response
    /// `Content-Type` and the extension in `Content-Disposition`, so it is the
    /// single input that determines what the browser saves.
    public var format: RestSchema.ExportFormat
    /// File type of a time-series export, applicable to the `fit` and `tcx`
    /// formats only and defaulting to `course` when omitted. Supplying it for any
    /// other format is rejected.
    public var variant: RestSchema.ExportVariant?
    /// Narrows the export to one segment of the itinerary. Omit it to export the
    /// whole itinerary. A single-segment export carries that segment's geometry
    /// alone and no waypoints, since a waypoint belongs to the itinerary rather
    /// than to any one segment, and the download is named `<itinerary name> -
    /// <segment name>`. An id that names no segment of this itinerary answers
    /// 404, the same as an unknown itinerary, so the response never confirms that
    /// a segment exists elsewhere.
    ///
    /// The id is matched against the version exported. A published snapshot's
    /// segments carry their own ids, which change at every publish, so a draft
    /// segment's id answers 404 there. So does a segment of this itinerary that
    /// holds no geometry, which a whole-itinerary export leaves out.
    public var segment_id: String?
    /// Reads the published snapshot rather than the draft. `published` is the only
    /// accepted value: there is deliberately no `draft` spelling, because the param
    /// only ever narrows what the caller is served. An unrecognized value is rejected
    /// with a validation error rather than silently ignored. A read of one itinerary,
    /// or of one zone, refuses it with `403` when it is personal, owned by no
    /// organization, to the person whose it is: the published surface is what a
    /// video and an embed are made of, and a personal itinerary or zone makes
    /// neither. Every other caller reads a personal itinerary or zone as published,
    /// and since one is never published it is answered as one that does not exist.
    public var surface: RestSchema.ReadSurface?

    /// Creates a `GetItineraryExportQuery` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      format: RestSchema.ExportFormat,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.format = format
      self.variant = nil
      self.segment_id = nil
      self.surface = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      items.append(.init(name: "format", value: self.format.rawValue))
      if let value = self.variant {
        items.append(.init(name: "variant", value: value.rawValue))
      }
      if let value = self.segment_id {
        items.append(.init(name: "segment_id", value: value))
      }
      if let value = self.surface {
        items.append(.init(name: "surface", value: value.rawValue))
      }
      return items
    }
  }
}
