import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: false,
      primarySwatch: AppColor.primarySwatchColor,
      primaryColor: AppColor.primary,
      fontFamily: 'Quicksand',
      scaffoldBackgroundColor: AppColor.pageBackground,
      canvasColor: AppColor.pageBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColor.primary,
        secondary: AppColor.primaryLight,
        surface: AppColor.card,
        error: AppColor.overBudget,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColor.textPrimary,
        onError: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
            bodyLarge: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: AppColor.textPrimary,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: AppColor.textSecondary,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColor.pageBackground,
        foregroundColor: AppColor.textPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'OpenSans',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColor.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColor.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.textSecondary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColor.card,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.textSecondary,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColor.card,
        headerBackgroundColor: AppColor.primary,
        headerForegroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.chipFill,
        labelStyle: const TextStyle(color: AppColor.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
      dividerColor: AppColor.divider,
    );
  }
}
