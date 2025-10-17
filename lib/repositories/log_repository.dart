import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/log_entry.dart';

class LogsRepository {
  final Dio dio;
  LogsRepository(this.dio);

  Future<void> createLog(LogEntry entry) async {
    await dio.post(ApiPaths.subUserLog, data: entry.toJson());
  }

  Future<List<LogEntry>> listBySubUser(String userId, String subUserId) async {
    final res = await dio.get(ApiPaths.subUserLogs(userId, subUserId));
    final data = res.data as List;
    return data
        .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
