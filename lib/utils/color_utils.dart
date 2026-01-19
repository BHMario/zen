import 'package:flutter/material.dart';

class ColorUtils {
  // Convertir hex a Color
  static Color hexToColor(String hexString) {
    try {
      hexString = hexString.replaceAll('#', '');
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Convertir Color a hex
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  // Obtener color aleatorio
  static Color getRandomColor() {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFFFB7185), // Rose
      const Color(0xFF14B8A6), // Teal
    ];
    return colors[(colors.length * DateTime.now().millisecond) ~/ 100000];
  }

  // Verificar si un color es "oscuro" para ajustar el texto
  static bool isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }

  // Obtener color de contraste apropiado
  static Color getContrastColor(Color color) {
    return isDarkColor(color) ? Colors.white : Colors.black;
  }
}
