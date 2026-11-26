// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataOperation {
  /// analyzeGeometry is the Data API's `analyzeGeometry`, with every field of its result in the
  /// schema's order, which is its full selection, and its budget.
  static let analyzeGeometry = DataOperation(
    name: "analyzeGeometry",
    inputType: "AnalyzeGeometryInput!",
    selection: [
      "analysis": [
        "elevation": [
          "altitude": [
            "max": true,
            "min": true,
          ],
          "ascent": true,
          "descent": true,
          "gradient": [
            "max": true,
            "min": true,
          ],
        ],
        "elevations": true,
        "slopeInfo": [
          "fromIndex": true,
          "toIndex": true,
          "value": true,
        ],
        "speedInfo": [
          "fromIndex": true,
          "toIndex": true,
          "value": true,
        ],
        "surfaceInfo": [
          "fromIndex": true,
          "toIndex": true,
          "value": true,
        ],
        "trailDifficultyInfo": [
          "fromIndex": true,
          "toIndex": true,
          "value": true,
        ],
        "wayTypeInfo": [
          "fromIndex": true,
          "toIndex": true,
          "value": true,
        ],
        "advisories": [
          "tollway": true,
          "restrictedAccess": true,
          "tollwayInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "roadAccessInfo": [
            "fromIndex": true,
            "toIndex": true,
            "values": true,
          ],
        ],
      ],
      "duration": true,
    ],
    timeout: .milliseconds(30000)
  )

  /// directions is the Data API's `directions`, with every field of its result in the schema's
  /// order, which is its full selection, and its budget.
  static let directions = DataOperation(
    name: "directions",
    inputType: "DirectionsInput!",
    selection: [
      "routes": [
        "distance": true,
        "duration": true,
        "elevation": [
          "altitude": [
            "max": true,
            "min": true,
          ],
          "ascent": true,
          "descent": true,
          "gradient": [
            "max": true,
            "min": true,
          ],
        ],
        "geometry": true,
        "analysis": [
          "elevation": [
            "altitude": [
              "max": true,
              "min": true,
            ],
            "ascent": true,
            "descent": true,
            "gradient": [
              "max": true,
              "min": true,
            ],
          ],
          "elevations": true,
          "slopeInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "speedInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "surfaceInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "trailDifficultyInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "wayTypeInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "advisories": [
            "tollway": true,
            "restrictedAccess": true,
            "tollwayInfo": [
              "fromIndex": true,
              "toIndex": true,
              "value": true,
            ],
            "roadAccessInfo": [
              "fromIndex": true,
              "toIndex": true,
              "values": true,
            ],
          ],
        ],
        "avoidance": true,
        "summary": true,
        "steps": [
          "fromIndex": true,
          "toIndex": true,
          "type": true,
          "name": true,
          "distance": true,
          "duration": true,
          "exitNumber": true,
        ],
      ]
    ],
    timeout: .milliseconds(30000)
  )

  /// exportItinerary is the Data API's `exportItinerary`, with every field of its result in the
  /// schema's order, which is its full selection, and its budget.
  static let exportItinerary = DataOperation(
    name: "exportItinerary",
    inputType: "ExportItineraryInput!",
    selection: [
      "url": true,
      "filename": true,
      "format": true,
      "expiresAt": true,
    ],
    timeout: .milliseconds(30000)
  )

  /// geocode is the Data API's `geocode`, with every field of its result in the schema's order,
  /// which is its full selection, and its budget.
  static let geocode = DataOperation(
    name: "geocode",
    inputType: "GeocodeInput!",
    selection: [
      "count": true,
      "places": [
        "osm": [
          "id": true,
          "type": true,
          "key": true,
          "value": true,
        ],
        "name": true,
        "label": true,
        "layer": true,
        "category": true,
        "point": true,
        "bounds": true,
        "country": true,
        "countryName": true,
        "region": true,
        "county": true,
        "city": true,
        "postcode": true,
        "street": true,
        "houseNumber": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )

  /// isochrones is the Data API's `isochrones`, with every field of its result in the schema's
  /// order, which is its full selection, and its budget.
  static let isochrones = DataOperation(
    name: "isochrones",
    inputType: "IsochronesInput!",
    selection: [
      "isochrones": [
        "value": true,
        "area": true,
        "reachFactor": true,
        "center": true,
        "geometry": true,
      ]
    ],
    timeout: .milliseconds(30000)
  )

  /// itinerary is the Data API's `itinerary`, with every field of its result in the schema's order,
  /// which is its full selection, and its budget.
  static let itinerary = DataOperation(
    name: "itinerary",
    inputType: "ItineraryInput!",
    selection: [
      "id": true,
      "name": true,
      "description": true,
      "activitySlug": true,
      "distance": true,
      "ascent": true,
      "isPrivate": true,
      "organizationId": true,
      "segments": [
        "id": true,
        "name": true,
        "description": true,
        "position": true,
        "groupId": true,
        "distance": true,
        "duration": true,
        "ascent": true,
        "descent": true,
        "altitude": [
          "max": true,
          "min": true,
        ],
        "gradient": [
          "max": true,
          "min": true,
        ],
        "geometry": true,
      ],
      "waypoints": [
        "id": true,
        "name": true,
        "description": true,
        "position": true,
        "point": true,
        "amenities": true,
        "timing": [
          "cutoffAt": true,
          "stopDuration": true,
        ],
        "contact": [
          "website": true,
          "phone": true,
          "email": true,
          "address": true,
          "openingHours": true,
          "bookingUrl": true,
        ],
        "media": [
          "photos": [
            "url": true,
            "caption": true,
          ],
          "links": [
            "label": true,
            "url": true,
          ],
        ],
        "properties": [
          "key": true,
          "label": true,
          "value": true,
          "format": true,
        ],
      ],
      "groups": [
        "id": true,
        "name": true,
        "color": true,
        "speed": true,
      ],
      "segmentCount": true,
      "waypointCount": true,
      "groupCount": true,
    ],
    timeout: .milliseconds(30000)
  )

  /// matrix is the Data API's `matrix`, with every field of its result in the schema's order, which
  /// is its full selection, and its budget.
  static let matrix = DataOperation(
    name: "matrix",
    inputType: "MatrixInput!",
    selection: [
      "durations": true,
      "distances": true,
    ],
    timeout: .milliseconds(30000)
  )

  /// pois is the Data API's `pois`, with every field of its result in the schema's order, which is
  /// its full selection, and its budget.
  static let pois = DataOperation(
    name: "pois",
    inputType: "PoisInput!",
    selection: [
      "count": true,
      "pois": [
        "osm": [
          "id": true,
          "type": true,
          "key": true,
          "value": true,
        ],
        "name": true,
        "category": true,
        "point": true,
        "elevation": true,
        "tags": [
          "key": true,
          "value": true,
        ],
        "distanceMeters": true,
        "country": true,
        "countryName": true,
        "region": true,
        "city": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )

  /// reverseGeocode is the Data API's `reverseGeocode`, with every field of its result in the
  /// schema's order, which is its full selection, and its budget.
  static let reverseGeocode = DataOperation(
    name: "reverseGeocode",
    inputType: "ReverseGeocodeInput!",
    selection: [
      "point": true,
      "places": [
        "osm": [
          "id": true,
          "type": true,
          "key": true,
          "value": true,
        ],
        "name": true,
        "label": true,
        "layer": true,
        "category": true,
        "point": true,
        "bounds": true,
        "country": true,
        "countryName": true,
        "region": true,
        "county": true,
        "city": true,
        "postcode": true,
        "street": true,
        "houseNumber": true,
      ],
      "count": true,
    ],
    timeout: .milliseconds(30000)
  )

  /// search is the Data API's `search`, with every field of its result in the schema's order, which
  /// is its full selection, and its budget.
  static let search = DataOperation(
    name: "search",
    inputType: "SearchInput!",
    selection: [
      "query": true,
      "language": true,
      "targets": [
        "places": true,
        "pois": true,
        "ways": true,
        "itineraries": true,
        "collections": true,
        "zones": true,
      ],
      "places": [
        "count": true,
        "places": [
          "osm": [
            "id": true,
            "type": true,
            "key": true,
            "value": true,
          ],
          "name": true,
          "label": true,
          "layer": true,
          "category": true,
          "point": true,
          "bounds": true,
          "country": true,
          "countryName": true,
          "region": true,
          "county": true,
          "city": true,
          "postcode": true,
          "street": true,
          "houseNumber": true,
        ],
      ],
      "pois": [
        "count": true,
        "pois": [
          "osm": [
            "id": true,
            "type": true,
            "key": true,
            "value": true,
          ],
          "name": true,
          "category": true,
          "point": true,
          "elevation": true,
          "tags": [
            "key": true,
            "value": true,
          ],
          "distanceMeters": true,
          "country": true,
          "countryName": true,
          "region": true,
          "city": true,
        ],
      ],
      "ways": [
        "count": true,
        "ways": [
          "osm": [
            "id": true,
            "type": true,
            "key": true,
            "value": true,
          ],
          "name": true,
          "highway": true,
          "surface": true,
          "sacScale": true,
          "point": true,
          "bounds": true,
          "coordinates": true,
          "activityCompatible": true,
          "country": true,
          "countryName": true,
          "region": true,
          "city": true,
        ],
        "activityApplied": true,
      ],
      "itineraries": [
        "count": true,
        "itineraries": [
          "id": true,
          "name": true,
          "description": true,
          "distance": true,
          "ascent": true,
          "activitySlug": true,
          "start": true,
          "bounds": true,
          "isPrivate": true,
          "organizationId": true,
          "score": true,
          "matchedField": true,
        ],
      ],
      "collections": [
        "count": true,
        "collections": [
          "id": true,
          "name": true,
          "description": true,
          "count": [
            "itineraries": true,
            "zones": true,
          ],
          "bounds": true,
          "isPrivate": true,
          "organizationId": true,
          "score": true,
          "matchedField": true,
        ],
      ],
      "zones": [
        "count": true,
        "zones": [
          "id": true,
          "name": true,
          "description": true,
          "level": true,
          "mode": true,
          "point": true,
          "bounds": true,
          "isPrivate": true,
          "organizationId": true,
          "score": true,
          "matchedField": true,
        ],
      ],
      "errors": [
        "target": true,
        "code": true,
        "message": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )

  /// suggestions is the Data API's `suggestions`, with every field of its result in the schema's
  /// order, which is its full selection, and its budget.
  static let suggestions = DataOperation(
    name: "suggestions",
    inputType: "SuggestionsInput!",
    selection: [
      "routes": [
        "distance": true,
        "duration": true,
        "elevation": [
          "altitude": [
            "max": true,
            "min": true,
          ],
          "ascent": true,
          "descent": true,
          "gradient": [
            "max": true,
            "min": true,
          ],
        ],
        "geometry": true,
        "analysis": [
          "elevation": [
            "altitude": [
              "max": true,
              "min": true,
            ],
            "ascent": true,
            "descent": true,
            "gradient": [
              "max": true,
              "min": true,
            ],
          ],
          "elevations": true,
          "slopeInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "speedInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "surfaceInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "trailDifficultyInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "wayTypeInfo": [
            "fromIndex": true,
            "toIndex": true,
            "value": true,
          ],
          "advisories": [
            "tollway": true,
            "restrictedAccess": true,
            "tollwayInfo": [
              "fromIndex": true,
              "toIndex": true,
              "value": true,
            ],
            "roadAccessInfo": [
              "fromIndex": true,
              "toIndex": true,
              "values": true,
            ],
          ],
        ],
        "summary": true,
        "steps": [
          "fromIndex": true,
          "toIndex": true,
          "type": true,
          "name": true,
          "distance": true,
          "duration": true,
          "exitNumber": true,
        ],
        "seed": true,
      ]
    ],
    timeout: .milliseconds(30000)
  )

  /// terrainGrid is the Data API's `terrainGrid`, with every field of its result in the schema's
  /// order, which is its full selection, and its budget.
  static let terrainGrid = DataOperation(
    name: "terrainGrid",
    inputType: "TerrainGridInput!",
    selection: [
      "count": true,
      "coveredCount": true,
      "zoom": true,
      "resolutionMeters": true,
      "cols": true,
      "rows": true,
      "cells": [
        "point": true,
        "elevation": true,
        "slope": true,
        "aspect": true,
        "aspectOctant": true,
        "steepnessBand": true,
        "distanceMeters": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )

  /// terrainProfile is the Data API's `terrainProfile`, with every field of its result in the
  /// schema's order, which is its full selection, and its budget.
  static let terrainProfile = DataOperation(
    name: "terrainProfile",
    inputType: "TerrainProfileInput!",
    selection: [
      "count": true,
      "coveredCount": true,
      "zoom": true,
      "resolutionMeters": true,
      "samples": [
        "point": true,
        "elevation": true,
        "slope": true,
        "aspect": true,
        "aspectOctant": true,
        "steepnessBand": true,
        "distanceMeters": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )

  /// terrainSamples is the Data API's `terrainSamples`, with every field of its result in the
  /// schema's order, which is its full selection, and its budget.
  static let terrainSamples = DataOperation(
    name: "terrainSamples",
    inputType: "TerrainSamplesInput!",
    selection: [
      "count": true,
      "coveredCount": true,
      "zoom": true,
      "resolutionMeters": true,
      "samples": [
        "point": true,
        "elevation": true,
        "slope": true,
        "aspect": true,
        "aspectOctant": true,
        "steepnessBand": true,
        "distanceMeters": true,
      ],
    ],
    timeout: .milliseconds(30000)
  )
}
