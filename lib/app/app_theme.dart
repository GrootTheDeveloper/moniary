import 'package:flutter/material.dart';

class MoniaryColors extends ThemeExtension<MoniaryColors> {
  const MoniaryColors({
    required this.background,
    required this.backgroundSoft,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.primary,
    required this.secondary,
    required this.button,
    required this.icon,
    required this.navBar,
    required this.navInactive,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDim,
    required this.success,
    required this.danger,
    required this.warning,
    required this.accentPink,
    required this.surfaceOverlay,
  });

  final Color background;
  final Color backgroundSoft;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color primary;
  final Color secondary;
  final Color button;
  final Color icon;
  final Color navBar;
  final Color navInactive;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;
  final Color success;
  final Color danger;
  final Color warning;
  final Color accentPink;
  final Color surfaceOverlay;

  @override
  MoniaryColors copyWith({
    Color? background,
    Color? backgroundSoft,
    Color? surface,
    Color? surfaceRaised,
    Color? outline,
    Color? primary,
    Color? secondary,
    Color? button,
    Color? icon,
    Color? navBar,
    Color? navInactive,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDim,
    Color? success,
    Color? danger,
    Color? warning,
    Color? accentPink,
    Color? surfaceOverlay,
  }) {
    return MoniaryColors(
      background: background ?? this.background,
      backgroundSoft: backgroundSoft ?? this.backgroundSoft,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      outline: outline ?? this.outline,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      button: button ?? this.button,
      icon: icon ?? this.icon,
      navBar: navBar ?? this.navBar,
      navInactive: navInactive ?? this.navInactive,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDim: textDim ?? this.textDim,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      accentPink: accentPink ?? this.accentPink,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
    );
  }

  @override
  MoniaryColors lerp(ThemeExtension<MoniaryColors>? other, double t) {
    if (other is! MoniaryColors) {
      return this;
    }
    return MoniaryColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundSoft: Color.lerp(backgroundSoft, other.backgroundSoft, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      button: Color.lerp(button, other.button, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
    );
  }
}

extension MoniaryThemeExtension on BuildContext {
  MoniaryColors get moniaryColors =>
      Theme.of(this).extension<MoniaryColors>() ?? AppTheme.defaultColors;
}

class AppTheme {
  static const background = Color(0xFF09111B);
  static const backgroundSoft = Color(0xFF101B28);
  static const surface = Color(0xFF121C28);
  static const surfaceRaised = Color(0xFF172331);
  static const outline = Color(0xFF243344);
  static const mint = Color(0xFF2563EB); // Deep Professional Blue
  static const mintSoft = Color(0xFF60A5FA); // Soft Blue
  static const mintTeal = Color(
    0xFF68E5D8,
  ); // Teal accent, used in avatar gradient
  static const mintTealDark = Color(
    0xFF10333B,
  ); // Dark teal, icon on teal surface
  static const pink = Color(0xFFE45CA6);
  static const amber = Color(0xFFF6B24D);
  static const danger = Color(0xFFFC8181);
  static const success = Color(0xFF44D884);
  static const textMuted = Color(0xFFBECCD9);
  static const textSubtle = Color(0xFF9CB0C2);
  static const textDim = Color(0xFF70869A);
  static const surfaceOverlay = Color(0x66000000);
  static const navInactive = Color(0xFF74889A);

  static const defaultColors = MoniaryColors(
    background: background,
    backgroundSoft: backgroundSoft,
    surface: surface,
    surfaceRaised: surfaceRaised,
    outline: outline,
    primary: mint,
    secondary: mintSoft,
    button: mint,
    icon: Colors.white,
    navBar: Color(0xFF0D1622),
    navInactive: navInactive,
    textPrimary: Colors.white,
    textSecondary: textMuted,
    textDim: textDim,
    success: success,
    danger: danger,
    warning: amber,
    accentPink: pink,
    surfaceOverlay: surfaceOverlay,
  );

  static ThemeData get darkTheme {
    const colors = defaultColors;
    final colorScheme = ColorScheme.dark(
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      error: colors.danger,
      outline: colors.outline,
      outlineVariant: colors.outline,
      primaryContainer: colors.primary.withValues(alpha: 0.16),
      onPrimaryContainer: colors.primary,
      secondaryContainer: colors.secondary.withValues(alpha: 0.16),
      onSecondaryContainer: colors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      splashFactory: NoSplash.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.02,
          color: colors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: colors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        titleSmall: TextStyle(color: colors.textPrimary),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: colors.textSecondary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(color: colors.textDim),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colors.textDim),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 1.2),
        ),
      ),
      iconTheme: IconThemeData(color: colors.icon),
      dividerColor: colors.outline,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.button,
        foregroundColor: _foregroundFor(colors.button),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.button,
          foregroundColor: _foregroundFor(colors.button),
          minimumSize: const Size.fromHeight(58),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceRaised,
        selectedColor: colors.primary,
        side: BorderSide(color: colors.outline),
        disabledColor: colors.surfaceRaised,
        labelStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static Color _foregroundFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
  }
}
