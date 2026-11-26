import Foundation
import MountayaClient

/// The middle dot between two spaces a summary's two clauses are parted by.
private let summarySeparator = " · "

/// waypointCard is everything a card about a place says, in the order a card says it, from what
/// the place records (`geo.profile.waypoint-card`), its words the reader's `scope`'s and its figures
/// written for `units`.
///
/// Its services by name (`amenityName(_:in:)`), a service the scope's words hold no name for named
/// by its own value. Its timing: the cut-off only through `formatCutoffAt`, since an instant needs a time zone
/// only the caller holds, then the planned stop as `formatDuration(_:units:)` writes it, a stop that
/// rounds to no minute taking no line. Its contact lines as opening hours, address, phone, email,
/// website and booking page, a phone carrying `tel:` and an email `mailto:` before its value, and a
/// website and a booking page carrying the address they read as past their white space, leaving the
/// app, only where it is a web address (`isWebAddress(_:)`), any other stated as text. Its fields
/// by their declared format (`waypointPropertyValue(_:units:formatInstant:)`), a `url` field anchored
/// only where its value is a web address (`waypointPropertyLink(_:)`). Its links, each anchored only
/// where its address is a web address, and its photos at a web address alone. A section with no
/// line states nothing, and the headline is the author's description, else the summary its record
/// assembles in two clauses at most.
public func waypointCard(
  _ details: WaypointDetails?,
  scope: ElementsScope,
  units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)? = nil
) -> WaypointCardFacts {
  let word = { (key: String) in scope.word("waypointCard.\(key)") }
  var timing: [WaypointCardFacts.Line] = []
  if let cutoffAt = details?.timing?.cutoffAt, let formatCutoffAt {
    timing.append(WaypointCardFacts.Line(label: word("cutoff"), value: formatCutoffAt(cutoffAt)))
  }
  let stop = formatDuration(details?.timing?.stopDuration.map(Double.init), units: units)
  if !stop.isEmpty {
    timing.append(WaypointCardFacts.Line(label: word("stop"), value: stop))
  }
  var contact: [WaypointCardFacts.Line] = []
  if let lines = details?.contact {
    if let hours = lines.openingHours {
      contact.append(WaypointCardFacts.Line(label: word("openingHours"), value: hours))
    }
    if let address = lines.address {
      contact.append(WaypointCardFacts.Line(label: word("address"), value: address))
    }
    if let phone = lines.phone {
      contact.append(
        WaypointCardFacts.Line(label: word("phone"), value: phone, href: "tel:\(phone)"))
    }
    if let email = lines.email {
      contact.append(
        WaypointCardFacts.Line(label: word("email"), value: email, href: "mailto:\(email)"))
    }
    if let website = lines.website {
      contact.append(webAddressLine(label: word("website"), value: website))
    }
    if let booking = lines.bookingUrl {
      contact.append(webAddressLine(label: word("booking"), value: booking))
    }
  }
  return WaypointCardFacts(
    headline: cardHeadline(details, scope: scope, units: units, formatCutoffAt: formatCutoffAt),
    services: (details?.amenities ?? []).map {
      WaypointCardFacts.Service(amenity: $0, name: amenityName($0, in: scope))
    },
    timing: timing,
    contact: contact,
    fields: (details?.properties ?? []).map { property in
      WaypointField(
        key: property.key, label: property.label,
        value: waypointPropertyValue(property, units: units, formatInstant: formatCutoffAt),
        href: waypointPropertyLink(property))
    },
    links: (details?.media?.links ?? []).map { link in
      let address = trimWhiteSpace(link.url)
      return WaypointCardFacts.MediaLink(
        label: link.label, url: link.url, href: isWebAddress(address) ? address : nil)
    },
    photos: (details?.media?.photos ?? []).compactMap { photo in
      let address = trimWhiteSpace(photo.url)
      return isWebAddress(address)
        ? WaypointDetails.Photo(url: address, caption: photo.caption) : nil
    },
    isEmpty: declaresNothing(details)
  )
}

/// A website's or a booking page's line: anchored, leaving the app, where its address read past its
/// white space is a web address, and text otherwise.
private func webAddressLine(label: String, value: String) -> WaypointCardFacts.Line {
  let address = trimWhiteSpace(value)
  guard isWebAddress(address) else { return WaypointCardFacts.Line(label: label, value: value) }
  return WaypointCardFacts.Line(label: label, value: value, href: address, isExternal: true)
}

/// Whether a place records no fact a card states, its description apart.
private func declaresNothing(_ details: WaypointDetails?) -> Bool {
  (details?.amenities ?? []).isEmpty && details?.timing == nil && details?.contact == nil
    && (details?.media?.photos ?? []).isEmpty && (details?.media?.links ?? []).isEmpty
    && (details?.properties ?? []).isEmpty
}

/// The line under a place's name: its description past the white space at its ends, else at most
/// two clauses, whether it is equipped and one timing fact, the opening hours, else the cut-off
/// where the caller can write one, else the planned stop, parted by a middle dot.
private func cardHeadline(
  _ details: WaypointDetails?, scope: ElementsScope, units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)?
) -> String? {
  guard let details else { return nil }
  let description = details.description.map(trimWhiteSpace) ?? ""
  if !description.isEmpty { return description }
  var clauses: [String] = []
  if !(details.amenities ?? []).isEmpty {
    clauses.append(scope.word("waypointCard.amenities"))
  }
  if let hours = details.contact?.openingHours, !hours.isEmpty {
    clauses.append(filledText(scope.word("waypointCard.summary.openingHours"), value: hours))
  } else if let cutoffAt = details.timing?.cutoffAt, let formatCutoffAt {
    clauses.append(
      filledText(scope.word("waypointCard.summary.cutoffAt"), value: formatCutoffAt(cutoffAt)))
  } else {
    let stop = formatDuration(details.timing?.stopDuration.map(Double.init), units: units)
    if !stop.isEmpty {
      clauses.append(filledText(scope.word("waypointCard.summary.stop"), value: stop))
    }
  }
  return clauses.isEmpty ? nil : clauses.joined(separator: summarySeparator)
}
