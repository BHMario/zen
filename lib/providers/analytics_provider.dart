import 'package:flutter/material.dart';
import 'package:zen/services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  Map<String, int> weeklyTaskCompletion = {};
  Map<String, double> timeByProject = {};
  Map<String, int> habitCompletion = {};
  Map<String, double> workLifeBalance = {};
  double productivityTrend = 0;
  int totalCompletedTasks = 0;
  int totalPendingTasks = 0;
  int productivityStreak = 0;

  bool isLoading = false;
  String? error;

  Future<void> loadAnalytics(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final [
        completion,
        timeProject,
        habits,
        balance,
        trend,
        completed,
        pending,
        streak,
      ] = await Future.wait([
        AnalyticsService.getWeeklyTaskCompletion(userId),
        AnalyticsService.getTimeByProject(userId),
        AnalyticsService.getHabitCompletion(userId),
        AnalyticsService.getWorkLifeBalance(userId),
        AnalyticsService.getProductivityTrend(userId),
        AnalyticsService.getTotalCompletedTasks(userId),
        AnalyticsService.getTotalPendingTasks(userId),
        AnalyticsService.getProductivityStreak(userId),
      ]);

      weeklyTaskCompletion = completion as Map<String, int>;
      timeByProject = timeProject as Map<String, double>;
      habitCompletion = habits as Map<String, int>;
      workLifeBalance = balance as Map<String, double>;
      productivityTrend = trend as double;
      totalCompletedTasks = completed as int;
      totalPendingTasks = pending as int;
      productivityStreak = streak as int;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
