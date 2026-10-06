import 'package:flutter/material.dart';

class AppColor {
  static const Color primary = Color(0xFF7C6CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF6D5AE6);
  static const Color pageBackground = Color(0xFFF6F5FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color headerStart = Color(0xFF8B7CF6);
  static const Color headerEnd = Color(0xFFB197FC);

  static const Color income = Color(0xFF2BB673);
  static const Color expense = Color(0xFFE85D5D);
  static const Color overBudget = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF6B6B);

  static const Color textPrimary = Color(0xFF1C1B22);
  static const Color textSecondary = Color(0xFF8E8AA3);
  static const Color divider = Color(0xFFE8E6F2);
  static const Color chipFill = Color(0xFFF3F1FA);

  static const List<Color> chartColors = [
    Color(0xFF7C6CF6),
    Color(0xFFFF8A4C),
    Color(0xFF4CD964),
    Color(0xFF4DA3FF),
    Color(0xFFFF6B9D),
    Color(0xFFFFC247),
  ];

  // Existing names kept so current screens pick up the new palette.
  static Color main1Color = primary;
  static Color main2Color = primaryLight;
  static Color main3Color = primaryDark;
  static Color blackColor = textPrimary;
  static Color whiteColor = card;
  static Color gray1Color = textSecondary;
  static Color gray2Color = chipFill;

  static Color pageContainerFirstColor = const Color(0xFFFF8A4C);
  static Color pageContainerSecondColor = const Color(0xFF4DA3FF);
  static Color pageContainerThirdColor = const Color(0xFF4CD964);
  static Color pageContainerFourthColor = const Color(0xFFFFC247);

  static const MaterialColor primarySwatchColor = MaterialColor(
    0xFF7C6CF6,
    <int, Color>{
      50: Color(0xFFF3F0FF),
      100: Color(0xFFE4DCFF),
      200: Color(0xFFC9BBFD),
      300: Color(0xFFB197FC),
      400: Color(0xFFA78BFA),
      500: Color(0xFF7C6CF6),
      600: Color(0xFF6D5AE6),
      700: Color(0xFF5B48D4),
      800: Color(0xFF4C3BB8),
      900: Color(0xFF3A2C91),
    },
  );
}
