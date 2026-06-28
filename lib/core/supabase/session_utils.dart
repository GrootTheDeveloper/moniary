import 'dart:convert';

/// Extracts the `session_id` claim from a Supabase JWT access token.
/// Returns null if the token is absent, malformed, or missing the claim.
String? extractJwtSessionId(String? accessToken) {
  if (accessToken == null) return null;
  try {
    final parts = accessToken.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1];
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    return data['session_id'] as String?;
  } catch (_) {
    return null;
  }
}
