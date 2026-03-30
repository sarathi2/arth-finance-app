import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/rich_ai_models.dart';

// ── Models for Multi-Session Management ─────────────────────────────────────
class ChatSession {
  final String id;
  String title;
  final DateTime updatedAt;
  final List<RichChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => {
              'text': m.text,
              'isUser': m.isUser,
              'timestamp': m.timestamp.toIso8601String(),
            }).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List).map((m) => RichChatMessage(
            text: m['text'],
            isUser: m['isUser'],
            timestamp: DateTime.parse(m['timestamp']),
          )).toList(),
    );
  }
}

class RichChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final RichAiResponse? richResponse;

  RichChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.richResponse,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ── Service ─────────────────────────────────────────────────────────────────
class ChatHistoryService {
  
  // ── 1. Load All Sessions ──────────────────────────────────────────────────
  Future<List<ChatSession>> loadSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('arth_chat_sessions_$userId');

    if (data == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(data);
      final sessions = decodedList.map((s) => ChatSession.fromJson(s)).toList();
      
      // Sort so the most recently updated chat is always at the top of the Drawer
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); 
      return sessions;
    } catch (e) {
      return [];
    }
  }

  // ── 2. Save All Sessions ──────────────────────────────────────────────────
  Future<void> saveSessions(String userId, List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString('arth_chat_sessions_$userId', encoded);
  }

  // ── 3. Clear All Sessions ─────────────────────────────────────────────────
  Future<void> clearSessions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('arth_chat_sessions_$userId');
  }

  // ── 4. Backend Sync Placeholders ──────────────────────────────────────────
  Future<List<ChatSession>> fetchFromBackend(String userId) async {
    // TODO: Implement GET request to your Node/Python backend later
    return [];
  }

  Future<void> syncToBackend(String userId, List<ChatSession> sessions) async {
    // TODO: Implement POST request to your Node/Python backend later
  }
}