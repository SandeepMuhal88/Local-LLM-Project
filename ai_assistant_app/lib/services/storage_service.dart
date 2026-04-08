import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/chat_session.dart';

class StorageService {
  static const _keyUserName = 'rama_user_name';
  static const _keyUserAvatar = 'rama_user_avatar';
  static const _keyThemeMode = 'rama_theme_mode';
  static const _keySessions = 'rama_chat_sessions';
  static const _keyCurrentSessionId = 'rama_current_session_id';
  static const _keyFirstLaunch = 'rama_first_launch';

  // ─── User profile ─────────────────────────────────────────────────────────
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<int> getUserAvatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserAvatar) ?? 0;
  }

  static Future<void> saveUserAvatarIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserAvatar, index);
  }

  // ─── Theme ────────────────────────────────────────────────────────────────
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeMode) ?? true;
  }

  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDark);
  }

  // ─── First launch ─────────────────────────────────────────────────────────
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  static Future<void> setNotFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  // ─── Chat Sessions ────────────────────────────────────────────────────────
  static Future<List<ChatSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keySessions) ?? [];
    return raw.map((s) => ChatSession.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllSessions();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.add(session);
    }
    await prefs.setStringList(
      _keySessions,
      all.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  static Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllSessions();
    all.removeWhere((s) => s.id == id);
    await prefs.setStringList(
      _keySessions,
      all.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  static Future<void> saveCurrentSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentSessionId, id);
  }

  static Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentSessionId);
  }
}
