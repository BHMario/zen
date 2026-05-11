import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/services/services.dart';
import 'package:zen/theme/zen_theme.dart';

class AddCalendarItemDialog extends StatefulWidget {
  final String? initialType;
  final String? initialProjectId;
  final DateTime selectedDate;

  const AddCalendarItemDialog({
    super.key,
    required this.selectedDate,
    this.initialType,
    this.initialProjectId,
  });

  @override
  State<AddCalendarItemDialog> createState() => _AddCalendarItemDialogState();
}

class _AddCalendarItemDialogState extends State<AddCalendarItemDialog> {
  String _selectedType = 'task'; // task, project, routine, goal
  String? _selectedProjectId;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  DateTime? _projectStartDate;
  DateTime? _projectEndDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskType _taskType = TaskType.other;
  GoalCategory _goalCategory = GoalCategory.other;
  GoalTimeframe _goalTimeframe = GoalTimeframe.mediumTerm;
  String _selectedColor = '#2A2A2A';
  List<String> _selectedLabels = [];
  String? _attachmentUrl;
  String? _attachmentType;
  String? _attachmentName;
  bool _isUploadingAttachment = false;
  bool _setReminder = false;
  DateTime? _reminderDateTime;

  final List<String> _availableColors = [
    '#111111', // Black
    '#2A2A2A', // Charcoal
    '#4A4A4A', // Dark Gray
    '#8E8E8E', // Medium Gray
    '#C9C9C9', // Light Gray
    '#2E7D32', // Green
    '#F2C94C', // Yellow
    '#D32F2F', // Red
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'task';
    _selectedProjectId = widget.initialProjectId;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    // Normalizar todas las fechas iniciales para evitar problemas de zona horaria
    _dueDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    _projectStartDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    _projectEndDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    _reminderDateTime = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
  }

  Future<void> _pickAttachment() async {
    setState(() => _isUploadingAttachment = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'webm', 'mov'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final uploadResult = await ApiService.uploadAttachment(file);

      if (uploadResult.containsKey('error')) {
        throw Exception(uploadResult['error']);
      }

      if (!mounted) return;

      setState(() {
        _attachmentUrl = uploadResult['url'] as String?;
        _attachmentType = uploadResult['kind'] as String?;
        _attachmentName = uploadResult['fileName'] as String? ?? file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir el adjunto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
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
          // Validaciones extendidas para proyectos
          final error = _validateProject();
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
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

  String _getTaskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.sport:
        return '⚽ Deporte';
      case TaskType.personal:
        return '🧘 Personal';
      case TaskType.work:
        return '💼 Trabajo';
      case TaskType.other:
        return '📋 Otro';
    }
  }

  String _goalCategoryLabel(GoalCategory category) {
    switch (category) {
      case GoalCategory.health:
        return 'Salud';
      case GoalCategory.career:
        return 'Carrera';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.finance:
        return 'Finanzas';
      case GoalCategory.education:
        return 'Educación';
      case GoalCategory.relationships:
        return 'Relaciones';
      case GoalCategory.other:
        return 'Otro';
    }
  }

  String _goalTimeframeLabel(GoalTimeframe timeframe) {
    switch (timeframe) {
      case GoalTimeframe.shortTerm:
        return 'Corto plazo';
      case GoalTimeframe.mediumTerm:
        return 'Medio plazo';
      case GoalTimeframe.longTerm:
        return 'Largo plazo';
    }
  }

  // Validación robusta para proyectos
  String? _validateProject() {
    final name = _titleController.text.trim();
    
    // 1. Longitud mínima del nombre (Evita nombres vacíos o poco descriptivos)
    if (name.length < 3) {
      return 'El nombre del proyecto debe tener al menos 3 caracteres';
    }

    // 2. Validación de fechas
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = _projectStartDate ?? today;
    final end = _projectEndDate;

    // Fecha de inicio no puede ser anterior a hoy (Evita proyectos retroactivos sin sentido)
    if (start.isBefore(today)) {
      return 'La fecha de inicio no puede ser anterior a hoy';
    }

    // Si hay fecha de fin, debe ser posterior o igual al inicio
    if (end != null) {
      if (end.isBefore(start)) {
        return 'La fecha de fin no puede ser anterior al inicio';
      }

      // 3. Validación de duración razonable (Zen promueve objetivos alcanzables)
      // Evitamos proyectos de más de 5 años para prevenir errores de entrada de datos
      final maxDuration = const Duration(days: 365 * 5);
      if (end.difference(start).abs() > maxDuration) {
        return 'Un proyecto no puede durar más de 5 años';
      }
    } else {
      // Un proyecto en Zen DEBE tener fecha de fin para fomentar la acción (opcional según el diseño, pero aquí lo haremos recomendado)
      return 'Por favor, selecciona una fecha de fin proyectada';
    }

    return null; // Todo correcto
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
      taskType: _taskType,
      color: _selectedColor,
      labels: _selectedLabels,
      projectId: _selectedProjectId,
      attachmentUrl: _attachmentUrl,
      attachmentType: _attachmentType,
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
      startDate: _projectStartDate ?? widget.selectedDate,
      endDate: _projectEndDate,
      attachmentUrl: _attachmentUrl,
      attachmentType: _attachmentType,
      userId: userId,
    );

    // Recargar proyectos desde la API para asegurar sincronización
    await context.read<ProjectProvider>().loadUserProjects(userId);

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
      category: _goalCategory,
      timeframe: _goalTimeframe,
      startDate: widget.selectedDate,
      targetDate: _dueDate ?? widget.selectedDate.add(const Duration(days: 30)),
      targetValue: 100,
      unit: '%',
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
                'Crear ${_getTypeLabel(_selectedType)}',
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
              
              // Fecha (varía según el tipo)
              if (_selectedType != 'project') ...[
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
              ],

              // Fechas de proyecto (solo para proyectos)
              if (_selectedType == 'project') ...[
                // Fecha de inicio
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _projectStartDate ?? (widget.selectedDate.isBefore(today) ? today : widget.selectedDate),
                      firstDate: today, // Evita seleccionar fechas pasadas
                      lastDate: today.add(const Duration(days: 365 * 5)), // Máximo 5 años a futuro
                    );
                    if (picked != null) {
                      setState(() {
                        _projectStartDate = DateTime(picked.year, picked.month, picked.day);
                        // Si la fecha de fin es ahora anterior a la nueva fecha de inicio, la reseteamos o ajustamos
                        if (_projectEndDate != null && _projectEndDate!.isBefore(_projectStartDate!)) {
                          _projectEndDate = _projectStartDate;
                        }
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
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de inicio del proyecto',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_projectStartDate ?? DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Fecha de fin
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final start = _projectStartDate ?? today;

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _projectEndDate ?? start,
                      firstDate: start, // No puede terminar antes de empezar
                      lastDate: start.add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setState(() => _projectEndDate = DateTime(picked.year, picked.month, picked.day));
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de fin del proyecto',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_projectEndDate ?? (_projectStartDate ?? DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
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
                // Tipo de tarea
                DropdownButtonFormField<TaskType>(
                  value: _taskType,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona tipo de tarea',
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.label_outlined),
                  ),
                  items: TaskType.values
                      .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_getTaskTypeLabel(t)),
                      ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _taskType = value);
                  },
                ),
                const SizedBox(height: 16),
                // Proyecto (opcional)
                Consumer<ProjectProvider>(
                  builder: (context, projectProvider, child) {
                    final projects = projectProvider.projects;
                    return DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        hintText: 'Selecciona proyecto (opcional)',
                        labelText: 'Proyecto',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ...projects.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedProjectId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_selectedType == 'task' || _selectedType == 'project') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjunto (opcional)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No es obligatorio. Puedes subir una imagen o video como recuerdo.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: ZenTheme.textLight),
                      ),
                      const SizedBox(height: 10),
                      if (_attachmentUrl == null)
                        OutlinedButton.icon(
                          onPressed: _isUploadingAttachment ? null : _pickAttachment,
                          icon: _isUploadingAttachment
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.attach_file),
                          label: Text(_isUploadingAttachment
                              ? 'Subiendo...'
                              : 'Adjuntar imagen/video'),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              _attachmentType == 'video'
                                  ? Icons.videocam_outlined
                                  : Icons.image_outlined,
                              color: ZenTheme.textDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachmentName ?? 'Archivo adjunto',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _attachmentUrl = null;
                                  _attachmentType = null;
                                  _attachmentName = null;
                                });
                              },
                              tooltip: 'Quitar adjunto',
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Formulario específico de objetivos
              if (_selectedType == 'goal') ...[
                DropdownButtonFormField<GoalCategory>(
                  value: _goalCategory,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona categoría',
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: GoalCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_goalCategoryLabel(c)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _goalCategory = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalTimeframe>(
                  value: _goalTimeframe,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona plazo',
                    labelText: 'Plazo',
                    prefixIcon: Icon(Icons.timeline_outlined),
                  ),
                  items: GoalTimeframe.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_goalTimeframeLabel(t)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _goalTimeframe = value);
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
                    child: Text('Crear ${_getTypeLabel(_selectedType)}'),
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
