import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/widgets/widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _timeFilter = 'day';
  DateTime _anchorDate = DateTime.now();

  String _priorityLabel(TaskPriority priority) {
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

  Future<void> _loadTasks() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<TaskProvider>().loadUserTasks(userId);
    }
  }

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

  DateTime _startOfWeek(DateTime d) {
    final normalized = DateTime(d.year, d.month, d.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  List<Task> _filterByDateScope(List<Task> tasks) {
    final day = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
    if (_timeFilter == 'day') {
      return tasks.where((t) {
        final td = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        return td == day;
      }).toList();
    }

    if (_timeFilter == 'week') {
      final start = _startOfWeek(day);
      final end = _endOfWeek(day);
      return tasks.where((t) {
        final td = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        return !td.isBefore(start) && !td.isAfter(end);
      }).toList();
    }

    final start = DateTime(day.year, day.month, 1);
    final end = DateTime(day.year, day.month + 1, 0);
    return tasks.where((t) {
      final td = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return !td.isBefore(start) && !td.isAfter(end);
    }).toList();
  }

  String _scopeLabel() {
    if (_timeFilter == 'day') {
      return DateFormat('dd/MM/yyyy').format(_anchorDate);
    }
    if (_timeFilter == 'week') {
      final start = _startOfWeek(_anchorDate);
      final end = _endOfWeek(_anchorDate);
      return '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}';
    }
    return DateFormat('MMMM yyyy', 'es_ES').format(_anchorDate);
  }

  void _shiftScope(int direction) {
    setState(() {
      if (_timeFilter == 'day') {
        _anchorDate = _anchorDate.add(Duration(days: direction));
      } else if (_timeFilter == 'week') {
        _anchorDate = _anchorDate.add(Duration(days: 7 * direction));
      } else {
        _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + direction, _anchorDate.day);
      }
    });
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _anchorDate = picked);
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
                            child: Text(_priorityLabel(p)),
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

    if (!mounted) return;
    try {
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

  Future<void> _showAddTaskDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AddCalendarItemDialog(
        selectedDate: DateTime.now(),
        initialType: 'task',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
      body: Consumer2<TaskProvider, ProjectProvider>(
        builder: (context, provider, projectProvider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = [...provider.tasks]
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final scopedTasks = _filterByDateScope(tasks);
          final completedCount =
              scopedTasks.where((t) => t.status == TaskStatus.completed).length;
          final pendingCount = scopedTasks.length - completedCount;

          return RefreshIndicator(
            onRefresh: _loadTasks,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt, color: ZenTheme.secondaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$completedCount completadas  ·  $pendingCount pendientes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ZenTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Día'),
                            selected: _timeFilter == 'day',
                            onSelected: (_) => setState(() => _timeFilter = 'day'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Semana'),
                            selected: _timeFilter == 'week',
                            onSelected: (_) => setState(() => _timeFilter = 'week'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Mes'),
                            selected: _timeFilter == 'month',
                            onSelected: (_) => setState(() => _timeFilter = 'month'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _shiftScope(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _pickAnchorDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: ZenTheme.dividerColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _scopeLabel(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _shiftScope(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _anchorDate = DateTime.now()),
                          child: const Text('Hoy'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Listado (${scopedTasks.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                if (scopedTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: EmptyState(
                      emoji: '✅',
                      title: 'Sin tareas',
                      description: 'No hay tareas para el rango temporal seleccionado.',
                      buttonText: 'Crear tarea',
                      onButtonPressed: _showAddTaskDialog,
                    ),
                  )
                else
                  ...scopedTasks.map((task) {
                    final projectName = task.projectId != null
                        ? projectProvider.getProjectById(task.projectId!)?.name
                        : null;
                    return TaskCard(
                      title: task.title,
                      description: task.description,
                      dueDate: task.dueDate,
                      priority: task.priority.name,
                      status: task.status.name,
                      color: task.color,
                      projectName: projectName,
                      attachmentType: task.attachmentType,
                      onTap: () async {
                        if (task.status == TaskStatus.completed) {
                          await CompletionDialog.showSummary(
                            context,
                            itemTypeLabel: 'Tarea',
                            title: task.title,
                            startedAt: task.createdAt,
                            completedAt: task.completedAt ?? task.updatedAt,
                            attachmentUrl: task.completionAttachmentUrl,
                            attachmentType: task.completionAttachmentType,
                          );
                          return;
                        }

                        TaskDetailSheet.show(
                          context,
                          task,
                          onEdit: () => _editTask(task),
                          onDelete: () => _deleteTask(task),
                          onToggleComplete: () => _toggleTaskComplete(task),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
