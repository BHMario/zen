import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';

class AddRoutineDialog extends StatefulWidget {
  const AddRoutineDialog({super.key});

  @override
  State<AddRoutineDialog> createState() => _AddRoutineDialogState();
}

class _AddRoutineDialogState extends State<AddRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _repeatDaysController;
  String _selectedColor = '#8B5CF6';
  TimeOfDay? _scheduleTime;

  final List<String> _availableColors = [
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _repeatDaysController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _repeatDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repeatDays = int.tryParse(_repeatDaysController.text.trim()) ?? 1;
    final scheduleTimeStr = _scheduleTime != null
        ? '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}'
        : null;

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await context.read<RoutineProvider>().addRoutine(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor,
        userId: userId,
        scheduleTime: scheduleTimeStr,
        repeatEveryDays: repeatDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina creada correctamente')),
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
                        color: ZenTheme.secondaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.repeat, color: ZenTheme.secondaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nueva Rutina',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
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

                // Repetir cada X días
                TextFormField(
                  controller: _repeatDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Repetir cada',
                    hintText: 'Número de días',
                    prefixIcon: Icon(Icons.repeat_one_outlined),
                    suffixText: 'días',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Introduce un número mayor a 0';
                    return null;
                  },
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
                        final isSelected = _selectedColor == color;
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
                        icon: const Icon(Icons.add),
                        label: const Text('Crear rutina'),
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
