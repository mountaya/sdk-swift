import Foundation
import GateSupport
import MountayaClient

/// GeoFixtures builds the client's own values from what a geo fixture writes, every position kept
/// as short as the fixture writes it and a number JSON cannot carry decoded where it stands, which
/// a JSON decoder would refuse.
enum GeoFixtures {
  /// geometry builds the GeoJSON geometry a fixture object writes.
  static func geometry(_ value: OrderedJSON) throws(FixtureError) -> GeoJSONGeometry {
    guard value.members != nil else {
      throw FixtureError(description: "a geometry is not an object")
    }
    switch try value.string(at: "type") {
    case "Point":
      return .point(GeoJSONPoint(coordinates: try value.numbers(at: "coordinates")))
    case "MultiPoint":
      return .multiPoint(GeoJSONMultiPoint(coordinates: try value.positions(at: "coordinates")))
    case "LineString":
      return .lineString(try lineString(value))
    case "MultiLineString":
      return .multiLineString(
        GeoJSONMultiLineString(coordinates: try lines(try value.array(at: "coordinates"))))
    case "Polygon":
      return .polygon(GeoJSONPolygon(coordinates: try lines(try value.array(at: "coordinates"))))
    case "MultiPolygon":
      var polygons: [[[[Double]]]] = []
      for polygon in try value.array(at: "coordinates") {
        guard let rings = polygon.elements else {
          throw FixtureError(description: "`coordinates` nests a value that is not an array")
        }
        polygons.append(try lines(rings))
      }
      return .multiPolygon(GeoJSONMultiPolygon(coordinates: polygons))
    case "GeometryCollection":
      var geometries: [GeoJSONGeometry] = []
      for member in try value.array(at: "geometries") {
        geometries.append(try geometry(member))
      }
      return .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
    case let other:
      throw FixtureError(description: "`\(other)` is not a GeoJSON geometry")
    }
  }

  /// lineString builds the `LineString` a fixture object writes, refusing any other geometry.
  static func lineString(_ value: OrderedJSON) throws(FixtureError) -> GeoJSONLineString {
    guard value["type"]?.stringValue == "LineString" else {
      throw FixtureError(description: "a line is not a LineString")
    }
    return GeoJSONLineString(coordinates: try value.positions(at: "coordinates"))
  }

  private static func lines(_ values: [OrderedJSON]) throws(FixtureError) -> [[[Double]]] {
    var lines: [[[Double]]] = []
    for line in values {
      guard let positions = line.elements else {
        throw FixtureError(description: "`coordinates` nests a value that is not an array")
      }
      var built: [[Double]] = []
      for position in positions {
        built.append(try position.numberList(naming: "coordinates"))
      }
      lines.append(built)
    }
    return lines
  }

  /// segment builds a segment as the REST API answers one, holding the members a fixture writes
  /// and a placeholder for every other the type requires, which no rule reads: created at the
  /// epoch by `user`, in the `linestring` mode, named by its id, at revision 1, in the itinerary
  /// `itinerary`, every optional member absent.
  static func segment(id: String, position: Int, geojson: GeoJSONGeometry?)
    -> RestSchema.ItinerarySegment
  {
    RestSchema.ItinerarySegment(
      altitude_max: nil, altitude_min: nil, ascent: nil, color: nil,
      created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
      descent: nil, description: nil, distance: nil, duration: nil, geojson: geojson,
      gradient_max: nil, gradient_min: nil, group_id: nil, id: id, itinerary_id: "itinerary",
      mode: .linestring, name: id, position: position, revision: 1,
      road_access_info: nil, slope_info: nil, speed: nil, speed_info: nil, start_at: nil,
      steps: nil, surface_info: nil, trail_difficulty_info: nil, way_type_info: nil)
  }

  /// numbers answers a list of numbers as the JSON array a fixture expects.
  static func numbers(_ values: [Double]) -> OrderedJSON {
    .array(values.map { .number($0) })
  }

  /// texts answers a list of texts as the JSON array a fixture expects.
  static func texts(_ values: [String]) -> OrderedJSON {
    .array(values.map { .string($0) })
  }

  /// textList reads the array under a key as texts, refusing any other value in it.
  static func textList(_ value: OrderedJSON, at key: String) throws(FixtureError) -> [String] {
    var texts: [String] = []
    for element in try value.array(at: key) {
      guard let text = element.stringValue else {
        throw FixtureError(description: "`\(key)` holds a value that is not a string")
      }
      texts.append(text)
    }
    return texts
  }

  /// json is a fixture's value as the client's `JSONValue`, the type a style's label and a bundle's
  /// words are handed to Geo as. An object's members lose their order, which no rule reads.
  static func json(_ value: OrderedJSON) -> JSONValue {
    switch value {
    case .null: return .null
    case .bool(let flag): return .bool(flag)
    case .number(let number): return .number(number)
    case .string(let text): return .string(text)
    case .array(let elements): return .array(elements.map(json))
    case .object(let members):
      return .object(
        Dictionary(members.map { ($0.key, json($0.value)) }, uniquingKeysWith: { _, last in last }))
    }
  }

  /// jsonObject is a fixture's object as the members of a client `JSONValue` object.
  static func jsonObject(_ value: OrderedJSON, naming what: String) throws(FixtureError)
    -> [String: JSONValue]
  {
    guard case .object(let members) = json(value) else {
      throw FixtureError(description: "`\(what)` is not an object")
    }
    return members
  }

  /// ordered is a client `JSONValue` as the value a fixture expects, an object's members written
  /// in the order of their keys, which the comparison does not read.
  static func ordered(_ value: JSONValue) -> OrderedJSON {
    switch value {
    case .null: return .null
    case .bool(let flag): return .bool(flag)
    case .number(let number): return .number(number)
    case .string(let text): return .string(text)
    case .array(let elements): return .array(elements.map(ordered))
    case .object(let members): return ordered(members)
    }
  }

  /// ordered is a client JSON object as the value a fixture expects.
  static func ordered(_ members: [String: JSONValue]) -> OrderedJSON {
    .object(
      members.sorted { $0.key < $1.key }.map {
        OrderedJSON.Member(key: $0.key, value: ordered($0.value))
      })
  }

  /// decoded is a fixture's value read by a generated type's own decoder, as a consumer receives
  /// it from the wire. A number JSON cannot carry, which the fixture writes as `$number`, is handed
  /// to the decoder as the string Foundation's non-conforming float strategy reads it from.
  static func decoded<Value: Decodable>(_ type: Value.Type, from value: OrderedJSON)
    throws(FixtureError) -> Value
  {
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    do {
      return try decoder.decode(type, from: Data(conforming(value).serialized().utf8))
    } catch {
      throw FixtureError(description: "the wire's decoder refuses the value: \(error)")
    }
  }

  /// conforming is a value with every number that is not finite written as the string the
  /// non-conforming float strategy reads.
  private static func conforming(_ value: OrderedJSON) -> OrderedJSON {
    switch value {
    case .number(let number) where number.isNaN: return .string("NaN")
    case .number(let number) where number.isInfinite:
      return .string(number > 0 ? "Infinity" : "-Infinity")
    case .array(let elements): return .array(elements.map(conforming))
    case .object(let members):
      return .object(members.map { OrderedJSON.Member(key: $0.key, value: conforming($0.value)) })
    default: return value
    }
  }

  /// written is a geometry as RFC 7946 writes it, its box where it carries one.
  static func written(_ geometry: GeoJSONGeometry) -> OrderedJSON {
    func shaped(_ type: String, coordinates: OrderedJSON, bbox: [Double]?) -> OrderedJSON {
      var members = [
        OrderedJSON.Member(key: "coordinates", value: coordinates),
        OrderedJSON.Member(key: "type", value: .string(type)),
      ]
      if let bbox {
        members.append(OrderedJSON.Member(key: "bbox", value: numbers(bbox)))
      }
      return .object(members)
    }
    func line(_ positions: [[Double]]) -> OrderedJSON { .array(positions.map(numbers)) }
    func rings(_ lines: [[[Double]]]) -> OrderedJSON { .array(lines.map(line)) }
    switch geometry {
    case .point(let point):
      return shaped("Point", coordinates: numbers(point.coordinates), bbox: point.bbox)
    case .multiPoint(let points):
      return shaped("MultiPoint", coordinates: line(points.coordinates), bbox: points.bbox)
    case .lineString(let string):
      return shaped("LineString", coordinates: line(string.coordinates), bbox: string.bbox)
    case .multiLineString(let strings):
      return shaped("MultiLineString", coordinates: rings(strings.coordinates), bbox: strings.bbox)
    case .polygon(let polygon):
      return shaped("Polygon", coordinates: rings(polygon.coordinates), bbox: polygon.bbox)
    case .multiPolygon(let polygons):
      return shaped(
        "MultiPolygon", coordinates: .array(polygons.coordinates.map(rings)), bbox: polygons.bbox)
    case .geometryCollection(let collection):
      var members = [
        OrderedJSON.Member(key: "geometries", value: .array(collection.geometries.map(written))),
        OrderedJSON.Member(key: "type", value: .string("GeometryCollection")),
      ]
      if let bbox = collection.bbox {
        members.append(OrderedJSON.Member(key: "bbox", value: numbers(bbox)))
      }
      return .object(members)
    }
  }
}
