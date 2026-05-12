import 'package:flutter/material.dart';

// Colores por defecto para diferentes tipos de elementos
class DefaultColors {
  // Color por defecto general
  static const String defaultColor = '#2A2A2A';

  // Colores por defecto para tareas
  static const String taskDefaultColor = '#2A2A2A';

  // Colores por defecto para proyectos
  static const String projectDefaultColor = '#3B82F6';

  // Colores por defecto para rutinas
  static const String routineDefaultColor = '#10B981';

  // Colores por defecto para objetivos
  static const String goalDefaultColor = '#6366F1';

  // Paleta de colores disponibles
  static const List<String> availableColors = [
    '#111111', // Black
    '#2A2A2A', // Charcoal
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#6366F1', // Indigo
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#14B8A6', // Teal
    '#F2C94C', // Yellow
  ];
}

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
