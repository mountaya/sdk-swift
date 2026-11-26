import Foundation
import Testing

@testable import MountayaClient

@Suite("FormBody")
struct FormBodyTests {
  @Test("each part is written under its field name, in order, between the boundary")
  func parts() {
    let written = FormBody.write([
      MultipartPart(name: "name", content: .text("Tour")),
      MultipartPart(name: "file", content: .file(Data([0x01, 0x02]))),
    ])
    let text = String(decoding: written.bytes, as: UTF8.self)

    #expect(written.contentType == "multipart/form-data; boundary=\(FormBody.base)")
    #expect(
      text.hasPrefix(
        "--\(FormBody.base)\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nTour\r\n"))
    #expect(text.hasSuffix("\r\n--\(FormBody.base)--\r\n"))
  }

  @Test("a file part states its file name and its media type where it is given them")
  func namedFile() {
    let written = FormBody.write([
      MultipartPart(
        name: "file",
        content: .file(Data("<gpx/>".utf8), filename: "tour \"7\".gpx", contentType: "text/xml")),
      MultipartPart(name: "bare", content: .file(Data([0x01]))),
    ])
    let text = String(decoding: written.bytes, as: UTF8.self)

    #expect(
      text.hasPrefix(
        "--\(FormBody.base)\r\nContent-Disposition: form-data; name=\"file\"; "
          + "filename=\"tour %227%22.gpx\"\r\nContent-Type: text/xml\r\n\r\n<gpx/>\r\n"))
    #expect(
      text.contains(
        "--\(FormBody.base)\r\nContent-Disposition: form-data; name=\"bare\"\r\n"
          + "Content-Type: application/octet-stream\r\n\r\n\u{1}\r\n"))
    #expect(
      FormBody.contentTypes([
        MultipartPart(name: "a", content: .text("x")),
        MultipartPart(name: "b", content: .file(Data(), contentType: "image/png")),
      ]) == ["image/png"])
  }

  @Test(
    "a file part given no media type is sent as application/octet-stream, and a text part as none")
  func octetStream() {
    let written = FormBody.write([
      MultipartPart(name: "provider", content: .text("strava")),
      MultipartPart(name: "file", content: .file(Data("<gpx/>".utf8), filename: "track.gpx")),
    ])
    let text = String(decoding: written.bytes, as: UTF8.self)

    #expect(
      text.contains(
        "Content-Disposition: form-data; name=\"provider\"\r\n\r\nstrava\r\n"))
    #expect(
      text.contains(
        "Content-Disposition: form-data; name=\"file\"; filename=\"track.gpx\"\r\n"
          + "Content-Type: application/octet-stream\r\n\r\n<gpx/>\r\n"))
  }

  @Test("a part holding the boundary lengthens it, and two writes of one form send the same bytes")
  func boundary() {
    let parts = [MultipartPart(name: "note", content: .text("--\(FormBody.base)"))]

    #expect(FormBody.write(parts).contentType.hasSuffix("\(FormBody.base)x"))
    #expect(FormBody.write(parts) == FormBody.write(parts))
  }
}
