import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/widgets/widgets.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  String _timeFilter = 'day';
  DateTime _anchorDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRoutines);
  }

  Future<void> _loadRoutines() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await context.read<RoutineProvider>().loadUserRoutines(userId);
    }
  }

  void _showAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddRoutineDialog(),
    );
    if (result == true) _loadRoutines();
  }

  void _showEditDialog(Routine routine) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditRoutineDialog(routine: routine),
    );
    if (result == true) _loadRoutines();
  }

  Future<void> _confirmDelete(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar rutina'),
        content: Text(
            '¿Estás seguro de que quieres eliminar "${routine.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ZenTheme.errorColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<RoutineProvider>().deleteRoutine(routine.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rutina eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleRoutineToday(Routine routine) async {
    final provider = context.read<RoutineProvider>();
    try {
      final today = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
      final wasCompleted = provider.isRoutineCompletedOnDate(routine.id, today);
      if (wasCompleted) {
        await provider.setRoutineCompletedForDate(
          routineId: routine.id,
          date: today,
          completed: false,
        );
      } else {
        await provider.setRoutineCompletedForDate(
          routineId: routine.id,
          date: today,
          completed: true,
        );

        final completionData = await CompletionDialog.showCelebrationAndAttach(
          context,
          itemTypeLabel: 'Rutina',
          title: routine.name,
          startedAt: routine.createdAt,
          completedAt: today,
        );

        final url = completionData?['completionAttachmentUrl'];
        final type = completionData?['completionAttachmentType'];
        if (url != null) {
          await provider.setRoutineCompletedForDate(
            routineId: routine.id,
            date: today,
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
                  ? 'Rutina marcada pendiente para hoy'
                  : 'Rutina completada para hoy',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar rutina: $e')),
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

  List<Routine> _filterByDateScope(RoutineProvider provider) {
    final date = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
    if (_timeFilter == 'day') {
      return provider.getRoutinesByDate(date);
    }

    final collected = <String, Routine>{};
    if (_timeFilter == 'week') {
      final start = _startOfWeek(date);
      final end = _endOfWeek(date);
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        for (final r in provider.getRoutinesByDate(cursor)) {
          collected[r.id] = r;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      return collected.values.toList();
    }

    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      for (final r in provider.getRoutinesByDate(cursor)) {
        collected[r.id] = r;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return collected.values.toList();
  }

  String _scopeLabel() {
    if (_timeFilter == 'day') {
      return '${_anchorDate.day.toString().padLeft(2, '0')}/${_anchorDate.month.toString().padLeft(2, '0')}/${_anchorDate.year}';
    }
    if (_timeFilter == 'week') {
      final start = _startOfWeek(_anchorDate);
      final end = _endOfWeek(_anchorDate);
      return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
    }
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${months[_anchorDate.month - 1]} ${_anchorDate.year}';
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

  String _repeatLabel(int days) {
    if (days == 1) return 'Todos los días';
    if (days == 7) return 'Cada semana';
    if (days == 14) return 'Cada 2 semanas';
    if (days == 30) return 'Cada mes';
    return 'Cada $days días';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recargar',
            onPressed: _loadRoutines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final routines = _filterByDateScope(provider);

          final active = routines.where((r) => r.isActive).toList();
          final inactive = routines.where((r) => !r.isActive).toList();
          final weeklyDone = provider.getCompletedCountForWeek(DateTime.now());

          return RefreshIndicator(
            onRefresh: _loadRoutines,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ZenTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, color: ZenTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Rutinas completadas esta semana: $weeklyDone',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: ZenTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                                  horizontal: 12,
                                  vertical: 10,
                                ),
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
                if (routines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      emoji: '🔄',
                      title: 'Sin rutinas',
                      description: 'Crea tu primera rutina para mantener hábitos consistentes.',
                      buttonText: 'Crear rutina',
                      onButtonPressed: _showAddDialog,
                    ),
                  )
                else ...[
                  if (active.isNotEmpty) ...[
                    _sectionHeader(context, 'Activas', active.length),
                    const SizedBox(height: 8),
                    ...active.map((r) => _buildRoutineCard(r)),
                  ],
                  if (inactive.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(context, 'Inactivas', inactive.length),
                    const SizedBox(height: 8),
                    ...inactive.map((r) => _buildRoutineCard(r)),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ZenTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: ZenTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    const routineColor = ZenTheme.secondaryColor;
    final selectedDate = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
    final routineProvider = context.watch<RoutineProvider>();
    final isCompletedOnSelectedDate = routineProvider.isRoutineCompletedOnDate(
      routine.id,
      selectedDate,
    );
    final completionInfo = routineProvider.getRoutineCompletionForDate(
      routine.id,
      selectedDate,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!isCompletedOnSelectedDate) return;
          await CompletionDialog.showSummary(
            context,
            itemTypeLabel: 'Rutina',
            title: routine.name,
            startedAt: routine.createdAt,
            completedAt: completionInfo?.completedAt ?? selectedDate,
            attachmentUrl: completionInfo?.attachmentUrl,
            attachmentType: completionInfo?.attachmentType,
          );
        },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZenTheme.borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ZenTheme.secondaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.repeat, color: ZenTheme.secondaryColor, size: 24),
                  ),
                  title: Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: routine.isActive ? null : TextDecoration.lineThrough,
                          color: routine.isActive ? ZenTheme.textDark : ZenTheme.textLight,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (routine.description != null && routine.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          routine.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: ZenTheme.textLight),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _chip(
                            Icons.repeat,
                            _repeatLabel(routine.repeatEveryDays),
                            routineColor,
                          ),
                          if (routine.scheduleTime != null)
                            _chip(
                              Icons.access_time,
                              routine.scheduleTime!,
                              routineColor,
                            ),
                          if (routine.steps.isNotEmpty)
                            _chip(
                              Icons.format_list_bulleted,
                              '${routine.steps.length} pasos',
                              routineColor,
                            ),
                        ],
                      ),
                      if (routine.steps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: routine.steps
                              .take(3)
                              .map(
                                (step) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 14,
                                        color: routineColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          step,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: ZenTheme.textLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isCompletedOnSelectedDate
                            ? 'Marcar pendiente hoy'
                            : 'Marcar completada hoy',
                        onPressed: () => _toggleRoutineToday(routine),
                        icon: Icon(
                          isCompletedOnSelectedDate
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: isCompletedOnSelectedDate
                              ? ZenTheme.successColor
                              : ZenTheme.textLight,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') _showEditDialog(routine);
                          if (value == 'delete') _confirmDelete(routine);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: ZenTheme.errorColor),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: ZenTheme.errorColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Barra de color inferior
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: routine.isActive
                        ? ZenTheme.secondaryColor
                        : ZenTheme.borderColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
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
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
