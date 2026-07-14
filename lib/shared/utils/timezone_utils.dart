/// Returns a friendly display label for an IANA timezone ID.
/// "Asia/Ho_Chi_Minh" → "Ho Chi Minh (Asia)"
/// "America/New_York" → "New York (America)"
/// "Etc/UTC"          → "UTC"
/// "UTC"              → "UTC"
String timezoneDisplayLabel(String ianaId) {
  final firstSlash = ianaId.indexOf('/');
  if (firstSlash < 0) return ianaId;
  final lastSlash = ianaId.lastIndexOf('/');
  final city = ianaId.substring(lastSlash + 1).replaceAll('_', ' ');
  final region = ianaId.substring(0, firstSlash);
  // Etc/UTC, Etc/GMT±N — hide the Etc prefix
  if (region == 'Etc') return city;
  return '$city ($region)';
}
