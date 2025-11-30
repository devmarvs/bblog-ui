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

  Future<AuthResponse?> signup({
    required String username,
    required String email,
    required String password,
    String? mobile,
    String? countryCode,
  }) async {
    final normalizedCountry = countryCode?.trim().toUpperCase();
    final normalizedMobile = mobile?.trim();
    final res = await dio.post(
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
    final data = res.data;
    if (data is Map<String, dynamic> && data.containsKey('token')) {
      return AuthResponse.fromJson(data);
    }
    return null;
  }

  Future<void> requestEmailVerification({required String email}) async {
    final trimmed = email.trim();
    // Backend now supports multiple public aliases for resend.
    final endpoints = <String>[
      ApiPaths.emailVerificationRequest,
      ApiPaths.emailVerificationResend,
      ApiPaths.emailVerificationRequestLegacy,
      '/user/verify-email', // no-prefix alias
      '/user/verify-email/request',
      '/user/resend-verification',
    ];

    DioException? lastError;
    for (final path in endpoints) {
      for (final skipAuth in [true, false]) {
        // Try POST
        try {
          await dio.post(
            path,
            data: {'email': trimmed},
            options: Options(extra: {'skipAuth': skipAuth}),
          );
          return;
        } on DioException catch (e) {
          lastError = e;
          if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
            rethrow;
          }
          // Else try GET below.
        }

        // Try GET
        try {
          await dio.get(
            path,
            queryParameters: {'email': trimmed},
            options: Options(extra: {'skipAuth': skipAuth}),
          );
          return;
        } on DioException catch (e) {
          lastError = e;
          if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
            rethrow;
          }
        }
      }
    }

    if (lastError != null) throw lastError;
  }

  Future<void> confirmEmailVerification({
    required String email,
    required String verificationCode,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedCode = verificationCode.trim();
    // Try primary + confirm-only aliases in case the backend is configured differently.
    final endpoints = <String>[
      ApiPaths.emailVerificationConfirmAlt, // /bblog/user/verify
      ApiPaths.emailVerificationConfirm,
      '/user/verify-email/confirm', // no-prefix alias
      '/user/verify-email', // some backends accept confirm via same endpoint
    ];

    DioException? lastError;
    for (final path in endpoints) {
      for (final skipAuth in [true, false]) {
        try {
          await dio.post(
            path,
            data: {'email': trimmedEmail, 'code': trimmedCode},
            options: Options(extra: {'skipAuth': skipAuth}),
          );
          return;
        } on DioException catch (e) {
          lastError = e;
          if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
            rethrow;
          }
        }

        // Some environments require GET; try that before giving up.
        try {
          await dio.get(
            path,
            queryParameters: {'email': trimmedEmail, 'code': trimmedCode},
            options: Options(extra: {'skipAuth': skipAuth}),
          );
          return;
        } on DioException catch (e) {
          lastError = e;
          if (e.response?.statusCode != 404 && e.response?.statusCode != 401) {
            rethrow;
          }
        }
      }
    }

    if (lastError != null) throw lastError;
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
