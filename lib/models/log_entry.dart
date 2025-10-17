class LogEntry {
  final String userLog;
  final String subUserId;
  final int logTypeId; // e.g. 1=milk,2=diaper ... per your API
  final String? logName;
  final DateTime logTime;
  final String? logDescription;

  LogEntry({
    required this.userLog,
    required this.subUserId,
    required this.logTypeId,
    required this.logTime,
    this.logName,
    this.logDescription,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    userLog: json['userLog'].toString(),
    subUserId: json['subUserId'].toString(),
    logTypeId: int.tryParse(json['logTypeId'].toString()) ?? 0,
    logName: json['logName'],
    logTime: DateTime.parse(json['logTime']),
    logDescription: json['logDescription'],
  );

  Map<String, dynamic> toJson() => {
    'userLog': userLog,
    'subUserId': subUserId,
    'logTypeId': logTypeId,
    if (logName != null) 'logName': logName,
    'logTime': logTime.toIso8601String(),
    if (logDescription != null) 'logDescription': logDescription,
  };
}
