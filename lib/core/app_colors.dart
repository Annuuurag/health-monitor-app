import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xFF00ADB5);
  static const amber = Color(0xFFF59E0B);
  static const cream = Color(0xFFF9F0E3);
  static const softLilac = Color(0xFFD8D2FF);
  static const softLilacDark = Color(0xFFC7C2F5);
  static const darkBackground = Color(0xFF222831);
  static const darkCard = Color(0xFF393E46);
  static const lightBackground = Color(0xFFF5F2EC);
  static const lightCard = Color(0xFFFFFFFF);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const mutedText = Color(0xFF5B5B5B);

  static Color pageBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  static Color primaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : darkBackground;
  }

  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD7D7D7)
        : mutedText;
  }

  static Color navigationBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cream
        : Colors.white;
  }
}
