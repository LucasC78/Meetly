import 'package:flutter/material.dart';

const LinearGradient pinkGradient = LinearGradient(
  colors: [
    Color(0xFFFF00FF),
    Color(0xFF9B30FF),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Couleurs MODE SOMBRE "NEON NIGHT"
const Color darkBackground = Color(0xFF0B0F2B);
const Color darkTextPrimary = Color(0xFFFFFFFF);
const Color darkTextSecondary = Color(0xFFAAB6D1);
const Color darkAccent1 = Color(0xFFF72585);
const Color darkAccent2 = Color(0xFF7209B7);
const Color darkAccent3 = Color(0xFF3A0CA3);
const Color darkBorder = Color(0xFF4361EE);
const Color darkMessageColor = Color(0xFFA78BFA);

// Couleurs MODE CLAIR "LUMINOUS DREAM"
const Color lightBackground = Color(0xFFFDFBFF);
const Color lightTextPrimary = Color(0xFF1E1E2F);
const Color lightTextSecondary = Color(0xFF5E5E6D);
const Color lightAccent1 = Color(0xFFFF5DB1);
const Color lightAccent2 = Color(0xFF8E77FF);
const Color lightAccent3 = Color(0xFF6C63FF);
const Color lightBorder = Color(0xFFD6D6F7);

// Dégradés pour les boutons
const Gradient darkButtonGradient = LinearGradient(
  colors: [darkAccent1, darkAccent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const Gradient lightButtonGradient = LinearGradient(
  colors: [lightAccent1, lightAccent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Font family
const String fontFamily = 'Poppins';

// Glow BoxShadow pour mode sombre
const List<BoxShadow> darkGlowShadow = [
  BoxShadow(
    color: Color.fromRGBO(114, 9, 183, 0.5),
    blurRadius: 12,
    spreadRadius: 1,
  ),
];

// Ombre douce mode clair
const List<BoxShadow> lightSoftShadow = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
];

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkBackground,
  fontFamily: fontFamily,
  primaryColor: darkAccent2,
  colorScheme: ColorScheme.dark(
    primary: darkAccent2,
    secondary: darkAccent1,
    background: darkBackground,
    onBackground: darkTextPrimary,
    surface: Color(0xFF121429), // un peu plus clair pour les cards
    onSurface: darkTextPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: darkTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: darkTextSecondary,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: darkBackground,
    foregroundColor: darkTextPrimary,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF121429),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkAccent1, width: 2),
    ),
    hintStyle: TextStyle(color: darkTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(vertical: 15, horizontal: 50)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevation: MaterialStateProperty.all(0),
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed))
          return darkAccent1.withOpacity(0.8);
        return Colors.transparent; // on utilise dégradé avec container
      }),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
      overlayColor: MaterialStateProperty.all(darkAccent1.withOpacity(0.2)),
      foregroundColor: MaterialStateProperty.all(darkTextPrimary),
    ),
  ),
  cardTheme: CardThemeData(
    color: Color(0xFF121429),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    shadowColor: Colors.transparent,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: darkBackground.withOpacity(0.7),
    selectedItemColor: darkAccent1,
    unselectedItemColor: darkTextSecondary,
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: lightBackground,
  fontFamily: fontFamily,
  primaryColor: lightAccent2,
  colorScheme: ColorScheme.light(
    primary: lightAccent2,
    secondary: lightAccent1,
    background: lightBackground,
    onBackground: lightTextPrimary,
    surface: Colors.white,
    onSurface: lightTextPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: lightTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: lightTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: lightTextSecondary,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: lightTextPrimary,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightAccent1, width: 2),
    ),
    hintStyle: TextStyle(color: lightTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(vertical: 15, horizontal: 50)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      backgroundColor:
          MaterialStateProperty.all(Colors.transparent), // dégradé en container
      elevation: MaterialStateProperty.all(0),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
      overlayColor: MaterialStateProperty.all(lightAccent1.withOpacity(0.2)),
      foregroundColor: MaterialStateProperty.all(lightTextPrimary),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    shadowColor: Colors.black.withOpacity(0.08),
    elevation: 8,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightBackground.withOpacity(0.9),
    selectedItemColor: lightAccent1,
    unselectedItemColor: lightTextSecondary,
  ),
);
