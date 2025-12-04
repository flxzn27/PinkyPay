import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Sesuai Request)
  static const Color primaryPink = Color(0xFFFF00B7);  
  static const Color lightPeach = Color(0xFFF2D1C9);   
  static const Color darkPurple = Color(0xFF462749);  
  static const Color lightGreen = Color(0xFFD6F8D6);  
  static const Color lightBlue = Color(0xFF89A1EF);  
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color greyText = Color(0xFF757575);
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color greyBorder = Color(0xFFEEEEEE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, Color(0xFFFF4DC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [darkPurple, Color(0xFF6A3A6F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}