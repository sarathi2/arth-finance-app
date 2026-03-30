import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use your computer's Wi-Fi IP if testing on a real phone!
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  static Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving profile to backend: $e');
      return false;
    }
  }

  // ... (keep your createGoal, addMoney, getGoals, getAlerts functions here) ...
}