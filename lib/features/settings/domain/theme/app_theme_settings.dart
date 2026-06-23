class AppThemeSettings {
  const AppThemeSettings({
    required this.presetId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.buttonColor,
    required this.iconColor,
    required this.appBarColor,
    required this.navigationBarColor,
  });

  static const defaultPresetId = 'default';
  static const customPresetId = 'custom';

  static const defaults = AppThemeSettings(
    presetId: defaultPresetId,
    primaryColor: 0xFF2563EB,
    secondaryColor: 0xFF60A5FA,
    backgroundColor: 0xFF09111B,
    surfaceColor: 0xFF121C28,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFBECCD9,
    buttonColor: 0xFF2563EB,
    iconColor: 0xFFFFFFFF,
    appBarColor: 0x00000000,
    navigationBarColor: 0xFF0D1622,
  );

  static const emerald = AppThemeSettings(
    presetId: 'emerald',
    primaryColor: 0xFF10B981,
    secondaryColor: 0xFF6EE7B7,
    backgroundColor: 0xFF071513,
    surfaceColor: 0xFF10201D,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFB8D8D0,
    buttonColor: 0xFF10B981,
    iconColor: 0xFFFFFFFF,
    appBarColor: 0x00000000,
    navigationBarColor: 0xFF0B1B18,
  );

  static const rose = AppThemeSettings(
    presetId: 'rose',
    primaryColor: 0xFFE45CA6,
    secondaryColor: 0xFFF0A7CF,
    backgroundColor: 0xFF170A13,
    surfaceColor: 0xFF24131D,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFE4C0D3,
    buttonColor: 0xFFE45CA6,
    iconColor: 0xFFFFFFFF,
    appBarColor: 0x00000000,
    navigationBarColor: 0xFF1D0E17,
  );

  static const highContrast = AppThemeSettings(
    presetId: 'high_contrast',
    primaryColor: 0xFFFFD166,
    secondaryColor: 0xFF8EECF5,
    backgroundColor: 0xFF000000,
    surfaceColor: 0xFF111111,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFE6E6E6,
    buttonColor: 0xFFFFD166,
    iconColor: 0xFFFFFFFF,
    appBarColor: 0xFF000000,
    navigationBarColor: 0xFF080808,
  );

  static const presets = <AppThemeSettings>[
    defaults,
    emerald,
    rose,
    highContrast,
  ];

  final String presetId;
  final int primaryColor;
  final int secondaryColor;
  final int backgroundColor;
  final int surfaceColor;
  final int textPrimaryColor;
  final int textSecondaryColor;
  final int buttonColor;
  final int iconColor;
  final int appBarColor;
  final int navigationBarColor;

  AppThemeSettings copyWith({
    String? presetId,
    int? primaryColor,
    int? secondaryColor,
    int? backgroundColor,
    int? surfaceColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    int? buttonColor,
    int? iconColor,
    int? appBarColor,
    int? navigationBarColor,
  }) {
    return AppThemeSettings(
      presetId: presetId ?? this.presetId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      buttonColor: buttonColor ?? this.buttonColor,
      iconColor: iconColor ?? this.iconColor,
      appBarColor: appBarColor ?? this.appBarColor,
      navigationBarColor: navigationBarColor ?? this.navigationBarColor,
    );
  }

  AppThemeSettings asCustom() => copyWith(presetId: customPresetId);

  Map<String, dynamic> toJson() {
    return {
      'presetId': presetId,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'surfaceColor': surfaceColor,
      'textPrimaryColor': textPrimaryColor,
      'textSecondaryColor': textSecondaryColor,
      'buttonColor': buttonColor,
      'iconColor': iconColor,
      'appBarColor': appBarColor,
      'navigationBarColor': navigationBarColor,
    };
  }

  factory AppThemeSettings.fromJson(Map<String, dynamic> json) {
    return AppThemeSettings(
      presetId: _readString(json, 'presetId', defaultPresetId),
      primaryColor: _readColor(json, 'primaryColor', defaults.primaryColor),
      secondaryColor: _readColor(
        json,
        'secondaryColor',
        defaults.secondaryColor,
      ),
      backgroundColor: _readColor(
        json,
        'backgroundColor',
        defaults.backgroundColor,
      ),
      surfaceColor: _readColor(json, 'surfaceColor', defaults.surfaceColor),
      textPrimaryColor: _readColor(
        json,
        'textPrimaryColor',
        defaults.textPrimaryColor,
      ),
      textSecondaryColor: _readColor(
        json,
        'textSecondaryColor',
        defaults.textSecondaryColor,
      ),
      buttonColor: _readColor(json, 'buttonColor', defaults.buttonColor),
      iconColor: _readColor(json, 'iconColor', defaults.iconColor),
      appBarColor: _readColor(json, 'appBarColor', defaults.appBarColor),
      navigationBarColor: _readColor(
        json,
        'navigationBarColor',
        defaults.navigationBarColor,
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  static int _readColor(Map<String, dynamic> json, String key, int fallback) {
    final value = json[key];
    if (value is int && _isValidColor(value)) {
      return value;
    }
    if (value is String) {
      final parsed = parseColorString(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  static int? parseColorString(String value) {
    final sanitized = value.trim().replaceFirst('#', '').toUpperCase();
    if (sanitized.length != 6 && sanitized.length != 8) {
      return null;
    }
    final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null || !_isValidColor(parsed)) {
      return null;
    }
    return parsed;
  }

  static bool _isValidColor(int value) {
    return value >= 0x00000000 && value <= 0xFFFFFFFF;
  }
}
