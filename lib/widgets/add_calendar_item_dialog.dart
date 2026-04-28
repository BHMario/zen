import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';

class AddCalendarItemDialog extends StatefulWidget {
  final DateTime selectedDate;

  const AddCalendarItemDialog({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddCalendarItemDialog> createState() => _AddCalendarItemDialogState();
}

class _AddCalendarItemDialogState extends State<AddCalendarItemDialog> {
  String _selectedType = 'task'; // task, project, routine, goal
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  String _selectedColor = '#6366F1';
  List<String> _selectedLabels = [];
  bool _setReminder = false;
  DateTime? _reminderDateTime;

  final List<String> _availableColors = [
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#EF4444', // Red
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dueDate = widget.selectedDate;
    _reminderDateTime = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addItem() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un título')),
      );
      return;
    }

    try {
      switch (_selectedType) {
        case 'task':
          await _addTask();
          break;
        case 'project':
          await _addProject();
          break;
        case 'routine':
          await _addRoutine();
          break;
        case 'goal':
          await _addGoal();
          break;
      }

      if (mounted) {
        final typeLabel = _getTypeLabel(_selectedType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$typeLabel agregado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'task':
        return 'Tarea';
      case 'project':
        return 'Proyecto';
      case 'routine':
        return 'Rutina';
      case 'goal':
        return 'Objetivo';
      default:
        return 'Item';
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  Future<void> _addTask() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await context.read<TaskProvider>().addTask(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate ?? widget.selectedDate,
      priority: _priority,
      color: _selectedColor,
      labels: _selectedLabels,
      userId: userId,
    );

    if (_setReminder && _reminderDateTime != null) {
      await context.read<ReminderProvider>().addReminder(
        itemId: '', // Se asignaría el ID real de la tarea
        type: ReminderType.task,
        dateTime: _reminderDateTime!,
        message: _titleController.text,
      );
    }
  }

  Future<void> _addProject() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await context.read<ProjectProvider>().addProject(
      name: _titleController.text,
      description: _descriptionController.text,
      color: _selectedColor,
      startDate: widget.selectedDate,
      userId: userId,
    );

    if (_setReminder && _reminderDateTime != null) {
      await context.read<ReminderProvider>().addReminder(
        itemId: '',
        type: ReminderType.project,
        dateTime: _reminderDateTime!,
        message: _titleController.text,
      );
    }
  }

  Future<void> _addRoutine() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await context.read<RoutineProvider>().addRoutine(
      name: _titleController.text,
      description: _descriptionController.text,
      frequency: Frequency.daily,
      color: _selectedColor,
      userId: userId,
    );

    if (_setReminder && _reminderDateTime != null) {
      await context.read<ReminderProvider>().addReminder(
        itemId: '',
        type: ReminderType.routine,
        dateTime: _reminderDateTime!,
        message: _titleController.text,
      );
    }
  }

  Future<void> _addGoal() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await context.read<GoalProvider>().addGoal(
      title: _titleController.text,
      description: _descriptionController.text,
      category: GoalCategory.other,
      timeframe: GoalTimeframe.mediumTerm,
      startDate: widget.selectedDate,
      targetDate: _dueDate ?? widget.selectedDate.add(const Duration(days: 30)),
      color: _selectedColor,
      userId: userId,
    );

    if (_setReminder && _reminderDateTime != null) {
      await context.read<ReminderProvider>().addReminder(
        itemId: '',
        type: ReminderType.goal,
        dateTime: _reminderDateTime!,
        message: _titleController.text,
      );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear Nueva Tarea',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              
              // Selector de tipo
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeButton('task', '✓ Tarea'),
                  _buildTypeButton('project', '📁 Proyecto'),
                  _buildTypeButton('routine', '🔄 Rutina'),
                  _buildTypeButton('goal', '🎯 Objetivo'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Título de la tarea',
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Añade detalles de la tarea',
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Fecha
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? widget.selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ZenTheme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_dueDate ?? widget.selectedDate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Prioridad (solo para tareas)
              if (_selectedType == 'task') ...[
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona prioridad',
                    labelText: 'Prioridad',
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_getPriorityLabel(p)),
                      ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Color
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elige un color',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
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
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recordatorio
              Row(
                children: [
                  Checkbox(
                    value: _setReminder,
                    onChanged: (value) {
                      setState(() => _setReminder = value ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Agregar un recordatorio',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              
              if (_setReminder) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _reminderDateTime = DateTime(
                          _dueDate?.year ?? widget.selectedDate.year,
                          _dueDate?.month ?? widget.selectedDate.month,
                          _dueDate?.day ?? widget.selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ZenTheme.dividerColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ZenTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _reminderDateTime != null
                                ? DateFormat('HH:mm').format(_reminderDateTime!)
                                : 'Elige la hora del recordatorio',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    child: const Text('Crear Tarea'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = type);
      },
    );
  }
}
