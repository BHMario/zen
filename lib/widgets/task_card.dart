import 'package:flutter/material.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: taskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? ZenTheme.errorColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ZenTheme.priorityColors[priority] ?? ZenTheme.primaryColor,
                      ),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ZenTheme.priorityColors[priority],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateTimeUtils.getRelativeDate(dueDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue ? ZenTheme.errorColor : ZenTheme.textLight,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? ZenTheme.successColor.withValues(alpha: 0.1)
                          : ZenTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status == 'completed' ? '✓ Completada' : 'Pendiente',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: status == 'completed'
                                ? ZenTheme.successColor
                                : ZenTheme.primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
