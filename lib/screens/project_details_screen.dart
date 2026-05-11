import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/models/models.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/utils/utils.dart';
import 'package:zen/widgets/widgets.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          // Obtener la versión más reciente del proyecto desde el provider
          final latestProject = projectProvider.getProjectById(project.id) ?? project;
          final projectColor = ColorUtils.hexToColor(latestProject.color);

          return CustomScrollView(
            slivers: [
              // Custom App Bar with project info
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    latestProject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  background: Container(
                    color: projectColor.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        Icons.folder_outlined,
                        size: 80,
                        color: projectColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleProjectAction(context, value, latestProject),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar Proyecto')),
                      const PopupMenuItem(value: 'status', child: Text('Cambiar Estado')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar Proyecto', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),

              // Project Details Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (latestProject.description != null && latestProject.description!.isNotEmpty) ...[
                        Text(
                          latestProject.description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Progress Card
                      Consumer<TaskProvider>(
                        builder: (context, taskProvider, child) {
                          final allTasks = taskProvider.tasks;
                          final completionPercentage = latestProject.calculateCompletionPercentage(allTasks);
                          final completedCount = latestProject.getCompletedTasksCount(allTasks);
                          final totalCount = latestProject.getTotalTasksCount(allTasks);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ZenTheme.dividerColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Progreso ($completedCount/$totalCount tareas)'),
                                    Text(
                                      '${completionPercentage.toInt()}%',
                                      style: TextStyle(
                                        color: projectColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: completionPercentage / 100.0,
                                  backgroundColor: projectColor.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(projectColor),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Tareas del Proyecto',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // Task List
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final tasks = taskProvider.getTasksByProject(latestProject.id);

                  if (tasks.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyState(
                          emoji: '📝',
                          title: 'No hay tareas',
                          description: 'Aún no has añadido tareas a este proyecto.',
                          buttonText: 'Añadir Tarea',
                          onButtonPressed: null, 
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          final isCompleted = task.status == TaskStatus.completed;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () async {
                                if (!isCompleted) return;
                                await CompletionDialog.showSummary(
                                  context,
                                  itemTypeLabel: 'Tarea',
                                  title: task.title,
                                  startedAt: task.createdAt,
                                  completedAt: task.completedAt ?? task.updatedAt,
                                  attachmentUrl: task.completionAttachmentUrl,
                                  attachmentType: task.completionAttachmentType,
                                );
                              },
                              leading: Checkbox(
                                value: isCompleted,
                                activeColor: projectColor,
                                onChanged: (value) async {
                                  if (value == true && !isCompleted) {
                                    await taskProvider.completeTask(task.id);
                                    if (!context.mounted) return;
                                    final updatedTask = taskProvider.tasks.firstWhere((t) => t.id == task.id);
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
                                      if (!context.mounted) return;
                                      await context.read<TaskProvider>().updateTask(
                                        updatedTask.copyWith(
                                          completionAttachmentUrl: url,
                                          completionAttachmentType: type,
                                          updatedAt: DateTime.now(),
                                        ),
                                      );
                                    }
                                  } else {
                                    await taskProvider.updateTaskStatus(
                                      task.id,
                                      value == true ? TaskStatus.completed : TaskStatus.pending,
                                    );
                                  }
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? ZenTheme.textLight : null,
                                ),
                              ),
                              subtitle: Text(
                                DateTimeUtils.getRelativeDate(task.dueDate),
                                style: TextStyle(
                                  color: isCompleted ? ZenTheme.textLight.withValues(alpha: 0.5) : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showTaskMenu(context, taskProvider, task),
                              ),
                            ),
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final latestProject = projectProvider.getProjectById(project.id) ?? project;
          final projectColor = ColorUtils.hexToColor(latestProject.color);
          
          return FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(context, latestProject),
            label: const Text('Nueva Tarea'),
            icon: const Icon(Icons.add),
            backgroundColor: projectColor,
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AddCalendarItemDialog(
        selectedDate: DateTime.now(),
        initialType: 'task',
        initialProjectId: project.id,
      ),
    );
  }

  void _showTaskMenu(BuildContext context, TaskProvider taskProvider, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar Tarea'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => EditTaskDialog(task: task),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar Tarea', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirm(context, 'tarea');
                if (confirm) {
                  await taskProvider.deleteTask(task.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProjectAction(BuildContext context, String action, Project project) async {
    final projectProvider = context.read<ProjectProvider>();
    
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => EditProjectDialog(project: project),
        );
        break;
      case 'status':
        _showStatusPicker(context, projectProvider, project);
        break;
      case 'delete':
        final confirm = await _showDeleteConfirm(context, 'proyecto');
        if (confirm) {
          await projectProvider.deleteProject(project.id);
          if (context.mounted) Navigator.pop(context);
        }
        break;
    }
  }

  void _showStatusPicker(BuildContext context, ProjectProvider provider, Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProjectStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusLabel(status)),
              leading: Radio<ProjectStatus>(
                value: status,
                groupValue: project.status,
                onChanged: (_) async {
                  Navigator.pop(context);
                  final updated = project.copyWith(status: status);
                  await provider.updateProject(updated);
                  if (status == ProjectStatus.completed && project.status != ProjectStatus.completed) {
                    final latest = provider.getProjectById(project.id) ?? updated;
                    if (!context.mounted) return;
                    final completionData = await CompletionDialog.showCelebrationAndAttach(
                      context,
                      itemTypeLabel: 'Proyecto',
                      title: latest.name,
                      startedAt: latest.createdAt,
                      completedAt: latest.completedAt ?? DateTime.now(),
                    );
                    final url = completionData?['completionAttachmentUrl'];
                    final type = completionData?['completionAttachmentType'];
                    if (url != null) {
                      await provider.updateProject(
                        latest.copyWith(
                          completionAttachmentUrl: url,
                          completionAttachmentType: type,
                          updatedAt: DateTime.now(),
                        ),
                      );
                    }
                  }
                },
              ),
              onTap: () async {
                Navigator.pop(context);
                final updated = project.copyWith(status: status);
                await provider.updateProject(updated);
                if (status == ProjectStatus.completed && project.status != ProjectStatus.completed) {
                  final latest = provider.getProjectById(project.id) ?? updated;
                  if (!context.mounted) return;
                  final completionData = await CompletionDialog.showCelebrationAndAttach(
                    context,
                    itemTypeLabel: 'Proyecto',
                    title: latest.name,
                    startedAt: latest.createdAt,
                    completedAt: latest.completedAt ?? DateTime.now(),
                  );
                  final url = completionData?['completionAttachmentUrl'];
                  final type = completionData?['completionAttachmentType'];
                  if (url != null) {
                    await provider.updateProject(
                      latest.copyWith(
                        completionAttachmentUrl: url,
                        completionAttachmentType: type,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning: return 'Planificación';
      case ProjectStatus.active: return 'Activo';
      case ProjectStatus.onHold: return 'En espera';
      case ProjectStatus.completed: return 'Completado';
    }
  }

  Future<bool> _showDeleteConfirm(BuildContext context, String type) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar $type?'),
        content: Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }
}
