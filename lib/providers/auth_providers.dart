import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dio_client.dart';
import '../core/storage/token_storage.dart';
import '../repositories/auth_repository.dart';

class AuthState {
  const AuthState({this.token, this.loading = false, this.error});

  final String? token;
  final bool loading;
  final String? error;

  static const _sentinel = Object();

  AuthState copyWith({
    Object? token = _sentinel,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return AuthState(
      token: token == _sentinel ? this.token : token as String?,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final TokenStorage _storage;
  late final DioClient _dioClient;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    _storage = ref.watch(tokenStorageProvider);
    _dioClient = ref.watch(dioClientProvider);
    _dioClient.onUnauthorized = _handleUnauthorized;
    ref.onDispose(() {
      _dioClient.onUnauthorized = null;
    });
    _init();
    return const AuthState(loading: true);
  }

  Future<void> _init() async {
    final token = await _storage.read();
    if (!ref.mounted) return;
    state = AuthState(token: token);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(token: null, loading: true, error: null);
    try {
      final res = await _repo.login(email: email, password: password);
      await _storage.save(res.token);
      state = AuthState(token: res.token);
    } on DioException catch (e) {
      final message =
          e.response?.data?.toString() ?? e.message ?? 'Failed to log in';
      state = AuthState(token: null, error: message);
    } catch (e) {
      state = AuthState(token: null, error: e.toString());
    }
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? country,
  }) async {
    state = state.copyWith(token: null, loading: true, error: null);
    try {
      await _repo.signup(
        username: username,
        email: email,
        password: password,
        phone: phone,
        country: country,
      );
      await login(email, password);
    } on DioException catch (e) {
      final message =
          e.response?.data?.toString() ?? e.message ?? 'Failed to sign up';
      state = AuthState(token: null, error: message);
    } catch (e) {
      state = AuthState(token: null, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(token: null);
  }

  void _handleUnauthorized() {
    unawaited(logout());
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(),
);

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(storage: storage);
});

final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
