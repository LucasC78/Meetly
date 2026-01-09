import 'package:flutter/material.dart';

// =======================
// GRADIENTS / CONSTANTS
// =======================

// Dégradé principal (garde le nom si tu l'utilises déjà)
const LinearGradient pinkGradient = LinearGradient(
  colors: [
    Color(0xFFFFC15E), // orange doux
    Color(0xFFFF8A5C), // orange plus soutenu
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// =======================
// MODE SOMBRE - "SUNSET NIGHT"
// =======================

const Color darkBackground = Color(0xFF0B0F2B);
const Color darkSurface = Color(0xFF121429);

const Color darkTextPrimary = Color(0xFFFFFFFF);
const Color darkTextSecondary = Color(0xFFAAB6D1);

// Accents chauds
const Color darkAccent1 = Color(0xFFFFB648); // bouton principal / élément clé
const Color darkAccent2 = Color(0xFFFF8A5C); // secondaire
const Color darkAccent3 = Color(0xFFFFE27A); // survol / badges

const Color darkBorder = Color(0xFFFFC26F);
const Color darkMessageColor = Color(0xFFFFD89B);

// Dégradé boutons
const Gradient darkButtonGradient = LinearGradient(
  colors: [darkAccent1, darkAccent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Glow BoxShadow pour mode sombre
const List<BoxShadow> darkGlowShadow = [
  BoxShadow(
    color: Color.fromRGBO(255, 138, 92, 0.5),
    blurRadius: 12,
    spreadRadius: 1,
  ),
];

// =======================
// MODE CLAIR - "PEACHY DAWN"
// =======================

const Color lightBackground = Color(0xFFFFF7EC); // crème chaud
const Color lightSurface = Color(0xFFFFFFFF);

const Color lightTextPrimary = Color(0xFF1E1E2F);
const Color lightTextSecondary = Color(0xFF5E5E6D);

const Color lightAccent1 = Color(0xFFFFA45C);
const Color lightAccent2 = Color(0xFFFFC15E);
const Color lightAccent3 = Color(0xFFFFE5A5);

const Color lightBorder = Color(0xFFFDD5A5);

// Dégradé boutons
const Gradient lightButtonGradient = LinearGradient(
  colors: [lightAccent1, lightAccent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Ombre douce mode clair
const List<BoxShadow> lightSoftShadow = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
];

// Font family
const String fontFamily = 'Poppins';

// =======================
// THEMES
// =======================

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkBackground,
  fontFamily: fontFamily,
  primaryColor: darkAccent2,
  cardColor: darkSurface,
  colorScheme: const ColorScheme.dark(
    primary: darkAccent2,
    secondary: darkAccent1,
    surface: darkSurface,
    background: darkBackground,
    onSurface: darkTextPrimary,
    onBackground: darkTextPrimary,
  ),
  textTheme: const TextTheme(
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
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
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
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: darkTextPrimary,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: darkAccent1, width: 2),
    ),
    hintStyle: const TextStyle(color: darkTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed)) {
          return darkAccent1.withOpacity(0.85);
        }
        return Colors.transparent; // gradient via container
      }),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      overlayColor: WidgetStateProperty.all(darkAccent1.withOpacity(0.2)),
      foregroundColor: WidgetStateProperty.all(darkTextPrimary),
    ),
  ),
  cardTheme: CardThemeData(
    color: darkSurface,
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
  cardColor: lightSurface,
  colorScheme: const ColorScheme.light(
    primary: lightAccent2,
    secondary: lightAccent1,
    surface: lightSurface,
    background: lightBackground,
    onSurface: lightTextPrimary,
    onBackground: lightTextPrimary,
  ),
  textTheme: const TextTheme(
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
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
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
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: lightTextPrimary,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightAccent1, width: 2),
    ),
    hintStyle: const TextStyle(color: lightTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      backgroundColor:
          WidgetStateProperty.all(Colors.transparent), // gradient via container
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      overlayColor: WidgetStateProperty.all(lightAccent1.withOpacity(0.15)),
      foregroundColor: WidgetStateProperty.all(lightTextPrimary),
    ),
  ),
  cardTheme: CardThemeData(
    color: lightSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    shadowColor: Colors.black.withOpacity(0.08),
    elevation: 8,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightBackground.withOpacity(0.95),
    selectedItemColor: lightAccent1,
    unselectedItemColor: lightTextSecondary,
  ),
);
