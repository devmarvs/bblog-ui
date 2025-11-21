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
    String? mobile,
    String? countryCode,
  }) async {
    final normalizedCountry = countryCode?.trim().toUpperCase();
    final normalizedMobile = mobile?.trim();
    await dio.post(
      ApiPaths.userCreate,
      data: {
        'user_type_id': 1, // 1 = user (required by API)
        'username': username,
        'email': email,
        'password': password,
        if (normalizedMobile != null && normalizedMobile.isNotEmpty)
          'mobile': normalizedMobile,
        if (normalizedCountry != null && normalizedCountry.isNotEmpty)
          'country_code': normalizedCountry,
      },
    );
  }

  Future<void> requestEmailVerification({required String email}) async {
    await dio.post(ApiPaths.emailVerificationRequest, data: {'email': email});
  }

  Future<void> confirmEmailVerification({
    required String email,
    required String verificationCode,
  }) async {
    await dio.post(
      ApiPaths.emailVerificationConfirm,
      data: {'email': email, 'code': verificationCode},
    );
  }

  Future<void> requestPasswordReset({required String email}) async {
    await dio.post(ApiPaths.passwordForgot, data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    await dio.post(
      ApiPaths.passwordReset,
      data: {'email': email, 'code': verificationCode, 'password': newPassword},
    );
  }
}
