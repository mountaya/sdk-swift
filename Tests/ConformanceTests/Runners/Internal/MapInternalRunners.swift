import GateSupport
import MountayaGeo

@testable import MountayaElements

extension InternalRunners {
  /// mapEditSnap answers where an edit's magnet places the case's `cursor` among its `segments`,
  /// through the projection the fixture states, the identity, a longitude an x and a latitude a y,
  /// one degree one pixel. The magnet's radius is held to the one the rule states. The rule is the
  /// editing engine's own, which the renderer applies through its projection, so it is reached as
  /// an internal.
  static let mapEditSnap = Runner(id: "map.edit.snap", table: .internal) { fixture, fixtureCase in
    try fixture.holdConstants(["snapThresholdPx": snapThresholdPx])
    let input = fixtureCase.input
    let segments = try input.array(at: "segments").enumerated().map {
      (index, line) throws(FixtureError) -> [[Double]] in
      guard let positions = line.elements else {
        throw FixtureError(description: "segments[\(index)] is not a list of positions")
      }
      return try positions.map { position throws(FixtureError) -> [Double] in
        guard let numbers = position.elements?.compactMap(\.numberValue),
          numbers.count == position.elements?.count
        else {
          throw FixtureError(description: "segments[\(index)] holds a position of no numbers")
        }
        return numbers
      }
    }
    let identity = ScreenProjection(point: { $0 }, position: { $0 })
    let cursor = try input.numbers(at: "cursor")
    let snap = await snapToActiveSegments(cursor, segments: segments, projection: identity)
    return .value(
      .object([
        OrderedJSON.Member(key: "lngLat", value: .array(snap.position.map { .number($0) })),
        OrderedJSON.Member(key: "snapped", value: .bool(snap.isSnapped)),
      ]))
  }
}

extension InternalRunners {
  /// mapIconsMarkerSprite answers what the marker sprite of the case's `glyph` in its `color`
  /// draws, from a set of the case's paint, width and box holding its `held` glyphs and no other,
  /// each a placeholder no rule reads. The sizes and colours the fixture declares are held to a
  /// sprite the rule describes, read back through it: its side, its border, its disc's radius, the
  /// square its glyph is fitted to and the colours of both. The rule is the map's own, which a
  /// consumer observes as the images a map draws, so it is reached as an internal.
  static let mapIconsMarkerSprite = Runner(id: "map.icons.marker-sprite", table: .internal) {
    fixture, fixtureCase in
    let input = fixtureCase.input
    guard let written = input["set"] else {
      throw FixtureError(description: "the input states no `set`")
    }
    let markup = OrderedJSON.object(
      try GeoFixtures.textList(input, at: "held").map {
        OrderedJSON.Member(key: $0, value: .string(#"<path d="M0 0h1"/>"#))
      })
    let set = try GeoIconFixtures.declared(
      .object(
        [
          OrderedJSON.Member(key: "name", value: .string("held")),
          OrderedJSON.Member(key: "markup", value: markup),
        ] + (written.members ?? [])))
    let referenceSet = try GeoIconFixtures.set(holding: ["x"])
    guard let reference = describeMarkerSprite("x", color: "#000000", in: referenceSet) else {
      throw FixtureError(description: "a set holding the glyph draws no sprite of it")
    }
    try fixture.holdConstants(
      [
        "spritePx": reference.size, "borderPx": reference.disc.borderWidth,
        "discRadiusPx": reference.disc.radius,
        "glyphBoxPx": reference.glyph.scale * referenceSet.viewBox,
      ],
      values: [
        "borderColor": .string(reference.disc.borderColor),
        "glyphColor": .string(reference.glyph.color),
      ])
    guard
      let sprite = describeMarkerSprite(
        try input.string(at: "glyph"), color: try input.string(at: "color"), in: set)
    else { return .value(.null) }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "disc",
          value: .object([
            OrderedJSON.Member(
              key: "border",
              value: .object([
                OrderedJSON.Member(key: "color", value: .string(sprite.disc.borderColor)),
                OrderedJSON.Member(key: "width", value: .number(sprite.disc.borderWidth)),
              ])),
            OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(sprite.disc.center)),
            OrderedJSON.Member(key: "fill", value: .string(sprite.disc.fill)),
            OrderedJSON.Member(key: "radius", value: .number(sprite.disc.radius)),
          ])),
        OrderedJSON.Member(
          key: "glyph",
          value: .object([
            OrderedJSON.Member(key: "color", value: .string(sprite.glyph.color)),
            OrderedJSON.Member(key: "offset", value: .number(sprite.glyph.offset)),
            OrderedJSON.Member(key: "scale", value: .number(sprite.glyph.scale)),
          ])),
        OrderedJSON.Member(key: "size", value: .number(sprite.size)),
      ]))
  }

  /// mapIconsMissingImage answers the marker sprite the case's image `id` names, its glyph and its
  /// colour, or null for an image left missing, read against a set holding the glyphs the fixture
  /// declares and no other. The prefixes are held to the ones the rule reads; the held glyphs are
  /// the input every case reads.
  static let mapIconsMissingImage = Runner(id: "map.icons.missing-image", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:], values: ["prefixes": GeoFixtures.texts(markerImagePrefixes)], inputs: ["heldGlyphs"])
    guard let constants = fixture.constants else {
      throw FixtureError(description: "the fixture declares no `heldGlyphs`")
    }
    let set = try GeoIconFixtures.set(holding: GeoFixtures.textList(constants, at: "heldGlyphs"))
    guard let image = readMarkerImageId(try fixtureCase.input.string(at: "id"), in: set) else {
      return .value(.null)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "color", value: .string(image.color)),
        OrderedJSON.Member(key: "glyph", value: .string(image.glyph)),
      ]))
  }

  /// mapIconsStripePattern answers how a restricted stretch of the case's `kind` is striped. The
  /// tile's size, the stripes' width, the ground and every kind's colour are held to what the rule
  /// answers for each kind.
  static let mapIconsStripePattern = Runner(id: "map.icons.stripe-pattern", table: .internal) {
    fixture, fixtureCase in
    let patterns = RoadAccessKind.allCases.map { ($0, roadAccessStripePattern($0)) }
    guard let first = patterns.first?.1 else {
      throw FixtureError(description: "no kind of restricted stretch is striped")
    }
    try fixture.holdConstants(
      ["tileSize": first.size, "stripeWidth": first.width],
      values: [
        "ground": first.ground.map { .string($0) } ?? .null,
        "kindColors": .object(
          patterns.sorted { $0.0.id < $1.0.id }.map {
            OrderedJSON.Member(key: $0.0.id, value: .string($0.1.color))
          }),
      ])
    let written = try fixtureCase.input.string(at: "kind")
    guard let kind = RoadAccessKind(rawValue: written) else {
      throw FixtureError(description: "`\(written)` is no kind of restricted stretch")
    }
    let pattern = roadAccessStripePattern(kind)
    return .value(
      .object([
        OrderedJSON.Member(key: "color", value: .string(pattern.color)),
        OrderedJSON.Member(key: "ground", value: pattern.ground.map { .string($0) } ?? .null),
        OrderedJSON.Member(key: "lineCap", value: .string(pattern.lineCap.rawValue)),
        OrderedJSON.Member(
          key: "segments",
          value: .array(pattern.segments.map { .array($0.map(GeoFixtures.numbers)) })
        ),
        OrderedJSON.Member(key: "size", value: .number(pattern.size)),
        OrderedJSON.Member(key: "width", value: .number(pattern.width)),
      ]))
  }
}
