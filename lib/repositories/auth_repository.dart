import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final Dio dio;
  AuthRepository(this.dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? country,
  }) async {
    await dio.post(
      ApiPaths.userCreate,
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (country != null) 'country': country,
      },
    );
  }
}
