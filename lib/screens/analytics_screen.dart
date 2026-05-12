import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:zen/providers/providers.dart';
import 'package:zen/theme/zen_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final analyticsProvider = context.read<AnalyticsProvider>();
      if (authProvider.currentUser != null) {
        analyticsProvider.loadAnalytics(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Productividad'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, _) {
          if (analyticsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (analyticsProvider.error != null) {
            return Center(
              child: Text('Error: ${analyticsProvider.error}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicadores principales
                _buildKPICards(analyticsProvider),
                const SizedBox(height: 24),

                // Gráfica de cumplimiento de tareas
                _buildTaskCompletionChart(analyticsProvider),
                const SizedBox(height: 24),

                // Gráfica de tiempo por proyecto
                if (analyticsProvider.timeByProject.isNotEmpty)
                  _buildTimeByProjectChart(analyticsProvider),
                if (analyticsProvider.timeByProject.isNotEmpty)
                  const SizedBox(height: 24),

                // Gráfica de balance trabajo/vida personal
                _buildWorkLifeBalanceChart(analyticsProvider),
                const SizedBox(height: 24),

                // Gráfica de hábitos
                if (analyticsProvider.habitCompletion.isNotEmpty)
                  _buildHabitCompletionChart(analyticsProvider),
                if (analyticsProvider.habitCompletion.isNotEmpty)
                  const SizedBox(height: 24),

                // Indicador de tendencia
                _buildTrendIndicator(analyticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICards(AnalyticsProvider provider) {
    // Obtener datos de otros providers
    final taskProvider = context.read<TaskProvider>();
    final goalProvider = context.read<GoalProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final routineProvider = context.read<RoutineProvider>();
    
    final totalGoals = goalProvider.goals.length;
    final completedGoals = goalProvider.goals.where((g) => g.completed).length;
    final totalProjects = projectProvider.projects.length;
    final activeRoutines = routineProvider.routines.where((r) => r.isActive).length;
    
    return Column(
      children: [
        // Primera fila: Tareas y Racha
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Completadas',
                value: provider.totalCompletedTasks.toString(),
                subtitle: 'Tareas',
                icon: Icons.check_circle,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Pendientes',
                value: provider.totalPendingTasks.toString(),
                subtitle: 'Tareas',
                icon: Icons.pending_actions,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: Objetivos y Proyectos
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: '$completedGoals/$totalGoals',
                value: totalGoals > 0 ? '${((completedGoals / totalGoals) * 100).toInt()}%' : '0%',
                subtitle: 'Objetivos',
                icon: Icons.flag,
                color: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Activos',
                value: totalProjects.toString(),
                subtitle: 'Proyectos',
                icon: Icons.folder,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tercera fila: Rutinas y Racha
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Activas',
                value: activeRoutines.toString(),
                subtitle: 'Rutinas',
                icon: Icons.repeat,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Racha',
                value: '${provider.productivityStreak}',
                subtitle: 'días',
                icon: Icons.local_fire_department,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskCompletionChart(AnalyticsProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cumplimiento de Tareas (Semanal)',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 200 : 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildTaskCompletionBars(provider),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'L',
                            'M',
                            'X',
                            'J',
                            'V',
                            'S',
                            'D'
                          ];
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          return Text(
                            days[i],
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                          );
                        },
                      ),
                    ),
                  ),
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildTaskCompletionBars(AnalyticsProvider provider) {
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
    ];

    return List.generate(7, (index) {
      final day = days[index];
      final value =
          (provider.weeklyTaskCompletion[day] ?? 0).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[index],
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    });
  }

  Widget _buildTimeByProjectChart(AnalyticsProvider provider) {
    if (provider.timeByProject.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final total =
        provider.timeByProject.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.pink,
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiempo por Proyecto (Horas)',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(
                    provider.timeByProject.length,
                    (index) {
                      final entry =
                          provider.timeByProject.entries.toList()[index];
                      return PieChartSectionData(
                        value: entry.value,
                        title: '${entry.value.toStringAsFixed(1)}h',
                        color: colors[index % colors.length],
                        radius: isSmallScreen ? 70 : 80,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(
                provider.timeByProject.length,
                (index) {
                  final entry =
                      provider.timeByProject.entries.toList()[index];
                  final percentage =
                      (entry.value / total) * 100;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isSmallScreen ? 10 : 12,
                        height: isSmallScreen ? 10 : 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key}: ${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkLifeBalanceChart(AnalyticsProvider provider) {
    final colors = [Colors.blue, Colors.green];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance Trabajo/Vida Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: provider.workLifeBalance['Trabajo'] ?? 50,
                      title: '${(provider.workLifeBalance['Trabajo'] ?? 50).toStringAsFixed(1)}%',
                      color: colors[0],
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    PieChartSectionData(
                      value: provider.workLifeBalance['Personal'] ?? 50,
                      title: '${(provider.workLifeBalance['Personal'] ?? 50).toStringAsFixed(1)}%',
                      color: colors[1],
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: colors[0],
                  label: 'Trabajo',
                  percentage: provider.workLifeBalance['Trabajo'] ?? 50,
                ),
                _LegendItem(
                  color: colors[1],
                  label: 'Personal',
                  percentage: provider.workLifeBalance['Personal'] ?? 50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCompletionChart(AnalyticsProvider provider) {
    if (provider.habitCompletion.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cumplimiento de Hábitos (Semanal)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildHabitCompletionBars(provider),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          return Text(days[i]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                  ),
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildHabitCompletionBars(AnalyticsProvider provider) {
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
    ];

    return List.generate(7, (index) {
      final day = days[index];
      final value = (provider.habitCompletion[day] ?? 0).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[index],
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    });
  }

  Widget _buildTrendIndicator(AnalyticsProvider provider) {
    final trend = provider.productivityTrend;
    final isPositive = trend >= 0;
    final trendPercent = trend.abs().toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tendencia de Productividad',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${isPositive ? '+' : '-'}$trendPercent%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      const TextSpan(
                        text: ' vs. semana anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 18 : 20,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
