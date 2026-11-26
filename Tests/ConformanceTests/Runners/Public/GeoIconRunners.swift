import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// iconsResolution answers the glyph name of the case's `amenity`, of its `activity` in a set
  /// holding the case's `held` glyphs, or of its `roadAccessKind`, or the sprite id of its `icon`
  /// in its `color`, whichever member the case states, a new waypoint's default icon and colour,
  /// `defaultWaypointIcon` and `defaultWaypointColor`, standing in for one a sprite case leaves out.
  /// Every prefix, default and the amenity vocabulary are held to the ones Geo publishes.
  static let iconsResolution = Runner(id: "geo.icons.resolution", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "activityMarkerPrefix": .string(activityMarkerPrefix),
        "defaultWaypointColor": .string(defaultWaypointColor),
        "defaultWaypointIcon": .string(defaultWaypointIcon.rawValue),
        "waypointAmenities": GeoFixtures.texts(waypointAmenities.map(\.rawValue)),
        "waypointFallbackGlyph": .string(waypointFallbackGlyph),
        "waypointIconPrefix": .string(waypointIconPrefix),
      ])
    let input = fixtureCase.input
    if let amenity = try input.optionalString(at: "amenity") {
      return .value(.string(amenityGlyph(RestSchema.WaypointAmenity(rawValue: amenity))))
    }
    if let activity = try input.optionalString(at: "activity") {
      let set = try GeoIconFixtures.set(holding: GeoFixtures.textList(input, at: "held"))
      return .value(
        activityMarkerGlyph(RestSchema.ActivitySlug(rawValue: activity), in: set).map {
          .string($0)
        } ?? .null)
    }
    if let written = try input.optionalString(at: "roadAccessKind") {
      guard let kind = RoadAccessKind(rawValue: written) else {
        throw FixtureError(description: "`\(written)` is no kind of restricted stretch")
      }
      return .value(.string(roadAccessGlyph(kind)))
    }
    return .value(
      .string(
        waypointSpriteId(
          icon: try input.optionalString(at: "icon").map { RestSchema.WaypointIcon(rawValue: $0) }
            ?? defaultWaypointIcon,
          color: try input.optionalString(at: "color") ?? defaultWaypointColor)))
  }

  /// iconsGlyphParse answers the shapes the case's `markup` reads into, each its `tag` and its
  /// `attributes`. The lists the fixture declares are the parse's: the attributes it publishes, and
  /// each shape read as a shape where it is written alone.
  static let iconsGlyphParse = Runner(id: "geo.icons.glyph-parse", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "attributes": GeoFixtures.texts(glyphAttributes.sorted()),
        "tags": GeoFixtures.texts(glyphShapeTags.sorted()),
      ])
    for tag in glyphShapeTags
    where parseGlyph("<\(tag)/>") != [GlyphShape(tag: tag, attributes: [:])] {
      throw FixtureError(description: "`<\(tag)/>` reads as no shape of its own")
    }
    return .value(
      .array(parseGlyph(try fixtureCase.input.string(at: "markup")).map(GeoIconFixtures.written)))
  }

  /// iconsGlyphPaint answers how each of the case's `shapes` is drawn in its `set`, built from the
  /// set's paint and width. The set's own paint, a shape that states nothing, is held to the cap,
  /// the join, the miter limit and the fill rule the fixture declares.
  static let iconsGlyphPaint = Runner(id: "geo.icons.glyph-paint", table: .public) {
    fixture, fixtureCase in
    let input = fixtureCase.input
    guard let written = input["set"] else {
      throw FixtureError(description: "the input states no `set`")
    }
    let set = try GeoIconFixtures.declared(
      .object(
        [OrderedJSON.Member(key: "name", value: .string("case"))]
          + (written.members ?? [])))
    let own = glyphPaint(GlyphShape(tag: "path", attributes: [:]), in: set)
    try fixture.holdConstants(
      ["miterLimit": own.miterLimit],
      values: [
        "fillRule": .string(own.fillRule.rawValue),
        "lineCap": .string(own.lineCap.rawValue),
        "lineJoin": .string(own.lineJoin.rawValue),
      ])
    var painted: [OrderedJSON] = []
    for written in try input.array(at: "shapes") {
      painted.append(
        GeoIconFixtures.written(glyphPaint(try GeoIconFixtures.shape(written), in: set)))
    }
    return .value(.array(painted))
  }

  /// iconsBundledSets answers the markup the case's `set`, `marker` or `control`, holds for its
  /// `glyph`, or null. Each set's paint, width and box are held to the ones the fixture declares.
  static let iconsBundledSets = Runner(id: "geo.icons.bundled-sets", table: .public) {
    fixture, fixtureCase in
    func drawn(_ set: GlyphSet) -> OrderedJSON {
      .object([
        OrderedJSON.Member(key: "paint", value: .string(set.paint.rawValue)),
        OrderedJSON.Member(key: "strokeWidth", value: .number(set.strokeWidth)),
        OrderedJSON.Member(key: "viewBox", value: .number(set.viewBox)),
      ])
    }
    try fixture.holdConstants(
      [:], values: ["control": drawn(.control), "marker": drawn(.marker)])
    let input = fixtureCase.input
    let sets = ["control": GlyphSet.control, "marker": GlyphSet.marker]
    let named = try input.string(at: "set")
    guard let set = sets[named] else {
      throw FixtureError(description: "`\(named)` names no bundled set")
    }
    return .value(set.markup[try input.string(at: "glyph")].map { .string($0) } ?? .null)
  }

  /// iconsGlyphSet answers whether the set the case declares is refused and, where it is not, the
  /// paint, the box and the width it is drawn at. A paint the closed `GlyphSet.Paint` does not
  /// hold is refused by the type, before any set is built. The defaults are held to those of a set
  /// that states neither box nor width.
  static let iconsGlyphSet = Runner(id: "geo.icons.glyph-set", table: .public) {
    fixture, fixtureCase in
    guard let bare = GlyphSet(name: "bare", paint: .stroke, markup: [:]) else {
      throw FixtureError(description: "a set that states neither box nor width is refused")
    }
    try fixture.holdConstants(["strokeWidth": bare.strokeWidth, "viewBox": bare.viewBox])
    let set = try GeoIconFixtures.optionalSet(fixtureCase.input)
    return .value(
      .object([
        OrderedJSON.Member(key: "paint", value: set.map { .string($0.paint.rawValue) } ?? .null),
        OrderedJSON.Member(key: "refused", value: .bool(set == nil)),
        OrderedJSON.Member(key: "strokeWidth", value: set.map { .number($0.strokeWidth) } ?? .null),
        OrderedJSON.Member(key: "viewBox", value: set.map { .number($0.viewBox) } ?? .null),
      ]))
  }

  /// iconsGlyphSetChain answers the chain of the case's `sets`, each declared as
  /// `geo.icons.glyph-set` declares one: whether it is refused and, where it is not, the markup it
  /// answers for each name `asked`, every name it holds, sorted by code unit as the fixture lists
  /// them, and the paint, the box and the width it draws in.
  static let iconsGlyphSetChain = Runner(id: "geo.icons.glyph-set-chain", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var sets: [GlyphSet] = []
    for written in try input.array(at: "sets") {
      sets.append(try GeoIconFixtures.declared(written))
    }
    let asked = try GeoFixtures.textList(input, at: "asked")
    guard let chain = GlyphSet(chaining: sets) else {
      return .value(
        .object([
          OrderedJSON.Member(key: "glyphs", value: .array([])),
          OrderedJSON.Member(key: "names", value: .array([])),
          OrderedJSON.Member(key: "paint", value: .null),
          OrderedJSON.Member(key: "refused", value: .bool(true)),
          OrderedJSON.Member(key: "strokeWidth", value: .null),
          OrderedJSON.Member(key: "viewBox", value: .null),
        ]))
    }
    let glyphs = asked.map { glyph in
      OrderedJSON.object([
        OrderedJSON.Member(key: "glyph", value: .string(glyph)),
        OrderedJSON.Member(key: "markup", value: chain.markup[glyph].map { .string($0) } ?? .null),
      ])
    }
    let names = chain.markup.keys.sorted { $0.utf16.lexicographicallyPrecedes($1.utf16) }
    return .value(
      .object([
        OrderedJSON.Member(key: "glyphs", value: .array(glyphs)),
        OrderedJSON.Member(key: "names", value: GeoFixtures.texts(names)),
        OrderedJSON.Member(key: "paint", value: .string(chain.paint.rawValue)),
        OrderedJSON.Member(key: "refused", value: .bool(false)),
        OrderedJSON.Member(key: "strokeWidth", value: .number(chain.strokeWidth)),
        OrderedJSON.Member(key: "viewBox", value: .number(chain.viewBox)),
      ]))
  }
}

/// GeoIconFixtures reads the icon fixtures' sets and shapes into Geo's values, and writes Geo's
/// answers back as the fixtures write them.
enum GeoIconFixtures {
  /// set is a set holding `glyphs` and no other, each a placeholder no rule reads, as the fixtures
  /// state a set by the glyphs it holds.
  static func set(holding glyphs: [String]) throws(FixtureError) -> GlyphSet {
    guard
      let set = GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(
          glyphs.map { ($0, "<path d=\"M0 0h1\"/>") }, uniquingKeysWith: { a, _ in a }))
    else { throw FixtureError(description: "a set holding the case's glyphs is refused") }
    return set
  }

  /// optionalSet is the set `written` declares, its `name`, its `paint`, its `markup` where it
  /// states one, and its `strokeWidth` and `viewBox` where it states them, the set's own defaults
  /// standing for those it leaves out; nil where the set is refused, a paint the closed
  /// `GlyphSet.Paint` does not hold among them.
  static func optionalSet(_ written: OrderedJSON) throws(FixtureError) -> GlyphSet? {
    let name = try written.string(at: "name")
    let width = try written.optionalNumber(at: "strokeWidth")
    let box = try written.optionalNumber(at: "viewBox")
    var markup: [String: String] = [:]
    for member in written["markup"]?.members ?? [] {
      guard let text = member.value.stringValue else {
        throw FixtureError(description: "the markup of `\(member.key)` is not a string")
      }
      markup[member.key] = text
    }
    guard let paint = GlyphSet.Paint(rawValue: try written.string(at: "paint")) else { return nil }
    switch (width, box) {
    case (nil, nil):
      return GlyphSet(name: name, paint: paint, markup: markup)
    case (let width?, nil):
      return GlyphSet(name: name, paint: paint, strokeWidth: width, markup: markup)
    case (nil, let box?):
      return GlyphSet(name: name, paint: paint, viewBox: box, markup: markup)
    case (let width?, let box?):
      return GlyphSet(name: name, paint: paint, strokeWidth: width, viewBox: box, markup: markup)
    }
  }

  /// declared is the set `written` declares, which the case states as one that is drawn.
  static func declared(_ written: OrderedJSON) throws(FixtureError) -> GlyphSet {
    guard let set = try optionalSet(written) else {
      throw FixtureError(description: "a set the case declares is refused")
    }
    return set
  }

  /// shape is a shape as `geo.icons.glyph-parse` answers one, its `tag` and its `attributes`.
  static func shape(_ written: OrderedJSON) throws(FixtureError) -> GlyphShape {
    var attributes: [String: String] = [:]
    for member in written["attributes"]?.members ?? [] {
      guard let text = member.value.stringValue else {
        throw FixtureError(description: "the attribute `\(member.key)` is not a string")
      }
      attributes[member.key] = text
    }
    return GlyphShape(tag: try written.string(at: "tag"), attributes: attributes)
  }

  /// written is a shape as the fixture writes one, its attributes in the order of their names,
  /// which the comparison does not read.
  static func written(_ shape: GlyphShape) -> OrderedJSON {
    .object([
      OrderedJSON.Member(
        key: "attributes",
        value: .object(
          shape.attributes.sorted { $0.key < $1.key }.map {
            OrderedJSON.Member(key: $0.key, value: .string($0.value))
          })),
      OrderedJSON.Member(key: "tag", value: .string(shape.tag)),
    ])
  }

  /// written is a shape's paint as the fixture writes one, the current colour as `current`.
  static func written(_ paint: ShapePaint) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "fill", value: .string(paint.isFilled ? "current" : "none")),
      OrderedJSON.Member(key: "fillRule", value: .string(paint.fillRule.rawValue)),
      OrderedJSON.Member(key: "lineCap", value: .string(paint.lineCap.rawValue)),
      OrderedJSON.Member(key: "lineJoin", value: .string(paint.lineJoin.rawValue)),
      OrderedJSON.Member(key: "miterLimit", value: .number(paint.miterLimit)),
      OrderedJSON.Member(key: "stroke", value: .string(paint.isStroked ? "current" : "none")),
      OrderedJSON.Member(key: "strokeWidth", value: .number(paint.strokeWidth)),
    ])
  }
}
