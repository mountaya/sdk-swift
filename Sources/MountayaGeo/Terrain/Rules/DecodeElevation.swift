/// decodeElevation answers the height in meters a pixel of an elevation tile stands for
/// (`geo.terrain.elevation-decode`), `pixel` its red, green and blue channels, each from 0 to 255,
/// read by `encoding`, the one the source's TileJSON names, `mapbox` where it names none:
///
/// - `mapbox`: -10000 + (R × 65536 + G × 256 + B) × 0.1 meters;
/// - `terrarium`: R × 256 + G + B / 256 - 32768 meters.
///
/// A fourth channel, the alpha, is read by neither. nil for any other encoding, compared whole, and
/// for a pixel of fewer than three channels. Reading a tile's bytes, a WebP or a PNG image, into its
/// pixels is each platform's own: the rule starts from the channels.
public func decodeElevation(_ pixel: [UInt8], encoding: ElevationEncoding?) -> Double? {
  guard pixel.count >= 3 else { return nil }
  return decodedHeight(
    red: pixel[0], green: pixel[1], blue: pixel[2], encoding: encoding ?? .mapbox)
}

/// decodedHeight is `decodeElevation(_:encoding:)` over three channels, which a tile's pixels are
/// read through without a list of their own.
func decodedHeight(red: UInt8, green: UInt8, blue: UInt8, encoding: ElevationEncoding)
  -> Double?
{
  let (r, g, b) = (Double(red), Double(green), Double(blue))
  if encoding == .mapbox {
    return -10000 + (r * 65536 + g * 256 + b) * 0.1
  }
  if encoding == .terrarium {
    return r * 256 + g + b / 256 - 32768
  }
  return nil
}
