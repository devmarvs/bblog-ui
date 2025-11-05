class SubUserModel {
  final String subUserId;
  final String userId;
  final String name;
  final String? description;
  final int? userTypeId;
  final int? subUserNumericId;

  SubUserModel({
    required this.subUserId,
    required this.userId,
    required this.name,
    this.description,
    this.userTypeId,
    this.subUserNumericId,
  });

  factory SubUserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['subUserId'] ??
        json['sub_user_id'] ??
        json['subUserID'] ??
        json['sub_userid'] ??
        json['subuserId'] ??
        json['subuser_id'] ??
        json['id'];
    final rawUserId = json['userId'] ?? json['user_id'];
    return SubUserModel(
      subUserId: rawId?.toString() ?? '',
      userId: rawUserId?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      userTypeId: _parseUserTypeId(json),
      subUserNumericId: _parseNumericId(rawId),
    );
  }

  static int? _parseUserTypeId(Map<String, dynamic> json) {
    final raw = json['userTypeId'] ??
        json['user_type_id'] ??
        json['userTypeID'] ??
        json['user_typeid'] ??
        json['userType'] ??
        json['typeId'] ??
        json['type_id'];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static int? _parseNumericId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final asString = raw.toString().trim();
    if (asString.isEmpty) return null;
    final direct = int.tryParse(asString);
    if (direct != null) return direct;
    final asDouble = double.tryParse(asString);
    return asDouble?.toInt();
  }
}
