import 'dart:async'; // 1. Added for TimeoutException
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 2. Changed return type to 'dynamic' so it doesn't crash if the backend returns a List []
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse('https://arth-prr1.onrender.com$endpoint'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 60));
          
      return _handleResponse(response);
      
    } on TimeoutException {
      // 3. Let Timeouts pass through to the DashboardProvider!
      rethrow; 
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('https://arth-prr1.onrender.com$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
          
      return _handleResponse(response);
      
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Changed return type to dynamic here as well
  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded; 
    }
    
    // Safely try to extract the error message whether it's a Map or not
    String errorMsg = 'Something went wrong';
    if (decoded is Map) {
       errorMsg = decoded['message'] ?? decoded['detail'] ?? errorMsg;
    }
    
    throw ApiException(
      errorMsg,
      statusCode: response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}