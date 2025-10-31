import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/log_type.dart';

class LogTypeRepository {
  final Dio dio;
  LogTypeRepository(this.dio);

  Future<List<LogType>> list() async {
    final res = await dio.get(ApiPaths.logTypes);
    final payload = res.data;
    final list = _extractList(payload);
    return list
        .map((item) => LogType.fromJson(item as Map<String, dynamic>))
        .where((lt) => lt.id != 0)
        .toList();
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      const keys = ['data', 'logTypes', 'log_types', 'items', 'results'];
      for (final key in keys) {
        final value = payload[key];
        if (value is List) return value;
      }
    }
    throw StateError('Unexpected log type response: ${payload.runtimeType}');
  }
}
