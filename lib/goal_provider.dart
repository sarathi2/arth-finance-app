import 'package:flutter/material.dart';
import 'package:arth/api_service.dart';

class GoalProvider extends ChangeNotifier {
  List<dynamic> _goals = [];
  List<String> _alerts = [];
  bool _isLoading = false;

  List<dynamic> get goals => _goals;
  List<String> get alerts => _alerts;
  bool get isLoading => _isLoading;

  // ── Fetch everything from Python Backend ──
  Future<void> loadDashboard(String userId) async {
    _isLoading = true;
    notifyListeners();

    _goals = await ApiService.getGoals(userId);
    _alerts = await ApiService.getAlerts(userId);

    _isLoading = false;
    notifyListeners();
  }

  // ── Create a new goal ──
  Future<bool> createNewGoal(String userId, String name, double target, String deadline) async {
    final success = await ApiService.createGoal(
      userId: userId, 
      name: name, 
      targetAmount: target, 
      deadline: deadline
    );
    if (success) {
      await loadDashboard(userId); // Refresh the UI
    }
    return success;
  }

  // ── Add money to an existing goal ──
  Future<bool> addMoney(String userId, String name, double amount) async {
    final success = await ApiService.addMoney(
      userId: userId, 
      name: name, 
      amount: amount
    );
    if (success) {
      await loadDashboard(userId); // Refresh the UI
    }
    return success;
  }
}