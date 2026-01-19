import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';
import 'package:zen/widgets/widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  String _filterType = 'all'; // all, tasks, projects, routines, goals

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
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ],
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
          ...filters.map((filter) {
            final isSelected = _filterType == filter.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.$2),
                avatar: Icon(filter.$3, size: 18),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _filterType = filter.$1);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final days = <int>[];
    // Días del mes anterior
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(-i);
    }
    // Días del mes actual
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }
    // Días del mes siguiente
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(100 + i);
    }

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
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
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrentMonth = day > 0 && day <= daysInMonth;
                  DateTime? date;

                  if (isCurrentMonth) {
                    date = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month,
                      day,
                    );
                  }

                  final tasksForDay = date != null
                      ? taskProvider.getTasksByDate(date)
                      : <Task>[];

                  final isSelected = isCurrentMonth &&
                      date?.day == _selectedDate.day &&
                      date?.month == _selectedDate.month &&
                      date?.year == _selectedDate.year;

                  return GestureDetector(
                    onTap: isCurrentMonth
                        ? () {
                            setState(() {
                              _selectedDate = date!;
                            });
                          }
                        : null,
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
                              day > 0 ? day.toString() : '',
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
                          if (tasksForDay.isNotEmpty && isCurrentMonth)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: Wrap(
                                spacing: 2,
                                children: tasksForDay
                                    .take(3)
                                    .map((task) {
                                  final taskColor = Color(
                                    int.parse(
                                      '0xFF${task.color.substring(1)}',
                                    ),
                                  );
                                  return Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : taskColor,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
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
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final tasksForDay = taskProvider.getTasksByDate(_selectedDate.toUtc());
        debugPrint('📅 Tareas para ${_selectedDate.toUtc().toIso8601String()}: ${tasksForDay.length}');

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
                      '${tasksForDay.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ZenTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tasksForDay.isEmpty)
                EmptyState(
                  emoji: '✨',
                  title: 'Sin actividades',
                  description:
                      'No hay tareas, proyectos ni objetivos para este día.',
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
                  itemCount: tasksForDay.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasksForDay[index];
                    final taskColor = Color(
                      int.parse('0xFF${task.color.substring(1)}'),
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: taskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: taskColor.withValues(alpha: 0.3)),
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
                                  color: taskColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (task.description != null)
                                      Text(
                                        task.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _getPriorityLabel(task.priority),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              ...task.labels.map((label) => Chip(
                                label: Text(label),
                                visualDensity: VisualDensity.compact,
                              )),
                              Chip(
                                label: Text(
                                  _getStatusLabel(task.status),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: task.status ==
                                        TaskStatus.completed
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : task.status == TaskStatus.inProgress
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ],
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
}

