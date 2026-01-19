import 'package:flutter/material.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📁 Mis Proyectos'),
            const SizedBox(height: 16),
            const Text('Próximamente: Gestión de proyectos y tareas'),
          ],
        ),
      ),
    );
  }
}
