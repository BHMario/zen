import 'package:flutter/material.dart';

// Colores por defecto para diferentes tipos de elementos
class DefaultColors {
  // Color por defecto general
  static const String defaultColor = '#2A2A2A';

  // Colores por defecto para tareas
  static const String taskDefaultColor = '#6366F1';

  // Colores por defecto para proyectos
  static const String projectDefaultColor = '#3B82F6';

  // Colores por defecto para rutinas
  static const String routineDefaultColor = '#10B981';

  // Colores por defecto para objetivos
  static const String goalDefaultColor = '#EC4899';

  // Paleta completa organizada por familias de color
  static const List<String> availableColors = [
    // Rojos
    '#EF4444', '#DC2626', '#B91C1C', '#F87171', '#FCA5A5',
    // Naranja/Rosa fuerte
    '#F43F5E', '#E11D48', '#FB7185', '#FDA4AF',
    // Naranjas
    '#F97316', '#EA580C', '#C2410C', '#FB923C', '#FDBA74',
    // Amarillos / Ámbar
    '#F59E0B', '#D97706', '#B45309', '#FCD34D', '#FDE68A',
    '#EAB308', '#CA8A04', '#F2C94C', '#FEF08A',
    // Verdes lima / Verde
    '#84CC16', '#65A30D', '#4D7C0F',
    '#22C55E', '#16A34A', '#15803D', '#4ADE80', '#86EFAC',
    // Esmeralda / Teal
    '#10B981', '#059669', '#047857', '#34D399', '#6EE7B7',
    '#14B8A6', '#0D9488', '#0F766E', '#2DD4BF', '#99F6E4',
    // Cyan
    '#06B6D4', '#0891B2', '#0E7490', '#22D3EE', '#67E8F9',
    // Azules
    '#3B82F6', '#2563EB', '#1D4ED8', '#1E40AF',
    '#60A5FA', '#93C5FD', '#BFDBFE',
    '#0EA5E9', '#0284C7', '#0369A1',
    // Índigo
    '#6366F1', '#4F46E5', '#4338CA', '#3730A3',
    '#818CF8', '#A5B4FC',
    // Violeta / Púrpura
    '#8B5CF6', '#7C3AED', '#6D28D9', '#5B21B6',
    '#A78BFA', '#C4B5FD', '#DDD6FE',
    '#A855F7', '#9333EA', '#7E22CE',
    '#D946EF', '#C026D3', '#A21CAF', '#E879F9',
    // Rosas / Fucsia
    '#EC4899', '#DB2777', '#BE185D', '#9D174D',
    '#F472B6', '#F9A8D4', '#FBCFE8',
    // Neutros / Oscuros
    '#111111', '#2A2A2A', '#374151',
    '#4B5563', '#6B7280', '#9CA3AF',
    '#78716C', '#57534E', '#44403C',
  ];

  /// 9 colores básicos representativos (uno por familia)
  static const List<String> basicColors = [
    '#EF4444', // Rojo
    '#F97316', // Naranja
    '#F59E0B', // Amarillo
    '#22C55E', // Verde
    '#14B8A6', // Teal
    '#3B82F6', // Azul
    '#6366F1', // Índigo
    '#8B5CF6', // Violeta
    '#EC4899', // Rosa
    '#374151', // Gris oscuro
  ];

  /// Paleta agrupada por familias (para un picker con secciones)
  static const Map<String, List<String>> colorGroups = {
    'Rojos': ['#EF4444', '#DC2626', '#B91C1C', '#F87171', '#FCA5A5',
               '#F43F5E', '#E11D48', '#FB7185', '#FDA4AF'],
    'Naranjas': ['#F97316', '#EA580C', '#C2410C', '#FB923C', '#FDBA74'],
    'Amarillos': ['#F59E0B', '#D97706', '#EAB308', '#FCD34D', '#F2C94C', '#FEF08A'],
    'Verdes': ['#22C55E', '#16A34A', '#15803D', '#4ADE80', '#86EFAC',
               '#84CC16', '#65A30D', '#10B981', '#059669', '#34D399'],
    'Teal/Cyan': ['#14B8A6', '#0D9488', '#2DD4BF', '#06B6D4', '#0891B2',
                  '#22D3EE', '#67E8F9', '#0EA5E9', '#0284C7'],
    'Azules': ['#3B82F6', '#2563EB', '#1D4ED8', '#1E40AF', '#60A5FA',
               '#93C5FD', '#BFDBFE'],
    'Índigo/Violeta': ['#6366F1', '#4F46E5', '#4338CA', '#818CF8', '#A5B4FC',
                       '#8B5CF6', '#7C3AED', '#6D28D9', '#A78BFA', '#C4B5FD',
                       '#A855F7', '#9333EA', '#D946EF', '#E879F9'],
    'Rosas': ['#EC4899', '#DB2777', '#BE185D', '#F472B6', '#F9A8D4', '#FBCFE8'],
    'Neutros': ['#111111', '#2A2A2A', '#374151', '#4B5563', '#6B7280',
                '#9CA3AF', '#78716C', '#57534E'],
  };
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
    final r = color.r.toInt().toRadixString(16).padLeft(2, '0');
    final g = color.g.toInt().toRadixString(16).padLeft(2, '0');
    final b = color.b.toInt().toRadixString(16).padLeft(2, '0');
    return '#${r}${g}${b}'.toUpperCase();
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
