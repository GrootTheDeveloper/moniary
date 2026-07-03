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

  MoniaryTypography get moniaryTypography =>
      Theme.of(this).extension<MoniaryTypography>() ??
      AppTheme.defaultTypography;
}

@immutable
class MoniaryTypography extends ThemeExtension<MoniaryTypography> {
  const MoniaryTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.metadata,
    required this.metadataStrong,
  });

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle metadata;
  final TextStyle metadataStrong;

  @override
  MoniaryTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? metadata,
    TextStyle? metadataStrong,
  }) {
    return MoniaryTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      metadata: metadata ?? this.metadata,
      metadataStrong: metadataStrong ?? this.metadataStrong,
    );
  }

  @override
  MoniaryTypography lerp(
    covariant ThemeExtension<MoniaryTypography>? other,
    double t,
  ) {
    if (other is! MoniaryTypography) return this;
    return MoniaryTypography(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      metadata: TextStyle.lerp(metadata, other.metadata, t)!,
      metadataStrong: TextStyle.lerp(metadataStrong, other.metadataStrong, t)!,
    );
  }
}

class AppTheme {
  // Frozen foundation tokens from the approved HTML redesign.
  static const background = Color(0xFFF1ECE1);
  static const backgroundSoft = Color(0xFFF6F2E9);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const outline = Color(0xFFD8CDBB);
  static const ink = Color(0xFF211D17);
  static const inkSoft = Color(0xFF2A241B);
  static const terracotta = Color(0xFFB85C38);
  static const terracottaBright = Color(0xFFE0784F);
  static const sage = Color(0xFF8E9B8F);
  static const forest = Color(0xFF4A7C59);
  static const sand = Color(0xFFD9A574);
  static const dustyRose = Color(0xFFA98C86);
  static const slate = Color(0xFF7E8CA0);
  static const taupe = Color(0xFFC2A98E);

  // Compatibility names used throughout the existing feature code.
  static const mint = terracotta;
  static const mintSoft = sand;
  static const mintTeal = sage;
  static const mintTealDark = forest;
  static const pink = dustyRose;
  static const amber = sand;
  static const danger = Color(0xFFA94736);
  static const success = forest;
  static const textMuted = Color(0xFF5F584F);
  static const textSubtle = Color(0xFF70675B);
  static const textDim = Color(0xFF81776A);
  static const surfaceOverlay = Color(0x66000000);
  static const navInactive = Color(0xFF8B8174);

  static const defaultColors = MoniaryColors(
    background: background,
    backgroundSoft: backgroundSoft,
    surface: surface,
    surfaceRaised: surfaceRaised,
    outline: outline,
    primary: mint,
    secondary: mintSoft,
    button: ink,
    icon: ink,
    navBar: background,
    navInactive: navInactive,
    textPrimary: ink,
    textSecondary: textMuted,
    textDim: textDim,
    success: success,
    danger: danger,
    warning: amber,
    accentPink: pink,
    surfaceOverlay: surfaceOverlay,
  );

  static const MoniaryTypography defaultTypography = MoniaryTypography(
    displayLarge: TextStyle(
      fontFamily: 'Instrument Serif',
      fontSize: 40,
      height: 1.05,
      color: ink,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Instrument Serif',
      fontSize: 30,
      height: 1.08,
      color: ink,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Instrument Serif',
      fontSize: 24,
      height: 1.12,
      color: ink,
    ),
    metadata: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 9.5,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      color: textDim,
    ),
    metadataStrong: TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: ink,
    ),
  );

  static ThemeData get lightTheme {
    const colors = defaultColors;
    final baseTextTheme = ThemeData.light(
      useMaterial3: true,
    ).textTheme.apply(fontFamily: 'Manrope');
    final colorScheme = ColorScheme.light(
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
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      splashFactory: NoSplash.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors, defaultTypography],
      textTheme: baseTextTheme.copyWith(
        headlineLarge: TextStyle(
          fontFamily: 'Instrument Serif',
          fontSize: 40,
          fontWeight: FontWeight.w400,
          height: 1.02,
          color: colors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Instrument Serif',
          fontSize: 30,
          fontWeight: FontWeight.w400,
          height: 1.05,
          color: colors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Instrument Serif',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.1,
          color: colors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Instrument Serif',
          fontSize: 22,
          fontWeight: FontWeight.w400,
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
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Instrument Serif',
          color: colors.textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colors.textDim),
        labelStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: colors.primary, width: 1.2),
        ),
      ),
      iconTheme: IconThemeData(color: colors.icon),
      dividerColor: colors.outline,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.backgroundSoft,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
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

  // Kept as an alias while feature tests and legacy call sites migrate.
  static ThemeData get darkTheme => lightTheme;

  static Color _foregroundFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
  }
}
