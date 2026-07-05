import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Fira Tech Brand Colors ────────────────────────────────────────────────
  static const Color forest = Color(0xFF276B47);
  static const Color forestLight = Color(0xFF3A855D);
  static const Color forestDark = Color(0xFF17452E);
  static const Color obsidian = Color(0xFF080C0A);
  static const Color obsidianLight = Color(0xFF1A231F);
  static const Color gold = Color(0xFFE8B82E);
  static const Color goldMuted = Color(0xFFB88F2E);
  static const Color foreground = Color(0xFFF2EDE4);
  static const Color mutedForeground = Color(0xFF998E7A);
  static const Color border = Color(0xFF262E2A);
  static const Color destructive = Color(0xFFD43D3D);
  static const Color card = Color(0xFF0E1612);

  // ── Semantic aliases (backward compat) ────────────────────────────────────
  static const Color primary = forest;
  static const Color primaryLight = forestLight;
  static const Color accent = gold;
  static const Color accentLight = Color(0xFF2A2410);
  static const Color warning = gold;
  static const Color warningLight = Color(0xFF2A2410);
  static const Color danger = destructive;
  static const Color dangerLight = Color(0xFF2A1212);
  static const Color surface = obsidian;
  static const Color cardBg = card;
  static const Color textPrimary = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color textMuted = Color(0xFF4A4538);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient gradientHero = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [obsidian, forestDark, obsidian],
  );

  static const LinearGradient gradientCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC142820), Color(0xE60C1410)],
  );

  static const LinearGradient gradientForest = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [forest, Color(0xFF1A5A3A)],
  );

  static const LinearGradient gradientGold = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [gold, Color(0xFFD49A1A)],
  );

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.dark,
        primary: gold,
        secondary: forest,
        surface: obsidian,
      ),
      scaffoldBackgroundColor: obsidian,
      textTheme: textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: obsidian,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: border),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forest, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0C1410),
        selectedItemColor: gold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 0.5,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: obsidianLight,
        contentTextStyle: TextStyle(color: foreground, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: obsidianLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
