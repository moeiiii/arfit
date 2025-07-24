import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF000000),
      primaryColor: const Color(0xFFF06500),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFFF06500),
        secondary: const Color(0xFFA1A1AA),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.exo(
          fontSize: 18,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.exo(
          fontSize: 16,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.exo(
          fontSize: 14,
          color: Color(0xFFA1A1AA),
        ),
        titleLarge: GoogleFonts.exo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1216),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF0E1216),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF06500),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.exo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
