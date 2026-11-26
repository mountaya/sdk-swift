import MountayaClient

/// WaypointCardFacts is everything a card about one place states, in the order a card states it, before
/// any of it is drawn (`geo.profile.waypoint-card`): its headline, its services by name, when it can
/// be used, how to reach it, its fields, its links and its photos, each label a word of the reader's
/// scope and each figure written for the reader's units, and whether it states nothing at all.
public struct WaypointCardFacts: Sendable, Hashable {
  /// headline is the line under the place's name: its author's description, or the summary its
  /// record assembles, nil where neither says anything.
  public var headline: String?
  /// services is the services the place offers, in its order, each named.
  public var services: [Service]
  /// timing is when the place can be used: its cut-off, through the caller's formatter alone, then
  /// its planned stop.
  public var timing: [Line]
  /// contact is how to reach the place: opening hours, address, phone, email, website and booking
  /// page.
  public var contact: [Line]
  /// fields is the fields the place's author published, each written by its declared format.
  public var fields: [WaypointField]
  /// links is the place's media links, each with the address it may be anchored by.
  public var links: [MediaLink]
  /// photos is the place's photos a renderer may load, each at an address read past its white
  /// space, a photo at any other address left out.
  public var photos: [WaypointDetails.Photo]
  /// isEmpty is whether the place states no fact at all, its description apart, as
  /// `waypointDeclaresNothing` reads a record.
  public var isEmpty: Bool

  /// Creates a card from everything it states.
  public init(
    headline: String?, services: [Service], timing: [Line], contact: [Line],
    fields: [WaypointField], links: [MediaLink], photos: [WaypointDetails.Photo], isEmpty: Bool
  ) {
    self.headline = headline
    self.services = services
    self.timing = timing
    self.contact = contact
    self.fields = fields
    self.links = links
    self.photos = photos
    self.isEmpty = isEmpty
  }

  /// Service is one service a place offers: the wire's own value, which names its glyph, and the
  /// reader's name for it, or the value itself where the reader's words hold none.
  public struct Service: Sendable, Hashable {
    /// amenity is the service as the wire spells it.
    public var amenity: RestSchema.WaypointAmenity
    /// name is the reader's name for it.
    public var name: String

    /// Creates a service from its value and its name.
    public init(amenity: RestSchema.WaypointAmenity, name: String) {
      self.amenity = amenity
      self.name = name
    }

    /// Two services are equal where both are written alike.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.amenity, rhs.amenity) && sameText(lhs.name, rhs.name)
    }

    /// hash feeds the value, then the name.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(amenity)
      hasher.combine(name)
    }
  }

  /// Line is one labelled fact a card states: the reader's noun and the value beside it, the
  /// address a reader acts on it through where it has one, a phone's `tel:` and an email's
  /// `mailto:` among them, and whether that address leaves the app.
  public struct Line: Sendable, Hashable {
    /// label is the reader's noun for the fact, a word of the scope's `waypointCard` section.
    public var label: String
    /// value is the fact, as written.
    public var value: String
    /// href is the address a reader acts on the fact through, nil where it is none.
    public var href: String?
    /// isExternal is whether `href` leaves the app, a website or a booking page.
    public var isExternal: Bool

    /// Creates a line from its label, its value and its address.
    public init(label: String, value: String, href: String? = nil, isExternal: Bool = false) {
      self.label = label
      self.value = value
      self.href = href
      self.isExternal = isExternal
    }

    /// Two lines are equal where every text is written alike and both leave alike.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.label, rhs.label) && sameText(lhs.value, rhs.value)
        && sameText(lhs.href, rhs.href) && lhs.isExternal == rhs.isExternal
    }

    /// hash feeds every member.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(label)
      hasher.combine(value)
      hasher.combine(href)
      hasher.combine(isExternal)
    }
  }

  /// MediaLink is one media link of a place: its author's label and address, as written, and the
  /// address a renderer anchors it by, only where the address read past its white space is a web
  /// address; any other is printed as its label.
  public struct MediaLink: Sendable, Hashable {
    /// label is the link's label, as written.
    public var label: String
    /// url is the link's address, as written, text to read rather than an address to anchor.
    public var url: String
    /// href is the address a renderer anchors the link by, nil where it is no web address.
    public var href: String?

    /// Creates a link from its label, its address and the address it is anchored by.
    public init(label: String, url: String, href: String?) {
      self.label = label
      self.url = url
      self.href = href
    }

    /// Two links are equal where every text is written alike, or absent on both.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.label, rhs.label) && sameText(lhs.url, rhs.url) && sameText(lhs.href, rhs.href)
    }

    /// hash feeds every member.
    public func hash(into hasher: inout Hasher) {
      hasher.combine(label)
      hasher.combine(url)
      hasher.combine(href)
    }
  }
}
