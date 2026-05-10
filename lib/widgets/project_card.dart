import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final projectColor = ColorUtils.hexToColor(project.color);
    
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;
        final completionPercentage = project.calculateCompletionPercentage(allTasks);
        final totalTasks = project.getTotalTasksCount(allTasks);
        final progress = completionPercentage / 100.0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias,
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: projectColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          color: projectColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (project.description != null && project.description!.isNotEmpty)
                              Text(
                                project.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context),
                    ],
                  ),
                  if (project.attachmentUrl != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          project.attachmentType == 'video'
                              ? Icons.videocam_outlined
                              : Icons.image_outlined,
                          size: 14,
                          color: ZenTheme.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          project.attachmentType == 'video'
                              ? 'Proyecto con video adjunto'
                              : 'Proyecto con imagen adjunta',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ZenTheme.textLight,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: ZenTheme.textLight,
                            ),
                      ),
                      Text(
                        '${completionPercentage.toInt()}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: projectColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: projectColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(projectColor),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: ZenTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTimeUtils.formatShortDate(project.startDate)} - ${project.endDate != null ? DateTimeUtils.formatShortDate(project.endDate!) : "Sin fin"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ZenTheme.textLight,
                            ),
                      ),
                      const Spacer(),
                      const Icon(Icons.check_circle_outline, size: 14, color: ZenTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '$totalTasks tareas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ZenTheme.textLight,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    String label;

    switch (project.status) {
      case ProjectStatus.planning:
        badgeColor = Colors.orange;
        label = 'Planificación';
        break;
      case ProjectStatus.active:
        badgeColor = ZenTheme.primaryColor;
        label = 'Activo';
        break;
      case ProjectStatus.onHold:
        badgeColor = Colors.grey;
        label = 'En espera';
        break;
      case ProjectStatus.completed:
        badgeColor = ZenTheme.successColor;
        label = 'Completado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
