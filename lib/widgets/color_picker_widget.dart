import 'package:flutter/material.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/color_utils.dart';

/// Widget reutilizable de selector de color con grupos por familia de tono
/// y opción de introducir un color personalizado en hex.
class ColorPickerWidget extends StatefulWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedColor;
  }

  void _pickHex(BuildContext context) async {
    // Usamos una variable local en StatefulBuilder para evitar usar
    // TextEditingController + ValueListenableBuilder, que causaba el crash
    // '_dependents.isEmpty: is not true' al disponer el controlador.
    String hexInput = _selected.replaceAll('#', '');
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final hex6 = hexInput.padRight(6, '0');
            final previewColor = ColorUtils.hexToColor('#$hex6');
            return AlertDialog(
              title: const Text('Color personalizado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: hexInput,
                    maxLength: 6,
                    autofocus: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      prefixText: '#',
                      labelText: 'Código hexadecimal',
                      hintText: 'Ej: EF280F',
                      counterText: '',
                      errorText: errorText,
                    ),
                    onChanged: (val) {
                      setDlg(() {
                        hexInput = val.trim();
                        errorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      color: previewColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ZenTheme.borderColor),
                    ),
                    child: Center(
                      child: Text(
                        '#${hexInput.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: ColorUtils.getContrastColor(previewColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final hexRegex = RegExp(r'^[0-9A-Fa-f]{6}$');
                    if (!hexRegex.hasMatch(hexInput)) {
                      setDlg(() => errorText = 'Introduce 6 caracteres hex válidos');
                      return;
                    }
                    Navigator.pop(ctx, '#${hexInput.toUpperCase()}');
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Diálogo cerrado → seguro llamar setState
    if (result != null && mounted) {
      setState(() => _selected = result);
      widget.onColorSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color seleccionado actualmente
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorUtils.hexToColor(_selected),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ZenTheme.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: ColorUtils.hexToColor(_selected).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'Color seleccionado',
                  style: TextStyle(fontSize: 11, color: ZenTheme.textLight),
                ),
              ],
            ),
            const Spacer(),
            // Botón de color personalizado
            GestureDetector(
              onTap: () => _pickHex(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ZenTheme.dividerColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ZenTheme.borderColor),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: ZenTheme.textLight),
                    SizedBox(width: 4),
                    Text(
                      'Personalizado',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ZenTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Colores básicos
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: DefaultColors.basicColors.map((hex) {
            final color = ColorUtils.hexToColor(hex);
            final isSelected = _selected.toUpperCase() == hex.toUpperCase();
            return GestureDetector(
              onTap: () {
                setState(() => _selected = hex);
                widget.onColorSelected(hex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isSelected ? 38 : 34,
                height: isSelected ? 38 : 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 18, color: ColorUtils.getContrastColor(color))
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

