import 'package:flutter/material.dart';
import 'package:arth/ai_service.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/app_localizations.dart';
import 'package:arth/chat_history_service.dart'; // 🔥 Imports the newly upgraded Service

class AiChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final ChatHistoryService _historyService = ChatHistoryService(); 

  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  String _language = 'english';
  String? _userId;

  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  String get language => _language;

  AppLocalizations get loc => AppLocalizations(_language);
  List<String> get quickPrompts => loc.quickPrompts;
  String get voiceLocale => _language == 'tamil' ? 'ta_IN' : 'en_IN';

  // 🔥 Get current active messages
  List<RichChatMessage> get messages {
    if (_currentSessionId == null) return [];
    final session = _sessions.firstWhere((s) => s.id == _currentSessionId, orElse: () => _sessions.first);
    return List.unmodifiable(session.messages);
  }

  // 🔥 Get filtered sessions for the Drawer Search
  List<ChatSession> get filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    return _sessions.where((s) {
      final matchesTitle = s.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMessage = s.messages.any((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesTitle || matchesMessage;
    }).toList();
  }

  AiChatProvider() {
    _init();
  }

  Future<void> _init() async {
    _language = await LocalStorage.getLanguage();
    _userId = await LocalStorage.getUserId();
    notifyListeners();
    await _loadAllSessions();
  }

  // ── Session Management ────────────────────────────────────────────────────
  Future<void> _loadAllSessions() async {
    _isLoadingHistory = true;
    notifyListeners();

    final uid = _userId ?? 'default';
    _sessions = await _historyService.loadSessions(uid);

    if (_sessions.isEmpty) {
      createNewSession();
    } else {
      _currentSessionId = _sessions.first.id;
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> _saveAllSessions() async {
    final uid = _userId ?? 'default';
    await _historyService.saveSessions(uid, _sessions);
  }

  void createNewSession() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      updatedAt: DateTime.now(),
      messages: [RichChatMessage(text: loc.chatWelcome, isUser: false)],
    );
    _sessions.insert(0, newSession);
    _currentSessionId = newSession.id;
    _searchQuery = '';
    notifyListeners();
    _saveAllSessions();
  }

  void switchSession(String id) {
    _currentSessionId = id;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Edit Message ──────────────────────────────────────────────────────────
  String editMessage(int index) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
    if (sessionIndex == -1) return '';

    final session = _sessions[sessionIndex];
    if (index < 0 || index >= session.messages.length) return '';

    final textToEdit = session.messages[index].text;
    
    // Deletes the edited message and everything below it
    session.messages.removeRange(index, session.messages.length);
    notifyListeners();
    _saveAllSessions();

    return textToEdit;
  }

  // ── Send Message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _userId ??= await LocalStorage.getUserId();
    if (_userId == null) {
      _errorMessage = loc.errorNotLoggedIn;
      notifyListeners();
      return;
    }

    final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
    if (sessionIndex == -1) return;

    final currentSession = _sessions[sessionIndex];

    // Auto-generate title for a new chat
    if (currentSession.messages.length == 1) {
      currentSession.title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    }

    currentSession.messages.add(RichChatMessage(text: text, isUser: true));

    // Pop the active chat to the top of the Drawer list
    _sessions.removeAt(sessionIndex);
    _sessions.insert(0, ChatSession(id: currentSession.id, title: currentSession.title, updatedAt: DateTime.now(), messages: currentSession.messages));

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String promptToSend = text;
      final lowerText = text.toLowerCase();
      final isQuestion = lowerText.contains('how much') || lowerText.contains('total') || lowerText.contains('what') || text.contains('?');

      if (isQuestion && messages.length > 1) {
        final chatLog = messages.sublist(0, messages.length - 1).map((m) => '${m.isUser ? 'User' : 'Arth AI'}: ${m.text}').join('\n');
        promptToSend = '''
[SYSTEM STRICT INSTRUCTION]
The user is asking a QUESTION.
1. Do NOT trigger any functions to log expenses.
2. Answer based on conversation history and user financial data.
3. Reply in ${_language == 'tamil' ? 'Tanglish' : 'English'}.
--- HISTORY ---
$chatLog
---
User: "$text"
''';
      }

      final response = await _aiService.processMessage(userId: _userId!, text: promptToSend, language: _language);
      final replyText = response.displayText.isNotEmpty ? response.displayText : loc.errorFallback;

      _sessions[0].messages.add(RichChatMessage(text: replyText, isUser: false, richResponse: response));
    } catch (e) {
      _sessions[0].messages.add(RichChatMessage(text: loc.errorGeneral, isUser: false));
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      await _saveAllSessions();
    }
  }

  void toggleLanguage() async {
    _language = _language == 'english' ? 'tamil' : 'english';
    await LocalStorage.setLanguage(_language);
    _sessions.first.messages.add(RichChatMessage(text: _language == 'tamil' ? 'Tanglish mode on! Naan ipo Tamil-la pesuven 🎉' : 'Switched to English mode!', isUser: false));
    notifyListeners();
  }

  void clearChat() async {
    _sessions.clear();
    createNewSession();
  }
}