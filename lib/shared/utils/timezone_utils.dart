/// Returns a friendly display label for an IANA timezone ID.
/// "Asia/Ho_Chi_Minh" → "Ho Chi Minh"
/// "America/New_York" → "New York"
/// "Etc/UTC" → "UTC"
String timezoneDisplayLabel(String ianaId) {
  final slash = ianaId.lastIndexOf('/');
  final city = slash >= 0 ? ianaId.substring(slash + 1) : ianaId;
  return city.replaceAll('_', ' ');
}
