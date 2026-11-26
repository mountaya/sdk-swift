import Foundation

/// ElevationImageDecoding reads an elevation tile's image, a WebP or a PNG, into its pixels, the
/// one step of `geo.terrain.elevation-sample` each platform takes through its own image codec.
///
/// `pixels(of:edge:)` answers the image's red, green and blue bytes, rows from the north down and
/// each row's pixels from the west, `edge × edge × 3` of them, or nil where the bytes are no image
/// of that edge it can read. It decides nothing about heights: `decodeElevation(_:encoding:)` reads
/// the channels.
protocol ElevationImageDecoding: Sendable {
  func pixels(of image: Data, edge: Int) -> [UInt8]?
}
