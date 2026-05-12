import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';
import 'package:zen/widgets/widgets.dart';

enum _LegendDotType { circle, square, diamond, bar }

// Colores de acento por tipo de ítem
const Color _taskColor = Color(0xFF6366F1);
const Color _projectColor = Color(0xFF10B981);
const Color _routineColor = Color(0xFF8B5CF6);
const Color _goalColor = Color(0xFFEC4899);
const Color _selectedDayColor = Color(0xFF6366F1);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  String _filterType = 'all'; // all, tasks, projects, routines, goals

  Future<void> _toggleTaskComplete(Task task) async {
    final provider = context.read<TaskProvider>();
    try {
      if (task.status == TaskStatus.completed) {
        await provider.updateTaskStatus(task.id, TaskStatus.pending);
      } else {
        await provider.completeTask(task.id);

        if (!mounted) return;
        final updatedTask = provider.tasks.firstWhere((t) => t.id == task.id);
        final completionData = await CompletionDialog.showCelebrationAndAttach(
          context,
          itemTypeLabel: 'Tarea',
          title: updatedTask.title,
          startedAt: updatedTask.createdAt,
          completedAt: updatedTask.completedAt ?? DateTime.now(),
        );

        final url = completionData?['completionAttachmentUrl'];
        final type = completionData?['completionAttachmentType'];
        if (url != null) {
          await provider.updateTask(
            updatedTask.copyWith(
              completionAttachmentUrl: url,
              completionAttachmentType: type,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.status == TaskStatus.completed
                  ? 'Tarea reactivada'
                  : 'Tarea completada',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando tarea: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ZenTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    try {
      await context.read<TaskProvider>().deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando tarea: $e')),
        );
      }
    }
  }

  Future<void> _editTask(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    TaskPriority selectedPriority = task.priority;
    DateTime selectedDate = task.dueDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: const Text('Editar tarea'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: TaskPriority.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(_getPriorityLabel(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedPriority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha límite'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocalState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) {
      titleController.dispose();
      descController.dispose();
      return;
    }

    try {
      if (!mounted) return;
      final updatedTask = task.copyWith(
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        dueDate: selectedDate,
        priority: selectedPriority,
        updatedAt: DateTime.now(),
      );
      await context.read<TaskProvider>().updateTask(updatedTask);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando tarea: $e')),
        );
      }
    } finally {
      titleController.dispose();
      descController.dispose();
    }
  }

  Future<void> _updateGoalProgress(Goal goal) async {
    final controller = TextEditingController(text: goal.currentValue.toString());
    final updated = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualizar progreso'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Progreso (%)',
            hintText: '0 a 100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (updated == null) return;

    if (!mounted) return;
    try {
      final wasCompleted = goal.isCompleted;
      await context.read<GoalProvider>().updateProgress(goal.id, updated);

      if (!mounted) return;
      final refreshedGoal = context
          .read<GoalProvider>()
          .goals
          .firstWhere((g) => g.id == goal.id);
      if (!wasCompleted && refreshedGoal.isCompleted) {
        final completionData = await CompletionDialog.showCelebrationAndAttach(
          context,
          itemTypeLabel: 'Objetivo',
          title: refreshedGoal.title,
          startedAt: refreshedGoal.startDate,
          completedAt: DateTime.now(),
        );

        final url = completionData?['completionAttachmentUrl'];
        final type = completionData?['completionAttachmentType'];
        if (url != null) {
          if (!mounted) return;
          await context.read<GoalProvider>().updateGoal(
                refreshedGoal.copyWith(
                  completionAttachmentUrl: url,
                  completionAttachmentType: type,
                  completedAt: refreshedGoal.completedAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progreso actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando progreso: $e')),
        );
      }
    }
  }

  Future<void> _toggleRoutineComplete(Routine routine) async {
    final provider = context.read<RoutineProvider>();
    try {
      final wasCompleted =
          provider.isRoutineCompletedOnDate(routine.id, _selectedDate);
      if (wasCompleted) {
        await provider.setRoutineCompletedForDate(
          routineId: routine.id,
          date: _selectedDate,
          completed: false,
        );
      } else {
        await provider.setRoutineCompletedForDate(
          routineId: routine.id,
          date: _selectedDate,
          completed: true,
        );

        if (!mounted) return;
        final completionData = await CompletionDialog.showCelebrationAndAttach(
          context,
          itemTypeLabel: 'Rutina',
          title: routine.name,
          startedAt: routine.createdAt,
          completedAt: _selectedDate,
        );

        final url = completionData?['completionAttachmentUrl'];
        final type = completionData?['completionAttachmentType'];
        if (url != null) {
          await provider.setRoutineCompletedForDate(
            routineId: routine.id,
            date: _selectedDate,
            completed: true,
            attachmentUrl: url,
            attachmentType: type,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasCompleted
                  ? 'Rutina marcada como pendiente para este día'
                  : 'Rutina completada para este día',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando rutina: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddCalendarItemDialog(
                  selectedDate: _selectedDate,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthSelector(context),
            const SizedBox(height: 4),
            _buildFilterBar(context),
            const SizedBox(height: 8),
            _buildCalendarGrid(context),
            const SizedBox(height: 24),
            _buildSelectedDayItems(context),
            const SizedBox(height: 16),
            _buildLegend(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      ('Tarea', Icons.check_circle_outline, _taskColor, _LegendDotType.circle),
      ('Proyecto', Icons.folder_outlined, _projectColor, _LegendDotType.square),
      ('Rutina', Icons.repeat, _routineColor, _LegendDotType.diamond),
      ('Objetivo', Icons.flag_outlined, _goalColor, _LegendDotType.bar),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ZenTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZenTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LEYENDA',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ZenTheme.textLight,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((entry) {
                final label = entry.$1;
                final icon = entry.$2;
                final color = entry.$3;
                final dotType = entry.$4;
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, size: 18, color: color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildLegendDot(dotType, color),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: ZenTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(_LegendDotType type, Color color) {
    switch (type) {
      case _LegendDotType.circle:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      case _LegendDotType.square:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case _LegendDotType.diamond:
        return Transform.rotate(
          angle: 0.7854,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      case _LegendDotType.bar:
        return Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
    }
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    int selectedYear = _displayedMonth.year;
    int selectedMonth = _displayedMonth.month;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: ZenTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ZenTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Selector de año
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        style: IconButton.styleFrom(
                          backgroundColor: ZenTheme.dividerColor,
                        ),
                        onPressed: () =>
                            setSheetState(() => selectedYear--),
                      ),
                      GestureDetector(
                        onTap: () async {
                          // Permitir escribir el año directamente
                          final ctrl = TextEditingController(
                              text: selectedYear.toString());
                          final result = await showDialog<int>(
                            context: ctx,
                            builder: (d) => AlertDialog(
                              title: const Text('Ir al año'),
                              content: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: const InputDecoration(
                                    labelText: 'Año'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(d),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final y = int.tryParse(ctrl.text.trim());
                                    Navigator.pop(d, y);
                                  },
                                  child: const Text('Ir'),
                                ),
                              ],
                            ),
                          );
                          ctrl.dispose();
                          if (result != null &&
                              result >= 1900 &&
                              result <= 2100) {
                            setSheetState(() => selectedYear = result);
                          }
                        },
                        child: Text(
                          selectedYear.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _selectedDayColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        style: IconButton.styleFrom(
                          backgroundColor: ZenTheme.dividerColor,
                        ),
                        onPressed: () =>
                            setSheetState(() => selectedYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grid de meses
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      final month = i + 1;
                      final isSel = month == selectedMonth;
                      final monthLabel = DateFormat('MMM', 'es_ES')
                          .format(DateTime(selectedYear, month))
                          .toUpperCase();
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedMonth = month),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _selectedDayColor
                                : ZenTheme.dividerColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: _selectedDayColor
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              monthLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? Colors.white
                                    : ZenTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _selectedDayColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _displayedMonth =
                                  DateTime(selectedYear, selectedMonth);
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Ir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: ZenTheme.dividerColor,
              foregroundColor: ZenTheme.textDark,
            ),
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month - 1,
                );
              });
            },
          ),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'es_ES')
                          .format(_displayedMonth)
                          .toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down,
                        color: _selectedDayColor, size: 20),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _selectedDayColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: ZenTheme.dividerColor,
              foregroundColor: ZenTheme.textDark,
            ),
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Color _filterColor(String filterType) {
    switch (filterType) {
      case 'tasks':
        return _taskColor;
      case 'projects':
        return _projectColor;
      case 'routines':
        return _routineColor;
      case 'goals':
        return _goalColor;
      default:
        return _selectedDayColor;
    }
  }

  Widget _buildFilterBar(BuildContext context) {
    final filters = [
      ('all', 'Todos', Icons.apps_rounded),
      ('tasks', 'Tareas', Icons.check_circle_outline),
      ('projects', 'Proyectos', Icons.folder_outlined),
      ('routines', 'Rutinas', Icons.repeat),
      ('goals', 'Objetivos', Icons.flag_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in filters) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                key: filter.$1,
                label: filter.$2,
                icon: filter.$3,
                color: _filterColor(filter.$1),
                isSelected: _filterType == filter.$1,
                onTap: () => setState(() => _filterType = filter.$1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String key,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : ZenTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : ZenTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : ZenTheme.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : ZenTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekday = firstDay.weekday;
    DateTime startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    final calendarDates = <DateTime>[];
    for (int i = 0; i < 42; i++) {
      calendarDates.add(startDate.add(Duration(days: i)));
    }

    final today = DateTime.now();

    return Consumer4<TaskProvider, ProjectProvider, RoutineProvider, GoalProvider>(
      builder: (context, taskProvider, projectProvider, routineProvider, goalProvider, _) {
        return Column(
          children: [
            // Cabecera de días de la semana
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _DayHeader('L'),
                  _DayHeader('M'),
                  _DayHeader('X'),
                  _DayHeader('J'),
                  _DayHeader('V'),
                  _DayHeader('S', isWeekend: true),
                  _DayHeader('D', isWeekend: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: calendarDates.length,
                itemBuilder: (context, index) {
                  final date = calendarDates[index];
                  final isCurrentMonth = date.year == _displayedMonth.year &&
                      date.month == _displayedMonth.month;
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  final items = _getFilteredItemsForDate(
                    date,
                    taskProvider,
                    projectProvider,
                    routineProvider,
                    goalProvider,
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : isCurrentMonth
                                ? ZenTheme.surfaceColor
                                : ZenTheme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : isToday
                                ? Border.all(
                                    color: _selectedDayColor,
                                    width: 2,
                                  )
                                : isCurrentMonth
                                    ? Border.all(
                                        color: ZenTheme.borderColor,
                                        width: 1,
                                      )
                                    : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _selectedDayColor.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: isToday && !isSelected
                                    ? BoxDecoration(
                                        color: _selectedDayColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                                child: Center(
                                  child: Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? _selectedDayColor
                                              : isCurrentMonth
                                                  ? ZenTheme.textDark
                                                  : ZenTheme.textLight
                                                      .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (items.isNotEmpty && isCurrentMonth)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5, left: 3, right: 3),
                              child: Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                alignment: WrapAlignment.center,
                                children: items
                                    .take(5)
                                    .map((item) => _buildItemDot(item, isSelected))
                                    .toList(),
                              ),
                            )
                          else
                            const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDayItems(BuildContext context) {
    return Consumer4<TaskProvider, ProjectProvider, RoutineProvider, GoalProvider>(
      builder: (context, taskProvider, projectProvider, routineProvider, goalProvider, _) {
        final items = _getFilteredItemsForDate(
          _selectedDate,
          taskProvider,
          projectProvider,
          routineProvider,
          goalProvider,
        );
        final weeklyRoutinesDone =
            routineProvider.getCompletedCountForWeek(_selectedDate);

        debugPrint('📅 Items para ${_selectedDate.toIso8601String()}: ${items.length}');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del día seleccionado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedDayColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actividades del Día',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeUtils.getRelativeDate(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (weeklyRoutinesDone > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'Rutinas esta semana: $weeklyRoutinesDone',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                EmptyState(
                  emoji: '✨',
                  title: 'Sin actividades',
                  description:
                      'No hay tareas, proyectos, rutinas ni objetivos para este día.',
                  buttonText: 'Agregar actividad',
                  onButtonPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddCalendarItemDialog(
                        selectedDate: _selectedDate,
                      ),
                    );
                  },
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemColor = _getItemColor(item);
                    final itemTitle = _getItemTitle(item, projectProvider);
                    final itemDescription = _getItemDescription(item);
                    final isTask = item is Task;
                    final isGoal = item is Goal;
                    final isRoutine = item is Routine;
                    final isRoutineCompletedToday = isRoutine
                        ? routineProvider.isRoutineCompletedOnDate(
                            item.id,
                            _selectedDate,
                          )
                        : false;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        if (isTask) {
                          if (item.status == TaskStatus.completed) {
                            await CompletionDialog.showSummary(
                              context,
                              itemTypeLabel: 'Tarea',
                              title: item.title,
                              startedAt: item.createdAt,
                              completedAt: item.completedAt ?? item.updatedAt,
                              attachmentUrl: item.completionAttachmentUrl,
                              attachmentType: item.completionAttachmentType,
                            );
                            return;
                          }
                          TaskDetailSheet.show(
                            context,
                            item,
                            onEdit: () => _editTask(item),
                            onDelete: () => _deleteTask(item),
                            onToggleComplete: () => _toggleTaskComplete(item),
                          );
                          return;
                        }

                        if (isRoutine && isRoutineCompletedToday) {
                          final completionInfo = routineProvider.getRoutineCompletionForDate(
                            item.id,
                            _selectedDate,
                          );
                          await CompletionDialog.showSummary(
                            context,
                            itemTypeLabel: 'Rutina',
                            title: item.name,
                            startedAt: item.createdAt,
                            completedAt: completionInfo?.completedAt ?? _selectedDate,
                            attachmentUrl: completionInfo?.attachmentUrl,
                            attachmentType: completionInfo?.attachmentType,
                          );
                          return;
                        }

                        if (isGoal && item.isCompleted) {
                          await CompletionDialog.showSummary(
                            context,
                            itemTypeLabel: 'Objetivo',
                            title: item.title,
                            startedAt: item.startDate,
                            completedAt: item.completedAt ?? item.updatedAt,
                            attachmentUrl: item.completionAttachmentUrl,
                            attachmentType: item.completionAttachmentType,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ZenTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: itemColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: itemColor.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Barra de color lateral
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        itemColor,
                                        itemColor.withValues(alpha: 0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: ZenTheme.textDark,
                                              decoration: isRoutineCompletedToday
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                      ),
                                      if (itemDescription != null &&
                                          itemDescription.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(
                                            itemDescription,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: ZenTheme.textLight,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildTypeBadge(item, context),
                                if (isTask)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'complete') {
                                        _toggleTaskComplete(item);
                                      } else if (value == 'edit') {
                                        _editTask(item);
                                      } else if (value == 'delete') {
                                        _deleteTask(item);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'complete',
                                        child: Text(
                                          item.status == TaskStatus.completed
                                              ? 'Marcar pendiente'
                                              : 'Marcar completada',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                if (isGoal)
                                  IconButton(
                                    tooltip: 'Actualizar progreso',
                                    onPressed: () => _updateGoalProgress(item),
                                    icon: Icon(Icons.trending_up,
                                        color: itemColor),
                                  ),
                                if (isRoutine)
                                  IconButton(
                                    tooltip: isRoutineCompletedToday
                                        ? 'Marcar pendiente hoy'
                                        : 'Marcar completada hoy',
                                    onPressed: () =>
                                        _toggleRoutineComplete(item),
                                    icon: Icon(
                                      isRoutineCompletedToday
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: isRoutineCompletedToday
                                          ? ZenTheme.successColor
                                          : ZenTheme.textLight,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _getItemChips(item, context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En Progreso';
      case TaskStatus.completed:
        return 'Completada';
      case TaskStatus.cancelled:
        return 'Cancelada';
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

  String _getProjectStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Planificación';
      case ProjectStatus.active:
        return 'Activo';
      case ProjectStatus.onHold:
        return 'En pausa';
      case ProjectStatus.completed:
        return 'Completado';
    }
  }

  String _getRoutineFrequencyLabel(Routine routine) {
    final days = routine.repeatEveryDays;
    if (days == 1) return 'Diaria';
    if (days == 7) return 'Semanal';
    if (days == 14) return 'Cada 2 semanas';
    if (days == 30) return 'Mensual';
    return 'Cada $days días';
  }

  List<dynamic> _getFilteredItemsForDate(
    DateTime date,
    TaskProvider taskProvider,
    ProjectProvider projectProvider,
    RoutineProvider routineProvider,
    GoalProvider goalProvider,
  ) {
    final items = <dynamic>[];

    if (_filterType == 'all' || _filterType == 'tasks') {
      items.addAll(taskProvider.getTasksByDate(date, includeProjectTasks: true));
    }

    if (_filterType == 'all' || _filterType == 'projects') {
      items.addAll(projectProvider.getProjectsByDate(date));
    }

    if (_filterType == 'all' || _filterType == 'routines') {
      items.addAll(routineProvider.getRoutinesByDate(date));
    }

    if (_filterType == 'all' || _filterType == 'goals') {
      items.addAll(goalProvider.getGoalsByDate(date));
    }

    return items;
  }

  Color _getItemColor(dynamic item) {
    if (item is Task) return _taskColor;
    if (item is Project) return _projectColor;
    if (item is Routine) return _routineColor;
    if (item is Goal) return _goalColor;
    return _taskColor;
  }

  Widget _buildItemDot(dynamic item, bool isSelected) {
    final color = isSelected ? Colors.white : _getItemColor(item);
    if (item is Task) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    } else if (item is Project) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (item is Routine) {
      return Transform.rotate(
        angle: 0.7854,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    } else if (item is Goal) {
      return Container(
        width: 10,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.5),
        ),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _getItemTitle(dynamic item, ProjectProvider projectProvider) {
    if (item is Task) {
      if (item.projectId == null) return item.title;
      final projectName = projectProvider.getProjectById(item.projectId!)?.name;
      if (projectName == null || projectName.isEmpty) return item.title;
      return '${item.title} · $projectName';
    } else if (item is Project) {
      return item.getDateLabel(_selectedDate);
    } else if (item is Routine) {
      return item.name;
    } else if (item is Goal) {
      return item.title;
    }
    return '';
  }

  String? _getItemDescription(dynamic item) {
    if (item is Task) {
      return item.description;
    } else if (item is Project) {
      return item.description;
    } else if (item is Routine) {
      return item.description;
    } else if (item is Goal) {
      return item.description;
    }
    return null;
  }

  Widget _buildTypeBadge(dynamic item, BuildContext context) {
    final IconData icon;
    final String label;
    final Color color;

    if (item is Task) {
      icon = Icons.check_circle_outline;
      label = 'Tarea';
      color = _taskColor;
    } else if (item is Project) {
      icon = Icons.folder_outlined;
      label = 'Proyecto';
      color = _projectColor;
    } else if (item is Routine) {
      icon = Icons.repeat;
      label = 'Rutina';
      color = _routineColor;
    } else if (item is Goal) {
      icon = Icons.flag_outlined;
      label = 'Objetivo';
      color = _goalColor;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getItemChips(dynamic item, BuildContext context) {
    final chips = <Widget>[];

    if (item is Task) {
      if (item.projectId != null) {
        final projectName = context
            .read<ProjectProvider>()
            .getProjectById(item.projectId!)
            ?.name;
        if (projectName != null && projectName.isNotEmpty) {
          chips.add(_buildSmallChip('📁 $projectName', ZenTheme.secondaryLight));
        }
      }

      for (final label in item.labels) {
        chips.add(_buildSmallChip(label, ZenTheme.dividerColor));
      }

      chips.add(_buildSmallChip(
        '📅 ${DateFormat('dd/MM').format(item.dueDate)}',
        ZenTheme.dividerColor,
      ));

      chips.add(_buildSmallChip(
        _getStatusLabel(item.status),
        item.status == TaskStatus.completed
            ? ZenTheme.successColor.withValues(alpha: 0.15)
            : item.status == TaskStatus.inProgress
                ? ZenTheme.warningColor.withValues(alpha: 0.2)
                : ZenTheme.borderColor,
      ));
    } else if (item is Project) {
      chips.add(_buildSmallChip(_getProjectStatusLabel(item.status), ZenTheme.secondaryLight));
    } else if (item is Routine) {
      final routineProvider = context.read<RoutineProvider>();
      final completedToday =
          routineProvider.isRoutineCompletedOnDate(item.id, _selectedDate);

      chips.add(_buildSmallChip(_getRoutineFrequencyLabel(item), ZenTheme.secondaryLight));
      chips.add(_buildSmallChip(
        completedToday ? '✅ Completada hoy' : '⏳ Pendiente hoy',
        completedToday
            ? ZenTheme.successColor.withValues(alpha: 0.15)
            : ZenTheme.borderColor,
      ));
    } else if (item is Goal) {
      chips.add(_buildSmallChip(
        item.isCompleted ? '🏆 Completado' : '🎯 En Progreso',
        item.isCompleted
            ? ZenTheme.successColor.withValues(alpha: 0.15)
            : ZenTheme.warningColor.withValues(alpha: 0.15),
      ));
    }

    return chips;
  }

  Widget _buildSmallChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ZenTheme.textDark,
        ),
      ),
    );
  }
}

// Widget auxiliar para cabecera de día de la semana
class _DayHeader extends StatelessWidget {
  final String label;
  final bool isWeekend;

  const _DayHeader(this.label, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isWeekend
                ? const Color(0xFF6366F1).withValues(alpha: 0.7)
                : ZenTheme.textLight,
          ),
        ),
      ),
    );
  }
}
