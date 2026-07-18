import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late Box _box;
  static late SharedPreferences _prefs;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'session_user_id';
  static const _loginTimeKey = 'session_login_time';
  static const _expiryTimeKey = 'session_expiry_time';

  static Future<void> init() async {
    _box = await Hive.openBox('study_coach_prefs');
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Tokens & Session ──────────────────────────────────────────────────────
  static Future<void> saveTokens(String access, String refresh) async {
    await _prefs.setString(_accessTokenKey, access);
    await _prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await saveTokens(accessToken, refreshToken);
    await _prefs.setString(_userIdKey, userId);
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 7));
    await _prefs.setString(_loginTimeKey, now.toIso8601String());
    await _prefs.setString(_expiryTimeKey, expiry.toIso8601String());
  }

  static Future<String?> getAccessToken() async => _prefs.getString(_accessTokenKey);
  static Future<String?> getRefreshToken() async => _prefs.getString(_refreshTokenKey);
  static String? getSessionUserId() => _prefs.getString(_userIdKey);

  static DateTime? getSessionLoginTime() {
    final str = _prefs.getString(_loginTimeKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  static DateTime? getSessionExpiryTime() {
    final str = _prefs.getString(_expiryTimeKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  static bool isSessionValid() {
    final token = _prefs.getString(_accessTokenKey);
    if (token == null || token.isEmpty) return false;

    final expiry = getSessionExpiryTime();
    if (expiry == null) return false;

    return DateTime.now().isBefore(expiry);
  }

  static Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  static Future<void> clearSession() async {
    await clearTokens();
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_loginTimeKey);
    await _prefs.remove(_expiryTimeKey);
    await clearUserCache();
  }

  // ── User Cache ─────────────────────────────────────────────────────────────
  static Future<void> saveUserCache(Map<String, dynamic> userJson) => _box.put('cached_user', userJson);
  static Map<String, dynamic>? getUserCache() {
    final data = _box.get('cached_user');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }
  static Future<void> clearUserCache() => _box.delete('cached_user');

  // ── Generic Prefs ──────────────────────────────────────────────────────────
  static Future<void> put(String key, dynamic value) => _box.put(key, value);
  static T? get<T>(String key, {T? defaultValue}) => _box.get(key, defaultValue: defaultValue) as T?;
  static Future<void> delete(String key) => _box.delete(key);
  static Future<void> clearAll() => _box.clear();

  // ── Offline Session Buffer ─────────────────────────────────────────────────
  static Future<void> bufferOfflineSession(Map<String, dynamic> session) async {
    final List existing = _box.get('offline_sessions', defaultValue: []);
    existing.add(session);
    await _box.put('offline_sessions', existing);
  }

  static List getOfflineSessions() => _box.get('offline_sessions', defaultValue: []);

  static Future<void> clearOfflineSessions() => _box.delete('offline_sessions');
}
