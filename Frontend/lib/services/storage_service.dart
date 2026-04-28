import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static late Box _box;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> init() async {
    _box = await Hive.openBox('study_coach_prefs');
  }

  // ── Tokens ─────────────────────────────────────────────────────────────────
  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
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
