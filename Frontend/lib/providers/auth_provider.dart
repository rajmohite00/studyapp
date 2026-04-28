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

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? initialized}) =>
      AuthState(
        user: user ?? this.user,
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

  Future<void> _init() async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      final cachedMap = StorageService.getUserCache();
      if (cachedMap != null) {
        state = AuthState(user: UserModel.fromJson(cachedMap), initialized: true);
      }

      try {
        final user = await _service.getMe();
        await StorageService.saveUserCache(user.toJson());
        state = AuthState(user: user, initialized: true);
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          await StorageService.clearTokens();
          await StorageService.clearUserCache();
          state = const AuthState(initialized: true);
        } else {
          if (cachedMap == null) {
            state = const AuthState(initialized: true);
          }
        }
      }
    } else {
      state = const AuthState(initialized: true);
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.register(name: name, email: email, password: password);
      final user = UserModel.fromJson(data['user']);
      await StorageService.saveUserCache(user.toJson());
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.login(email: email, password: password);
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
    await _service.logout();
    await StorageService.clearUserCache();
    state = const AuthState(initialized: true);
  }

  void forceLogout() {
    StorageService.clearTokens();
    StorageService.clearUserCache();
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
