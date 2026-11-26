// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

/// RestSchema is every type the REST API sends or receives but the admin unit's own, which
/// `MountayaAdmin` declares in `AdminSchema`, named as the contract names it.
///
/// The types live here rather than at module scope because many names exist on more than one
/// surface, not always with one shape, and some would shadow a type the standard library or
/// Foundation publishes in every file that imports this module.
public enum RestSchema {}
