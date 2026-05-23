import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTheme {
  static const Color mint = Color(0xFF00C853);
  static const Color mintLight = Color(0xFF69F0AE);
  static const Color mintDark = Color(0xFF00A843);
  static const Color peach = Color(0xFFFF8A65);
  static const Color peachLight = Color(0xFFFFAB91);
  static const Color offWhite = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D3E50);

  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, mintLight],
  );

  static const LinearGradient peachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [peach, peachLight],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );

  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 20,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(opacity)
          : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration premiumCardDecoration({
    required bool isDark,
    double borderRadius = 24,
    bool withGradientBorder = false,
  }) {
    return BoxDecoration(
      color: isDark ? darkCard : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: withGradientBorder
          ? null
          : Border.all(
              color: isDark ? darkBorder : Colors.grey.shade200,
              width: 1,
            ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: 0,
          ),
      ],
    );
  }

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: offWhite,
    useMaterial3: true,
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.bold),
      displayMedium:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.bold),
      displaySmall:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.bold),
      headlineLarge:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.bold),
      headlineMedium:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.bold),
      headlineSmall:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.w600),
      titleLarge:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.w600),
      titleMedium:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.w600),
      titleSmall:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.nunito(color: darkText),
      bodyMedium: GoogleFonts.nunito(color: darkText),
      bodySmall: GoogleFonts.nunito(color: darkText.withOpacity(0.7)),
      labelLarge:
          GoogleFonts.nunito(color: darkText, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.nunito(color: darkText),
      labelSmall: GoogleFonts.nunito(color: darkText.withOpacity(0.7)),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: mint,
      primary: mint,
      secondary: peach,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mint,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: mint, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: mint,
      unselectedItemColor: Colors.grey.shade400,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: mint,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    useMaterial3: true,
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
      titleMedium:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
      titleSmall:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.nunito(color: Colors.white),
      bodyMedium: GoogleFonts.nunito(color: Colors.white),
      bodySmall: GoogleFonts.nunito(color: Colors.white70),
      labelLarge:
          GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.nunito(color: Colors.white),
      labelSmall: GoogleFonts.nunito(color: Colors.white70),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: mint,
      primary: mint,
      secondary: peach,
      surface: darkSurface,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      color: darkCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mint,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: mint, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIconColor: Colors.grey,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: mint,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: mint,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    dividerTheme: DividerThemeData(
      color: darkBorder,
      thickness: 1,
    ),
  );
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(
              isDark: isDark,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsets padding;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.mintGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: AppTheme.premiumCardDecoration(
        isDark: isDark,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
