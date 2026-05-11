import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/widgets/widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _timeFilter = 'day';
  DateTime _anchorDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadGoals);
  }

  Future<void> _loadGoals() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<GoalProvider>().loadUserGoals(userId);
    }
  }

  Future<void> _showAddGoalDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));
    GoalCategory category = GoalCategory.other;
    GoalTimeframe timeframe = GoalTimeframe.mediumTerm;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Nuevo objetivo'),
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
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: GoalCategory.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(_categoryLabel(e)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocalState(() => category = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalTimeframe>(
                  value: timeframe,
                  decoration: const InputDecoration(labelText: 'Plazo'),
                  items: GoalTimeframe.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(_timeframeLabel(e)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocalState(() => timeframe = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha objetivo'),
                  subtitle: Text(
                    '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setLocalState(() => targetDate = picked);
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
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      if (titleController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El título del objetivo es obligatorio')),
          );
        }
        titleController.dispose();
        descriptionController.dispose();
        return;
      }

      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<GoalProvider>().addGoal(
              title: titleController.text.trim(),
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              category: category,
              timeframe: timeframe,
              startDate: DateTime.now(),
              targetDate: targetDate,
              targetValue: 100,
              unit: '%',
              userId: userId,
            );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditGoalDialog(Goal goal) async {
    final titleController = TextEditingController(text: goal.title);
    final descriptionController =
        TextEditingController(text: goal.description ?? '');
    final currentController = TextEditingController(text: goal.currentValue.toStringAsFixed(0));
    DateTime targetDate = goal.targetDate;
    GoalCategory category = goal.category;
    GoalTimeframe timeframe = goal.timeframe;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Editar objetivo'),
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
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: GoalCategory.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(_categoryLabel(e)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocalState(() => category = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalTimeframe>(
                  value: timeframe,
                  decoration: const InputDecoration(labelText: 'Plazo'),
                  items: GoalTimeframe.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(_timeframeLabel(e)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocalState(() => timeframe = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Progreso (%)',
                    hintText: '0 a 100',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha objetivo'),
                  subtitle: Text(
                    '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setLocalState(() => targetDate = picked);
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
      ),
    );

    if (saved == true) {
      final currentInput = double.tryParse(currentController.text.trim()) ?? goal.currentValue;
      final current = currentInput.clamp(0, 100).toDouble();
      final updated = goal.copyWith(
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        category: category,
        timeframe: timeframe,
        targetDate: targetDate,
        targetValue: 100,
        currentValue: current,
        unit: '%',
        isCompleted: current >= 100,
        updatedAt: DateTime.now(),
      );
      await context.read<GoalProvider>().updateGoal(updated);
    }

    titleController.dispose();
    descriptionController.dispose();
    currentController.dispose();
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar objetivo'),
        content: Text('¿Seguro que quieres eliminar "${goal.title}"?'),
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

    if (confirm == true) {
      try {
        await context.read<GoalProvider>().deleteGoal(goal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objetivo eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando objetivo: $e')),
          );
        }
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

  List<Goal> _filterByDateScope(List<Goal> goals) {
    final day = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);

    bool inScope(Goal g, DateTime scopeStart, DateTime scopeEnd) {
      final gStart = DateTime(g.startDate.year, g.startDate.month, g.startDate.day);
      final gEnd = DateTime(g.targetDate.year, g.targetDate.month, g.targetDate.day);
      // El objetivo es relevante si su rango [startDate, targetDate] se solapa con el scope
      return !gEnd.isBefore(scopeStart) && !gStart.isAfter(scopeEnd);
    }

    if (_timeFilter == 'day') {
      return goals.where((g) => inScope(g, day, day)).toList();
    }

    if (_timeFilter == 'week') {
      final start = _startOfWeek(day);
      final end = _endOfWeek(day);
      return goals.where((g) => inScope(g, start, end)).toList();
    }

    final start = DateTime(day.year, day.month, 1);
    final end = DateTime(day.year, day.month + 1, 0);
    return goals.where((g) => inScope(g, start, end)).toList();
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

  Future<void> _toggleGoalComplete(Goal goal) async {
    final provider = context.read<GoalProvider>();
    if (goal.isCompleted) {
      await provider.updateGoal(
        goal.copyWith(
          isCompleted: false,
          clearCompletedAt: true,
          clearCompletionAttachmentUrl: true,
          clearCompletionAttachmentType: true,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    final completed = goal.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await provider.updateGoal(completed);

    final completionData = await CompletionDialog.showCelebrationAndAttach(
      context,
      itemTypeLabel: 'Objetivo',
      title: goal.title,
      startedAt: goal.startDate,
      completedAt: DateTime.now(),
    );

    final url = completionData?['completionAttachmentUrl'];
    final type = completionData?['completionAttachmentType'];
    if (url != null) {
      await provider.updateGoal(
        completed.copyWith(
          completionAttachmentUrl: url,
          completionAttachmentType: type,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGoals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo objetivo'),
      ),
      body: Consumer<GoalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final scopedGoals = _filterByDateScope(provider.goals);

          final active = scopedGoals.where((g) => !g.isCompleted).toList();
          final completed = scopedGoals.where((g) => g.isCompleted).toList();
          final completionRate = scopedGoals.isEmpty
              ? 0
              : ((completed.length / scopedGoals.length) * 100).round();

          return RefreshIndicator(
            onRefresh: _loadGoals,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ZenTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.track_changes, color: ZenTheme.secondaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${active.length} activos  ·  ${completed.length} completados  ·  $completionRate%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ZenTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                if (scopedGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      emoji: '🎯',
                      title: 'Sin objetivos',
                      description: 'No hay objetivos para el rango temporal seleccionado.',
                      buttonText: 'Crear objetivo',
                      onButtonPressed: _showAddGoalDialog,
                    ),
                  )
                else ...[
                  if (active.isNotEmpty) ...[
                    _sectionHeader('Activos', active.length),
                    const SizedBox(height: 8),
                    ...active.map(_goalCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader('Completados', completed.length),
                    const SizedBox(height: 8),
                    ...completed.map(_goalCard),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
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

  Widget _goalCard(Goal goal) {
    final progress = goal.targetValue <= 0
        ? 0.0
        : (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
    final dueText =
        '${goal.targetDate.day.toString().padLeft(2, '0')}/${goal.targetDate.month.toString().padLeft(2, '0')}/${goal.targetDate.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (!goal.isCompleted) return;
        await CompletionDialog.showSummary(
          context,
          itemTypeLabel: 'Objetivo',
          title: goal.title,
          startedAt: goal.startDate,
          completedAt: goal.completedAt ?? goal.updatedAt,
          attachmentUrl: goal.completionAttachmentUrl,
          attachmentType: goal.completionAttachmentType,
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ZenTheme.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_outlined, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle') {
                      await _toggleGoalComplete(goal);
                    } else if (value == 'edit') {
                      await _showEditGoalDialog(goal);
                    } else if (value == 'delete') {
                      await _deleteGoal(goal);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(goal.isCompleted
                          ? 'Marcar activo'
                          : 'Marcar completado'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            if (goal.description != null && goal.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                goal.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ZenTheme.textLight),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: ZenTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted ? ZenTheme.successColor : ZenTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Progreso: ${goal.currentValue.toStringAsFixed(0)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Fecha: $dueText',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ZenTheme.textLight),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  static String _categoryLabel(GoalCategory category) {
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

  static String _timeframeLabel(GoalTimeframe timeframe) {
    switch (timeframe) {
      case GoalTimeframe.shortTerm:
        return 'Corto plazo';
      case GoalTimeframe.mediumTerm:
        return 'Medio plazo';
      case GoalTimeframe.longTerm:
        return 'Largo plazo';
    }
  }
}
