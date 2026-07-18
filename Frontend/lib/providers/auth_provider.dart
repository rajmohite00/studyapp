import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool initialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.initialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? initialized,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        initialized: initialized ?? this.initialized,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _init();
  }

  /// On startup, check if a valid 7-day session exists in SharedPreferences.
  /// - If valid:  restore user from cache (instant) → navigate to home.
  /// - If expired: clear all session data → go to login.
  /// A background network refresh is done silently after restoring from cache.
  Future<void> _init() async {
    try {
      if (StorageService.isSessionValid()) {
        // Restore from local cache — instant, no spinner
        final cachedMap = StorageService.getUserCache();
        if (cachedMap != null) {
          try {
            final cachedUser = UserModel.fromJson(cachedMap);
            state = AuthState(user: cachedUser, initialized: true);
            // Silently refresh user data from the server in background
            _refreshUserInBackground();
            return;
          } catch (_) {
            await StorageService.clearUserCache();
          }
        }

        // Cache missing but session valid — fetch from network once
        try {
          final user = await _service.getMe();
          await StorageService.saveUserCache(user.toJson());
          state = AuthState(user: user, initialized: true);
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 401) {
            // Server rejected token — clear session
            await StorageService.clearSession();
            state = const AuthState(initialized: true);
          } else {
            // Network/server error (e.g. Render cold start) — keep offline
            state = const AuthState(initialized: true);
          }
        }
      } else {
        // Session expired or doesn't exist — clear any remnants
        await StorageService.clearSession();
        state = const AuthState(initialized: true);
      }
    } catch (_) {
      await StorageService.clearSession();
      state = const AuthState(initialized: true);
    }
  }

  /// Silently refresh user profile from server after cache restore.
  Future<void> _refreshUserInBackground() async {
    try {
      final user = await _service.getMe();
      await StorageService.saveUserCache(user.toJson());
      if (mounted) state = state.copyWith(user: user);
    } catch (_) {
      // Ignore — cached data stays valid
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.register(name: name, email: email, password: password);
      final user = UserModel.fromJson(data['user']);
      // Persist 7-day session
      await StorageService.saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        userId: user.id,
      );
      await StorageService.saveUserCache(user.toJson());
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rawData = await _service.loginRaw(email: email, password: password);
      final user = UserModel.fromJson(rawData['user']);
      // Persist 7-day session
      await StorageService.saveSession(
        accessToken: rawData['accessToken'],
        refreshToken: rawData['refreshToken'],
        userId: user.id,
      );
      await StorageService.saveUserCache(user.toJson());
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.updateProfile(data);
      await StorageService.saveUserCache(user.toJson());
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } finally {
      await StorageService.clearSession();
      state = const AuthState(initialized: true);
    }
  }

  void forceLogout() {
    StorageService.clearSession();
    state = const AuthState(initialized: true);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet.';
      }
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error']['message'] ?? 'Authentication failed';
      }
      return e.response?.statusMessage ?? 'Something went wrong. Please try again.';
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}

final authServiceProvider = Provider((_) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

