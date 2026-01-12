import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegentColors {
  static const Color blue = Color(0xFF1565C0);
  static const Color green = Color(0xFF2E7D32);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color grey = Color(0xFF757575);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  // New violet/purple colors for DM
  static const Color violet = Color(0xFF7C4DFF);
  static const Color darkViolet = Color(0xFF651FFF);
  static const Color lightViolet = Color(0xFFB388FF);
  static const Color dmBackground = Color(0xFF1A1A2E);
  static const Color dmSurface = Color(0xFF16213E);
  static const Color dmCard = Color(0xFF0F3460);
}

class AppTheme {
  // Get text theme with Google Fonts
  static TextTheme _getTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    try {
      return GoogleFonts.poppinsTextTheme(baseTheme);
    } catch (e) {
      // Fallback to default if Google Fonts fails
      return baseTheme;
    }
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: RegentColors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: _getTextTheme(Brightness.light),
    colorScheme: ColorScheme.fromSeed(
      seedColor: RegentColors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RegentColors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RegentColors.blue, width: 2),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    dividerTheme: DividerThemeData(color: Colors.grey[300]),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.black87,
      iconColor: Colors.black54,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RegentColors.green;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RegentColors.green.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    useMaterial3: true,
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: RegentColors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: _getTextTheme(Brightness.dark),
    colorScheme: ColorScheme.fromSeed(
      seedColor: RegentColors.blue,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: RegentColors.blue, width: 2),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: const DividerThemeData(color: Color(0xFF404040)),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RegentColors.green;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return RegentColors.green.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2D2D2D),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2D2D2D),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF2D2D2D),
    ),
    useMaterial3: true,
  );
}
