import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/user_type.dart';

class UserTypeRepository {
  final Dio dio;
  UserTypeRepository(this.dio);

  Future<List<UserType>> list() async {
    final res = await dio.get(ApiPaths.userTypes);
    final payload = res.data;
    final list = _extractList(payload);
    return list
        .map((e) => UserType.fromJson(e as Map<String, dynamic>))
        .where((type) => type.id != 0)
        .toList();
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      const keys = ['data', 'items', 'results', 'userTypes', 'user_types'];
      for (final key in keys) {
        final value = payload[key];
        if (value is List) return value;
      }
    }
    throw StateError('Unexpected user type response: ${payload.runtimeType}');
  }
}
