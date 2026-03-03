import 'package:flutter/material.dart';

class SetuplyTheme {
  static const Color darkBg = Color(0xFF000000); // Zifiri Siyah
  static const Color deepPurple = Color(0xFF12001A); // Koyu Paneller
  static const Color accentPurple = Color(0xFFC147E9); // Parlak Neon Mor
  static const Color glassColor = Color(0x1AFFFFFF); // Cam efekti

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBg,
    primaryColor: accentPurple,
    canvasColor: darkBg, // Tüm alt yüzeyler siyah
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          color: accentPurple, fontSize: 22, fontWeight: FontWeight.w900),
    ),
  );
}
