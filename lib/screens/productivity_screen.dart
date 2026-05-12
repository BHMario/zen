import 'package:flutter/material.dart';
import 'package:zen/theme/zen_theme.dart';
import 'package:zen/screens/tasks_screen.dart';
import 'package:zen/screens/projects_screen.dart';
import 'package:zen/screens/routines_screen.dart';
import 'package:zen/screens/goals_screen.dart';

class ProductivityScreen extends StatelessWidget {
  const ProductivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final spacing = screenWidth > 600 ? 20.0 : 12.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Productividad',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: ZenTheme.backgroundColor,
      ),
      backgroundColor: ZenTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.95,
            children: [
              _ProductivityCard(
                icon: Icons.checklist,
                title: 'Tareas',
                description: 'Gestiona tus tareas diarias',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TasksScreen()),
                  );
                },
              ),
              _ProductivityCard(
                icon: Icons.flag,
                title: 'Objetivos',
                description: 'Define y alcanza tus metas',
                color: const Color(0xFFEC4899),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsScreen()),
                  );
                },
              ),
              _ProductivityCard(
                icon: Icons.folder,
                title: 'Proyectos',
                description: 'Organiza tus proyectos',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProjectsScreen()),
                  );
                },
              ),
              _ProductivityCard(
                icon: Icons.repeat,
                title: 'Rutinas',
                description: 'Mantén tus hábitos',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoutinesScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ProductivityCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ZenTheme.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 48 : 56,
                height: isSmallScreen ? 48 : 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 24 : 28,
                  color: color,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
