import Foundation
import Testing

@testable import MountayaClient

@Suite("MultipartPart")
struct MultipartPartTests {
  @Test("a part is a field or a file, under the contract's property name")
  func content() {
    let field = MultipartPart(name: "provider", content: .text("gpx"))
    let file = MultipartPart(name: "file", content: .file(Data([0x3C])))

    #expect(field != file)
    #expect(file.content == .file(Data([0x3C])))
    #expect(file.content == .file(Data([0x3C]), filename: nil, contentType: nil))
  }

  @Test("a file part may state its file name and its media type, and compares by both")
  func namedFile() {
    let named = MultipartPart(
      name: "file", content: .file(Data([0x3C]), filename: "tour.gpx", contentType: "text/xml"))

    #expect(named != MultipartPart(name: "file", content: .file(Data([0x3C]))))
    #expect(named.name == "file")
  }
}
