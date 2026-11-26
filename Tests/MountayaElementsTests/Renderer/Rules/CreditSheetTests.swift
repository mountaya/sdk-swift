import Foundation
import Testing
import UIKit

@testable import MountayaElements

@Suite("creditSheet")
@MainActor
struct CreditSheetTests {
  @Test("a credit reads as the text its markup shows, and opens its first link")
  func links() throws {
    let mountaya = creditLink(
      #"<a href="https://mountaya.com/" target="_blank">&copy; Mountaya</a>"#)
    #expect(mountaya.text == "\u{A9} Mountaya")
    #expect(mountaya.url == URL(string: "https://mountaya.com/"))
    let quoted = creditLink("<a href='https://osm.org/copyright'>&#169; OSM &amp; friends</a>")
    #expect(quoted.text == "\u{A9} OSM & friends")
    #expect(quoted.url == URL(string: "https://osm.org/copyright"))
    let plain = creditLink("  Imagery &copy; Satellite Provider &#x2014; &unknown; ")
    #expect(plain.text == "Imagery \u{A9} Satellite Provider \u{2014} &unknown;")
    #expect(plain.url == nil)
  }

  @Test("the sheet holds one action per credit, in order, and one that closes it")
  func sheet() throws {
    var opened: [URL] = []
    let sheet = creditSheet(
      [#"<a href="https://mountaya.com/">&copy; Mountaya</a>"#, "Imagery"]
    ) { opened.append($0) }
    #expect(sheet.actions.map(\.title) == ["\u{A9} Mountaya", "Imagery", "OK"])
    #expect(sheet.preferredStyle == .actionSheet)
    #expect(opened.isEmpty)
  }
}
