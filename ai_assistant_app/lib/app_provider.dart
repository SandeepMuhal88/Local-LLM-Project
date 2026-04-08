import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'models/chat_session.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String _userName = '';
  int _avatarIndex = 0;
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  int get avatarIndex => _avatarIndex;
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  ChatSession? get currentSession => _currentSession;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _isDarkMode = await StorageService.isDarkMode();
    _userName = await StorageService.getUserName() ?? '';
    _avatarIndex = await StorageService.getUserAvatarIndex();
    _sessions = await StorageService.getAllSessions();
    final savedId = await StorageService.getCurrentSessionId();
    if (savedId != null) {
      _currentSession = _sessions.firstWhere(
        (s) => s.id == savedId,
        orElse: () => _sessions.isNotEmpty ? _sessions.first : ChatSession.create(),
      );
    }
    _isLoaded = true;
    notifyListeners();
  }

  // ─── Theme ────────────────────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  // ─── Profile ──────────────────────────────────────────────────────────────
  Future<void> setUserName(String name) async {
    _userName = name;
    await StorageService.saveUserName(name);
    notifyListeners();
  }

  Future<void> setAvatarIndex(int index) async {
    _avatarIndex = index;
    await StorageService.saveUserAvatarIndex(index);
    notifyListeners();
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────
  Future<ChatSession> createNewSession() async {
    final session = ChatSession.create();
    _sessions.insert(0, session);
    _currentSession = session;
    await StorageService.saveSession(session);
    await StorageService.saveCurrentSessionId(session.id);
    notifyListeners();
    return session;
  }

  Future<void> selectSession(ChatSession session) async {
    _currentSession = session;
    await StorageService.saveCurrentSessionId(session.id);
    notifyListeners();
  }

  Future<void> updateCurrentSession() async {
    if (_currentSession == null) return;
    final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (idx >= 0) _sessions[idx] = _currentSession!;
    await StorageService.saveSession(_currentSession!);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    if (_currentSession?.id == id) {
      _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
    }
    await StorageService.deleteSession(id);
    notifyListeners();
  }
}
