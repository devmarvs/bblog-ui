import 'package:intl/intl.dart';

class LogEntry {
  final String userLog;
  final String subUserId;
  final int? subUserNumericId;
  final int logTypeId; // e.g. 1=milk,2=diaper ... per your API
  final String? logName;
  final DateTime logTime;
  final String? logDescription;

  LogEntry({
    required this.userLog,
    required this.subUserId,
    this.subUserNumericId,
    required this.logTypeId,
    required this.logTime,
    this.logName,
    this.logDescription,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final subUser = json['subUserId'] ?? json['sub_user_id'];
    final logType = json['logTypeId'] ?? json['log_type_id'];
    final logName = json['logName'] ?? json['log_name'];
    final logDescription = json['logDescription'] ?? json['log_description'];
    final userLog = json['userLog'] ?? json['user_log'];
    final rawTime = json['logTime'] ?? json['log_time'];
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    DateTime parseLogTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? formatter.parse(value);
      }
      throw FormatException('Unsupported logTime format: $value');
    }

    return LogEntry(
      userLog: userLog?.toString() ?? '',
      subUserId: subUser?.toString() ?? '',
      subUserNumericId: _parseFlexibleInt(subUser),
      logTypeId: int.tryParse(logType?.toString() ?? '') ?? 0,
      logName: logName?.toString(),
      logTime: parseLogTime(rawTime),
      logDescription: logDescription?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final subUser = subUserNumericId ?? _parseFlexibleInt(subUserId);
    if (subUser == null) {
      throw const FormatException('sub_user_id must be numeric');
    }

    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final description = logDescription ?? '';

    return {
      'sub_user_id': subUser,
      'log_type_id': logTypeId,
      'log_time': formatter.format(logTime),
      'log_description': description,
    };
  }

  static int? _parseFlexibleInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final direct = int.tryParse(value);
    if (direct != null) return direct;
    final asDouble = double.tryParse(value);
    return asDouble?.toInt();
  }
}
