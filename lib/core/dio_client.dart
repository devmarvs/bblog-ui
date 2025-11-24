import 'package:dio/dio.dart';
import 'constants.dart';
import 'storage/token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage _tokenStorage;
  void Function()? onUnauthorized;

  DioClient({TokenStorage? storage, this.onUnauthorized})
    : dio = Dio(
        BaseOptions(
          baseUrl: kApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      ),
      _tokenStorage = storage ?? const TokenStorage() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Allow callers to opt out of auth header (e.g., public endpoints).
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await _tokenStorage.read();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Basic 401 handling → notify app to logout
          final path = e.requestOptions.path;
          final isLoginRequest = path.endsWith(ApiPaths.login);
          final isVerificationRequest = path.endsWith(
                ApiPaths.emailVerificationRequest,
              ) ||
              path.endsWith(ApiPaths.emailVerificationRequestLegacy) ||
              path.endsWith(ApiPaths.emailVerificationConfirm);

          // Ignore auth failures on login/verification endpoints so we can
          // surface the actual error message instead of resetting state.
          if (e.response?.statusCode == 401 &&
              !isLoginRequest &&
              !isVerificationRequest) {
            await _tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
  }
}
