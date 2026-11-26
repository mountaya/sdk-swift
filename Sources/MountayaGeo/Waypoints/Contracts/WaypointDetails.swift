import Foundation
import MountayaClient

/// WaypointDetails is what a waypoint says about the place it marks, as an element reads it: the
/// services there, its author's note, its timing, how to reach it, its photos and links, and the
/// fields its author published. `itineraryWaypoints(_:)` reads it off the wire's waypoint.
///
/// The wire says "nothing here" four ways, a member absent, one written null, an empty list and a
/// block whose every member is null, which is what a partial write stores, and here each of them
/// is nil. A member is present only where it holds something, so a renderer asks whether it is
/// there and has its answer.
///
/// An address, a website, a booking page, a photo's and a link's, is the text the wire answers,
/// never a `URL`: a card states it as written and anchors it only where it is a web address
/// (`isWebAddress(_:)`), which a Foundation `URL` would decide first, percent-encoding text that is
/// no address or refusing it.
///
/// Two are equal where every member is, texts compared scalar for scalar and an instant as the same
/// number, as every value of the geo layer compares.
public struct WaypointDetails: Sendable, Hashable {
  /// amenities is the services available at the place, in the order the wire lists them, nil where
  /// it lists none.
  public var amenities: [RestSchema.WaypointAmenity]?
  /// description is the author's note about the place.
  public var description: String?
  /// timing is the place's cut-off and its planned stop.
  public var timing: Timing?
  /// contact is how to reach the place.
  public var contact: Contact?
  /// media is the photos and links attached to the place.
  public var media: Media?
  /// properties is the fields the author published about the place, in the order they are shown,
  /// nil where there is none.
  public var properties: [Property]?

  /// Creates details from what a waypoint says, each member nil unless given.
  public init(
    amenities: [RestSchema.WaypointAmenity]? = nil,
    description: String? = nil,
    timing: Timing? = nil,
    contact: Contact? = nil,
    media: Media? = nil,
    properties: [Property]? = nil
  ) {
    self.amenities = amenities
    self.description = description
    self.timing = timing
    self.contact = contact
    self.media = media
    self.properties = properties
  }

  /// Timing is a place's cut-off and its planned stop.
  public struct Timing: Sendable, Hashable {
    /// cutoffAt is the instant by which the place must be left.
    public var cutoffAt: Date?
    /// stopDuration is the seconds planned at the place.
    public var stopDuration: Int?

    /// Creates a timing from its cut-off and its planned stop.
    public init(cutoffAt: Date? = nil, stopDuration: Int? = nil) {
      self.cutoffAt = cutoffAt
      self.stopDuration = stopDuration
    }

    /// Two timings are equal where the cut-offs are the same instant, as the same number of
    /// seconds, and the stops are the same.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameNumber(
        lhs.cutoffAt?.timeIntervalSinceReferenceDate, rhs.cutoffAt?.timeIntervalSinceReferenceDate)
        && lhs.stopDuration == rhs.stopDuration
    }

    /// hash feeds the cut-off as the same-number relation reads it, then the stop.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(sameNumber: cutoffAt?.timeIntervalSinceReferenceDate)
      hasher.combine(stopDuration)
    }
  }

  /// Contact is how to reach a place, each member a line of its own.
  public struct Contact: Sendable, Hashable {
    /// address is the place's postal address.
    public var address: String?
    /// bookingUrl is where the place is booked, as written.
    public var bookingUrl: String?
    /// email is the place's email address.
    public var email: String?
    /// openingHours is when the place is open, as its author wrote it.
    public var openingHours: String?
    /// phone is the place's telephone number.
    public var phone: String?
    /// website is the place's own site, as written.
    public var website: String?

    /// Creates a contact from its members, each nil unless given.
    public init(
      address: String? = nil,
      bookingUrl: String? = nil,
      email: String? = nil,
      openingHours: String? = nil,
      phone: String? = nil,
      website: String? = nil
    ) {
      self.address = address
      self.bookingUrl = bookingUrl
      self.email = email
      self.openingHours = openingHours
      self.phone = phone
      self.website = website
    }

    /// Two contacts are equal where every member is written alike, or absent on both.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.address, rhs.address) && sameText(lhs.bookingUrl, rhs.bookingUrl)
        && sameText(lhs.email, rhs.email) && sameText(lhs.openingHours, rhs.openingHours)
        && sameText(lhs.phone, rhs.phone)
        && sameText(lhs.website, rhs.website)
    }

    /// hash feeds every member.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(address)
      hasher.combine(bookingUrl)
      hasher.combine(email)
      hasher.combine(openingHours)
      hasher.combine(phone)
      hasher.combine(website)
    }
  }

  /// Media is the photos and links attached to a place, each list nil rather than empty.
  public struct Media: Sendable, Hashable {
    /// photos is the place's photographs, in the order they are shown.
    public var photos: [Photo]?
    /// links is the place's links, in the order they are shown.
    public var links: [Link]?

    /// Creates media from its photos and its links.
    public init(photos: [Photo]? = nil, links: [Link]? = nil) {
      self.photos = photos
      self.links = links
    }
  }

  /// Photo is a photograph of a place, by where it is.
  public struct Photo: Sendable, Hashable {
    /// url is where the photograph is, as written.
    public var url: String
    /// caption is what the photograph shows, in its author's words.
    public var caption: String?

    /// Creates a photo from where it is and its caption.
    public init(url: String, caption: String? = nil) {
      self.url = url
      self.caption = caption
    }

    /// Two photos are equal where they are at addresses written alike, with captions written alike.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.url, rhs.url) && sameText(lhs.caption, rhs.caption)
    }

    /// hash feeds where it is, then the caption.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(url)
      hasher.combine(caption)
    }
  }

  /// Link is a labelled link attached to a place.
  public struct Link: Sendable, Hashable {
    /// label is what a reader reads for the link.
    public var label: String
    /// url is where the link leads, as written.
    public var url: String

    /// Creates a link from its label and where it leads.
    public init(label: String, url: String) {
      self.label = label
      self.url = url
    }

    /// Two links are equal where the labels and where they lead are written alike.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.label, rhs.label) && sameText(lhs.url, rhs.url)
    }

    /// hash feeds the label, then where it leads.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(label)
      hasher.combine(url)
    }
  }

  /// Property is a field a place's author published: a key a machine reads, the label a reader
  /// reads, and its value.
  public struct Property: Sendable, Hashable {
    /// key is the field's key, unique within its waypoint.
    public var key: String
    /// label is the field's name as a reader reads it.
    public var label: String
    /// value is the field's value, as its author wrote it.
    public var value: String
    /// format is how the value is rendered, nil read as text.
    public var format: RestSchema.WaypointPropertyFormat?

    /// Creates a field from its key, its label, its value and its format.
    public init(
      key: String, label: String, value: String, format: RestSchema.WaypointPropertyFormat? = nil
    ) {
      self.key = key
      self.label = label
      self.value = value
      self.format = format
    }

    /// Two fields are equal where every member is written alike, or absent on both.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.key, rhs.key) && sameText(lhs.label, rhs.label)
        && sameText(lhs.value, rhs.value) && sameText(lhs.format, rhs.format)
    }

    /// hash feeds every member.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(key)
      hasher.combine(label)
      hasher.combine(value)
      hasher.combine(format)
    }
  }

  /// Two details are equal where every member is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameList(lhs.amenities, rhs.amenities) { sameText($0, $1) }
      && sameText(lhs.description, rhs.description) && lhs.timing == rhs.timing
      && lhs.contact == rhs.contact && lhs.media == rhs.media
      && sameList(lhs.properties, rhs.properties) { $0 == $1 }
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(amenities)
    hasher.combine(description)
    hasher.combine(timing)
    hasher.combine(contact)
    hasher.combine(media)
    hasher.combine(properties)
  }
}

/// sameList tells whether two lists a value may leave absent are the same: both absent, or as long
/// as each other and the same element for element, as `same` reads two elements.
private func sameList<Element>(
  _ a: [Element]?, _ b: [Element]?, by same: (Element, Element) -> Bool
) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return a.elementsEqual(b, by: same)
  default: return false
  }
}
