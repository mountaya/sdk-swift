/// themeTokenValue is the value `token` reads under `scheme` (`geo.style.theme-tokens`): its dark
/// value under the dark scheme where it states one, and its light value otherwise.
///
/// A consumer states a value of its own by setting the token whole on a copy of
/// `ElementTokens.standard`, `tokens.controlBg = ThemeToken(light: HexColor(hex: "#000000"))`. A
/// token of a light value alone reads it under both schemes, so a consumer's value stands in both,
/// where a token as the table states it reads the table's dark value under the dark scheme. A
/// consumer who wants a value of its own under each scheme states both,
/// `ThemeToken(light: ..., dark: ...)`.
public func themeTokenValue<Value>(_ token: ThemeToken<Value>, in scheme: ThemeScheme) -> Value {
  switch scheme {
  case .light: token.light
  case .dark: token.dark ?? token.light
  }
}
