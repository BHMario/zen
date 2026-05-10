import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/widgets/widgets.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ZenTheme.primaryColor,
          labelColor: ZenTheme.primaryColor,
          unselectedLabelColor: ZenTheme.textLight,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Activos'),
            Tab(text: 'Finalizados'),
          ],
        ),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProjects = projectProvider.projects;
          
          if (allProjects.isEmpty) {
            return EmptyState(
              emoji: '📁',
              title: 'No hay proyectos aún',
              description: 'Crea tu primer proyecto para empezar a organizar tus metas.',
              buttonText: 'Nuevo Proyecto',
              onButtonPressed: () => _showAddProjectDialog(context),
            );
          }

          final activeProjects = projectProvider.getActiveProjects();
          final completedProjects = projectProvider.getCompletedProjects();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProjectList(allProjects),
              _buildProjectList(activeProjects),
              _buildProjectList(completedProjects),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectList(List<dynamic> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Text(
          'No hay proyectos en esta categoría',
          style: TextStyle(color: ZenTheme.textLight),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          project: project,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailsScreen(project: project),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCalendarItemDialog(
        selectedDate: DateTime.now(),
        initialType: 'project',
      ),
    );
  }
}
