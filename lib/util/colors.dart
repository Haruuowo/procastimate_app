// Helper function to convert hex string to Color
import 'package:flutter/material.dart';

Color hexStringToColorValue(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}

// Named theme colors — change these to update the app color scheme

final Color kAccentA = hexStringToColorValue("BCA88D");
final Color kAccentB = hexStringToColorValue("BCA88D");