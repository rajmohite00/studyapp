import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final _dio = DioClient.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = res.data['data'];
    await StorageService.saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data['data'];
    await StorageService.saveTokens(data['accessToken'], data['refreshToken']);
    return UserModel.fromJson(data['user']);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await StorageService.clearTokens();
    }
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data['data']);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
}
