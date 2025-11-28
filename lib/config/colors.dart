import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryPink = Color(0xFFFF00B7);
  static const Color lightPeach = Color(0xFFF2D1C9);
  static const Color darkPurple = Color(0xFF462749);
  static const Color lightGreen = Color(0xFFD6F8D6);
  static const Color lightBlue = Color(0xFF89A1EF);

  // Additional Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color greyText = Color(0xFF757575);
  static const Color greyLight = Color(0xFFF5F5F5);
  
  // Gradient
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [primaryPink, Color(0xFFFF4DB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [lightGreen, Color(0xFFE8F9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}