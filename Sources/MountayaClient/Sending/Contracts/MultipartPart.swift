import Foundation

/// MultipartPart is one part of a `multipart/form-data` body: a form field's text, or a file's
/// bytes, under the field's name.
///
/// A printed form writes its parts itself, one to a property; a call made by its declaration
/// hands its own, `RequestBody.multipart`, which are sent in the order given.
public struct MultipartPart: Sendable, Hashable {
  /// Content is what a part carries.
  public enum Content: Sendable, Hashable {
    /// text is a form field.
    case text(String)
    /// file is an uploaded file's bytes, with the file name its part states, left out where it is
    /// nil, and the media type its part is sent as, `application/octet-stream` where it is nil.
    case file(Data, filename: String? = nil, contentType: String? = nil)
  }

  /// name is the part's form field name, the contract's property name verbatim.
  public let name: String
  /// content is what the part carries.
  public let content: Content

  /// Creates a part carrying `content` under the form field `name`.
  public init(name: String, content: Content) {
    self.name = name
    self.content = content
  }
}
