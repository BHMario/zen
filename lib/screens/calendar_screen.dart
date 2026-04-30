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
          ChangeNotifierProvider(create: (_) => RoutineProvider()),
          ChangeNotifierProvider(create: (_) => GoalProvider()),
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
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
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
                                children: items
                                    .take(3)
                                    .map((item) {
                                  final itemColor = _getItemColor(item);
                                  return Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : itemColor,
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
    return Consumer4<TaskProvider, ProjectProvider, RoutineProvider, GoalProvider>(
      builder: (context, taskProvider, projectProvider, routineProvider, goalProvider, _) {
        final items = _getFilteredItemsForDate(
          _selectedDate,
          taskProvider,
          projectProvider,
          routineProvider,
          goalProvider,
        );

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
                    final itemType = _getItemType(item);
                    final itemTitle = _getItemTitle(item);
                    final itemDescription = _getItemDescription(item);

                    return Container(
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
                                          ?.copyWith(fontWeight: FontWeight.w600),
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
                              Chip(
                                label: Text(
                                  itemType,
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
                            children: _getItemChips(item, context),
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
      items.addAll(taskProvider.getTasksByDate(date));
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
    String colorHex = '#6366F1';
    
    if (item is Task) {
      colorHex = item.color;
    } else if (item is Project) {
      colorHex = item.color;
    } else if (item is Routine) {
      colorHex = item.color;
    } else if (item is Goal) {
      colorHex = item.color;
    }

    return Color(int.parse('0xFF${colorHex.substring(1)}'));
  }

  String _getItemType(dynamic item) {
    if (item is Task) {
      return '✓ Tarea';
    } else if (item is Project) {
      return '📁 Proyecto';
    } else if (item is Routine) {
      return '🔄 Rutina';
    } else if (item is Goal) {
      return '🎯 Objetivo';
    }
    return 'Item';
  }

  String _getItemTitle(dynamic item) {
    if (item is Task) {
      return item.title;
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

  List<Widget> _getItemChips(dynamic item, BuildContext context) {
    final chips = <Widget>[];

    if (item is Task) {
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
          _getStatusLabel(item.status),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: item.status == TaskStatus.completed
            ? Colors.green.withValues(alpha: 0.2)
            : item.status == TaskStatus.inProgress
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
      ));
    } else if (item is Project) {
      chips.add(Chip(
        label: Text(
          item.status.toString().split('.').last.toUpperCase(),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.blue.withValues(alpha: 0.2),
      ));
    } else if (item is Routine) {
      chips.add(Chip(
        label: Text(
          item.frequency.toString().split('.').last.toUpperCase(),
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.purple.withValues(alpha: 0.2),
      ));
    } else if (item is Goal) {
      chips.add(Chip(
        label: Text(
          item.isCompleted ? 'Completado' : 'En Progreso',
          style: const TextStyle(fontSize: 10),
        ),
        visualDensity: VisualDensity.compact,
        backgroundColor: item.isCompleted
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
      ));
    }

    return chips;
  }
}

