// swift-format-ignore-file
// Printed by `swift run GenerateClient` from `sdk/elements/words.json`, model digest
// c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong value is a defect in `mountaya/schemas`, fixed there and printed
// again (SPEC.md section 3).

import MountayaClient

extension WordBundle {
  /// elements is the words the elements put on screen, by section, as the contract's words table
  /// holds them: English, which every language falls back to, and the translations it carries (fr).
  /// A word is a string, a template a string holding `{name}` placeholders, and a counted word an
  /// object of the forms CLDR's plural rules name, `other` among them. A consumer's own words are
  /// folded over them by `resolveBundle(_:language:overrides:handedOver:)`.
  public static let elements = WordBundle(english: wordsEn, translations: ["fr": wordsFr])
}

/// The elements' words in the language `en`.
private let wordsEn: [String: JSONValue] = [
  "controls": [
    "close": "Close",
    "quote": "Say \"hi\"\\now",
  ],
  "search": [
    "resultCount": [
      "one": "{count} result",
      "other": "{count} results",
    ],
  ],
  "tooltips": [
    "zoomIn": [
      "description": "Zoom in by one level.",
      "title": "Zoom in",
    ],
  ],
]

/// The elements' words in the language `fr`.
private let wordsFr: [String: JSONValue] = [
  "controls": [
    "close": "Fermer",
    "quote": "Dire « salut »",
  ],
  "search": [
    "resultCount": [
      "one": "{count} résultat",
      "other": "{count} résultats",
    ],
  ],
  "tooltips": [
    "zoomIn": [
      "description": "Zoomer d'un niveau.",
      "title": "Zoomer",
    ],
  ],
]
