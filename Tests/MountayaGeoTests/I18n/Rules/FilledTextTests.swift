import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("filledText")
struct FilledTextTests {
  @Test("a template takes the value handed to it in place of its placeholder")
  func filled() {
    #expect(filledText("{elapsed} stop", value: "15 min") == "15 min stop")
    #expect(filledText("{elapsed} d’arrêt", value: "15 min") == "15 min d’arrêt")
    #expect(filledText("Cut-off {moment}", value: "21:30") == "Cut-off 21:30")
    #expect(filledText("Open {hours}", value: "8:00 to 18:00") == "Open 8:00 to 18:00")
  }

  @Test("the value is written exactly as handed, never read as a pattern")
  func asHanded() {
    #expect(filledText("Ouvert {hours}", value: "$& 8:00") == "Ouvert $& 8:00")
    #expect(filledText("{a}", value: #"\1 $1 {a}"#) == #"\1 $1 {a}"#)
    #expect(filledText("{a}", value: "") == "")
  }

  @Test("only the first placeholder fills, and a template holding none is written as it is")
  func placeholders() {
    #expect(filledText("{a} and {b}", value: "x") == "x and {b}")
    #expect(filledText("{{a}}", value: "x") == "{x}")
    #expect(filledText("{a1}", value: "x") == "x")
    #expect(filledText("no placeholder", value: "x") == "no placeholder")
    #expect(filledText("{}", value: "x") == "{}")
    #expect(filledText("{1a} {a b} {a-b} {é}", value: "x") == "{1a} {a b} {a-b} {é}")
    #expect(filledText("{elapsed", value: "x") == "{elapsed")
    #expect(filledText("", value: "x") == "")
  }

  @Test("a placeholder is read scalar by scalar, its brace standing where its scalar does")
  func scalars() {
    // The opening brace and the combining acute accent are one character, and two scalars.
    #expect(filledText("e{\u{301}a}", value: "x") == "e{\u{301}a}")
    #expect(filledText("\u{301}{a}", value: "x") == "\u{301}x")
    #expect(firstPlaceholder(in: "a {b} {c}", named: "c").map { "a {b} {c}"[$0] } == "{c}")
    #expect(firstPlaceholder(in: "a {b}", named: "B") == nil)
  }

  @Test("a template handed values by name takes each in every placeholder of its name")
  func byName() {
    let values = ["min": "2°C", "max": "5°C"]
    #expect(filledText("Between {min} and {max}", values: values) == "Between 2°C and 5°C")
    #expect(filledText("Up to {max}, from {min}", values: values) == "Up to 5°C, from 2°C")
    #expect(filledText("{min} {min}", values: values) == "2°C 2°C")
    #expect(filledText("Between {min} and {upper}", values: values) == "Between 2°C and {upper}")
    #expect(filledText("{max}", values: ["max": "{min}", "min": "x"]) == "{min}")
    #expect(filledText("no placeholder", values: values) == "no placeholder")
  }
}
