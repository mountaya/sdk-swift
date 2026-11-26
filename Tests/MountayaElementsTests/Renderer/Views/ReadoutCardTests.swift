import Foundation
import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ReadoutCard")
@MainActor
struct ReadoutCardTests {
  @Test("the card stands with its top-left corner at its point, flipped to stay in the safe area")
  func anchor() {
    let size = CGSize(width: 400, height: 600)
    func anchor(_ point: [Double], safeArea: PixelPadding = PixelPadding(0)) -> CGSize {
      ReadoutCard.anchor(point, in: size, safeArea: safeArea, height: 160, clearOf: nil)
    }
    #expect(anchor([60, 100]) == CGSize(width: 60, height: 100))
    #expect(anchor([300, 100]) == CGSize(width: 12, height: 100), "flipped to the left")
    #expect(anchor([60, 500]) == CGSize(width: 60, height: 340), "flipped above")
    #expect(
      anchor([60, 30], safeArea: PixelPadding(top: 59, right: 0, bottom: 34, left: 0)).height
        == 59, "never under the status bar")
  }

  @Test("a card that would lay over the watermark's frame moves clear of it by the smallest move")
  func clearOfTheMark() {
    let mark = CGRect(x: -4, y: 55, width: 180, height: 75.5)
    let placed = ReadoutCard.anchor(
      [60, 70], in: CGSize(width: 390, height: 844),
      safeArea: PixelPadding(top: 59, right: 0, bottom: 34, left: 0), height: 160, clearOf: mark)
    #expect(placed == CGSize(width: 60, height: 55 + 75.5))
  }

  @Test("a readout open on the map is drawn on the panel's ground, and none is drawn closed")
  func drawn() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    surface.longTap(at: [100, 40], position: [6.8652, 45.9237])
    let open = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          ReadoutCard(engine: map)
        }
        .frame(width: 320, height: 400)))
    #expect(
      Pixels.pixel(open, at: CGPoint(x: 20, y: 90))?.isNear(Controls.color("#ffffff")) == true,
      "flipped left of its point and moved under the frame held clear while the read waits")

    surface.tap(at: [100, 40], position: [6.8652, 45.9237])
    let closed = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          ReadoutCard(engine: map)
        }
        .frame(width: 320, height: 400)))
    #expect(
      Pixels.pixel(closed, at: CGPoint(x: 20, y: 90))?.isNear(Controls.color("#000000")) == true)
  }

  @Test("the map's edge cuts a card that no place inside the safe area clears the frame for")
  func cutByTheMap() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    surface.longTap(at: [100, 40], position: [6.8652, 45.9237])
    // The map is 100 points tall, so the card opens with its top at the frame's bottom, held
    // clear while the read waits, and runs past the map's bottom edge.
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .top) {
          Color.black
          ReadoutCard(engine: map).frame(width: 320, height: 100)
        }
        .frame(width: 320, height: 400)))
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 20, y: 90))?.isNear(Controls.color("#ffffff")) == true,
      "drawn below the frame, inside the map")
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 20, y: 110))?.isNear(Controls.color("#000000")) == true,
      "cut at the map's bottom edge")
    withExtendedLifetime(surface) {}
  }

  @Test("in a layout that runs right to left, the card stands where the map's points put it")
  func rightToLeft() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    surface.longTap(at: [100, 40], position: [6.8652, 45.9237])
    let open = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          ReadoutCard(engine: map)
        }
        .frame(width: 320, height: 400)
        .environment(\.layoutDirection, .rightToLeft)))
    #expect(
      Pixels.pixel(open, at: CGPoint(x: 20, y: 90))?.isNear(Controls.color("#ffffff")) == true,
      "at the left edge and under the frame held clear, as in a layout that runs left to right")
    #expect(
      Pixels.pixel(open, at: CGPoint(x: 310, y: 30))?.isNear(Controls.color("#000000")) == true)
  }

  @Test("a moment is written in the time zone the device keeps, whatever the view's environment")
  func moment() {
    let device = ReadoutCard.zone
    defer { ReadoutCard.zone = device }
    let instant = Date(timeIntervalSince1970: 1_767_225_600)
    ReadoutCard.zone = { "Pacific/Kiritimati" }
    #expect(
      ReadoutCard.moment(instant, locale: "en-US")
        == formatDateTime(
          instant, locale: "en-US", timeZone: "Pacific/Kiritimati", dateLength: .medium,
          timeLength: .short))
    ReadoutCard.zone = device
    #expect(
      ReadoutCard.moment(instant, locale: "en-US")
        == formatDateTime(
          instant, locale: "en-US", timeZone: deviceTimeZone(), dateLength: .medium,
          timeLength: .short))
  }

  @Test("a moment the device's zone cannot write is left out, never written another way")
  func unwritten() {
    let device = ReadoutCard.zone
    defer { ReadoutCard.zone = device }
    let start = Date(timeIntervalSince1970: 1_767_225_600)
    let end = start.addingTimeInterval(86_400)
    ReadoutCard.zone = { "Mars/Olympus_Mons" }
    #expect(ReadoutCard.moment(start, locale: "en-US") == nil, "no UTC, no ISO string, no word")
    #expect(
      ReadoutCard.windowMoments(start: start, end: end, locale: "en-US") == nil,
      "the window is left out whole")
    #expect(ReadoutCard.windowMoments(start: nil, end: end, locale: "en-US") == nil)

    ReadoutCard.zone = { "Europe/Paris" }
    let written = { (instant: Date) in
      formatDateTime(
        instant, locale: "en-US", timeZone: "Europe/Paris", dateLength: .medium,
        timeLength: .short)
    }
    #expect(
      ReadoutCard.windowMoments(start: start, end: end, locale: "en-US")
        == ["start": written(start) ?? "-", "end": written(end) ?? "-"])
    #expect(
      ReadoutCard.windowMoments(start: nil, end: end, locale: "en-US")
        == ["end": written(end) ?? "-"], "a bound the window does not state is not asked for")
  }
}
