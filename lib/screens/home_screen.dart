import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/screens/calendar_screen.dart';
import 'package:zen/screens/analytics_screen.dart';
import 'package:zen/screens/tasks_screen.dart';
import 'package:zen/screens/projects_screen.dart';
import 'package:zen/screens/routines_screen.dart';
import 'package:zen/screens/goals_screen.dart';
import 'package:zen/screens/profile_screen.dart';
import 'package:zen/services/services.dart';
import 'package:zen/theme/zen_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSyncing = true;
  String? _syncError;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const AnalyticsScreen(),
    const TasksScreen(),
    const ProjectsScreen(),
    const RoutinesScreen(),
    const GoalsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncUserData);
  }

  /// Sincronizar todos los datos del usuario
  Future<void> _syncUserData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      if (authProvider.currentUser == null) {
        setState(() {
          _syncError = 'Usuario no autenticado';
          _isSyncing = false;
        });
        return;
      }

      final userId = authProvider.currentUser!.id;
      
      debugPrint('🔄 Iniciando sincronización de datos...');

      await DataSyncService.syncUserData(
        userId: userId,
        authProvider: authProvider,
        taskProvider: context.read<TaskProvider>(),
        projectProvider: context.read<ProjectProvider>(),
        routineProvider: context.read<RoutineProvider>(),
        goalProvider: context.read<GoalProvider>(),
        reminderProvider: context.read<ReminderProvider>(),
        analyticsProvider: context.read<AnalyticsProvider>(),
      );

      // Mostrar información de sincronización para debugging
      final debugInfo = await DataSyncService.getDebugInfo(userId);
      debugPrint(debugInfo);

      setState(() {
        _isSyncing = false;
        _syncError = null;
      });
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
      setState(() {
        _syncError = e.toString();
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Zen - Cargando datos...'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sincronizando tus datos...'),
            ],
          ),
        ),
      );
    }

    if (_syncError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error de Sincronización'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_syncError'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _syncUserData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ZenTheme.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'Análisis',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Proyecto',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_outlined),
              selectedIcon: Icon(Icons.repeat),
              label: 'Rutinas',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Objetivos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
