class BankInstitution {
  const BankInstitution({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isSupported = true,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final bool isSupported;

  factory BankInstitution.fromMap(Map<String, dynamic> map) {
    return BankInstitution(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      isSupported: map['is_supported'] as bool? ?? true,
    );
  }
}
