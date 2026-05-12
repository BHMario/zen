import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/color_utils.dart';

class EditRoutineDialog extends StatefulWidget {
  final Routine routine;

  const EditRoutineDialog({super.key, required this.routine});

  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _customDaysController;
  late TextEditingController _stepsController;
  late String _selectedColor;
  TimeOfDay? _scheduleTime;
  late bool _isActive;
  int _repeatDays = 1;
  bool _isCustomRepeat = false;

  static const _repeatPresets = [
    (label: 'Diario', days: 1, icon: Icons.today_outlined),
    (label: 'Cada 2 días', days: 2, icon: Icons.event_repeat_outlined),
    (label: 'Cada 3 días', days: 3, icon: Icons.event_repeat_outlined),
    (label: 'Semanal', days: 7, icon: Icons.calendar_view_week_outlined),
    (label: 'Quincenal', days: 14, icon: Icons.calendar_view_month_outlined),
    (label: 'Mensual', days: 30, icon: Icons.calendar_month_outlined),
  ];

  // Paleta de colores disponibles desde DefaultColors
  List<String> get _availableColors => DefaultColors.availableColors;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController =
        TextEditingController(text: widget.routine.description ?? '');
    _stepsController = TextEditingController(
      text: widget.routine.steps.join('\n'),
    );
    _selectedColor = widget.routine.color;
    _isActive = widget.routine.isActive;

    // Inicializar selector de repetición
    final savedDays = widget.routine.repeatEveryDays;
    final isPreset = _repeatPresets.any((p) => p.days == savedDays);
    if (isPreset) {
      _repeatDays = savedDays;
      _isCustomRepeat = false;
    } else {
      _isCustomRepeat = true;
      _repeatDays = savedDays;
    }
    _customDaysController = TextEditingController(
      text: _isCustomRepeat ? savedDays.toString() : '1',
    );

    if (widget.routine.scheduleTime != null) {
      final parts = widget.routine.scheduleTime!.split(':');
      if (parts.length == 2) {
        _scheduleTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDaysController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    int repeatDays = _repeatDays;
    if (_isCustomRepeat) {
      repeatDays = int.tryParse(_customDaysController.text.trim()) ?? 1;
      if (repeatDays < 1) repeatDays = 1;
    }
    final steps = _stepsController.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
    final scheduleTimeStr = _scheduleTime != null
        ? '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final updated = widget.routine.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _selectedColor,
      isActive: _isActive,
      scheduleTime: scheduleTimeStr,
      repeatEveryDays: repeatDays,
      steps: steps,
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<RoutineProvider>().updateRoutine(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina actualizada correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ZenTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_outlined, color: ZenTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editar Rutina',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la rutina',
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Añade una descripción (opcional)',
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Repetición
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.repeat_outlined, size: 18, color: ZenTheme.textLight),
                        const SizedBox(width: 8),
                        Text(
                          'Repetición',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._repeatPresets.map((preset) {
                          final isSelected = !_isCustomRepeat && _repeatDays == preset.days;
                          return ChoiceChip(
                            avatar: Icon(
                              preset.icon,
                              size: 16,
                              color: isSelected ? Colors.white : ZenTheme.textLight,
                            ),
                            label: Text(preset.label),
                            selected: isSelected,
                            selectedColor: ZenTheme.secondaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : ZenTheme.textDark,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            onSelected: (_) => setState(() {
                              _repeatDays = preset.days;
                              _isCustomRepeat = false;
                            }),
                          );
                        }),
                        ChoiceChip(
                          avatar: Icon(
                            Icons.tune_outlined,
                            size: 16,
                            color: _isCustomRepeat ? Colors.white : ZenTheme.textLight,
                          ),
                          label: const Text('Personalizado'),
                          selected: _isCustomRepeat,
                          selectedColor: ZenTheme.secondaryColor,
                          labelStyle: TextStyle(
                            color: _isCustomRepeat ? Colors.white : ZenTheme.textDark,
                            fontWeight: _isCustomRepeat ? FontWeight.w600 : FontWeight.normal,
                          ),
                          onSelected: (_) => setState(() => _isCustomRepeat = true),
                        ),
                      ],
                    ),
                    if (_isCustomRepeat) ...[  
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Número de días',
                          prefixIcon: Icon(Icons.repeat_one_outlined),
                          suffixText: 'días',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (!_isCustomRepeat) return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Mínimo 1 día';
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Pasos de la rutina
                TextFormField(
                  controller: _stepsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pasos (opcional)',
                    hintText: 'Un paso por línea',
                    prefixIcon: Icon(Icons.checklist_rtl_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Hora opcional
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _scheduleTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _scheduleTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: ZenTheme.dividerColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ZenTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined, color: ZenTheme.textLight),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scheduleTime != null
                                ? 'Hora: ${_scheduleTime!.format(context)}'
                                : 'Añadir hora (opcional)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _scheduleTime != null
                                      ? ZenTheme.textDark
                                      : ZenTheme.textLight,
                                ),
                          ),
                        ),
                        if (_scheduleTime != null)
                          GestureDetector(
                            onTap: () => setState(() => _scheduleTime = null),
                            child: const Icon(Icons.close, size: 18, color: ZenTheme.textLight),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Activa / Inactiva
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ZenTheme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.toggle_on_outlined, color: ZenTheme.textLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rutina activa',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Color
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = _selectedColor.toUpperCase() ==
                            color.toUpperCase();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${color.substring(1)}')),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: ZenTheme.textDark, width: 2.5)
                                  : Border.all(color: Colors.transparent, width: 2.5),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
