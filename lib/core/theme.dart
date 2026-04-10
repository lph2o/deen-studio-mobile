import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ═══════════════════════════════════════════
  // Deen Lumina Core Colors
  // ═══════════════════════════════════════════
  static const primaryColor = Color(0xFFA2D1BB);
  static const primaryContainerColor = Color(0xFF0F3D2E);
  static const onPrimaryColor = Color(0xFF073829);
  static const accentColor = Color(0xFF7C9A6E);  // softer green accent

  static const secondaryColor = Color(0xFFE9C349);
  static const secondaryContainerColor = Color(0xFFAF8D11);

  static const backgroundDark = Color(0xFF121414);
  static const surfaceLowest = Color(0xFF0D0F0F);
  static const surfaceLow = Color(0xFF1A1C1C);
  static const surfaceContainer = Color(0xFF1E2020);
  static const surfaceHigh = Color(0xFF282A2A);
  static const surfaceHighest = Color(0xFF333535);

  static const onSurface = Color(0xFFE2E2E2);
  static const outlineVariant = Color(0xFF414944);

  // ═══════════════════════════════════════════
  // Track Colors
  // ═══════════════════════════════════════════
  static const trackArabic = Color(0xFFE9C349);
  static const trackPhonetic = Color(0xFFD4AF37);
  static const trackTranslation = Color(0xFF38BDF8);
  static const trackText = Color(0xFF7C3AED);
  static const trackAudio = Color(0xFF10B981);
  static const trackVideo = Color(0xFFF59E0B);
  static const trackImage = Color(0xFFEC4899);
  static const trackSticker = Color(0xFFFF6B6B);

  static const Color playheadColor = Color(0xFF7C9A6E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        primaryContainer: primaryContainerColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainerColor,
        surface: backgroundDark,
        surfaceContainerLowest: surfaceLowest,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: surfaceHighest,
        onSurface: onSurface,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: backgroundDark,

      // ═══════════════════════════════════════════
      // Typography
      // ═══════════════════════════════════════════
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          fontSize: 36,
          color: onSurface,
          letterSpacing: -1.0,
        ),
        displaySmall: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: onSurface.withValues(alpha: 0.8),
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: onSurface.withValues(alpha: 0.6),
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onPrimaryColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),

      // ═══════════════════════════════════════════
      // Component Themes
      // ═══════════════════════════════════════════

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        dragHandleColor: onSurface.withValues(alpha: 0.2),
        dragHandleSize: const Size(36, 4),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: surfaceHighest,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPrimaryColor,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.2);
          }
          return surfaceHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return outlineVariant.withValues(alpha: 0.3);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide.none,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.3)),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: onSurface.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHighest,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 500),
      ),

      dividerTheme: DividerThemeData(
        color: outlineVariant.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface.withValues(alpha: 0.7)),
      ),
    );
  }
}


