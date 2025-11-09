import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/log_entry.dart';

class LogsRepository {
  final Dio dio;
  LogsRepository(this.dio);

  Future<void> createLog(LogEntry entry) async {
    await dio.post(ApiPaths.subUserLog, data: entry.toJson());
  }

  Future<LogsFetchResult> listBySubUser(String userId, String subUserId) async {
    final res = await dio.get(ApiPaths.subUserLogs(userId, subUserId));
    final raw = res.data;
    final list = _extractLogList(raw);
    final entries = list
        .whereType<Map<String, dynamic>>()
        .map(LogEntry.fromJson)
        .toList();
    return LogsFetchResult(entries: entries, rawResponse: raw);
  }

  List<dynamic> _extractLogList(dynamic raw) {
    final list = _findList(raw);
    if (list != null) return list;
    // When the API returns null/empty payloads for sub-users with no logs,
    // treat it as an empty collection so the UI can show a friendly message
    // instead of surfacing a parsing error.
    if (raw == null) return const [];
    if (raw is Map && raw.isEmpty) return const [];
    if (raw is List && raw.isEmpty) return const [];
    return const [];
  }

  List<dynamic>? _findList(dynamic node) {
    if (node is List) return node;
    if (node is Map) {
      for (final value in node.values) {
        final result = _findList(value);
        if (result != null) return result;
      }
    }
    return null;
  }
}

class LogsFetchResult {
  LogsFetchResult({required this.entries, required this.rawResponse});

  final List<LogEntry> entries;
  final dynamic rawResponse;
}
