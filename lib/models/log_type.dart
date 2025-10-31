class LogType {
  final int id;
  final String name;

  const LogType({required this.id, required this.name});

  factory LogType.fromJson(Map<String, dynamic> json) {
    final idValue = json['log_type_id'] ?? json['logTypeId'] ?? json['id'];
    final nameValue = json['log_name'] ?? json['logName'] ?? json['name'];
    return LogType(
      id: (idValue is int) ? idValue : int.tryParse(idValue.toString()) ?? 0,
      name: nameValue?.toString() ?? 'Unknown',
    );
  }
}
