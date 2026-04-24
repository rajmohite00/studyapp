import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

// ── App Config ─────────────────────────────────────────────────────────────
// To use a local backend during development:
//   Change _kBaseUrl to 'http://10.0.2.2:3000/api/v1' (Android emulator)
//   or     'http://localhost:3000/api/v1'              (Windows/iOS simulator)
const String _kBaseUrl = 'https://studyapp-e1sp.onrender.com/api/v1';

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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));

    // Only log in debug builds — never log tokens/bodies in production
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }

    return dio;
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
            await StorageService.clearTokens();
            DioClient.onUnauthorized?.call();
          }
        } catch (_) {
          await StorageService.clearTokens();
          DioClient.onUnauthorized?.call();
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
      final response = await Dio(BaseOptions(baseUrl: _kBaseUrl))
          .post('/auth/refresh', data: {'refreshToken': refreshToken});

      final data = response.data['data'];
      await StorageService.saveTokens(data['accessToken'], data['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── API Response Helper ─────────────────────────────────────────────────────
extension ApiResponse on Response {
  dynamic get apiData => data['data'];
}
