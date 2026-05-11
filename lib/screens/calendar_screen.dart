import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';
import 'package:zen/widgets/widgets.dart';

enum _LegendDotType { circle, square, diamond, bar }

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
            // Selector de mes
            _buildMonthSelector(context),
            const Divider(),
            // Filtros
            _buildFilterBar(context),
            const SizedBox(height: 12),
            // Calendario
            _buildCalendarGrid(context),
            const SizedBox(height: 24),
            // Items del día seleccionado
            _buildSelectedDayItems(context),
            const SizedBox(height: 16),
            // Leyenda
            _buildLegend(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      (
        'Tarea',
        Icons.check_circle_outline,
        const Color(0xFF6366F1),
        _LegendDotType.circle,
      ),
      (
        'Proyecto',
        Icons.folder_outlined,
        const Color(0xFF10B981),
        _LegendDotType.square,
      ),
      (
        'Rutina',
        Icons.repeat,
        const Color(0xFF8B5CF6),
        _LegendDotType.diamond,
      ),
      (
        'Objetivo',
        Icons.flag_outlined,
        const Color(0xFFEC4899),
        _LegendDotType.bar,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ZenTheme.dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZenTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leyenda',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ZenTheme.textLight,
                    letterSpacing: 0.5,
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _buildLegendDot(dotType, color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(icon, size: 14, color: color),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: ZenTheme.textLight,
                        fontWeight: FontWeight.w500,
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
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
    }
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month - 1,
                );
              });
            },
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy', 'es_ES')
                    .format(_displayedMonth)
                    .toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                DateFormat('dd MMM yyyy', 'es_ES')
                    .format(_selectedDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
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

  Widget _buildFilterBar(BuildContext context) {
    final filters = [
      ('all', 'Todos', Icons.apps),
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
              child: FilterChip(
                label: Text(filter.$2),
                avatar: Icon(filter.$3, size: 18),
                selected: _filterType == filter.$1,
                onSelected: (selected) {
                  if (selected) setState(() => _filterType = filter.$1);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekday = firstDay.weekday;

    // Calcular la primera fecha a mostrar (puede ser del mes anterior)
    DateTime startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    // Crear lista de 42 fechas (6 semanas)
    final calendarDates = <DateTime>[];
    for (int i = 0; i < 42; i++) {
      calendarDates.add(startDate.add(Duration(days: i)));
    }

    return Consumer4<TaskProvider, ProjectProvider, RoutineProvider, GoalProvider>(
      builder: (context, taskProvider, projectProvider, routineProvider, goalProvider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('L'),
                  Text('M'),
                  Text('X'),
                  Text('J'),
                  Text('V'),
                  Text('S'),
                  Text('D'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: calendarDates.length,
                itemBuilder: (context, index) {
                  final date = calendarDates[index];
                  final isCurrentMonth = date.year == _displayedMonth.year &&
                      date.month == _displayedMonth.month;

                  // Obtener items filtrados
                  final items = _getFilteredItemsForDate(
                    date,
                    taskProvider,
                    projectProvider,
                    routineProvider,
                    goalProvider,
                  );

                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ZenTheme.primaryColor
                            : isCurrentMonth
                                ? Colors.transparent
                                : ZenTheme.dividerColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrentMonth && !isSelected
                            ? Border.all(color: ZenTheme.borderColor, width: 1)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 4,
                            right: 4,
                            child: Text(
                              date.day.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : isCurrentMonth
                                            ? null
                                            : ZenTheme.textLight,
                                  ),
                            ),
                          ),
                          if (items.isNotEmpty && isCurrentMonth)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                alignment: WrapAlignment.center,
                                children: items
                                    .take(4)
                                    .map((item) =>
                                      _buildItemDot(item, isSelected))
                                    .toList(),
                              ),
                            ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividades del Día',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        DateTimeUtils.getRelativeDate(_selectedDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rutinas completadas esta semana: $weeklyRoutinesDone',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: ZenTheme.successColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ZenTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ZenTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
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
                      const SizedBox(height: 12),
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
                      borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: itemColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: itemColor,
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
                                            .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: isRoutineCompletedToday
                                            ? TextDecoration.lineThrough
                                            : null,
                                          ),
                                      ),
                                      if (itemDescription != null)
                                        Text(
                                          itemDescription,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
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
                                    icon: const Icon(Icons.trending_up),
                                  ),
                                if (isRoutine)
                                  IconButton(
                                    tooltip: isRoutineCompletedToday
                                        ? 'Marcar pendiente hoy'
                                        : 'Marcar completada hoy',
                                    onPressed: () => _toggleRoutineComplete(item),
                                    icon: Icon(
                                      isRoutineCompletedToday
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: isRoutineCompletedToday
                                          ? ZenTheme.successColor
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
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

  // Métodos para obtener items filtrados
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
    String hex = '#6366f1';
    if (item is Task) {
      hex = item.color;
    } else if (item is Project) {
      hex = item.color;
    } else if (item is Routine) {
      hex = item.color;
    } else if (item is Goal) {
      hex = item.color;
    }
    return ColorUtils.hexToColor(hex);
  }

  Widget _buildItemDot(dynamic item, bool isSelected) {
    final color = isSelected ? Colors.white : _getItemColor(item);
    if (item is Task) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    } else if (item is Project) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    } else if (item is Routine) {
      return Transform.rotate(
        angle: 0.7854,
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      );
    } else if (item is Goal) {
      return Container(
        width: 8,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
  String _getItemTitle(dynamic item, ProjectProvider projectProvider) {
    if (item is Task) {
      if (item.projectId == null) return item.title;
      final projectName = projectProvider.getProjectById(item.projectId!)?.name;
      if (projectName == null || projectName.isEmpty) return item.title;
      return '${item.title} (Proyecto $projectName)';
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
      color = ColorUtils.hexToColor(item.color);
    } else if (item is Project) {
      icon = Icons.folder_outlined;
      label = 'Proyecto';
      color = ColorUtils.hexToColor(item.color);
    } else if (item is Routine) {
      icon = Icons.repeat;
      label = 'Rutina';
      color = ColorUtils.hexToColor(item.color);
    } else if (item is Goal) {
      icon = Icons.flag_outlined;
      label = 'Objetivo';
      color = ColorUtils.hexToColor(item.color);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
          chips.add(Chip(
            label: Text(
              'Proyecto $projectName',
              style: const TextStyle(fontSize: 10),
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: ZenTheme.secondaryLight,
          ));
        }
      }

      // Agregar labels
      for (final label in item.labels) {
        chips.add(Chip(
          label: Text(label),
          visualDensity: VisualDensity.compact,
        ));
      }

      // Agregar estado
      chips.add(Chip(
        label: Text(
          'Entrega ${DateFormat('dd/MM').format(item.dueDate)}',
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: ZenTheme.dividerColor,
      ));

      chips.add(Chip(
        label: Text(
          _getStatusLabel(item.status),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: item.status == TaskStatus.completed
            ? ZenTheme.successColor.withValues(alpha: 0.2)
            : item.status == TaskStatus.inProgress
                ? ZenTheme.warningColor.withValues(alpha: 0.2)
                : ZenTheme.borderColor,
      ));
    } else if (item is Project) {
      chips.add(Chip(
        label: Text(
          _getProjectStatusLabel(item.status),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: ZenTheme.secondaryLight,
      ));
    } else if (item is Routine) {
      final routineProvider = context.read<RoutineProvider>();
      final completedToday =
          routineProvider.isRoutineCompletedOnDate(item.id, _selectedDate);

      chips.add(Chip(
        label: Text(
          _getRoutineFrequencyLabel(item),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: ZenTheme.secondaryLight,
      ));

      chips.add(Chip(
        label: Text(
          completedToday ? 'Completada hoy' : 'Pendiente hoy',
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: completedToday
            ? ZenTheme.successColor.withValues(alpha: 0.2)
            : ZenTheme.borderColor,
      ));
    } else if (item is Goal) {
      chips.add(Chip(
        label: Text(
          item.isCompleted ? 'Completado' : 'En Progreso',
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: item.isCompleted
            ? ZenTheme.successColor.withValues(alpha: 0.2)
            : ZenTheme.warningColor.withValues(alpha: 0.2),
      ));
    }

    return chips;
  }
}

