import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:arth/ai_service.dart';
import 'package:arth/ai_models.dart';
import 'package:arth/local_storage.dart';

class DashboardProvider extends ChangeNotifier {
  final AiService _aiService = AiService();

  List<InsightModel> _insights = [];
  bool _isLoading = false;
  String? _error;

  List<InsightModel> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInsights() async {
    final userId = await LocalStorage.getUserId();
    
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // The timeout forces the app to stop waiting after 60 seconds
      _insights = await _aiService
          .getInsights(userId)
          .timeout(const Duration(seconds: 60));
          
    } on TimeoutException {
      _error = 'The server took too long to respond. Please pull down to refresh.';
    } catch (e) {
      _error = 'Could not load insights: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}