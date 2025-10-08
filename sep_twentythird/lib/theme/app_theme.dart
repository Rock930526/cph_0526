import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.cyanAccent,
  scaffoldBackgroundColor: const Color(0xFF0D0D0D),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.cyanAccent,
    brightness: Brightness.dark,
  ),
  textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
  // Flutter 3.3x 之後 cardTheme 型別為 CardThemeData
  cardTheme: CardThemeData(
    color: Colors.white.withValues(alpha: 0.05),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.cyanAccent,
    foregroundColor: Colors.black,
  ),
);
