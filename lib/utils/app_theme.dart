import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1565C0); // Biru elegan
  static const Color accent = Color(0xFFFFC107); // Kuning emas
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color info = Color(0xFF0288D1);
  static const Color warning = Color(0xFFFFA000);
  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF222B45);
  static const Color subtitle = Color(0xFF6B778D);

  static const TextStyle subtitleTextStyle = TextStyle(
    color: subtitle,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static ThemeData get themeData => ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primary,
      secondary: accent,
      background: background,
      error: danger,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Montserrat',
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: subtitle),
      prefixIconColor: primary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: subtitle,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static Widget statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = warning;
        text = 'Pending';
        break;
      case 'approved':
        color = info;
        text = 'Disetujui';
        break;
      case 'in_use':
        color = primary;
        text = 'Sedang Digunakan';
        break;
      case 'completed':
        color = success;
        text = 'Selesai';
        break;
      case 'rejected':
        color = danger;
        text = 'Ditolak';
        break;
      case 'returned':
        color = Colors.blueGrey;
        text = 'Dikembalikan';
        break;
      default:
        color = subtitle;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
} 