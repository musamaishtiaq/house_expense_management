import 'dart:ui';

import 'package:flutter/material.dart';

class AppColor {
  static Color main1Color = const Color.fromARGB(255, 240, 172, 71);
  static Color main2Color = const Color.fromARGB(255, 220, 162, 81);
  static Color main3Color = const Color.fromARGB(255, 200, 152, 91);
  static Color blackColor = const Color.fromARGB(255, 0, 0, 0);
  static Color whiteColor = const Color.fromARGB(255, 255, 255, 255);
  static Color gray1Color = const Color.fromARGB(255, 165, 165, 165);
  static Color gray2Color = const Color.fromARGB(255, 205, 205, 205);

  static Color pageContainerFirstColor = const Color(0xFFD3891B);
  static Color pageContainerSecondColor = const Color(0xFF0775D4);
  static Color pageContainerThirdColor = const Color(0xFF1AA12B);
  static Color pageContainerFourthColor = const Color(0xFFC2B624);

  static final MaterialColor primarySwatchColor = MaterialColor(0xFFFFFFFF, <int, Color>{
    50: main1Color,
    100: main1Color,
    200: main1Color,
    300: main1Color,
    400: main1Color,
    500: main1Color,
    600: main1Color,
    700: main1Color,
    800: main1Color,
    900: main1Color,
  });
}
