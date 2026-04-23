import 'package:dio/dio.dart';
import 'storage_service.dart';

const String _baseUrl = 'http://10.132.127.43:3000/api/v1';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    ]);

    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshTokens();
        if (refreshed) {
          // Retry original request
          final token = await StorageService.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        await StorageService.clearTokens();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: _baseUrl))
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
