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
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Basic 401 handling → notify app to logout
          if (e.response?.statusCode == 401) {
            await _tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
  }
}
