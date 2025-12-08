import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/version_info.dart';

class VersionRepository {
  VersionRepository(this.dio);

  final Dio dio;

  Future<VersionInfo?> fetch() async {
    const endpoints = <String>[
      ApiPaths.version, // primary
      '/version', // no-prefix fallback
      ApiPaths.versioning, // legacy
      '/versioning', // legacy no-prefix
    ];

    for (final path in endpoints) {
      for (final skipAuth in [true, false]) {
        try {
          final res = await dio.get(
            path,
            options: Options(extra: {'skipAuth': skipAuth}),
          );
          final parsed = _parseVersion(res.data);
          if (parsed != null) return parsed;
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 404 || status == 401 || status == 403) {
            continue;
          }
          rethrow;
        } catch (_) {}
      }
    }

    return null;
  }

  VersionInfo? _parseVersion(dynamic data) {
    VersionInfo? fromMap(Map map) {
      final normalized = map.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final info = VersionInfo.fromJson(normalized);
      final hasValue = info.mobileVersion != null ||
          info.apiVersion != null ||
          info.webVersion != null ||
          info.minimumMobileVersion != null;
      return hasValue ? info : null;
    }

    if (data is Map) {
      final direct = fromMap(data);
      if (direct != null) return direct;
      for (final value in data.values) {
        final nested = _parseVersion(value);
        if (nested != null) return nested;
      }
    }

    if (data is List) {
      for (final item in data) {
        final nested = _parseVersion(item);
        if (nested != null) return nested;
      }
    }

    return null;
  }
}
