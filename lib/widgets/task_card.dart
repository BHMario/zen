import 'package:flutter/material.dart';
import 'package:zen/models/models.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime dueDate;
  final String priority;
  final String status;
  final String color;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.title,
    this.description,
    required this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.color = '#6366F1',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskColor = ColorUtils.hexToColor(color);
    final isOverdue = DateTimeUtils.isOverdue(dueDate) && status != 'completed';
    final isCompleted = status == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isCompleted ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: taskColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1, right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? ZenTheme.successColor
                            : Colors.transparent,
                        border: isCompleted
                            ? null
                            : Border.all(
                                color: taskColor.withValues(alpha: 0.6),
                                width: 2,
                              ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? ZenTheme.textLight
                                      : ZenTheme.textDark,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: ZenTheme.textLight),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _priorityBadge(context, priority),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today_outlined,
                      size: 13,
                      color: isOverdue
                          ? ZenTheme.errorColor
                          : ZenTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateTimeUtils.getRelativeDate(dueDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? ZenTheme.errorColor
                                : ZenTheme.textLight,
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                    const Spacer(),
                    _statusBadge(context, status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(BuildContext context, String priority) {
    final color = ZenTheme.priorityColors[priority] ?? ZenTheme.primaryColor;
    final labels = {
      'urgent': 'URGENTE',
      'high': 'ALTA',
      'medium': 'MEDIA',
      'low': 'BAJA',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labels[priority] ?? priority.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'completed':
        bgColor = ZenTheme.successColor.withValues(alpha: 0.12);
        textColor = ZenTheme.successColor;
        label = '✓ Completada';
        break;
      case 'inProgress':
        bgColor = ZenTheme.primaryColor.withValues(alpha: 0.12);
        textColor = ZenTheme.primaryColor;
        label = '● En progreso';
        break;
      case 'cancelled':
        bgColor = ZenTheme.errorColor.withValues(alpha: 0.12);
        textColor = ZenTheme.errorColor;
        label = '✕ Cancelada';
        break;
      default:
        bgColor = ZenTheme.textLight.withValues(alpha: 0.12);
        textColor = ZenTheme.textLight;
        label = '○ Pendiente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

class TaskDetailSheet extends StatelessWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
  });

  static Future<void> show(
    BuildContext context,
    Task task, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onToggleComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskDetailSheet(
        task: task,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleComplete: onToggleComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color taskColor;
    try {
      taskColor = Color(
          int.parse('0xFF${task.color.replaceFirst('#', '')}'));
    } catch (_) {
      taskColor = ZenTheme.primaryColor;
    }

    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.isOverdue;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ZenTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: taskColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.task_alt_outlined,
                          color: taskColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            _statusPill(context, task.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    _infoRow(
                      context,
                      Icons.notes_outlined,
                      'Descripción',
                      task.description!,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _infoRow(
                    context,
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today_outlined,
                    'Vence',
                    DateTimeUtils.getRelativeDate(task.dueDate),
                    valueColor:
                        isOverdue ? ZenTheme.errorColor : null,
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                    context,
                    Icons.flag_outlined,
                    'Prioridad',
                    _priorityLabel(task.priority),
                    valueColor:
                        ZenTheme.priorityColors[task.priority.name],
                  ),
                  if (task.labels.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.label_outline,
                            size: 18, color: ZenTheme.textLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: task.labels
                                .map((l) => Chip(
                                      label: Text(l,
                                          style: const TextStyle(
                                              fontSize: 11)),
                                      visualDensity:
                                          VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onToggleComplete?.call();
                          },
                          icon: Icon(isCompleted
                              ? Icons.undo_rounded
                              : Icons.check_rounded),
                          label: Text(isCompleted
                              ? 'Reactivar'
                              : 'Completar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isCompleted
                                ? ZenTheme.textLight
                                : ZenTheme.successColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit?.call();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDelete?.call();
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: ZenTheme.errorColor),
                        style: IconButton.styleFrom(
                          side: const BorderSide(
                              color: ZenTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, TaskStatus status) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.completed:
        color = ZenTheme.successColor;
        label = 'Completada';
        break;
      case TaskStatus.inProgress:
        color = ZenTheme.primaryColor;
        label = 'En progreso';
        break;
      case TaskStatus.cancelled:
        color = ZenTheme.errorColor;
        label = 'Cancelada';
        break;
      default:
        color = ZenTheme.textLight;
        label = 'Pendiente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ZenTheme.textLight),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: ZenTheme.textLight)),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? ZenTheme.textDark,
                      fontWeight: FontWeight.w500,
                    )),
          ],
        ),
      ],
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return 'Urgente';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.low:
        return 'Baja';
    }
  }
}
