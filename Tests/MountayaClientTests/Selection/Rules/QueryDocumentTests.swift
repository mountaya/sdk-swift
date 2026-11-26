import Testing

@testable import MountayaClient

@Suite("QueryDocument")
struct QueryDocumentTests {
  @Test("two spaces to a level, one field to a line, and one newline at the end")
  func layout() {
    let document = QueryDocument.print(
      name: "terrainProfile",
      inputType: "TerrainProfileInput!",
      selection: ["profile": ["points": ["altitude": true]], "duration": true]
    )

    #expect(
      document
        == "query TerrainProfile($input: TerrainProfileInput!) {\n"
        + "  terrainProfile(input: $input) {\n"
        + "    profile {\n"
        + "      points {\n"
        + "        altitude\n"
        + "      }\n"
        + "    }\n"
        + "    duration\n"
        + "  }\n"
        + "}\n"
    )
  }

  @Test("the operation is named after its field with only the first letter upper-cased")
  func operationName() {
    let document = QueryDocument.print(
      name: "pois",
      inputType: "POIsInput!",
      selection: ["total": true]
    )

    #expect(document.hasPrefix("query Pois($input: POIsInput!) {\n  pois(input: $input) {\n"))
  }
}
