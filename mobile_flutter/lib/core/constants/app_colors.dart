import 'package:flutter/material.dart';

class AppColors {
  static const primaryBlue = Color(0xFF8EC5FC);

  static const lightBlue = Color(0xFFFFFFFF);
  static const cardBlue = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF2D4B68);
  static const textGrey = Color(0xFF7D8FA3);
  static const borderColor = Color(0xFFE4EEF8);

  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xFF111111);
  static const darkTitle = Color(0xFFEAF6FF);
  static const darkSubText = Color(0xFF94A3B8);
  static const darkBorder = Color(0xFF2A2A2A);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bg(BuildContext context) {
    return isDark(context) ? darkBg : lightBlue;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? darkCard : Colors.white;
  }

  static Color title(BuildContext context) {
    return isDark(context) ? darkTitle : textDark;
  }

  static Color subText(BuildContext context) {
    return isDark(context) ? darkSubText : textGrey;
  }

  static Color sub(BuildContext context) {
    return subText(context);
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : borderColor;
  }

  static Color softCard(BuildContext context) {
    return isDark(context) ? const Color(0xFF1A1A1A) : Colors.white;
  }

  static Color shadow(BuildContext context) {
    return isDark(context)
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.08);
  }
}