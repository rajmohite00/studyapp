import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

// ── App Config ─────────────────────────────────────────────────────────────
const String _kBaseUrl = 'https://studyapp-e1sp.onrender.com/api/v1';

// Paths that call Groq AI and can take 60-90 seconds
const _kLongTimeoutPaths = ['/tests/create', '/analyse', '/exam-plan/create'];

class DioClient {
  static Dio? _instance;
  static VoidCallback? onUnauthorized;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90), // default; overridden per-request below
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));
    dio.interceptors.add(_TimeoutInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    return dio;
  }
}

/// Per-request timeout — give AI-heavy routes 3 minutes.
class _TimeoutInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isLong = _kLongTimeoutPaths.any((p) => options.path.contains(p));
    if (isLong) {
      options.receiveTimeout = const Duration(minutes: 3);
      options.connectTimeout = const Duration(seconds: 20);
    }
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  Future<bool>? _refreshFuture;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If a refresh is already in progress, wait for it
      if (_refreshFuture != null) {
        try {
          final refreshed = await _refreshFuture!;
          if (refreshed) {
            final token = await StorageService.getAccessToken();
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(err.requestOptions);
            return handler.resolve(response);
          }
        } catch (_) {}
      } else {
        // Start a new refresh process
        _refreshFuture = _refreshTokens();
        try {
          final refreshed = await _refreshFuture!;
          if (refreshed) {
            final token = await StorageService.getAccessToken();
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(err.requestOptions);
            return handler.resolve(response);
          } else {
            await StorageService.clearSession();
            DioClient.onUnauthorized?.call();
          }
        } on DioException catch (e) {
          // If the refresh request itself got a 401/403, we clear tokens.
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            await StorageService.clearSession();
            DioClient.onUnauthorized?.call();
          }
          // Otherwise, it was a network error (like Render waking up timeout). Let the error bubble up without logging out.
        } catch (_) {
          // Non-dio error, just let it fail without clearing tokens.
        } finally {
          _refreshFuture = null;
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: _kBaseUrl, connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)))
          .post('/auth/refresh', data: {'refreshToken': refreshToken});

      final data = response.data['data'];
      await StorageService.saveTokens(data['accessToken'], data['refreshToken']);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return false;
      }
      rethrow;
    }
  }
}

// ── API Response Helper ─────────────────────────────────────────────────────
extension ApiResponse on Response {
  dynamic get apiData => data['data'];
}
